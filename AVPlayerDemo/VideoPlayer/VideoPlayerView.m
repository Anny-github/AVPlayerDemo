//
//  VideoPlayer.m
//  AVPlayerDemo
//
//  Created by anne on 16/12/7.
//  Copyright © 2016年 anne. All rights reserved.
//

#import "VideoPlayerView.h"
#import <AVFoundation/AVFoundation.h>
#import "Masonry.h"


#define SCREEN_WIDTH    [[UIScreen mainScreen] bounds].size.width
#define SCREEN_HEIGHT   [[UIScreen mainScreen] bounds].size.height

#define MovieURL @"http://7xnujb.com2.z0.glb.qiniucdn.com/%E5%A4%8F%E8%87%B3%E6%9C%AA%E8%87%B301/001.mp4"

@interface VideoPlayerView ()
{
    AVPlayer *_player;
    AVPlayerItem *_playerItem;
    NSString *_videoUrl;
    AVPlayerLayer *_videoLayer;
    UIActivityIndicatorView *_indicatorView;
    CGFloat totalTime;
    CGFloat currentTime;
    
    UIButton *_pauseBtn;
    UISlider *_prosessSlider;
    UIButton *_fullScreenBtn;
    
    BOOL _isFullScreen;
    CGFloat _totalTime;
    PlayingStatus _playStatus;
    UIView *_controlView;
    CGRect _originalFrame;
    Reachability *_reach;
    CGPoint _panBeginPoint;
    UIView *_rollTimeView;
    
    BOOL haveShowPlayAlert;
}
@end
@implementation VideoPlayerView

-(instancetype)initWithFrame:(CGRect)frame videoUrl:(NSString*)urlString{
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor blackColor];
        _originalFrame = frame;
        _videoUrl = MovieURL;
        _totalTime = -1;
        [self setUI];
        [self preparePlay];

    }
    return self;
}
-(void)setFrame:(CGRect)frame{
    [super setFrame:frame];
    _videoLayer.frame = self.layer.bounds;
    _controlView.frame = self.bounds;
}
-(void)setUI{
    
    _controlView = [[UIView alloc]initWithFrame:self.bounds];
    _controlView.backgroundColor = [UIColor clearColor];
    [self addSubview:_controlView];
    
    _pauseBtn = [[UIButton alloc]initWithFrame:CGRectMake(0, self.frame.size.height - 40, 40, 40)];
    
    [_controlView addSubview:_pauseBtn];
    
    _prosessSlider = [[UISlider alloc]initWithFrame:CGRectMake(_pauseBtn.frame.size.width , _pauseBtn.frame.origin.y , self.frame.size.width - 80 , 40)];
    _prosessSlider.minimumValue = 0;
    _prosessSlider.maximumValue = 1;
    _prosessSlider.thumbTintColor = [UIColor redColor];
    _prosessSlider.tintColor = [UIColor whiteColor];
    _prosessSlider.continuous = NO;
    [_prosessSlider addTarget:self action:@selector(sliderChange:) forControlEvents:UIControlEventValueChanged];
    [_controlView addSubview:_prosessSlider];
    _fullScreenBtn = [[UIButton alloc]initWithFrame:CGRectMake(self.frame.size.width - 40, _pauseBtn.frame.origin.y, 40, 40)];
    _pauseBtn.selected = NO;
    [_controlView addSubview:_fullScreenBtn];

    
    [_pauseBtn setImage:[UIImage imageNamed:@"kr-video-player-pause"] forState:UIControlStateNormal];
    [_pauseBtn setImage:[UIImage imageNamed:@"kr-video-player-play"] forState:UIControlStateSelected];
    [_fullScreenBtn setImage:[UIImage imageNamed:@"fullScreenBtnImg"] forState:UIControlStateNormal];
    [_fullScreenBtn setImage:[UIImage imageNamed:@"existFullScreenBtnImg"] forState:UIControlStateSelected];
    
    [_pauseBtn addTarget:self action:@selector(pauseBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    [_fullScreenBtn addTarget:self action:@selector(fullScreenBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    
   /* [_controlView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.mas_left);
        make.right.equalTo(self.mas_right);
        make.top.equalTo(self.mas_top);
        make.bottom.equalTo(self.mas_bottom);
    }];*/
//
    [_pauseBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(_controlView.mas_left);
        make.bottom.equalTo(_controlView.mas_bottom);
        make.width.equalTo(@(40));
        make.height.equalTo(@(40));
    }];
    [_fullScreenBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(_controlView.mas_right);
        make.bottom.equalTo(_controlView.mas_bottom);
        make.width.equalTo(@(40));
        make.height.equalTo(@(40));
    }];
    
    [_prosessSlider mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(_pauseBtn.mas_right);
        make.top.equalTo(_pauseBtn.mas_top);
        make.right.equalTo(_fullScreenBtn.mas_left);
        make.height.equalTo(@(40));
    }];
    
    
    //给controlView加滑动手势
    [_controlView addGestureRecognizer:[[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(controlViewPanHandle:)]];

    //初始化播放器layer
    _videoLayer = [AVPlayerLayer playerLayerWithPlayer:[self player]];
    _videoLayer.frame = self.layer.bounds;
    [self.layer insertSublayer:_videoLayer atIndex:0];
    _videoLayer.videoGravity = AVLayerVideoGravityResizeAspect; //视频填充模式

}

-(void)layoutSubviews{
    [super layoutSubviews];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillEnterForeground:) name:UIApplicationDidBecomeActiveNotification object:nil];
    
    //先开启播放 再监测网络
    [self networkNotification];
   
}

