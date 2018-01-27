//
//  EffectButtonPanel.h
//  Havoc Video
//
//  Created by Richard Insley on 9/7/10.
//  Copyright 2010 WildWestWare. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ChangeScriptProtocol.h"
#import <QuartzCore/CALayer.h>

@interface EffectButtonPanel : UIView 
{
	int _index;
	id <ChangeScriptProtocol> _callback;
}

+(NSString *)getPathForImageFile:(const char *)name;
+(CGImageRef)maskImage:(CGImageRef)image withMask:(CGImageRef)mask;

- (id)initWithFrame:(CGRect)frame 
			Caption:(NSString*)caption 
			  Image:(const char *)imagePath 
			  Index:(int)index 
		   IsActive:(bool)isActive
	 ScriptCallback:(id <ChangeScriptProtocol>)callback;

- (void)buttonPressed;
@end

