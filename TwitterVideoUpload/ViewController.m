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
    
    NSString * path = [[NSBundle mainBundle] pathForResource:@"sample_mpeg4" ofType:@"mp4"];
    NSData *videoData = [NSData dataWithContentsOfFile:path];
    [self addText:[NSString stringWithFormat:@"Video size: %d KB", ([videoData length] / 1024)]];
    
    ACAccountStore *account = [[ACAccountStore alloc] init];
    ACAccountType *accountType = [account accountTypeWithAccountTypeIdentifier:
                                  ACAccountTypeIdentifierTwitter];
    [account requestAccessToAccountsWithType:accountType options:nil
                                  completion:^(BOOL granted, NSError *error)
    {
        if (granted == YES)
        {
            NSArray *arrayOfAccounts = [account accountsWithAccountType:accountType];
            
            if ([arrayOfAccounts count] > 0)
            {
                ACAccount *twitterAccount = [arrayOfAccounts lastObject];
                if (twitterAccount == nil) {
                    [self addText:@"ACAccount = nil"];
                    return;
                }
                [self addText:[NSString stringWithFormat:@"Type: %@\nDesc: %@\nUsername: %@\nFull name: %@\nCredential: %@",
                      twitterAccount.accountType,
                      twitterAccount.accountDescription,
                      twitterAccount.username,
                      twitterAccount.userFullName,
                      twitterAccount.credential]];
                
                [SocialVideoHelper uploadTwitterVideo:videoData account:twitterAccount withCompletion:^{
                    [self addText:@"Complete"];
                }];
            }
        }
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
