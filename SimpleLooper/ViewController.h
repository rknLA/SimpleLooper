//
//  ViewController.h
//  SimpleLooper
//
//  Created by Kevin Nelson on 11/2/14.
//  Copyright (c) 2014 R. Kevin Nelson. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController

@property (strong, nonatomic) IBOutlet UILabel *loopLabel;
@property (strong, nonatomic) IBOutlet UIButton *recordButton;

- (IBAction)beginRecording:(id)sender;
- (IBAction)endRecording:(id)sender;

@end

