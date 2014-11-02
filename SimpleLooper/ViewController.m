//
//  ViewController.m
//  SimpleLooper
//
//  Created by Kevin Nelson on 11/2/14.
//  Copyright (c) 2014 R. Kevin Nelson. All rights reserved.
//

#import "ViewController.h"

#import "RKNSimpleLooper.h"
#import <AVFoundation/AVFoundation.h>

@interface ViewController ()

@property (strong, nonatomic) RKNSimpleLooper *looper;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session requestRecordPermission:^(BOOL granted) {
        if (granted) {
            self.looper = [[RKNSimpleLooper alloc] init];
        } else {
            NSLog(@", well, alert that we can't really do anything?");
        }
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

# pragma mark - UI Handlers

- (IBAction)beginRecording:(id)sender
{
    [self.looper startRecording];
}

- (IBAction)endRecording:(id)sender
{
    [self.looper stopRecording];
}

@end
