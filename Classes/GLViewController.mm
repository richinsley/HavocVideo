//
//  GLViewController.m
//  VideoTexture
//
//  Created by Richard Insley on 8/25/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "GLViewController.h"

// callback when an audio sound completes
static void MyAudioServicesSystemSoundCompletionProc (
                                                      SystemSoundID  ssID,
                                                      void           *clientData
                                                      )
{
	GLViewController* controller = (GLViewController*)clientData;
	if(ssID == controller.startSoundFileObject)
	{
		// start the actuall recording
		[controller.glView startRecording];
	}
}

@implementation GLViewController
@synthesize glView;
@synthesize startSoundFileObject;
@synthesize stopSoundFileObject;

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil 
 {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) 
 {
        // Custom initialization
    }
    return self;
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad 
{
	shouldOpenCoverPlate = false;
	assetsDenied = false;
	effectOpen = false;
    [super viewDidLoad];
	
	// we need to manually track orientation
	[[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(receivedRotate:) name: UIDeviceOrientationDidChangeNotification object: nil];
	
	// Create and configure the four recognizers.
	UIGestureRecognizer *recognizer;
	
    // Create a tap recognizer and add it to the view.
	recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapFrom:)];
	[self.glView addGestureRecognizer:recognizer];
    recognizer.delegate = self;
	[recognizer release];
	
	// Create a swipe gesture recognizer to recognize right swipes
	recognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeFrom:)];
	[self.glView addGestureRecognizer:recognizer];
	recognizer.delegate = self;
	[recognizer release];
	
    // Create a swipe gesture recognizer to recognize left swipes.
	recognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeFrom:)];
	[self.glView addGestureRecognizer:recognizer];
    ((UISwipeGestureRecognizer *)recognizer).direction = UISwipeGestureRecognizerDirectionLeft;
	[recognizer release];
	
	// Create a swipe gesture recognizer to recognize up swipes.
	recognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeFrom:)];
	[self.glView addGestureRecognizer:recognizer];
    ((UISwipeGestureRecognizer *)recognizer).direction = UISwipeGestureRecognizerDirectionUp;
	[recognizer release];
	
	// Create a swipe gesture recognizer to recognize down swipes.
	recognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeFrom:)];
	[self.glView addGestureRecognizer:recognizer];
    ((UISwipeGestureRecognizer *)recognizer).direction = UISwipeGestureRecognizerDirectionDown;
	[recognizer release];
	
	// create a progress HUD view
	savingAlert = [[MBProgressHUD alloc] initWithView:glView];
	savingAlert.labelText = @"Saving to Camera Roll";
	// Add HUD to the GLView
    [self.view addSubview:savingAlert];

	// Create the URL for the source audio file. The URLForResource:withExtension: method is
    //    new in iOS 4.0.
    NSURL *tapSound   = [[NSBundle mainBundle] URLForResource: @"ping"
                                                withExtension: @"aiff"];
	
    // Store the URL as a CFURLRef instance
    startSoundFileURLRef = (CFURLRef) [tapSound retain];
	
    // Create a system sound object representing the sound file.
    AudioServicesCreateSystemSoundID (
									  startSoundFileURLRef,
									  &startSoundFileObject
									  );
	
	tapSound   = [[NSBundle mainBundle] URLForResource: @"doubleping"
										 withExtension: @"aiff"];
	
    // Store the URL as a CFURLRef instance
    stopSoundFileURLRef = (CFURLRef) [tapSound retain];
	
    // Create a system sound object representing the sound file.
    AudioServicesCreateSystemSoundID (
									  stopSoundFileURLRef,
									  &stopSoundFileObject
									  );
	
	// register the callback to know when the sounds have stopped
	AudioServicesAddSystemSoundCompletion(startSoundFileObject, NULL, NULL, MyAudioServicesSystemSoundCompletionProc, self);
	AudioServicesAddSystemSoundCompletion(stopSoundFileObject, NULL, NULL, MyAudioServicesSystemSoundCompletionProc, self);
	
	// set up images needed for generating asset button image
	CGImageRef maskImage = [UIImage imageWithContentsOfFile:[GLViewController getPathForImageFile:"assetButtonMask"]].CGImage;
	assetLightingImage = [UIImage imageWithContentsOfFile:[GLViewController getPathForImageFile:"assetButtonLighting"]].CGImage;
	assetMask = CGImageMaskCreate(CGImageGetWidth(maskImage),
										CGImageGetHeight(maskImage),
										CGImageGetBitsPerComponent(maskImage),
										CGImageGetBitsPerPixel(maskImage),
										CGImageGetBytesPerRow(maskImage),
										CGImageGetDataProvider(maskImage), NULL, false);
	
	CGImageRetain(assetLightingImage);
	
	// we want to know when the asset player has completed
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	[notificationCenter addObserver:self selector:@selector(assetPlayerClosing:) name:@"assetPlayerClosing" object:nil];
	
	// we want to know when an effect is loading
	[notificationCenter addObserver:self selector:@selector(effectLoading:) name:@"effectLoading" object:nil];
	
	// we want to know when the renderer is fully initialized
	[notificationCenter addObserver:self selector:@selector(rendererInitialized:) name:@"rendererInitialized" object:nil];
	
	// we want to know when the GLView has performed layoutSubviews
	[notificationCenter addObserver:self selector:@selector(gllayoutSubviews:) name:@"gllayoutSubviews" object:nil];
	
	// we need to know when a frame has arrived so we can open the cover plate when it is closed
	[notificationCenter addObserver:self selector:@selector(frameNeedsProcessing:) name:@"frameNeedsProcessing" object:nil];
	
	// async queue to finalize video on
	finalizerq = dispatch_queue_create("finalizerq", NULL);
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
}

