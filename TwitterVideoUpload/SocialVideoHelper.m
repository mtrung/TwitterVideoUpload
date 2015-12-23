//
//  SocialVideoHelper.m
//
//  Created by Trung Vo on 12/22/15.
//  Copyright (c) 2015 Trung Vo. All rights reserved.
//

#import "SocialVideoHelper.h"


@interface SocialVideoHelper ()
{
    NSData* videoData;
    NSString* mediaID;
    NSURL* twitterPostURL;
    NSURL* twitterUpdateURL;
    CbUploadComplete completion;
    
    NSDictionary* paramList[4];
}

@property (nonatomic) ACAccount* account;
@property (nonatomic) NSString* statusContent;

@end


@implementation SocialVideoHelper

static SocialVideoHelper *sInstance = nil;

+ (SocialVideoHelper*) instance {
    if (sInstance == nil) {
        sInstance = [SocialVideoHelper new];
        [sInstance initialize];
    }
    return sInstance;
}

- (void) initialize {
    twitterPostURL = [[NSURL alloc] initWithString:@"https://upload.twitter.com/1.1/media/upload.json"];
    twitterUpdateURL = [[NSURL alloc] initWithString:@"https://api.twitter.com/1.1/statuses/update.json"];
    self.statusContent = @"#TwitterVideo https://github.com/mtrung/TwitterVideoUpload";
}

+(BOOL)userHasAccessToTwitter
{
    return [SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter];
}

- (void) getAccount {
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
                     NSLog(@"ACAccount = nil");
                     return;
                 }
                 
                 self.account = twitterAccount;
                 [self sendCommand:0];
             }
         }
     }];
}


- (void) uploadTwitterVideo:(NSData*)videoData1 withCompletion:(CbUploadComplete)completion1 {
    
    completion = completion1;
    videoData = videoData1;
    
    paramList[0] = @{@"command": @"INIT",
                     @"total_bytes" : [NSNumber numberWithInteger: videoData.length].stringValue,
                     @"media_type" : @"video/mp4"
                     };
    
    if (self.account != nil) [self sendCommand:0];
    else [self getAccount];
}

- (void) sendCommand:(int)i {
    
    NSDictionary* postParams = paramList[i];
    
    SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeTwitter requestMethod:SLRequestMethodPOST
                                                      URL:((i<3)?twitterPostURL:twitterUpdateURL) parameters:postParams];
    // Set the account and begin the request.
    request.account = self.account;
    
    if (i == 1) {
        [request addMultipartData:videoData withName:@"media" type:@"video/mp4" filename:@"video"];
    }
    
    NSLog(@"%d >> ", i);
          //,request.preparedURLRequest.allHTTPHeaderFields);

    [request performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
        
        NSString* statusStr = [NSString stringWithFormat:@"HTTP status %d %@", [urlResponse statusCode], [NSHTTPURLResponse localizedStringForStatusCode:[urlResponse statusCode]]];
        NSLog(@"%d << %@", i, statusStr);
        
        //NSLog(@"%@", [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
        
        if (error) {
            NSLog(@"Error: %@", error);
        } else {
            BOOL is2XX = ([urlResponse statusCode] / 100) == 2;
            if (!is2XX) {
                NSMutableDictionary *returnedData = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableContainers error:&error];
                NSString* errStr = (returnedData) ? returnedData[@"error"] : statusStr;
                DispatchMainThread(^(){completion(errStr);});
                return;
            }
            
            if (i == 0) {
                NSMutableDictionary *returnedData = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableContainers error:&error];
                
                mediaID = [NSString stringWithFormat:@"%@", [returnedData valueForKey:@"media_id_string"]];
                NSLog(@"mediaID = %@", mediaID);
                
                //  ...since we have mediaID, we now can populate the rest of paramList
                paramList[1] = @{@"command": @"APPEND",
                                 @"media_id" : mediaID,
                                 @"segment_index" : @"0"
                                 };
                
                paramList[2] = @{@"command": @"FINALIZE",
                                 @"media_id" : mediaID };
                
                paramList[3] = @{@"status": self.statusContent,
                                 @"media_ids" : @[mediaID]};
            }
            else if (i == 3) {
                if ([urlResponse statusCode] == 200 && completion != nil){
                    NSLog(@"upload success !");
                    DispatchMainThread(^(){completion(nil);});
                }
                return;
            }
            
            [self sendCommand:i+1];
        }
    }];
}

@end
