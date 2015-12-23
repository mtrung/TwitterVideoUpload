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
    
    if ([SocialVideoHelper userHasAccessToTwitter] == FALSE) {
        [self addText:@"userHasAccessToTwitter: No"];
        return;
    }
    [self addText:@"userHasAccessToTwitter"];
    
    NSString * path = [[NSBundle mainBundle] pathForResource:@"pass" ofType:@"mp4"];
//    NSString * path = [[NSBundle mainBundle] pathForResource:@"fail_finalize" ofType:@"mp4"];
    
    NSData *videoData = [NSData dataWithContentsOfFile:path];
    [self addText:[NSString stringWithFormat:@"Video size: %d KB", ([videoData length] / 1024)]];

    [[SocialVideoHelper instance] uploadTwitterVideo:videoData withCompletion:^(NSString* errorString)
    {
        if (errorString == nil)
            [self addText:@"Complete"];
        else [self addText:errorString];
    }];
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