-(void) updateAssetsStatus
{
	[self getAssestsGroups];
}

-(void)gllayoutSubviews:(NSNotification*)notification
{

}

-(void)effectLoading:(NSNotification*)notification
{
	NSString * val = [notification object];
}

-(void)rendererInitialized:(NSNotification*)notification
{
	// set up the effect menu
	EffectScript** scripts = [self.glView getScripts];
	
	// get the count
	int scriptCount = 0;
	while(scripts[scriptCount])
	{
		scriptCount ++;
	}
	
	int kNumberOfPages = (int)ceil((float)scriptCount / 6.0);

	[dots setPageCount:kNumberOfPages];
	[dots setDotGap:6];
	[dots setDotSize:9];
	
	// create button views
	effectScrollView.pagingEnabled = YES;
	effectScrollView.contentSize = CGSizeMake(effectScrollView.frame.size.width, effectScrollView.frame.size.height * kNumberOfPages);
	effectScrollView.showsHorizontalScrollIndicator = NO;
	effectScrollView.showsVerticalScrollIndicator = NO;
	effectScrollView.scrollsToTop = NO;
	effectScrollView.delegate = self;
	
	// gen the button subviews
	int i = 0;
	for(i = 0; i < kNumberOfPages; i ++)
	{
		effectSubViews[i * 2] = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 176, 176)] retain];
		[effectSubViews[i * 2] setCenter:CGPointMake(96, 88 + effectScrollView.frame.size.height * i)];
		
		effectSubViews[i * 2 + 1] = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 176, 176)] retain];
		[effectSubViews[i * 2 + 1] setCenter:CGPointMake(96, 264 + effectScrollView.frame.size.height * i)];
	}
	effectSubViews[i * 2] = 0;
	
	// gen the buttons
	int boff = 38;
	int bcount = 0;
	int sview = 0;
	
	for(i = 0; i < scriptCount; i++)
	{
		UIButton * effectButton = [UIButton buttonWithType:UIButtonTypeCustom];
		[effectButton setFrame:CGRectMake(0,0,160,37)];
		[effectButton setContentHorizontalAlignment:UIControlContentHorizontalAlignmentCenter];
		[effectButton setCenter:CGPointMake(88, boff + bcount * 50)];
		[effectButton setTitle:scripts[i]->scriptName forState:UIControlStateNormal];
		[effectButton addTarget:self action:@selector(effectButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
		[effectButton setTitleColor:[UIColor colorWithWhite:0.75 alpha:1.0] forState:UIControlStateHighlighted];
		 
		effectButton.tag = i;
		[effectSubViews[sview] addSubview:effectButton];
		
		bcount++;
		if(bcount == 3) 
		{
			bcount = 0;
			boff + 38;
			sview++;
		}
	}
	
	// the render is initialized and capture is running
	[UIView animateWithDuration:0.65
					 animations:^
	 {
		 effectView.center = CGPointMake(125, 663);
		 recordView.center = CGPointMake(220, 445);
	 }
	 
					 completion:^(BOOL completed)
	 {
		 // when a video frame has come in, open the cover plate
		 shouldOpenCoverPlate = true;
	 }
	 ];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
	CGRect visibleBounds = scrollView.bounds;
	int npage = (int)MIN(MAX(0,floorf(visibleBounds.origin.y / CGRectGetHeight(visibleBounds))),dots.pageCount);
	if(npage != dots.currentPage)
	{
		[dots setCurrentPage:npage];
	}
}

- (void) openCoverPlate
{
	[coverPlate setHidden:false];
	[UIView animateWithDuration:0.5
					 animations:^
	 {
		 //coverPlate.center = CGPointMake(160, -240);
		 coverPlate.alpha = 0.0;
	 }
	 
	completion:^(BOOL completed)
	 {
		 [coverPlate setHidden:true];
	 }
	 ];
		 
}

-(void) closeCoverPlate
{
	[coverPlate setHidden:false];
	[UIView animateWithDuration:0.5
					 animations:^
	 {
		 coverPlate.center = CGPointMake(160, 240);
	 }
	 
					 completion:^(BOOL completed)
	 {
		 
	 }
	 ];
}

- (void)frameNeedsProcessing:(NSNotification*)notification
{
	if(shouldOpenCoverPlate)
	{
		shouldOpenCoverPlate = false;
		[self performSelectorOnMainThread:@selector(openCoverPlate) withObject:self waitUntilDone:NO];
	}
}

- (void)effectButtonPressed:(id)sender
{
	// tel the rederer to change to the new effect script
	int script = ((UIButton*)sender).tag;
	[[self.glView getRenderer] setCurrentScript:script];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch 
{
	// we only want the EAGLView to respond to swipes
	bool canrec = [touch.view isKindOfClass:[EAGLView class]];
	
	if(canrec && effectOpen)
	{
		// close the effect panel
		[self chooseEffectButton:self];
	}
	
	return canrec;
}

- (void)handleTapFrom:(UITapGestureRecognizer *)recognizer 
{
	if(!effectOpen)
	{
		CGPoint location = [recognizer locationInView:self.view];
	}
}

- (void)handleSwipeFrom:(UISwipeGestureRecognizer *)recognizer 
{
	if(!effectOpen)
	{
		CGPoint location = [recognizer locationInView:self.view];
		if(recognizer.direction == UISwipeGestureRecognizerDirectionLeft || recognizer.direction == UISwipeGestureRecognizerDirectionUp)
		{
			[glView decEffect];
		}
		else if(recognizer.direction == UISwipeGestureRecognizerDirectionRight || recognizer.direction == UISwipeGestureRecognizerDirectionDown)
		{
			[glView incEffect];
		}
	}
}

- (void)handleRotationFrom:(UIRotationGestureRecognizer *)recognizer {
	
	if(!effectOpen)
	{
		CGPoint location = [recognizer locationInView:self.view];
		
		/*
		CGAffineTransform transform = CGAffineTransformMakeRotation([recognizer rotation]);
		imageView.transform = transform;
		[self showImageWithText:@"rotation" atPoint:location];
		
		[UIView beginAnimations:nil context:NULL];
		[UIView setAnimationDuration:0.65];
		imageView.alpha = 0.0;
		imageView.transform = CGAffineTransformIdentity;
		[UIView commitAnimations];
		*/
	}
}

-(void) receivedRotate: (NSNotification*) notification
{
	UIDeviceOrientation interfaceOrientation = [[UIDevice currentDevice] orientation];
	
	// let the glview know the current orientation
	glView.orientation = (UIInterfaceOrientation)interfaceOrientation;
	((ES2Renderer*)[glView getRenderer]).orientation = (UIInterfaceOrientation)interfaceOrientation;
	
	currentOrientation = (UIInterfaceOrientation)interfaceOrientation;
	
	// broadcast the orientation change
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	[notificationCenter postNotificationName:@"orientationChange" object:[NSNumber numberWithInt:(int)interfaceOrientation]];
	

	// animate our bottons
	float newf = [GLViewController getTransformForOrientation:currentOrientation];
	CGAffineTransform newt = CGAffineTransformMakeRotation(newf);
	
	CGContextRef context = UIGraphicsGetCurrentContext();
	[UIView beginAnimations:nil context:context];
	[UIView setAnimationCurve:UIViewAnimationCurveLinear];
	[UIView setAnimationDuration:0.25];
	
	lampButton.transform = newt;
	switchCameraButton.transform = newt; 
	timeLabel.transform = newt;
	
	int esv = 0;
	while(effectSubViews[esv])
	{
		effectSubViews[esv].transform = newt;
		esv++;
	}
	
	[UIView commitAnimations];
}

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{	
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)didReceiveMemoryWarning 
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload 
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
	
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	[[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
}

- (void)setLampButtonOn:(bool)lampon
{
	if(lampon)
	{
		[lampButton setImage:[UIImage imageNamed:@"camera-flash-on.png"] forState:UIControlStateNormal];
	}
	else 
	{
		[lampButton setImage:[UIImage imageNamed:@"camera-flash.png"] forState:UIControlStateNormal];
	}
}

- (void)lampButton:(id)sender
{
	// toggle the lamp (if lamp is not available for device, it will be ignored)
	id renderer = [self.view getRenderer];
	[renderer enableLamp:![renderer isLampEnabled]];
	[self setLampButtonOn:[renderer isLampEnabled]];
}

- (void)switchCameraButton:(id)sender
{
	// switch camera views
	id renderer = [self.view getRenderer];
	[self setLampButtonOn:false];
	[renderer setFrontCamera:![renderer isFrontCamera]];
}

- (void)chooseEffectButton:(id)sender
{
	CGContextRef context = UIGraphicsGetCurrentContext();
	[UIView beginAnimations:nil context:context];
	[UIView setAnimationCurve:UIViewAnimationCurveLinear];
	[UIView setAnimationDuration:0.25];
	
	if(effectOpen)
	{
		[UIView animateWithDuration:0.35
									animations:^
									{
										effectView.center = CGPointMake(125, 663);
										effectView.alpha = 1.0;
										chooseEffectButton.transform  = CGAffineTransformMakeRotation(0);
									}

									completion:^(BOOL completed)
									{
										int vc = 0;
										while(effectSubViews[vc])
										{
											[effectSubViews[vc] removeFromSuperview];
											vc++;
										}
									}
		 ];
	}
	else
	{
		int vc = 0;
		while(effectSubViews[vc])
		{
			[effectScrollView addSubview:effectSubViews[vc]];
			vc++;
		}
		
		effectView.center = CGPointMake(125, 300);
		effectView.alpha = 0.7;
		chooseEffectButton.transform  = CGAffineTransformMakeRotation(PI);
	}
	
	[UIView commitAnimations];
	effectOpen = !effectOpen;
}

- (void)someOtherButton:(id)sender
{
	[self setLampButtonOn:false];
	[glView stopRecording:false];
	[glView stopCapture];
	AssetLibraryViewController * controller = [[AssetLibraryViewController alloc] initWithAsset:recentAsset];
	[self presentModalViewController:controller animated:true];
	[controller release];
}

- (void)assetPlayerClosing:(NSNotification*)notification
{
	// remove the asset player and restart the capture
	AssetLibraryViewController * viewer = [notification object];
	[glView startCapture];
}

- (void) playerClosed:(id)sender Asset:(NSURL*)newAsset
{
	[self dismissModalViewControllerAnimated:YES];
	[glView startCapture];
	[self setRecentRecording:[newAsset retain]];
}

- (void)recordButton:(id)sender 
{
	if(glView)
	{
		if([glView isRecording])
		{
			[glView pauseRecording];
			
			[self playStopAlertSound];
			
			// stop the capture while we save
			[glView stopCapture];
			[self setLampButtonOn:false];
			
			// show the saving progress
			float of = [GLViewController getTransformForOrientation:currentOrientation];
			savingAlert.transform = CGAffineTransformMakeRotation(of);
			[savingAlert show:FALSE];
			
			dispatch_async(finalizerq, ^(void)
						   {
								NSString * path = [glView stopRecording:true];
								
								if(path)
								{
										// process the recorded video
										[self processMovieFile:path];
								}
								else
								{
									// something horrible has happened
									[savingAlert hide:FALSE];
								}
							});
		}
		else 
		{
			[self playStartAlertSound];
		}
	}
}

- (void) playStartAlertSound
{	
	// the callback will trigger the actuall start of the recording
    AudioServicesPlaySystemSound (startSoundFileObject);
}

- (void) playStopAlertSound
{	
	// the callback will trigger the actuall start of the recording
    AudioServicesPlaySystemSound (stopSoundFileObject);
}

- (void) getAssestsGroups
{
    if (!assetsLibrary) 
	{
        assetsLibrary = [[ALAssetsLibrary alloc] init];
    }
	
    if (!groups) 
	{
        groups = [[NSMutableArray alloc] init];
    } 
	else 
	{
        [groups removeAllObjects];
    }
    
    ALAssetsLibraryGroupsEnumerationResultsBlock listGroupBlock = ^(ALAssetsGroup *group, BOOL *stop) {
        
        if (group) 
		{
            [groups addObject:group];
        } 
		else 
		{
            // NULL is passed when all groups have been enumerated
			if (groups.count != 0)
			{
				assetsGroup = [groups objectAtIndex:0];
				[self setRecentRecording:NULL];
			}
        }
    };
    
    ALAssetsLibraryAccessFailureBlock failureBlock = ^(NSError *error) 
	{
		// there is no access to assets library
		assetsDenied = true;
		
		UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Havoc Video Requires Location Services" message:@"Go to Settings/General/Location Services to enable Location Services for Havoc Video" delegate:NULL cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease];
		[alert show];
    };
    
    NSUInteger groupTypes = ALAssetsGroupSavedPhotos /*ALAssetsGroupAll*/; // we only want the saved group
    [assetsLibrary enumerateGroupsWithTypes:groupTypes usingBlock:listGroupBlock failureBlock:failureBlock];	
}

- (void) setRecentRecording:(NSURL*)assetPath
{
    if(assetPath)
	{
		if(recentAsset)
		{
			[recentAsset release];
			recentAsset = NULL;
		}
		
		recentAsset = [assetPath retain];
		
		ALAssetsLibraryAssetForURLResultBlock arblock = ^(ALAsset *asset)
		{
			// get the thumbnail from the asset and set it to the image of the recent button
			CGImageRef thumbnail = [asset thumbnail];
			
			// crate masked button image
			CGImageRef buttonimage = thumbnail;
			int iwidth = CGImageGetHeight(buttonimage);
			int iheight = CGImageGetWidth(buttonimage);
			
			// mask with mask (for it to work correctly, the source image must be ARGB)
			CGImageRef maskedimage = [GLViewController maskImage:buttonimage withMask:assetMask];
			
			// composite the button image into outputImage
			UIGraphicsBeginImageContext(CGSizeMake(iwidth, iheight)); 
			/* Put any sort of drawing code here */ 
			[[UIImage imageWithCGImage:maskedimage] drawAtPoint:CGPointZero];
			[[UIImage imageWithCGImage:assetLightingImage] drawInRect:CGRectMake(0, 0, iwidth, iheight)];
			UIImage *outputImage = UIGraphicsGetImageFromCurrentImageContext(); 
			UIGraphicsEndImageContext();

			[someOtherButton setImage:outputImage forState:UIControlStateNormal];
			
			// clean up images
			CGImageRelease(maskedimage);
			
			// make sure the button is visible
			[someOtherButton setHidden:false];
		};
		
		ALAssetsLibraryAccessFailureBlock afblock = ^(NSError *error)
		{
			// the asset was not found
			recentAsset = NULL;
			
			// hide the button for now
			[someOtherButton setHidden:true];
			
			UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Havoc Video Requires Location Services" message:@"Go to Settings/General/Location Services to enable Location Services for Havoc Video" delegate:NULL cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease];
			[alert show];
		};
		
		[assetsLibrary assetForURL:recentAsset resultBlock:arblock failureBlock:afblock];
	}
	else
	{
		if(assetsGroup)
		{
			// enumerate the existing assets and get the most recent recording
			if (!assets) 
			{
				assets = [[NSMutableArray alloc] init];
			} 
			else 
			{
				[assets removeAllObjects];
			}
			
			ALAssetsGroupEnumerationResultsBlock assetsEnumerationBlock = ^(ALAsset *result, NSUInteger index, BOOL *stop) 
			{
				
				if (result) 
				{
					[assets addObject:result];
				}
				else
				{
					// ignore if there are no videos available
					if(assets.count)
					{
						// that is the last of the movies
						// set the most recent from the last one in the assets array
						ALAsset * ra = [assets objectAtIndex:(assets.count - 1)];
						
						// we want the default representations URL
						ALAssetRepresentation * dr = [ra defaultRepresentation];
						[self setRecentRecording:[dr url]];
					}
					else
					{
						// there are no video, so hide the button
						[someOtherButton setHidden:true];
					}
				}
			};
			
			ALAssetsFilter *onlyPhotosFilter = [ALAssetsFilter allVideos];
			[assetsGroup setAssetsFilter:onlyPhotosFilter];
			[assetsGroup enumerateAssetsUsingBlock:assetsEnumerationBlock];
		}
		else
		{
			// we have no access to the assets library
			int br = 0;
		}
	}
}

- (void)snapShotAnimationComplete:(NSURL*)url
{
	[self setRecentRecording:url];
}

- (void) processMovieFile:(NSString *) moviePath
{
	NSURL *urlPath = [[NSURL alloc] initFileURLWithPath:moviePath];
	ALAssetsLibrary * library = [[ALAssetsLibrary alloc] init];
	
	if([library videoAtPathIsCompatibleWithSavedPhotosAlbum:urlPath])
	{
		[library writeVideoAtPathToSavedPhotosAlbum:urlPath completionBlock:^(NSURL *assetURL, NSError *error)
		 {
			 if(error)
			 {
				 NSLog(@"Error moving video to camera roll");
			 }
			 else
			 {
				 // animate the last frame to the last rec button
				 UIImage * image = [glView getLastImage];
				 if(image)
				 {
					 SnapshotView * snap = [[SnapshotView alloc] initWithImage:image];
					 [image release];
					 
					 [snap presentWithSuperview:self.view 
									  StartSize:CGRectMake(0, 0, 320, 426) 
									 StartPoint:CGPointMake(160, 213) 
									   EndSize:CGRectMake(0, 0, 48, 48)
									   //EndPoint:CGPointMake(28, 454)
									   EndPoint:someOtherButton.center
									  CallbackTarget:self
									   AssetURL:assetURL];
				 }
			 }
			 
			 // restart the capture
			 [glView startCapture];
			 
			 [savingAlert hide:FALSE];
		 }];
	}
	else
	{
		NSLog(@"Error moving video to camera roll");
	}
}

+(float)getTransformForOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	
	switch (interfaceOrientation) 
	{
		case UIInterfaceOrientationPortrait:
			return 0;			// 0 in radians
			break;
		case UIInterfaceOrientationPortraitUpsideDown:
			return 3.1415927;	// 180 in radians
			break;
		case UIInterfaceOrientationLandscapeLeft:
			return -1.5707964;	// -90 in radians
			break;
		case UIInterfaceOrientationLandscapeRight:
			return 1.5707964;	// 90 in radians
			break;
		default:
			return 0;
			break;
	}
}

+(CGImageRef) maskImage:(CGImageRef)image withMask:(CGImageRef)mask  
{	
	CGImageRef masked = CGImageCreateWithMask(image, mask);
	return masked;
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

- (void)dealloc 
{
    [super dealloc];

	[glView release];
	
	if(savingAlert)
	{
		[savingAlert release];
	}
}


@end
