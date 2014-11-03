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

- (void)handleBufferInput:(AudioQueueBufferRef)inBuffer atTime:(const AudioTimeStamp *)time packetCount:(UInt32)packetCount;

@end

#pragma mark - AudioQueue C++

static OSStatus oserr;

static void HandleInputBuffer(void *inData,
                              AudioQueueRef inAQ,
                              AudioQueueBufferRef inBuffer,
                              const AudioTimeStamp *inStartTime,
                              UInt32 inNumPackets,
                              const AudioStreamPacketDescription *inPacketDesc)
{
    RKNSimpleLooper *looper = (__bridge RKNSimpleLooper *)inData;
    [looper handleBufferInput:inBuffer atTime:inStartTime packetCount:inNumPackets];
}

static void LogIfOSErr(NSString *output)
{
    if (oserr != noErr) {
        char *strErr = (char *)oserr;
        NSString *errCode = [NSString stringWithFormat:@"%c%c%c%c", strErr[3], strErr[2], strErr[1], strErr[0]];
        NSLog(@"OSErr: %@\t%@", errCode, output);
    }
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
    asbd.mSampleRate = kPreferredSampleRate;
    asbd.mBitsPerChannel = 16;
    asbd.mChannelsPerFrame = kPreferredNumChannels;
    asbd.mBytesPerPacket = asbd.mBytesPerFrame = (kPreferredNumChannels * sizeof(SInt16));
    asbd.mFramesPerPacket = 1;
    asbd.mFormatFlags = (kLinearPCMFormatFlagIsBigEndian |
                         kLinearPCMFormatFlagIsSignedInteger |
                         kLinearPCMFormatFlagIsPacked);
    
    // hard coded, but this is what we want for now. 512 byte buffer size. like a pro.
    inputBufferSizeInBytes = 512;
    
    oserr = AudioQueueNewInput(&asbd, HandleInputBuffer, (__bridge void *)self, NULL, kCFRunLoopCommonModes, 0, &audioQueue);
    LogIfOSErr(@"failed to create new audio input");
    if (oserr != noErr) {
        self.state = RKNLooperStateError;
        return;
    }
    
    // queue up all of the input buffers
    for (int i = 0; i < kNumAudioBuffers; i++) {
        oserr = AudioQueueAllocateBuffer(audioQueue, inputBufferSizeInBytes, &audioQueueBuffer[i]);
        LogIfOSErr(@"Failed to allocate buffer");
        oserr = AudioQueueEnqueueBuffer(audioQueue, audioQueueBuffer[i], 0, NULL);
        LogIfOSErr(@"Failed to enqueue buffer");
    }
}

#pragma mark - Recording

- (void)startRecording
{
    NSLog(@"start recording");
    oserr = AudioQueueStart(audioQueue, NULL);
    LogIfOSErr(@"error starting queue");
}

- (void)stopRecording
{
    NSLog(@"Stop recording and begin playback");
    oserr = AudioQueueStop(audioQueue, NO);
    LogIfOSErr(@"error stopping queue");
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

#pragma mark - Audio Queue stuff
- (void)handleBufferInput:(AudioQueueBufferRef)inBuffer atTime:(const AudioTimeStamp *)time packetCount:(UInt32)packetCount;
{
    NSLog(@"got some packets: %ld", (long)packetCount);
    NSLog(@"recording time: %f", time->mSampleTime);
    AudioQueueEnqueueBuffer(audioQueue, inBuffer, 0, NULL);
}

@end
