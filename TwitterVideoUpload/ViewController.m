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
    
}

- (IBAction)sharePass:(id)sender {
    [self share:@"pass"];
}
- (IBAction)shareFail:(id)sender {
    [self share:@"fail_finalize"];
}

- (void) share:(NSString*)filename {
    
    BOOL status = [[SocialVideoHelper instance] setVideo:filename];
    if (status == FALSE) {
        [self addText:@"Failed reading video file"];
        return;
    }
    
    status = [[SocialVideoHelper instance] uploadTwitterVideo:^(NSString* errorString)
              {
                  NSString* printStr = [NSString stringWithFormat:@"Share video %@: %@", filename,
                                        (errorString == nil) ? @"Success" : errorString];
                  [self addText:printStr];
              }];
    
    
    if (status == FALSE) {
        [self addText:@"No Twitter account. Please add twitter account to Settings app."];
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
