//
//  EffectChooser.m
//  Havoc Video
//
//  Created by Richard Insley on 9/7/10.
//  Copyright 2010 WildWestWare. All rights reserved.
//

#import "EffectChooser.h"

@implementation EffectChooser

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // Custom initialization
    }
    return self;
}
*/

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad 
{
    [super viewDidLoad];
	
	// attach the image to the menu bar
	UIColor * backcolor = [[UIColor alloc] initWithPatternImage:[UIImage imageNamed:@"menubar.png"]];
	menuBar.backgroundColor = backcolor;
	[backcolor release];
}

-(void)initScripts:(EffectScript**)scripts ScriptCallback:(id <ChangeScriptProtocol>)callback Orientation:(UIInterfaceOrientation)orientation
{
	// check the view is not null.  This access will cause the view to be loaded if it's not already
	if(self.view)
	{
		currentOrientation = orientation;
		_scripts = scripts;
		_callback = callback;
		
		// get the count
		scriptCount = 0;
		while(scripts[scriptCount])
		{
			scriptCount ++;
		}
		
		int kNumberOfPages = (int)ceil((float)scriptCount / 6.0);
		pageControl.numberOfPages = kNumberOfPages;
		
		// create button views
		scrollView.pagingEnabled = YES;
		scrollView.contentSize = CGSizeMake(scrollView.frame.size.width * kNumberOfPages, scrollView.frame.size.height);
		scrollView.showsHorizontalScrollIndicator = NO;
		scrollView.showsVerticalScrollIndicator = NO;
		scrollView.scrollsToTop = NO;
		scrollView.delegate = self;
		
		/*
		// load mask image into maskImage and create mask in mask
		CGImageRef maskImage = [UIImage imageWithContentsOfFile:[EffectButtonPanel getPathForImageFile:"effectButtonMask"]].CGImage;
		CGImageRef lightingImage = [UIImage imageWithContentsOfFile:[EffectButtonPanel getPathForImageFile:"effectButtonLighting"]].CGImage;
		CGImageRef mask = CGImageMaskCreate(CGImageGetWidth(maskImage),
											CGImageGetHeight(maskImage),
											CGImageGetBitsPerComponent(maskImage),
											CGImageGetBitsPerPixel(maskImage),
											CGImageGetBytesPerRow(maskImage),
											CGImageGetDataProvider(maskImage), NULL, false);
		
		 */
		
		int count = 0;
		
		for(int i = 0; i < kNumberOfPages; i++)
		{
			for(int y = 0; y < 4; y++)
			{
				if(y == 0 || y == 3)
				{
					for(int x = 0; x < 3; x++)
					{
						if(_scripts[count] == NULL)
						{
							break;
						}
						
						const char * effectname = _scripts[count]->getGlobalString("EFFECTNAME");
						const char * buttomImageName = _scripts[count]->getGlobalString("BUTTONIMAGE");
						
						EffectButtonPanel * bp = [[EffectButtonPanel alloc] 
												  initWithFrame:CGRectMake(0, 0, 100, 100) 
												  Caption:[NSString stringWithCString:effectname encoding:NSUTF8StringEncoding]
												  Image:buttomImageName
												  Index:count 
												  IsActive:false
												  ScriptCallback:_callback];
						
						
						bp.center = CGPointMake(62 + (i * scrollView.frame.size.width) + x * 100, 52 + y * 100);
						float of = [EffectChooser getTransformForOrientation:currentOrientation];
						bp.transform = CGAffineTransformMakeRotation(of);

						[scrollView addSubview:bp];
						
						panels[count] = bp;
						
						count++;
					}
				}
			}
		}
		
		// CGImageRelease(mask);
		
		NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
		[notificationCenter addObserver:self selector:@selector(orientationChange:) name:@"orientationChange" object:nil];
	}
}



