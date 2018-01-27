//
//  AssetPlayerViewController.h
//  Havoc Video
//
//  Created by Richard Insley on 9/16/10.
//  Copyright 2010 WildWestWare. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import "AssetPlayerProtocol.h"
#import <MobileCoreServices/UTCoreTypes.h>
#import "FaceBookUploaderViewController.h"

#import "ModalAlert.h"
#import "ModalLogin.h"
#import "MBProgressHUD.h"
#import "Reachability.h"

@interface AssetPlayerViewController : UIViewController < UIImagePickerControllerDelegate , UINavigationControllerDelegate >
{
	MPMoviePlayerController * moviePlayer;
	NSURL * currentAsset;
	IBOutlet UIView * canvas;
	id _callback;

	FBSession * _session;
	
	// twitter things
	NSMutableDictionary * loginDetails;
	
	Reachability* internetReach;
}

@property (nonatomic, retain) MPMoviePlayerController *moviePlayer;

- (id) initWithAssetURL:(NSURL*) asset AssetPlayerProtocol:(id <AssetPlayerProtocol>)callback;
- (void)viewWillDisappear:(BOOL)animated;

- (void) shareButtonPressed:(id)sender;

- (void) doneButtonPressed:(id)sender;
- (void) videoButtonPressed:(id)sender;
- (void) actionButtonPressed:(id)sender;
@end
