//
//  SnapshotView.m
//  Havoc Video
//
//  Created by Richard Insley on 9/10/10.
//  Copyright 2010 WildWestWare. All rights reserved.
//

#import "SnapshotView.h"


@implementation SnapshotView


- (id)initWithImage:(UIImage *)image
{
    if ((self = [super initWithImage:image])) 
	{
        // Initialization code
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (void)dealloc 
{
    [super dealloc];
}

// Add this view to superview, and slide it in from the bottom
- (void)presentWithSuperview:(UIView *)superview 
				   StartSize:(CGRect)startRect 
				  StartPoint:(CGPoint)startpoint 
					 EndSize:(CGRect)endRect 
					EndPoint:(CGPoint)endpoint 
			  CallbackTarget:(id <ChangeScriptProtocol>)callback  
					AssetURL:(NSURL*)assetURL
{
    // Set the Start
    self.bounds = startRect;
	self.center = startpoint;
	_callback = callback;
	_assetURL = [assetURL retain];
	
    [superview addSubview:self];            
	
    // Animate to new location
    [UIView beginAnimations:@"presentWithSuperview" context:self];
	
	// selector to be called when animation stops
	[UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
	
    self.bounds = endRect;
	self.center = endpoint;
	
    [UIView commitAnimations];
}

// Method called when removeFromSuperviewWithAnimation's animation completes
- (void)animationDidStop:(NSString *)animationID
                finished:(NSNumber *)finished
                 context:(void *)context 
{
    if ([animationID isEqualToString:@"presentWithSuperview"]) 
	{
		[_callback snapShotAnimationComplete:_assetURL];
        [self removeFromSuperview];
    }
}

@end
