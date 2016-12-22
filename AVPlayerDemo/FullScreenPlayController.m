//
//  FullScreenPlayController.m
//  AVPlayerDemo
//
//  Created by anne on 16/12/20.
//  Copyright © 2016年 anne. All rights reserved.
//

#import "FullScreenPlayController.h"
#import "VideoPlayerView.h"

@interface FullScreenPlayController ()
{
    
}
@end

@implementation FullScreenPlayController

- (void)viewDidLoad {
    [super viewDidLoad];
    
}

#pragma mark - 横屏代码
- (BOOL)shouldAutorotate{
    return YES;
} //NS_AVAILABLE_IOS(6_0);当前viewcontroller是否支持转屏

- (UIInterfaceOrientationMask)supportedInterfaceOrientations{
    
    return UIInterfaceOrientationMaskLandscape;
} //当前viewcontroller支持哪些转屏方向

-(UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationLandscapeRight;
}
- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (void)dealloc
{
    NSLog(@"----");
}

- (BOOL)prefersStatusBarHidden
{
    return NO;
}

@end
