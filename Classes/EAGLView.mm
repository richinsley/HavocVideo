//
//  EAGLView.m
//  VideoTexture
//
//  Created by Richard Insley on 8/17/10.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import "EAGLView.h"
#import "ES2Renderer.h"

@implementation EAGLView

@synthesize animating;
@dynamic animationFrameInterval;
@synthesize moviePlayer;
@synthesize orientation;

// You must implement this method
+ (Class)layerClass
{
    return [CAEAGLLayer class];
}

//The EAGL view is stored in the nib file. When it's unarchived it's sent -initWithCoder:
- (id)initWithCoder:(NSCoder*)coder
{    
    if ((self = [super initWithCoder:coder]))
    {
        // Get the layer
        CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;

		// setting the contentScaleFactor to 1.5 will cause the underlying opengl view to be 480x720 
		//self.contentScaleFactor = 1.5;
		//self.contentMode = UIViewContentModeScaleToFill;
		
        eaglLayer.opaque = TRUE;
        eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                        [NSNumber numberWithBool:FALSE], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];

        renderer = [[ES2Renderer alloc] init];

        if (!renderer)
        {
            //renderer = [[ES1Renderer alloc] init];

            if (!renderer)
            {
                [self release];
                return nil;
            }
        }

		lastFrameImage = NULL;
        animating = FALSE;
        displayLinkSupported = FALSE;
        animationFrameInterval = 1;
        displayLink = nil;
        animationTimer = nil;

        // A system version of 3.1 or greater is required to use CADisplayLink. The NSTimer
        // class is used as fallback when it isn't available.
        NSString *reqSysVer = @"3.1";
		
        NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
        if ([currSysVer compare:reqSysVer options:NSNumericSearch] != NSOrderedAscending)
            displayLinkSupported = TRUE;
		
		// set up notifications for the state of media
		NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
		[notificationCenter addObserver:self selector:@selector(frameNeedsProcessing:) name:@"frameNeedsProcessing" object:nil];
		[notificationCenter addObserver:self selector:@selector(audioNeedsProcessing:) name:@"audioNeedsProcessing" object:nil];
		[notificationCenter addObserver:self selector:@selector(restartCapture:) name:@"restartCapture" object:nil];
		[notificationCenter addObserver:self selector:@selector(effectChanged:) name:@"effectChanged" object:nil];
		
		recBlinkTimer = NULL;
	}

    return self;
}

- (void)drawView:(id)sender
{
	// we want the videobuffer to control the repainting interval of the media
	return;
}

-(void)audioNeedsProcessing:(NSNotification*)notification
{
	// the CMSampleBufferRef will be wrapped in an NSValue handed over by the output callback
	NSValue * val = [notification object];
	void* refptr;
	[val getValue:&refptr];
	CMSampleBufferRef samplebuffer = (CMSampleBufferRef)refptr;
	[renderer processAudio:samplebuffer];
}

- (void)frameNeedsProcessing:(NSNotification*)notification
{
	// the CMTime timestamp will be wrapped in an NSValue handed over by the output callback
	NSValue * val = [notification object];
	CMTime timestamp = [val CMTimeValue];
	[renderer renderToSampleBuffer:timestamp];
}

-(void)restartCapture:(NSNotification*)notification
{
	UIViewController * view = [notification object];
	[self startCapture];
	
	// if this was called by a sub view, remove that subview
	if(view)
	{
		[view.view removeFromSuperview];
	}
}

-(void)effectChanged:(NSNotification*)notification
{
	UIViewController * view = [notification object];
	NSNumber * val = [notification object];
	EffectScript * script = (EffectScript*)[val unsignedIntValue];
	
	if(effectLabel)
	{
		NSString * ename = [NSString stringWithCString:script->getGlobalString("EFFECTNAME") encoding:NSUTF8StringEncoding];
		[effectLabel performSelectorOnMainThread:@selector(setText:) withObject:ename waitUntilDone:NO];
	}
}

- (void)layoutSubviews
{
    [renderer resizeFromLayer:(CAEAGLLayer*)self.layer];
    [self drawView:nil];
	
	// announce our render surfaces have been generated
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	[notificationCenter postNotificationName:@"gllayoutSubviews" object:NULL];
}

- (NSInteger)animationFrameInterval
{
    return animationFrameInterval;
}

- (void)setAnimationFrameInterval:(NSInteger)frameInterval
{
    // Frame interval defines how many display frames must pass between each time the
    // display link fires. The display link will only fire 30 times a second when the
    // frame internal is two on a display that refreshes 60 times a second. The default
    // frame interval setting of one will fire 60 times a second when the display refreshes
    // at 60 times a second. A frame interval setting of less than one results in undefined
    // behavior.
    if (frameInterval >= 1)
    {
        animationFrameInterval = frameInterval;

        if (animating)
        {
            [self stopAnimation];
            [self startAnimation];
        }
    }
}

// start and stop video feed from camera
-(void)stopCapture
{
	[renderer stopCapture];
}

-(void)startCapture
{
	[renderer startCapture];
}

- (void)startAnimation
{
    if (!animating)
    {
		/*
		// CADisplayLink is API new to iPhone SDK 3.1. Compiling against earlier versions will result in a warning, but can be dismissed
		// if the system version runtime check for CADisplayLink exists in -initWithCoder:. The runtime check ensures this code will
		// not be called in system versions earlier than 3.1.

		displayLink = [NSClassFromString(@"CADisplayLink") displayLinkWithTarget:self selector:@selector(drawView:)];
		[displayLink setFrameInterval:animationFrameInterval];
		[displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
		*/
		
		// the capture thread will drive the animation.
		[self startCapture];
        animating = TRUE;
    }
}

