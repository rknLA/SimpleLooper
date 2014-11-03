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
    AudioQueueRef aqRecordQueue;
    AudioQueueBufferRef aqRecordBuffer[kNumAudioBuffers];
    UInt32 bufferWriteIndex;
    
    AudioQueueRef aqPlaybackQueue;
    AudioQueueBufferRef aqPlaybackBuffer[kNumAudioBuffers];
    UInt32 bufferReadIndex;
    
    UInt32 inputBufferSizeInBytes;
    
    char * loopData;
    UInt32 loopLengthInBytes;
    BOOL shouldKillRunLoop;
}

@property (nonatomic, assign) CMTime duration;
@property (nonatomic, assign) RKNLooperState state;

- (void)recordBuffer:(AudioQueueBufferRef)inBuffer atTime:(const AudioTimeStamp *)time packetCount:(UInt32)packetCount;
- (void)getNextPlaybackBuffer:(AudioQueueBufferRef)inBuffer;

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
    [looper recordBuffer:inBuffer atTime:inStartTime packetCount:inNumPackets];
}

static void HandleOutputBuffer(void *inData,
                               AudioQueueRef inAQ,
                               AudioQueueBufferRef inBuffer)
{
    RKNSimpleLooper *looper = (__bridge RKNSimpleLooper *)inData;
    [looper getNextPlaybackBuffer:inBuffer];
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
        NSUInteger bufferSize = kMaxLoopLengthSeconds * kPreferredSampleRate * kPreferredNumChannels * 2; // 2 bytes per frame
        loopData = calloc(bufferSize, sizeof(char *));
        loopLengthInBytes = 0;
        bufferWriteIndex = 0;
        shouldKillRunLoop = NO;
        [self prepareAVSession];
    }
    return self;
}

- (void)dealloc
{
    free(loopData);
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
    
    oserr = AudioQueueNewInput(&asbd, HandleInputBuffer, (__bridge void *)self, NULL, kCFRunLoopCommonModes, 0, &aqRecordQueue);
    LogIfOSErr(@"failed to create new audio input");
    if (oserr != noErr) {
        self.state = RKNLooperStateError;
        return;
    }
    
    // queue up all of the input buffers
    for (int i = 0; i < kNumAudioBuffers; i++) {
        oserr = AudioQueueAllocateBuffer(aqRecordQueue, inputBufferSizeInBytes, &aqRecordBuffer[i]);
        LogIfOSErr(@"Failed to allocate buffer");
        oserr = AudioQueueEnqueueBuffer(aqRecordQueue, aqRecordBuffer[i], 0, NULL);
        LogIfOSErr(@"Failed to enqueue buffer");
    }
    
    
    oserr = AudioQueueNewOutput(&asbd, HandleOutputBuffer, (__bridge void *)self, CFRunLoopGetCurrent(), kCFRunLoopCommonModes, 0, &aqPlaybackQueue);
    LogIfOSErr(@"failed to create new audio output");
}

#pragma mark - Recording

- (void)startRecording
{
    // clear the loop buffer;
    memset(loopData, 0, loopLengthInBytes);
    
    NSLog(@"start recording");
    oserr = AudioQueueStart(aqRecordQueue, NULL);
    LogIfOSErr(@"error starting queue");
}

- (void)stopRecording
{
    NSLog(@"Stop recording and begin playback");
    oserr = AudioQueueFlush(aqRecordQueue);
    LogIfOSErr(@"error stopping queue");
    oserr = AudioQueueStop(aqRecordQueue, NO);
    LogIfOSErr(@"error stopping queue");
    
    [self preparePlayback];
    [self startPlayback];
}

#pragma mark - Playback

- (void)preparePlayback
{
    for (int i = 0; i < kNumAudioBuffers; i++) {
        oserr = AudioQueueAllocateBuffer(aqPlaybackQueue, inputBufferSizeInBytes, &aqPlaybackBuffer[i]);
        LogIfOSErr(@"Failed to allocate buffer");
        
        [self getNextPlaybackBuffer:aqPlaybackBuffer[i]];
    }
}

- (void)startPlayback
{
    bufferReadIndex = 0;
    oserr = AudioQueueStart(aqPlaybackQueue, NULL);
    LogIfOSErr(@"failed to start playback queue");
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        do {
            CFRunLoopRunInMode(kCFRunLoopDefaultMode,
                               0.25,
                               false);
        } while (!shouldKillRunLoop);
        
        CFRunLoopRunInMode(kCFRunLoopDefaultMode, 1, false);
    });
}

- (void)runRunLoop
{
    
}

- (void)pausePlayback
{
    
}

- (void)seekToPosition:(CMTime)position
{
    
}

#pragma mark - Audio Queue stuff
- (void)recordBuffer:(AudioQueueBufferRef)inBuffer atTime:(const AudioTimeStamp *)time packetCount:(UInt32)packetCount
{
    NSLog(@"got some packets: %ld", (long)inBuffer->mAudioDataByteSize);
    NSLog(@"recording time: %f", time->mSampleTime);
    
    memcpy(&loopData[bufferWriteIndex], inBuffer->mAudioData, inBuffer->mAudioDataByteSize);
    bufferWriteIndex += inBuffer->mAudioDataByteSize;
    
    loopLengthInBytes = bufferWriteIndex - 1;
    
    AudioQueueEnqueueBuffer(aqRecordQueue, inBuffer, 0, NULL);
}

- (void)getNextPlaybackBuffer:(AudioQueueBufferRef)inBuffer
{
    NSLog(@"do something with inbuffer?");
    UInt32 bytesToFill = inBuffer->mAudioDataBytesCapacity;
    if (bufferReadIndex + bytesToFill > loopLengthInBytes) {
        //only enqueue the end of the buffer
        bytesToFill = loopLengthInBytes - bufferReadIndex;
    }
    
    memcpy(inBuffer->mAudioData, &loopData[bufferReadIndex], bytesToFill);
    inBuffer->mAudioDataByteSize = bytesToFill;
    bufferReadIndex = (bufferReadIndex + bytesToFill) % loopLengthInBytes;
        
    AudioQueueEnqueueBuffer(aqPlaybackQueue, inBuffer, 0, NULL);
}


@end
