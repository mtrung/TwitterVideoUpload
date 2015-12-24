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
    
    NSMutableArray* paramList;
}

@property (nonatomic) ACAccount* account;

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

#define VIDEO_CHUNK_SIZE 5000000 // 5*(1<<20)
#define MAX_VIDEO_SIZE 15*(1<<20)

- (void) initialize {
    twitterPostURL = [[NSURL alloc] initWithString:@"https://upload.twitter.com/1.1/media/upload.json"];
    twitterUpdateURL = [[NSURL alloc] initWithString:@"https://api.twitter.com/1.1/statuses/update.json"];
    self.statusContent = @"#TwitterVideo https://github.com/mtrung/TwitterVideoUpload";
    paramList = [NSMutableArray arrayWithCapacity:4];
}

+(BOOL)userHasAccessToTwitter
{
    return [SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter];
}

- (void) getAccount:(BOOL)toSendVideo {
    ACAccountStore *account = [[ACAccountStore alloc] init];
    ACAccountType *accountType = [account accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    [account requestAccessToAccountsWithType:accountType options:nil
                                  completion:^(BOOL granted, NSError *error)
     {
         if (granted == YES) {
             NSArray *arrayOfAccounts = [account accountsWithAccountType:accountType];
             if ([arrayOfAccounts count] > 0) {
                 ACAccount *twitterAccount = [arrayOfAccounts lastObject];
                 if (twitterAccount == nil) {
                     NSLog(@"ACAccount = nil");
                     return;
                 }
                 
                 self.account = twitterAccount;
                 
                 if (toSendVideo && paramList.count > 0)
                     [self sendCommand:0];
             }
         }
     }];
}

- (BOOL) setVideo:(NSString *)videoFileName {
    
    if (videoFileName == nil || videoFileName.length == 0) {
        NSLog(@"Video file is not set");
        return FALSE;
    }
    _videoFileName = videoFileName;
    
    NSString *path = [[NSBundle mainBundle] pathForResource:self.videoFileName ofType:@"mp4"];
    if (path == nil) {
        NSLog(@"File is not found");
        return FALSE;
    }
    
    videoData = [NSData dataWithContentsOfFile:path];
    if (videoData == nil) {
        NSLog(@"Error while reading file");
        return FALSE;
    }
    
    NSLog(@"Video size: %d bytes", videoData.length);
    
    if (videoData.length > MAX_VIDEO_SIZE) {
        NSLog(@"Video is too big");
        return FALSE;
    }
    
    return TRUE;
}

/**
 uploadTwitterVideo
 Automatically geting twitter account credential if not previously retrieved.
 Return FALSE if failed pre-check.
 */
- (BOOL) uploadTwitterVideo:(CbUploadComplete)completionBlock {
    
    if ([SocialVideoHelper userHasAccessToTwitter] == FALSE) {
        NSLog(@"No Twitter account. Please add twitter account to Settings app.");
        return FALSE;
    }

    completion = completionBlock;
    
    if (videoData == nil) {
        NSLog(@"No video data set");
        return FALSE;
    }
    NSString* sizeStr = @(videoData.length).stringValue;
    
    [paramList removeAllObjects];
    paramList[0] = @{@"command": @"INIT",
                     @"total_bytes" : sizeStr,
                     @"media_type" : @"video/mp4"
                     };
    
    if (self.account != nil) [self sendCommand:0];
    else [self getAccount:TRUE];
    return TRUE;
}

- (void) processInitResp:(NSData*)responseData {
    NSError* error = nil;
    NSMutableDictionary *returnedData = [NSJSONSerialization JSONObjectWithData:responseData
                                                                        options:NSJSONReadingMutableContainers error:&error];
    
    mediaID = [NSString stringWithFormat:@"%@", [returnedData valueForKey:@"media_id_string"]];
    NSLog(@"mediaID = %@", mediaID);
    
    //  ...since we have mediaID, we now can populate the rest of paramList
    
    int cmdIndex = 0;
    int segment = 0;
    for (; segment*VIDEO_CHUNK_SIZE < videoData.length; segment++) {
        paramList[++cmdIndex] = @{@"command": @"APPEND",
                                  @"media_id" : mediaID,
                                  @"segment_index" : @(segment).stringValue
                                  };
    }
    
    paramList[++cmdIndex] = @{@"command": @"FINALIZE",
                              @"media_id" : mediaID };
    
    paramList[++cmdIndex] = @{@"status": self.statusContent,
                              @"media_ids" : @[mediaID]};
}

//  ...handle chunk upload
- (void) addVideoChunk:(SLRequest*)request {
    
    NSData* videoChunk;
    
    if (videoData.length > VIDEO_CHUNK_SIZE) {
        int segment_index = [request.parameters[@"segment_index"] intValue];
        
        NSRange range = NSMakeRange(segment_index * VIDEO_CHUNK_SIZE, VIDEO_CHUNK_SIZE);
        int maxPos = NSMaxRange(range);
        if (maxPos >= videoData.length) {
            range.length = videoData.length - range.location;
        }
        videoChunk = [videoData subdataWithRange:range];
        NSLog(@"\tsegment_index %d: loc=%d len=%d", segment_index, range.location, range.length);
    } else {
        videoChunk = videoData;
    }
    
    [request addMultipartData:videoChunk withName:@"media" type:@"video/mp4" filename:@"video"];
}

/* Standard success flow:
    0 >> INIT
    0 << INIT: HTTP status 202 accepted
    mediaID = 679712963431804928
    1 >> APPEND
    1 << APPEND: HTTP status 204 no content
    2 >> FINALIZE
    2 << FINALIZE: HTTP status 201 created
    3 >>
    3 << : HTTP status 200 no error
 */
- (void) sendCommand:(int)i {
    
    if (i >= paramList.count) {
        NSLog(@"Invalid command index %d", i);
        return;
    }
    
    NSDictionary* postParams = paramList[i];
    NSURL* url = (i == paramList.count-1 && i > 0) ? twitterUpdateURL : twitterPostURL;
    
    SLRequest *request = [SLRequest requestForServiceType:SLServiceTypeTwitter requestMethod:SLRequestMethodPOST
                                                      URL:url
                                               parameters:postParams];
    // Set the account
    request.account = self.account;
    
    NSString* cmdStr = postParams[@"command"];
    if (cmdStr == nil) cmdStr = @"";
    NSLog(@"%d >> %@", i, cmdStr);
    //,request.preparedURLRequest.allHTTPHeaderFields);

    if ([cmdStr isEqualToString:@"APPEND"]) {
        [self addVideoChunk:request];
    }

    [request performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
        
        NSString* statusStr = [NSString stringWithFormat:@"HTTP status %d %@", [urlResponse statusCode], [NSHTTPURLResponse localizedStringForStatusCode:[urlResponse statusCode]]];
        NSLog(@"%d << %@: %@", i, cmdStr, statusStr);
        //NSLog(@"%@", [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
        
        if (error) {
            NSLog(@"Error: %@", error);
        } else {
            
            //  ...must return 2XX status code; if not, stop & return error
            BOOL is2XX = ([urlResponse statusCode] / 100) == 2;
            if (!is2XX) {
                NSString* respStr = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
                NSLog(@"%@", respStr);

                NSString* errStr = statusStr;
                
                NSMutableDictionary *returnedData = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableContainers error:&error];
                if (returnedData && (returnedData[@"error"] || returnedData[@"errors"])) {
                    errStr = respStr;
                }
                
                DispatchMainThread(^(){completion(errStr);});
                return;
            }
            
            if (i == 0) {
                [self processInitResp:responseData];
            }
            else if (i == paramList.count-1) {
                if (completion != nil){
                    DispatchMainThread(^(){completion(nil);});
                }
                return;
            }
            
            if (i+1 >= paramList.count) return;
            
            [self sendCommand:i+1];
        }
    }];
}

@end