- (void)stopAnimation
{
    if (animating)
    {
		/*
        if (displayLinkSupported)
        {
            [displayLink invalidate];
            displayLink = nil;
        }
        else
        {
            [animationTimer invalidate];
            animationTimer = nil;
        }
		*/
		
        animating = FALSE;
    }
}

- (id)getRenderer
{
	return renderer;
}

- (UIImage *)getLastImage
{
	UIImage * retv = lastFrameImage;
	lastFrameImage = NULL;
	return retv;
}

- (void)dealloc
{
	[self stopRecording:false];
	[self stopCapture];
	
    [super dealloc];
	
	if(lastFrameImage)
	{
		[lastFrameImage release];
		lastFrameImage = NULL;
	}
	
	[renderer release];
}

- (void)effectButton:(id)sender
{
	[renderer incEffect];
}

-(void)startRecording
{
	// start the record blink timer
	[self addBlinkTimer];
	timeLabel.text = @"00:00";
	timeLabel.hidden = NO;
	
	[renderer startRecording:orientation];
	[recordButton setImage:[UIImage imageNamed:@"record-btn-on.png"] forState:UIControlStateNormal];
	recordButton.tag = 1;
}

-(NSString *)stopRecording:(bool)snapshot
{	
	dispatch_async(dispatch_get_main_queue(), ^{
		timeLabel.hidden = YES;
		[self removeBlinkTimer];
		[recordButton setImage:[UIImage imageNamed:@"record-btn.png"] forState:UIControlStateNormal];
		recordButton.tag = 0;
	});
	
	if([renderer isRecording])
	{
		NSString * path = [renderer stopRecording];
		
		if(snapshot)
		{
			if(lastFrameImage)
			{
				[lastFrameImage release];
			}
			
			lastFrameImage = [[self saveImageFromGLView] retain];
		}
		
		return path;
	}
	
	return NULL;
}

- (void)incEffect
{
	[renderer incEffect];
}

- (void)decEffect
{
	[renderer decEffect];
}

-(UIImage *) saveImageFromGLView
{
	int w = 320;
	int h = 480;
	int offset = 54;
	
    NSInteger myDataLength = 320 * (480 - offset) * 4;
	
    // allocate array and read pixels into it.
    GLubyte *buffer = (GLubyte *) malloc(myDataLength);
    glReadPixels(0, offset, 320, 480 - offset, GL_RGBA, GL_UNSIGNED_BYTE, buffer);
	
    // gl renders "upside down" so swap top to bottom into new array.
    // there's gotta be a better way, but this works.
    GLubyte *buffer2 = (GLubyte *) malloc(myDataLength);
    for(int y = 0; y < 480 - offset; y++)
    {
        for(int x = 0; x < 320 * 4; x++)
        {
            buffer2[((480 - 1 - offset) - y) * 320 * 4 + x] = buffer[y * 4 * 320 + x];
        }
    }
    // make data provider with data.
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, buffer2, myDataLength, NULL);
	
    // prep the ingredients
    int bitsPerComponent = 8;
    int bitsPerPixel = 32;
    int bytesPerRow = 4 * 320;
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
	
    // make the cgimage
    CGImageRef imageRef = CGImageCreate(320, 480 - offset, bitsPerComponent, bitsPerPixel, bytesPerRow, colorSpaceRef, bitmapInfo, provider, NULL, NO, renderingIntent);
	
    // then make the uiimage from that
    UIImage *myImage = [UIImage imageWithCGImage:imageRef];
    return myImage;
}

-(void)pauseRecording
{
	[renderer pauseRecording];
}

- (void)recordButton:(id)sender 
{
	if([renderer isRecording])
	{
		[self stopRecording:false];
	}
	else 
	{
		[self startRecording];
	}

}

- (bool)isRecording
{
	if(renderer)
	{
		return [renderer isRecording];
	}
	
	return false;
}

// returns the available scripts in the renderer
- (EffectScript**)getScripts
{
	return [renderer GetScripts];
}

- (void)addBlinkTimer
{
	if(!recBlinkTimer)
	{
		recBlinkTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(blinkRecord:) userInfo:self repeats:true];
	}
}

- (void)removeBlinkTimer
{
	if(recBlinkTimer)
	{
		[recBlinkTimer invalidate];
		//[recBlinkTimer release];
		recBlinkTimer = NULL;
	}
}

- (void)blinkRecord:(NSTimer*)theTimer
{
	if(recordButton.tag == 1)
	{
		// update the time label
		double dur = [renderer getDuration];
		if (dur < 60)
		{
			timeLabel.text = [NSString stringWithFormat:@"00:%02d", (int)dur];
		}
		else
		{
			int secs = (int)dur % 60;
			int min = (int)(dur / 60);
			timeLabel.text = [NSString stringWithFormat:@"%d:%02d", min, secs];
		}
		
		[recordButton setImage:[UIImage imageNamed:@"record-btn.png"] forState:UIControlStateNormal];
		recordButton.tag = 0;
	}
	else 
	{
		[recordButton setImage:[UIImage imageNamed:@"record-btn-on.png"] forState:UIControlStateNormal];
		recordButton.tag = 1;
	}
}

@end

