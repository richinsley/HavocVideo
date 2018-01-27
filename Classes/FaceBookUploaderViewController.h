//
//  FaceBookUploaderViewController.h
//  Havoc Video
//
//  Created by Richard Insley on 9/22/10.
//  Copyright 2010 WildWestWare. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FaceBookUploader.h"
#import "EditViewController.h"

@interface FaceBookUploaderViewController : UIViewController  < FBSessionDelegate , 
	FBRequestDelegate , 
	FBDialogDelegate, 
	UITextFieldDelegate , 
	FaceBookUploaderProtocol , 
	UIVideoEditorControllerDelegate,
	UIAlertViewDelegate >
{
	FaceBookUploader* uploader;
	
	FBSession * _session;
	
	bool isEditing;
	NSURL * currentAsset;
	
	ALAssetsLibrary *assetsLibrary;
	ALAssetRepresentation * dr;
	long long dataSize;
	double _duration;
	
	int maxsize;
	int maxlength;
	
	NSString * vid;
	
	FacebookUploadState currentState;
	
	UIBarButtonItem *anotherButton;
	
	IBOutlet UIView *cview;
	IBOutlet UIImageView *image;
	IBOutlet UITextField *titletf;
	IBOutlet UITextField *descriptiontf;
	IBOutlet UIProgressView *progress;
	IBOutlet UIButton *trimButton;
	
	IBOutlet UILabel *sizeLabel;
	IBOutlet UILabel *durationLabel;
	
	IBOutlet UIActivityIndicatorView *spinnyThing;
	
	NSString * pretrimtemp;
	NSString * posttrimtemp;
	
	bool _hasWifi;
}

- (void) editButton:(id)sender;
- (void) cancelButton:(id)sender;
- (void) postButton:(id)sender;
- (void) uploadInBack:(id)sender;
- (void) startEdit:(id)sender;
- (void) endEdit:(id)sender;
+ (NSString *)stringFromFileSize:(int)theSize;
@end