-(void)networkNotification{

    _reach = [Reachability reachabilityWithHostname:@"www.baidu.com"];
    
    // Set the blocks
    __weak typeof(self) weakSelf = self;
    _reach.reachableBlock = ^(Reachability*reach)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            
            NSLog(@"REACHABLE!");
        });
    };
    
    _reach.unreachableBlock = ^(Reachability*reach)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf failedNetworkAlert];
        });
        NSLog(@"UNREACHABLE!");
    };
    
    // Start the notifier, which will cause the reachability object to retain itself!
    [_reach startNotifier];
}
-(void)appDidEnterBackground:(NSNotification*)tf{
    /*if (_playStatus == PlayingStatus_Playing) {
        [self pauseBtnClick:_pauseBtn];
        
    }*/
}

//回来继续播放
-(void)appWillEnterForeground:(NSNotification*)tf{
    
   if (_playStatus == PlayingStatus_Pause) {
       _pauseBtn.selected = YES;
       [_player pause];

   }else{
       _pauseBtn.selected = NO;
       [_player play];
       haveShowPlayAlert = NO;
       [self playAlert]; //如果进入后台前在播放，进入仍播放，只不过检测一次网络
   }
}
#pragma mark --get 播放相关类--
-(AVPlayer*)player{
    if (_player == nil) {
        AVPlayerItem *playerItem = [self playerItem:_videoUrl];
        [playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];

        _player = [AVPlayer playerWithPlayerItem:playerItem];
    }
    return _player;
}

-(AVPlayerItem*)playerItem:(NSString*)urlStr{
    if (_playerItem == nil) {
        _playerItem  =[AVPlayerItem playerItemWithURL:[NSURL URLWithString:urlStr]];
    }
    return _playerItem;
}

-(void)playAlert{
    
    if (haveShowPlayAlert) {
        return;
    }
    
    haveShowPlayAlert = YES;
    //先暂停播放
    _pauseBtn.selected = YES;
    [_player pause];
    //提示当前为手机流量
    if ([_reach currentReachabilityStatus] == ReachableViaWiFi) {
        UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"流量提醒" message:@"当前为手机流量播放" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *cancleAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            [alertVC dismissViewControllerAnimated:YES completion:nil];

            return ;
        }];
        
        UIAlertAction *goAction = [UIAlertAction actionWithTitle:@"继续" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            _pauseBtn.selected = NO;
            [_player play];
            [alertVC dismissViewControllerAnimated:YES completion:nil];
        }];
        [alertVC addAction:cancleAction];
        [alertVC addAction:goAction];
        
        [[[[UIApplication sharedApplication]delegate]window].rootViewController presentViewController:alertVC animated:YES completion:^{
            
        }];
    }
}

