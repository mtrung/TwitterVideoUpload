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

/**
 * Tweet text sending along with video
 */
@property (nonatomic) NSString* statusContent;

@property (nonatomic, readonly) NSString* videoFileName;

+ (BOOL) userHasAccessToTwitter;

+ (TwitterVideoUpload*) instance;

/**
 * Set video data for uploading
 * This is convenient method: get file from main bundle to set
 * Return FALSE if failed local validation
 */
- (BOOL) setVideo:(NSString*)videoFileName;

/**
 * Set video data for uploading
 * Return FALSE if failed local validation
 */
- (BOOL) setVideoData:(NSData *)vidData;

/**
 * main upload method
 */
- (BOOL) upload:(CbUploadComplete)completion;

@end
