//
//  GLViewController.h
//  VideoTexture
//
//  Created by Richard Insley on 8/25/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/CALayer.h>
#include <AudioToolbox/AudioToolbox.h>

#import "EAGLView.h"
#import "MBProgressHUD.h"
#import "SnapshotView.h"
#import "AssetPlayerViewController.h"
#import "AssetLibraryViewController.h"
#import "DotsView.h"

@interface GLViewController : UIViewController < UIGestureRecognizerDelegate , ChangeScriptProtocol , AssetPlayerProtocol , UIScrollViewDelegate >
{
	IBOutlet EAGLView *glView;
	
	// canvas based ui elements
	IBOutlet UIButton *lampButton;
	IBOutlet UIButton *switchCameraButton;
	IBOutlet UIButton *chooseEffectButton;
	IBOutlet UIButton *someOtherButton;
	IBOutlet UILabel * effectLabel;
	IBOutlet UILabel *timeLabel;
	
	// record button panel
	IBOutlet UIView * recordView;
	
	// effects view
	IBOutlet UIView * effectView;
	IBOutlet UIScrollView * effectScrollView;
	IBOutlet DotsView * dots;
	
	UIView * effectSubViews[1024];
	
	// the coverplate
	IBOutlet UIView  * coverPlate;
	IBOutlet UILabel * statusLabel1;
	IBOutlet UILabel * statusLabel2;
	bool shouldOpenCoverPlate; // flag to indicate that when a frame arrives, animate the cover plate open
	
	UIInterfaceOrientation currentOrientation;
	
	// subviews that we want to keep around for the duration
	MBProgressHUD * savingAlert;
	
	// for our ping files
	CFURLRef		startSoundFileURLRef;
	SystemSoundID	startSoundFileObject;
	
	CFURLRef		stopSoundFileURLRef;
	SystemSoundID	stopSoundFileObject;
	
	// current list of movie assets
	ALAssetsLibrary *assetsLibrary;
	NSMutableArray *groups;
	ALAssetsGroup *assetsGroup;
	NSMutableArray * assets;
	bool assetsDenied;
	NSURL * recentAsset;
	
	CGImageRef assetLightingImage;
	CGImageRef assetMask;
	
	bool effectOpen;
	
	dispatch_queue_t finalizerq;
}

@property (nonatomic, retain) IBOutlet EAGLView *glView;
@property (readonly)	SystemSoundID	startSoundFileObject;
@property (readonly)	SystemSoundID	stopSoundFileObject;

+(CGImageRef) maskImage:(CGImageRef)image withMask:(CGImageRef)mask;
+(float)getTransformForOrientation:(UIInterfaceOrientation)interfaceOrientation;
+(NSString *)getPathForImageFile:(const char *)name;

- (void) playerClosed:(id)sender Asset:(NSURL*)newAsset;
- (void) lampButton:(id)sender;
- (void) switchCameraButton:(id)sender;
- (void) chooseEffectButton:(id)sender;
- (void) someOtherButton:(id)sender;
- (void) recordButton:(id)sender;
- (void) setLampButtonOn:(bool)lampon;
- (void) playStartAlertSound;

- (void) processMovieFile:(NSString *) moviePath;
- (void) setRecentRecording:(NSURL*)assetPath;
- (void) updateAssetsStatus;
- (void) snapShotAnimationComplete:(NSURL*)url;

@end
