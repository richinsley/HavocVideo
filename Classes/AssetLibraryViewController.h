//
//  AssetLibraryViewController.h
//  Havoc Video
//
//  Created by Richard Insley on 9/19/10.
//  Copyright 2010 WildWestWare. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "AlbumContentsViewController.h"
#import "AssetPlayerViewController.h"

@interface AssetLibraryViewController : UIViewController 
{
	UIView * canvas;
	UINavigationController *navigationController;
	NSURL * _currentAsset;
	
	ALAssetsLibrary *assetsLibrary;
    NSMutableArray *groups;
	
	AlbumContentsViewController* contentsView;
}

- (id)initWithAsset:(NSURL *)asset;
- (void)newAssetSet:(NSNotification*)notification;
- (void)addAssetPlayer;

@property (nonatomic, retain) IBOutlet UIView *canvas;
@property (nonatomic, retain) IBOutlet UINavigationController *navigationController;
@end