-(void)replaceCurrentItem:(NSString*)url{
    [self removeAllObserver];
    _playerItem = [AVPlayerItem playerItemWithURL:[NSURL URLWithString:url]];
    [_playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    [_player replaceCurrentItemWithPlayerItem:_playerItem];
    [self preparePlay];
    [_player.currentItem seekToTime:CMTimeMakeWithSeconds(currentTime, _playerItem.asset.duration.timescale)];
    
    _pauseBtn.selected = NO;
}

-(void)preparePlay{
    [_player play];
    [self showIndicatorView];
    _playStatus = PlayingStatus_Playing;
    [self monitorPlay];
}


-(void)monitorPlay{
    //播放进度
    __weak typeof(_prosessSlider) slider = _prosessSlider;
    __weak typeof(_playerItem) playerItem = _playerItem;
    __weak typeof(self) weakSelf = self;
    __weak typeof(_pauseBtn) pauseButton = _pauseBtn;

    [_player addPeriodicTimeObserverForInterval:CMTimeMake(1.0, 1.0) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        
        float current = CMTimeGetSeconds(time);
        float total = CMTimeGetSeconds(playerItem.duration);
        NSLog(@"当前已经播放%f / %f",current,_totalTime);
        slider.value = current/_totalTime;
        currentTime = current;
        if (current == total) {
            _playStatus = PlayingStatus_Finish;
            [playerItem seekToTime:CMTimeMake(0, playerItem.duration.timescale)];
            [weakSelf pauseBtnClick:pauseButton];
        }
    }];
    
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(playerBufferPause:) name:AVPlayerItemPlaybackStalledNotification object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(playerBufferFinish:) name:AVPlayerItemNewAccessLogEntryNotification object:nil];
    
    NSLog(@"视频layer--%@，self.layer---%@,-------self.view--%@",NSStringFromCGRect(_videoLayer.frame),NSStringFromCGRect(self.layer.frame),NSStringFromCGRect(self.bounds));
}

-(void)removeAllObserver{
    
    [_player.currentItem removeObserver:self forKeyPath:@"status" context:nil];
    [[NSNotificationCenter defaultCenter]removeObserver:self  name:AVPlayerItemPlaybackStalledNotification object:nil];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:AVPlayerItemNewAccessLogEntryNotification object:nil];

}

-(void)endPlay{
    
    [_player pause];
}


-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context{
    if ([keyPath isEqualToString:@"status"]) {
        [self hideIndicatorView];

        if ([keyPath isEqualToString:@"status"]) {
            AVPlayerStatus status= [[change objectForKey:@"new"] intValue];
            if(status == AVPlayerStatusReadyToPlay){
                [self playAlert];
                _totalTime = CMTimeGetSeconds(_player.currentItem.duration);
                NSLog(@"开始播放,视频总长度:%.2f",_totalTime);
                
            }else if(status == AVPlayerStatusUnknown){
                
                NSLog(@"%@",@"AVPlayerStatusUnknown");
                
            }else if (status == AVPlayerStatusFailed){
                [self failedNetworkAlert];
                NSLog(@"%@",@"AVPlayerStatusFailed");
            }  
        }
    }
}

-(void)failedNetworkAlert{
    if ([_reach currentReachabilityStatus] == NotReachable) {
        UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"播放提醒" message:@"网络错误" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *action = [UIAlertAction actionWithTitle:@"重试" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self replaceCurrentItem:_videoUrl];
            [alertVC dismissViewControllerAnimated:YES completion:nil];
            
        }];
        [alertVC addAction:action];
        [[[[UIApplication sharedApplication]delegate]window].rootViewController presentViewController:alertVC animated:YES completion:nil];
        
    }

}
#pragma mark --播放控制

-(void)controlViewPanHandle:(UIPanGestureRecognizer*)pan{
    CGFloat screen_Width = [[UIScreen mainScreen]bounds].size.width;
    CGPoint point = [pan locationInView:_controlView];
    if (pan.state == UIGestureRecognizerStateBegan) {
        _panBeginPoint = point;
    }else{
        CGFloat distance = point.x - _panBeginPoint.x; //可正可负
        CGFloat edgeTime = 0.1*distance/screen_Width * CMTimeGetSeconds(_player.currentItem.duration);
        CGFloat toTime = CMTimeGetSeconds(_player.currentItem.currentTime)+edgeTime;

        if(pan.state == UIGestureRecognizerStateChanged){
            
            [self showRollTimeView:toTime];
            
        }else if (pan.state == UIGestureRecognizerStateEnded){
            [self hideRolltimeView];
            [_player seekToTime:CMTimeMakeWithSeconds(toTime, _player.currentItem.duration.timescale) completionHandler:^(BOOL finished) {
                
            }];
            
        }

        
    }
    
}
-(void)sliderChange:(UISlider*)slider{
    [_player pause];
    
    float nowTime = CMTimeGetSeconds(_player.currentItem.duration) * slider.value;
    CMTime time = CMTimeMakeWithSeconds(nowTime, _player.currentItem.duration.timescale);
    [_player seekToTime:time];
    if (_playStatus == PlayingStatus_Playing) {
        [_player play];
    }else{
        [_player pause];

    }
}

