//
//  VideoPlayer.h
//  AVPlayerDemo
//
//  Created by anne on 16/12/7.
//  Copyright © 2016年 anne. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Reachability.h"


typedef NS_ENUM(NSInteger,PlayingStatus){
    PlayingStatus_Playing = 1,
    PlayingStatus_Pause,
    PlayingStatus_Finish,
    PlayingStatus_Error

};


@protocol VideoPlayerViewDelegate <NSObject>

@end

@interface VideoPlayerView : UIView

-(instancetype)initWithFrame:(CGRect)frame videoUrl:(NSString*)urlString;

-(void)endPlay;

@end
