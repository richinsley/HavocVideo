//
//  SnapshotView.h
//  Havoc Video
//
//  Created by Richard Insley on 9/10/10.
//  Copyright 2010 WildWestWare. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ChangeScriptProtocol

-(void)snapShotAnimationComplete:(NSURL*)url;

@end


@interface SnapshotView : UIImageView 
{
	id <ChangeScriptProtocol> _callback;
	NSURL* _assetURL;
}

- (void)presentWithSuperview:(UIView *)superview 
				   StartSize:(CGRect)startRect 
				  StartPoint:(CGPoint)startpoint 
					 EndSize:(CGRect)endRect 
					EndPoint:(CGPoint)endpoint 
			  CallbackTarget:(id <ChangeScriptProtocol>)callback  
					AssetURL:(NSURL*)assetURL;		

@end
