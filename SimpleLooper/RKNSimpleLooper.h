//
//  RKNSimpleLooper.h
//  SimpleLooper
//
//  Created by Kevin Nelson on 11/2/14.
//  Copyright (c) 2014 R. Kevin Nelson. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

typedef enum {
    RKNLooperStateInitializing = 0,
    RKNLooperStateInitialized,
    RKNLooperStateRecording,
    RKNLooperStatePlaying,
    RKNLooperStatePaused,
    RKNLooperStateError
} RKNLooperState;

@interface RKNSimpleLooper : NSObject

@property (nonatomic, readonly) CMTime duration;
@property (nonatomic, readonly) RKNLooperState state;

- (id)init;
- (void)startRecording;
- (void)stopRecording;

- (void)startPlayback;
- (void)pausePlayback;

- (void)seekToPosition:(CMTime)position;

@end
