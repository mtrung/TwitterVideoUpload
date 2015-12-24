# Overview
Light-weight share/upload video to Twitter for iOS

- Support chunk upload for > 5MB video file
- Built-in support for user's credential retrieval
- Support tweet text along with video
- Use Objective-C (Swift is TBD)
- Use SLRequest from Apple's Social framework to keep things light. No need to add extra frameworks such as TwitterKit and Fabric.
- Use new Twitter Uploading Media REST API, which was released in May 2015 https://blog.twitter.com/2015/rest-api-now-supports-native-video-upload.
- Twitter Uploading Media REST API document: https://dev.twitter.com/rest/public/uploading-media.

# Usage
- Copy 2 files TwitterVideoUpload.h and .m to your project.
- Add 2 lines below to your view controller:
```Objective-C
[[TwitterVideoUpload instance] setVideo:filename];
[[TwitterVideoUpload instance] upload:^(NSString* errorString) { ... }];
```
-  If success, completionHandler's errStr will be nil. If failed, errStr will contain REST response string.
- To add tweet text along with video:
```Objective-C
[TwitterVideoUpload instance].statusContent = @"...";
```

## Optional usage
- By default (account property is nil), upload: will try to get account before uploading. Optional: if you want to obtain account (ACAccount obj) manually, you can set yours as below:
```Objective-C
[TwitterVideoUpload instance].account = aACAccountObj;
```

# Notes
- Twitter username + password must be provided to iOS Settings app
- Twitter video requirement: https://dev.twitter.com/rest/public/uploading-media#videorecs.
- FINALIZE command verifies video file per Twitter video requirement before completing the upload.
- If you get "HTTP status 400 bad request" with response data having "Invalid or unsupported media, Reason: UnsupportedMedia." error after sending FINALIZE command, you need to verify your video file with Twitter video requirement.

# License
TwitterVideoUpload is available under the MIT license. See the LICENSE file for more info.
