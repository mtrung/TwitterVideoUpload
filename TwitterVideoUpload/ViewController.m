//
//  ViewController.m
//  TwitterVideoUpload
//
//  Created by Trung Vo on 12/21/15.
//  Copyright © 2015 Trung Vo. All rights reserved.
//

#import "ViewController.h"
#import "SocialVideoHelper.h"

@interface ViewController ()

@property (nonatomic, retain) IBOutlet UITextView *tv;

@end


@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [SocialVideoHelper instance].statusContent = @"#TwitterVideo https://github.com/mtrung/TwitterVideoUpload";
    
    BOOL status = [[SocialVideoHelper instance] setVideo:@"rxmedsaver_app_intro_video"];
    if (status == FALSE) {
        [self addText:@"Failed reading video file"];
    }
    
    status = [[SocialVideoHelper instance] uploadTwitterVideo:^(NSString* errorString)
    {
        if (errorString == nil)
            [self addText:@"Complete"];
        else [self addText:errorString];
    }];
    
    
    if (status == FALSE) {
        [self addText:@"Failed pre-check"];
    }
}

- (void) addText:(NSString*)str {
    if ([NSThread isMainThread])
        self.tv.text = [NSString stringWithFormat:@"%@\n%@", str, self.tv.text];
    else {
        [self performSelectorOnMainThread:@selector(addText:) withObject:str waitUntilDone:NO];
        return;
    }
    NSLog(@"%@", str);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
