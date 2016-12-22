//
//  ViewController.m
//  AVPlayerDemo
//
//  Created by anne on 16/12/7.
//  Copyright © 2016年 anne. All rights reserved.
//

#import "ViewController.h"
#import "VideoPlayerView.h"
#import "FullScreenPlayController.h"

@interface ViewController ()
{
    VideoPlayerView *_playerView;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBarHidden = YES;
    
    
    _playerView = [[VideoPlayerView alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 200) videoUrl:[[NSBundle mainBundle]pathForResource:@"testAudio" ofType:@"mp3"]];
    [self.view addSubview:_playerView];
    
    
}

-(void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [super touchesEnded:touches withEvent:event];
//    FullScreenPlayController *fullVC = [[FullScreenPlayController alloc]init];
//    
//    [self.navigationController presentViewController:fullVC animated:NO completion:^{
//        
//        [fullVC.view addSubview:_playerView];
//        _playerView.frame = fullVC.view.bounds;
//    }];
}

-(BOOL)prefersStatusBarHidden{
    return YES;
}
@end
