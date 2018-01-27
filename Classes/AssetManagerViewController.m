//
//  AssetManagerViewController.m
//  Havoc Video
//
//  Created by Richard Insley on 9/16/10.
//  Copyright 2010 WildWestWare. All rights reserved.
//

#import "AssetManagerViewController.h"

@implementation AssetManagerViewController

@synthesize theNavController;

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // Custom initialization
    }
    return self;
}
*/

- (id) initWithAssetURL:(NSURL*) asset 
{
	if((self = [super init]))
	{
		currentAsset = asset;
	}
	return self;
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad 
{
    [super viewDidLoad];
	[self.view addSubview:theNavController.view];
	NSArray * controllers = self.theNavController.viewControllers;
	thePlayer = [controllers objectAtIndex:0];
	[thePlayer setPlayerAsset:currentAsset];
}

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    // return (interfaceOrientation == UIInterfaceOrientationPortrait);
	return YES;
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
}


- (void)dealloc 
{
    [super dealloc];
}


@end
