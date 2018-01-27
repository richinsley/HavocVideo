//
//  AssetManagerViewController.h
//  Havoc Video
//
//  Created by Richard Insley on 9/16/10.
//  Copyright 2010 WildWestWare. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AssetPlayerViewController.h"

@interface AssetManagerViewController : UIViewController 
{
	UINavigationController *theNavController;
	NSURL * currentAsset;
	AssetPlayerViewController * thePlayer;
	
}

- (id) initWithAssetURL:(NSURL*) asset;

@property (nonatomic, retain) IBOutlet UINavigationController *theNavController;


@end