-(void)pauseBtnClick:(UIButton*)btn{
    btn.selected = !btn.selected;
    
    if (_playerItem) {
        
        if (_playStatus == PlayingStatus_Playing) {
            [_player pause];
            _playStatus = PlayingStatus_Pause;
        }else if (_playStatus == PlayingStatus_Pause){
            [_player play];
            _playStatus = PlayingStatus_Playing;
            
        }else if (_playStatus == PlayingStatus_Finish){
            
            _playStatus = PlayingStatus_Pause;
        }
    }
    
}
-(void)fullScreenBtnClick:(UIButton*)btn{
    if (_isFullScreen) { //缩小

        [UIView animateWithDuration:0.5 animations:^{
            self.transform = CGAffineTransformIdentity;
            self.frame = _originalFrame;

        } completion:^(BOOL finished) {
            _videoLayer.frame = self.layer.bounds;
            _controlView.frame = self.bounds;
            
        }];

    }else{ //全屏
        

        [UIView animateWithDuration:0.5 animations:^{
            self.transform = CGAffineTransformMakeRotation(M_PI_2);
            self.frame = CGRectMake(SCREEN_WIDTH, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
            self.center = CGPointMake(SCREEN_WIDTH/2.0, SCREEN_HEIGHT/2.0);
            
        } completion:^(BOOL finished) {
            _videoLayer.frame = self.layer.bounds;
            _controlView.frame = self.bounds;
        }];
        
    }
    
    _isFullScreen = !_isFullScreen;
}

-(void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [super touchesEnded:touches withEvent:event];
    _controlView.hidden = !_controlView.hidden;
}

#pragma mark --缓冲
-(void)playerBufferPause:(NSNotification*)tf{
    NSLog(@"%s",__func__);
    
}

-(void)playerBufferFinish:(NSNotification*)tf{
    NSLog(@"%s",__func__);

}

//快进回退视图
-(UIView*)rollTimeView{
    if (!_rollTimeView) {
        _rollTimeView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 100, 80)];
        UILabel *timeL = [[UILabel alloc]initWithFrame:CGRectMake(0, 30, _rollTimeView.frame.size.width,30)];
        timeL.textColor = [UIColor whiteColor];
        timeL.tag = 1000;
        timeL.textAlignment = NSTextAlignmentCenter;
        timeL.font = [UIFont systemFontOfSize:19];
        [_rollTimeView addSubview:timeL];
        
        UIProgressView *progressV = [[UIProgressView alloc]initWithFrame:CGRectMake(0, timeL.frame.origin.y + 30, _rollTimeView.frame.size.width, 1)];
        progressV.progressViewStyle = UIProgressViewStyleBar;
        progressV.trackTintColor = [UIColor lightGrayColor];
        progressV.progressTintColor = [UIColor whiteColor];
        progressV.tag = 10000;
        progressV.progress = 0;
        [_rollTimeView addSubview:progressV];
        _rollTimeView.userInteractionEnabled = NO;
    }
    return _rollTimeView;
}

-(void)showRollTimeView:(CGFloat)time{
    _rollTimeView = [self rollTimeView];
    if (!_rollTimeView.superview) {
        [_controlView addSubview:_rollTimeView];
        _rollTimeView.center = _controlView.center;
    }
    
    UILabel *timeL = [_rollTimeView viewWithTag:1000];
    timeL.text = [self hourMinuteSecondWithSecond:time];
    UIProgressView *progressV = [_rollTimeView viewWithTag:10000];
    [progressV setProgress:time/CMTimeGetSeconds(_player.currentItem.duration) animated:YES];
}
-(void)hideRolltimeView{
    
    [_rollTimeView removeFromSuperview];
}

//缓冲视图
-(UIActivityIndicatorView*)indicatorView{
    if (!_indicatorView) {
        _indicatorView = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        [_indicatorView startAnimating];
    }
    return _indicatorView;
}

-(void)showIndicatorView{
    _indicatorView = [self indicatorView];
    _indicatorView.center = _controlView.center;
    [_controlView addSubview:_indicatorView];
    [_indicatorView startAnimating];
}
-(void)hideIndicatorView{
    [_indicatorView removeFromSuperview];
}


-(NSString*)hourMinuteSecondWithSecond:(CGFloat)second{
    
    int minute = second/60;
    CGFloat seconds = second - minute*60;
    NSString *time = [NSString stringWithFormat:@"%d:%.f",minute,seconds];
    return time;
}

-(void)dealloc{
    [self removeAllObserver];
    _player = nil;
}



@end