-(void)orientationChange:(NSNotification*)notification
{
	// the CMSampleBufferRef will be wrapped in an NSValue handed over by the output callback
	NSNumber * val = [notification object];
	UIInterfaceOrientation newOrientation = (UIInterfaceOrientation)val.intValue;
	if(newOrientation != currentOrientation)
	{
		float newf = [EffectChooser getTransformForOrientation:newOrientation];
		CGAffineTransform newt = CGAffineTransformMakeRotation(newf);
		
		CGContextRef context = UIGraphicsGetCurrentContext();
		[UIView beginAnimations:nil context:context];
		[UIView setAnimationCurve:UIViewAnimationCurveLinear];
		[UIView setAnimationDuration:0.25];
		
		for(int i = 0; i < scriptCount; i++)
		{
			panels[i].transform = newt;
		}
		
		[UIView commitAnimations];
	}
	
	currentOrientation = newOrientation;
}

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
    [super dealloc];
	
	// release the button panels
	for(int i = 0; i < scriptCount; i++)
	{
		[panels[i] release];
		panels[i] = 0;
	}
}

// Add this view to superview, and slide it in from the bottom
- (void)presentWithSuperview:(UIView *)superview 
{
    // Set initial location at bottom of superview
    CGRect frame = self.view.frame;
    frame.origin = CGPointMake(0.0, superview.bounds.size.height);
    self.view.frame = frame;
    [superview addSubview:self.view];            
	
    // Animate to new location
    [UIView beginAnimations:@"presentWithSuperview" context:nil];
    frame.origin = CGPointZero;
    self.view.frame = frame;
    [UIView commitAnimations];
}

// Method called when removeFromSuperviewWithAnimation's animation completes
- (void)animationDidStop:(NSString *)animationID
                finished:(NSNumber *)finished
                 context:(void *)context {
    if ([animationID isEqualToString:@"removeFromSuperviewWithAnimation"]) {
        [self.view removeFromSuperview];
    }
}

// Slide this view to bottom of superview, then remove from superview
- (void)removeFromSuperviewWithAnimation {
    [UIView beginAnimations:@"removeFromSuperviewWithAnimation" context:nil];
	
    // Set delegate and selector to remove from superview when animation completes
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
	
    // Move this view to bottom of superview
    CGRect frame = self.view.frame;
    frame.origin = CGPointMake(0.0, self.view.superview.bounds.size.height);
    self.view.frame = frame;
	
    [UIView commitAnimations];    
}

// ScrollView delegates
- (void)scrollViewDidScroll:(UIScrollView *)sender 
{
    // We don't want a "feedback loop" between the UIPageControl and the scroll delegate in
    // which a scroll event generated from the user hitting the page control triggers updates from
    // the delegate method. We use a boolean to disable the delegate logic when the page control is used.
    if (pageControlUsed) 
	{
        // do nothing - the scroll was initiated from the page control, not the user dragging
        return;
    }
	
    // Switch the indicator when more than 50% of the previous/next page is visible
    CGFloat pageWidth = scrollView.frame.size.width;
    int page = floor((scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    pageControl.currentPage = page;
	
	/*
    // load the visible page and the page on either side of it (to avoid flashes when the user starts scrolling)
    [self loadScrollViewWithPage:page - 1];
    [self loadScrollViewWithPage:page];
    [self loadScrollViewWithPage:page + 1];
	*/
	
    // A possible optimization would be to unload the views+controllers which are no longer visible
}

// At the begin of scroll dragging, reset the boolean used when scrolls originate from the UIPageControl
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView 
{
    pageControlUsed = NO;
}

// At the end of scroll animation, reset the boolean used when scrolls originate from the UIPageControl
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView 
{
    pageControlUsed = NO;
}

- (IBAction)changePage:(id)sender
{
    int page = pageControl.currentPage;
	
	/*
    // load the visible page and the page on either side of it (to avoid flashes when the user starts scrolling)
    [self loadScrollViewWithPage:page - 1];
    [self loadScrollViewWithPage:page];
    [self loadScrollViewWithPage:page + 1];
    */
	
	// update the scroll view to the appropriate page
    CGRect frame = scrollView.frame;
    frame.origin.x = frame.size.width * page;
    frame.origin.y = 0;
    [scrollView scrollRectToVisible:frame animated:YES];
    
	// Set the boolean used when scrolls originate from the UIPageControl. See scrollViewDidScroll: above.
    pageControlUsed = YES;
}

- (IBAction)goBack:(id)sender
{
	[self removeFromSuperviewWithAnimation];
}
@end
