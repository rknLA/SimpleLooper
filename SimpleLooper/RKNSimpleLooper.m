//
//  RKNSimpleLooper.m
//  SimpleLooper
//
//  Created by Kevin Nelson on 11/2/14.
//  Copyright (c) 2014 R. Kevin Nelson. All rights reserved.
//

#import "RKNSimpleLooper.h"

@interface RKNSimpleLooper()

@property (nonatomic, assign) CMTime duration;
@property (nonatomic, assign) RKNLooperState state;

@end

@implementation RKNSimpleLooper

- (id)init
{
    self = [super init];
    if (self) {
        self.state = RKNLooperStateInitializing;
        self.duration = CMTimeMake(0, 0);
        [self prepareAVSession];
    }
    return self;
}

#pragma mark - Setup
- (void)prepareAVSession
{
    NSError *err;
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setActive:YES error:&err];
    if (err) {
        NSLog(@"Error activating session!");
        self.state = RKNLooperStateError;
        return;
    }
    
    
    
}

#pragma mark - Recording

- (void)startRecording
{
    
}

- (void)stopRecording
{
    
}

#pragma mark - Playback

- (void)startPlayback
{
    
}

- (void)pausePlayback
{
    
}

- (void)seekToPosition:(CMTime)position
{
    
}

@end
