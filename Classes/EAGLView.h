//
//  EAGLView.h
//  VideoTexture
//
//  Created by Richard Insley on 8/17/10.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <MediaPlayer/MediaPlayer.h>
#import <AssetsLibrary/AssetsLibrary.h>

#import "EditViewController.h"
#import "EffectScript.h"

#import "ES2Renderer.h"

// This class wraps the CAEAGLLayer from CoreAnimation into a convenient UIView subclass.
// The view content is basically an EAGL surface you render your OpenGL scene into.
// Note that setting the view non-opaque will only work if the EAGL surface has an alpha channel.
@interface EAGLView : UIView
{    
@private
	IBOutlet UIButton *recordButton;
	IBOutlet UIButton *effectButton;
	IBOutlet UIViewController * parentController;
	IBOutlet UILabel *effectLabel;
	IBOutlet UIScrollView *effectScrollView;
	IBOutlet UILabel *timeLabel;
	
    //id <ES2Renderer> renderer;
	ES2Renderer * renderer;
	
    BOOL animating;
    BOOL displayLinkSupported;
    NSInteger animationFrameInterval;
    // Use of the CADisplayLink class is the preferred method for controlling your animation timing.
    // CADisplayLink will link to the main display and fire every vsync when added to a given run-loop.
    // The NSTimer class is used only as fallback when running on a pre 3.1 device where CADisplayLink
    // isn't available.
    id displayLink;
    NSTimer *animationTimer;
	
	// Playback
	MPMoviePlayerController *moviePlayer;
	
	// current orientation
	UIInterfaceOrientation orientation;
	
	// the most recent snapshot of a recording
	UIImage *lastFrameImage;
	
	NSTimer* recBlinkTimer;
}

@property (readonly, nonatomic, getter=isAnimating) BOOL animating;
@property (nonatomic) NSInteger animationFrameInterval;
@property (readwrite) UIInterfaceOrientation orientation;
@property (readwrite, retain) MPMoviePlayerController *moviePlayer;

- (void)startAnimation;
- (void)stopAnimation;
- (void)drawView:(id)sender;
- (void)frameNeedsProcessing:(NSNotification*)notification;
- (void)audioNeedsProcessing:(NSNotification*)notification;
- (void)effectChanged:(NSNotification*)notification;

- (void)startCapture;
- (void)stopCapture;

- (NSString *)stopRecording:(bool)snapshot;
- (void)startRecording;
- (bool)isRecording;

- (EffectScript**)getScripts;
- (id)getRenderer;

- (void)videoEditorController:(UIVideoEditorController *)editor didSaveEditedVideoToPath:(NSString *)editedVideoPath;

- (void)recordButton:(id)sender;
- (void)effectButton:(id)sender;

// caled by the record timer blink thingy
- (void)blinkRecord:(NSTimer*)theTimer;

- (UIImage *)getLastImage;
@end
