//
//  VideoTextureAppDelegate.h
//  VideoTexture
//
//  Created by Richard Insley on 8/17/10.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EAGLView.h"

@class GLViewController;

@interface VideoTextureAppDelegate : NSObject <UIApplicationDelegate> 
{
    UIWindow *window;
	GLViewController *viewController;
	bool captureNeedsRestart;
}

+(NSMutableArray*)getUploads;
@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet GLViewController *viewController;

@end

