//
//  TwitterVideoUpload.h
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

/**
 * User's twitter account
 * If this property is nil, upload: will try to get account before uploading.
 * If you want to get account manually, you can assign it to this property.
 */
@property (nonatomic) ACAccount* account;

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
 * Main upload method
 * Once done, completionHandler will be called with errStr.
 * If success, errStr will be nil.
 * If failed, errStr will contain responseString.
 */
- (BOOL) upload:(CbUploadComplete)completionHandler;

@end
