//
//  EffectButtonPanel.mm
//  Havoc Video
//
//  Created by Richard Insley on 9/7/10.
//  Copyright 2010 WildWestWare. All rights reserved.
//

#import "EffectButtonPanel.h"


@implementation EffectButtonPanel


- (id)initWithFrame:(CGRect)frame 
			Caption:(NSString*)caption 
			  Image:(const char *)imagePath 
			  Index:(int)index 
		   IsActive:(bool)isActive 
	 ScriptCallback:(id <ChangeScriptProtocol>)callback
{
    if ((self = [super initWithFrame:frame])) 
	{
		_callback = callback;
		_index = index;
		
        // Initialization code
		UILabel * effectLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 96, 21)];
		effectLabel.center = CGPointMake(50, 89);
		effectLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size: 10.0];
		effectLabel.textAlignment = UITextAlignmentCenter;
		effectLabel.adjustsFontSizeToFitWidth = true;
		effectLabel.numberOfLines = 1;
		effectLabel.text = caption;
		effectLabel.opaque = false;
		effectLabel.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.6];
		
		// modify the labels layer properties ( must inlude QuartzCore/CALayer.h to access CALayer !)
		[[effectLabel layer] setCornerRadius:4.0f];
		[[effectLabel layer] setBorderColor:[UIColor colorWithWhite:1.0 alpha:0.8].CGColor];
		[[effectLabel layer] setBorderWidth:1.0f];
		
		[self addSubview:effectLabel];
		[effectLabel release];
		
		// load image
		//UIImage * biu = [UIImage imageWithContentsOfFile:[EffectButtonPanel getPathForImageFile:imagePath]];
		
		// load image as a cached image
		NSString * iname = [ NSString stringWithCString: imagePath encoding: NSASCIIStringEncoding ];
		UIImage * biu = [UIImage imageNamed:iname];
		
		/*
		CGImageRef buttonimage = biu.CGImage;
		int iwidth = CGImageGetHeight(buttonimage);
		int iheight = CGImageGetWidth(buttonimage);

		// mask with mask (for it to work correctly, the source image must be ARGB)
		CGImageRef maskedimage = [EffectButtonPanel maskImage:buttonimage withMask:mask];
		
		// composite the button image into outputImage
		UIGraphicsBeginImageContext(CGSizeMake(iwidth, iheight)); 
		[[UIImage imageWithCGImage:maskedimage] drawAtPoint:CGPointZero];
		[[UIImage imageWithCGImage:lightingImage] drawAtPoint:CGPointZero];
		UIImage *outputImage = UIGraphicsGetImageFromCurrentImageContext(); 
		UIGraphicsEndImageContext();
		*/
		
		UIButton * effectButton = [UIButton buttonWithType:UIButtonTypeCustom];
		[effectButton setFrame:CGRectMake(0,0,74,74)];
		[effectButton setCenter:CGPointMake(50, 43)];
		[effectButton addTarget:self action:@selector(buttonPressed) forControlEvents:UIControlEventTouchUpInside];
		[effectButton setImage:biu forState:UIControlStateNormal];
		[self addSubview:effectButton];

    }
    return self;
}

- (void)buttonPressed
{
	[_callback setCurrentScript:_index];
}

+(NSString *)getPathForImageFile:(const char *)name
{
	NSString *imageName = [ NSString stringWithCString: name encoding: NSASCIIStringEncoding ];
	
	imageName = [[NSBundle mainBundle] pathForResource:imageName ofType:@"png"];
	if(!imageName)
	{
		// try jpeg
		imageName = [ NSString stringWithCString: name encoding: NSASCIIStringEncoding ];
		imageName = [[NSBundle mainBundle] pathForResource:imageName ofType:@"jpg"];
	}
	
	return imageName;
}

+(CGImageRef) maskImage:(CGImageRef)image withMask:(CGImageRef)mask  
{	
	CGImageRef masked = CGImageCreateWithMask(image, mask);
	return masked;
}

- (void)dealloc 
{
    [super dealloc];
}


@end
