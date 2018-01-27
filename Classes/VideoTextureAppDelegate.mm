//
//  VideoTextureAppDelegate.m
//  VideoTexture
//
//  Created by Richard Insley on 8/17/10.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import "VideoTextureAppDelegate.h"
#import "EAGLView.h"
#import "GLViewController.h"

@implementation VideoTextureAppDelegate

@synthesize window;
@synthesize viewController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions   
{
	captureNeedsRestart = false;
	
	[window addSubview:viewController.view];
    [window makeKeyAndVisible];
	
	// prevent dimming
	UIApplication *myApp = [UIApplication sharedApplication];
	myApp.idleTimerDisabled = YES;
    
	[viewController.glView startAnimation]; 
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
	// abort any recording and stop the capture process
    [viewController.glView stopRecording:false];
	[viewController.glView stopCapture];
	[viewController setLampButtonOn:false]; // when we return, the lamp will not be enabled if it already was
	captureNeedsRestart = true;
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
	if(captureNeedsRestart)
	{
		// restart the capture
		[viewController.glView startCapture];
	}
	
	// get state of alassets access
	[viewController updateAssetsStatus];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    [viewController.glView stopRecording:false];
	[viewController.glView stopCapture];
}

- (void)dealloc
{
    [window release];
    [super dealloc];
}

@end
