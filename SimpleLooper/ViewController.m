//
//  ViewController.m
//  SimpleLooper
//
//  Created by Kevin Nelson on 11/2/14.
//  Copyright (c) 2014 R. Kevin Nelson. All rights reserved.
//

#import "ViewController.h"

#import <AVFoundation/AVFoundation.h>

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session requestRecordPermission:^(BOOL granted) {
        if (granted) {
            NSLog(@"cool, initialize the session...");
        } else {
            NSLog(@", well, alert that we can't really do anything?");
        }
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
