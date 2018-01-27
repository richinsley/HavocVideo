//
//  FaceBookUploader.h
//  Havoc Video
//
//  Created by Richard Insley on 10/1/10.
//  Copyright 2010 WildWestWare. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FBConnect.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "JSON.h"

enum FacebookUploadState
{
	FUSUserDenied	= -2, // the user either canceled logging in, or denied access to video and stream
	FUSFailed		= -1, // something has gone horribly wrong
	FUSPendingAuth	= 0,  // waiting for user to authorize	(will resolve after video limits received)
	FUSPendingSend	= 1,  // waiting for user to send			(will resolve after user commits publish action)
	FUSUploading	= 2,  // uploading video
	FUSPendingVideo	= 3,  // waiting for video information FQL
	FUSPendingUpdate= 4,  // waiting for update to user's wall
	FUSComplete		= 5   // all actions complete
};
typedef enum FacebookUploadState FacebookUploadState;

@protocol FaceBookUploaderProtocol

-(void)FaceBookUploaderError:(NSString*)reason FacebookUploadState:(FacebookUploadState)state;
-(void)FaceBookUploaderAuthorized;
-(void)FaceBookUploaderComplete;
-(void)FaceBookUploaderProgress:(float)progressValue;

@end

@interface FaceBookUploader : NSObject < FBSessionDelegate , FBRequestDelegate , FBDialogDelegate >
{
	id fbdelegate;
	
	ALAssetRepresentation * dr;
	FacebookUploadState currentState;
	
	long long dataSize;
	
	int maxsize;
	int maxlength;
	
	// the video ID returned from facebook
	NSString* vid;
	
	UIBackgroundTaskIdentifier bgTask;
	
	NSString*tempFile;
	
	int throttleSize;
}

-(void)uploadWithPath:(NSString*)path Title:(NSString*)title Description:(NSString*)desc;
-(void)uploadWithTitle:(NSString*)title Description:(NSString*)desc;

@property (readwrite, nonatomic) int throttleSize;
@property (readonly, nonatomic) FacebookUploadState currentState;
@property (readonly, nonatomic) int maxlength;

@end
