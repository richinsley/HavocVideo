//
//  AssetLibraryViewController.m
//  Havoc Video
//
//  Created by Richard Insley on 9/19/10.
//  Copyright 2010 WildWestWare. All rights reserved.
//

#import "AssetLibraryViewController.h"


@implementation AssetLibraryViewController

@synthesize canvas;
@synthesize navigationController;


- (id)initWithAsset:(NSURL *)asset 
{
    if ((self = [super init])) 
	{
        // Custom initialization
		_currentAsset = asset;
		
		NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
		[notificationCenter addObserver:self selector:@selector(newAssetSet:) name:@"newAssetSet" object:nil];
		[notificationCenter addObserver:self selector:@selector(assetPlayerDone:) name:@"assetPlayerDone" object:nil];
    }
    return self;
}

- (void)newAssetSet:(NSNotification*)notification
{
	// the CMTime timestamp will be wrapped in an NSValue handed over by the output callback
	NSURL * val = [notification object];
	
	if(_currentAsset)
	{
		[_currentAsset release];
	}
	
	_currentAsset = val;
	[self addAssetPlayer];
}

-(void) viewDidDisappear:(BOOL)animated
{
	// pop all the views so they will clean up properly
	int vcount = [self.navigationController.viewControllers count];
	while(vcount > 1)
	{
		[self.navigationController popViewControllerAnimated:false];
		vcount = [self.navigationController.viewControllers count];
	}
	
	// broadcast that we are closing
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	
	// we want this to be completely hidden before we restart the capture process again
	[notificationCenter postNotificationName:@"assetPlayerClosing" object:self];
}

- (void)assetPlayerDone:(NSNotification*)notification
{
	[self dismissModalViewControllerAnimated:true];
}

- (void)addAssetPlayer
{
	// add a new asset player view for the current asset
	AssetPlayerViewController* newPlayer = [[AssetPlayerViewController alloc] initWithAssetURL:_currentAsset AssetPlayerProtocol:NULL];
	[self.navigationController pushViewController:newPlayer animated:true];
	[newPlayer release];
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad 
{
    [super viewDidLoad];
	[self.view addSubview:navigationController.view];
	
	// at this point, we should already have the rootview and the first camera roll view
	// add the player for the current asset, and all is happy super number one
	[self addAssetPlayer];
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

-(void)viewWillAppear:(BOOL)animated 
{ 
	[super viewWillAppear:animated];
	[self.navigationController viewWillAppear:animated];
}

-(void)viewWillDisappear:(BOOL)animated 
{ 
	[super viewWillAppear:animated];
	[self.navigationController viewWillDisappear:animated];
}

- (void)viewDidUnload 
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
	
	[navigationController.view removeFromSuperview];
}

- (void)dealloc 
{
    [super dealloc];
}


@end
