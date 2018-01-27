//
//  AssetPlayerViewController.m
//  Havoc Video
//
//  Created by Richard Insley on 9/16/10.
//  Copyright 2010 WildWestWare. All rights reserved.
//

#import "AssetPlayerViewController.h"

@implementation AssetPlayerViewController

@synthesize moviePlayer;

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // Custom initialization
    }
    return self;
}
*/

- (id) initWithAssetURL:(NSURL*) asset AssetPlayerProtocol:(id <AssetPlayerProtocol>)callback
{
	if((self = [super init]))
	{
		_callback = callback;
		currentAsset = asset;
		
		internetReach = [[Reachability reachabilityForInternetConnection] retain];
	}
	return self;
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad 
{
	moviePlayer = NULL;
    [super viewDidLoad];
	[self setPlayerAsset:currentAsset];
	
	// add a cancel button
	UIBarButtonItem *anotherButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStylePlain target:self action:@selector(doneButton:)];          
	self.navigationItem.rightBarButtonItem = anotherButton;
	[anotherButton release];
}

- (void) doneButton:(id)sender
{
	[moviePlayer stop];
	
	// raise notification that we are done playing
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	[notificationCenter postNotificationName:@"assetPlayerDone" object:NULL];
}

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)didReceiveMemoryWarning 
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];

	
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload 
{
	
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
	
	if(moviePlayer)
	{
		[moviePlayer release];
		moviePlayer = NULL;
	}
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	[self setPlayerAsset:currentAsset];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[moviePlayer stop];
	[super viewWillDisappear:animated];
}

- (void) setPlayerAsset:(NSURL*)asset
{
	if(self.view)
	{
		[self removeMoviePlayer];
		
		currentAsset = asset;
		
		moviePlayer = [[[MPMoviePlayerController alloc] initWithContentURL: asset] retain];
		moviePlayer.scalingMode = MPMovieScalingModeAspectFit;
		moviePlayer.fullscreen = NO;
		moviePlayer.controlStyle = MPMovieControlStyleDefault;
		moviePlayer.shouldAutoplay = FALSE;
		moviePlayer.view.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | 
			UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		moviePlayer.movieSourceType = MPMovieSourceTypeFile;
		
		[moviePlayer.view setFrame:CGRectMake(0, 0, canvas.frame.size.width, canvas.frame.size.height)];
		
		[canvas addSubview:moviePlayer.view];
	}
}

- (void)removeMoviePlayer
{
	if(moviePlayer)
	{
		[moviePlayer.view removeFromSuperview];
		[moviePlayer release];
		moviePlayer = NULL;
	}
}

- (void)dealloc 
{
    [super dealloc];
	
	if(moviePlayer)
	{
		[moviePlayer release];
		moviePlayer	= NULL;
	}
}

- (void) doneButtonPressed:(id)sender
{
	[_callback playerClosed:self Asset:currentAsset];
}

- (void) videoButtonPressed:(id)sender;
{
	// create an image picker that only allows for non-editing movies
	UIImagePickerController *controller = [[UIImagePickerController alloc] init];
	[controller setDelegate:self];
	controller.sourceType = UIImagePickerControllerSourceTypePhotoLibrary/*UIImagePickerControllerSourceTypeSavedPhotosAlbum*/;
	controller.allowsEditing = NO; 
	controller.mediaTypes = [NSArray arrayWithObject:(NSString *)kUTTypeMovie];
	controller.videoQuality = UIImagePickerControllerQualityTypeHigh;
	
	[self presentModalViewController:controller animated:YES];
	[controller release];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
	[self dismissModalViewControllerAnimated:YES];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
	// recover video URL
	currentAsset = [[info objectForKey:UIImagePickerControllerMediaURL] retain];
	[self dismissModalViewControllerAnimated:YES];
	[self setPlayerAsset:currentAsset];
}

- (void) actionButtonPressed:(id)sender
{
	
}

- (void) shareButtonPressed:(id)sender
{
	// see if there is network connectivity
	NetworkStatus netstatus = [internetReach currentReachabilityStatus];
	if(netstatus == NotReachable)
	{
		UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Network Status" message:@"Facebook upload requires an internet connection via WiFi or cellular network to work." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease];
		[alert show];
		[alert release];
	}
	else
	{
		[self removeMoviePlayer];
		
		FaceBookUploaderViewController * fbu = [[FaceBookUploaderViewController alloc] initWithAsset:currentAsset HasWifi:netstatus == kReachableViaWiFi];
		[self.navigationController pushViewController:fbu animated:true];
		[fbu release];
	}
}

@end
