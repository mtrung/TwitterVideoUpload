//
//  SocialVideoHelper.h
//
//  Created by Trung Vo on 12/22/15.
//  Copyright (c) 2015 Trung Vo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Social/Social.h>
#import <Accounts/Accounts.h>

#define DispatchMainThread(block, ...) if(block) dispatch_async(dispatch_get_main_queue(), ^{ block(__VA_ARGS__); })

typedef void(^CbUploadComplete)(NSString* errStr);

@interface TwitterVideoUpload : NSObject

@property (nonatomic) NSString* statusContent;
@property (nonatomic, readonly) NSString* videoFileName;

+ (BOOL) userHasAccessToTwitter;
+ (TwitterVideoUpload*) instance;

- (BOOL) setVideo:(NSString*)videoFileName;
- (BOOL) uploadTwitterVideo:(CbUploadComplete)completion;

@end
