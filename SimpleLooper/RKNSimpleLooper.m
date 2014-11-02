//
//  RKNSimpleLooper.m
//  SimpleLooper
//
//  Created by Kevin Nelson on 11/2/14.
//  Copyright (c) 2014 R. Kevin Nelson. All rights reserved.
//

#import "RKNSimpleLooper.h"

@interface RKNSimpleLooper() {
    AudioStreamBasicDescription asbd;
    AudioQueueRef audioQueue;
    AudioQueueBufferRef audioQueueBuffer[kNumAudioBuffers];
    UInt32 bufferWriteIndex;
    UInt32 inputBufferSizeInBytes;
}

@property (nonatomic, assign) CMTime duration;
@property (nonatomic, assign) RKNLooperState state;

- (void)handleBufferInput:(AudioQueueBufferRef)inBuffer;

@end

#pragma mark - AudioQueue C++

static void HandleInputBuffer(void *inData,
                              AudioQueueRef inAQ,
                              AudioQueueBufferRef inBuffer,
                              const AudioTimeStamp *inStartTime,
                              UInt32 inNumPackets,
                              const AudioStreamPacketDescription *inPacketDesc)
{
    RKNSimpleLooper *looper = (__bridge RKNSimpleLooper *)inData;
    [looper handleBufferInput:inBuffer];
}



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
    OSStatus oserr;
    
    NSError *err;
    AVAudioSession *session = [AVAudioSession sharedInstance];
    
    /* Allow mixWithOthers here in case you wanna do something crazy like loop
     * the audio coming out of your speaker.
     */
    [session setCategory:AVAudioSessionCategoryPlayAndRecord
             withOptions:(AVAudioSessionCategoryOptionDefaultToSpeaker |
                          AVAudioSessionCategoryOptionAllowBluetooth |
                          AVAudioSessionCategoryOptionMixWithOthers)
                   error:&err];
    if (err) {
        NSLog(@"Error setting session category");
        self.state = RKNLooperStateError;
        return;
    }
    
    [session setPreferredSampleRate:kPreferredSampleRate error:&err];
    if (err) {
        NSLog(@"Error setting preferred sample rate");
        self.state = RKNLooperStateError;
        return;
    }
    
    [session setPreferredIOBufferDuration:kPreferredBufferSizeSeconds error:&err];
    if (err) {
        NSLog(@"Error setting preferred buffer size");
        self.state = RKNLooperStateError;
        return;
    }
    
    [session setActive:YES error:&err];
    if (err) {
        NSLog(@"Error activating session!");
        self.state = RKNLooperStateError;
        return;
    }
    
    [session setPreferredInputNumberOfChannels:kPreferredNumChannels error:&err];
    if (err) {
        NSLog(@"Error setting preferred input channels");
        self.state = RKNLooperStateError;
        return;
    }
    
    // setup the asbd
    memset(&asbd, 0, sizeof(asbd));
    asbd.mFormatID = kAudioFormatLinearPCM;
    UInt32 asbdSize = sizeof(asbd);
    
    oserr = AudioFormatGetProperty(kAudioFormatProperty_FormatInfo, 0, NULL, &asbdSize, &asbd);
    if (oserr != noErr) {
        NSLog(@"failed to get format property");
        self.state = RKNLooperStateError;
        return;
    }
    
    oserr = AudioQueueNewInput(&asbd, HandleInputBuffer, (__bridge void *)self, NULL, NULL, 0, &audioQueue);
    if (oserr != noErr) {
        NSLog(@"failed to create new input!");
        self.state = RKNLooperStateError;
        return;
    }
}

#pragma mark - Recording

- (void)startRecording
{
    NSLog(@"start recording");
}

- (void)stopRecording
{
    NSLog(@"Stop recording and begin playback");
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
