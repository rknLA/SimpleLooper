//
//  RKNSimpleLooper.h
//  SimpleLooper
//
//  Created by Kevin Nelson on 11/2/14.
//  Copyright (c) 2014 R. Kevin Nelson. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

#define kNumAudioBuffers 16
#define kPreferredNumChannels 1
#define kPreferredSampleRate 44100
#define kPreferredBufferSizeSeconds 0.01 // 10ms, or about 512 frames at 44.1, according to the docs
#define kMaxLoopLengthSeconds 300 // 5 minutes

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
