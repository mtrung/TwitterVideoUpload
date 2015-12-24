# Overview
Light-weight share/upload video to Twitter for iOS

- Support > 5MB video file via chunk upload
- Objective-C (Swift is TBD)
- Use SLRequest from Apple's Social framework to keep things light. No need to add extra frameworks such as TwitterKit and Fabric.
- Twitter Uploading Media REST API (https://dev.twitter.com/rest/public/uploading-media)

# Usage
- Copy 2 files TwitterVideoUpload.h and .m to your project.
- Add 2 lines below to your view controller:

    [[TwitterVideoUpload instance] setVideo:filename];
    [[TwitterVideoUpload instance] upload:^(NSString* errorString) { ... }];


# Notes
- Twitter username + password must be provided to iOS Settings app
- Twitter video requirement: https://dev.twitter.com/rest/public/uploading-media#videorecs.
- FINALIZE command verifies video file per Twitter video requirement before completing the upload.
- If you get "HTTP status 400 bad request" with response data having "Invalid or unsupported media, Reason: UnsupportedMedia." error after sending FINALIZE command, you need to verify your video file with Twitter video requirement.
