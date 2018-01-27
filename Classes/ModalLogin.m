//
//  ModalLogin.m
//  SteelMagnolia
//
//  Created by Nathan Walker on 9/21/10.
//  Copyright 2010 Vision Worx Productions. All rights reserved.
//

#import "ModalLogin.h"

#define TEXT_FIELD_TAG	9999
#define TEXT_PW_FIELD_TAG	10000

@interface ModalLoginDelegate : NSObject <UIAlertViewDelegate, UITextFieldDelegate> 
{
	CFRunLoopRef currentLoop;
	NSMutableDictionary *loginDetails;
	NSUInteger index;
}
@property (assign) NSUInteger index;
@property (retain) NSMutableDictionary *loginDetails;
@end

@implementation ModalLoginDelegate
@synthesize index;
@synthesize loginDetails;

-(id) initWithRunLoop: (CFRunLoopRef)runLoop 
{
	if (self = [super init]) currentLoop = runLoop;
	return self;
}

// User pressed button. Retrieve results
-(void)alertView:(UIAlertView*)aView clickedButtonAtIndex:(NSInteger)anIndex 
{
	UITextField *username_tf = (UITextField *)[aView viewWithTag:TEXT_FIELD_TAG];
	UITextField *password_tf = (UITextField *)[aView viewWithTag:TEXT_PW_FIELD_TAG];
	self.loginDetails = [[NSMutableDictionary alloc] init];
	if (![username_tf.text isEqualToString:@""] && ![password_tf.text isEqualToString:@""]) 
	{
		[self.loginDetails setObject:username_tf.text forKey:@"username"];
		[self.loginDetails setObject:password_tf.text forKey:@"password"];
	}
	self.index = anIndex;
	CFRunLoopStop(currentLoop);
}

- (BOOL) isLandscape
{
	return ([UIDevice currentDevice].orientation == UIDeviceOrientationLandscapeLeft) || ([UIDevice currentDevice].orientation == UIDeviceOrientationLandscapeRight);
}

// Move alert into place to allow keyboard to appear
- (void) moveLoginDialog: (UIAlertView *) alertView
{
	CGContextRef context = UIGraphicsGetCurrentContext();
	[UIView beginAnimations:nil context:context];
	//[UIView setAnimationCurve:UIViewAnimationTransitionNone];
	[UIView setAnimationDuration:0.25f];
	if (![self isLandscape])
		alertView.center = CGPointMake(160.0f, 40.0f);
	else 
		alertView.center = CGPointMake(240.0f, 40.0f);
	[UIView commitAnimations];
	
	[[alertView viewWithTag:TEXT_FIELD_TAG] becomeFirstResponder];
}

- (void) dealloc
{
	self.loginDetails = nil;
	[super dealloc];
}

@end

@implementation ModalLogin

+(NSMutableDictionary *) loginQueryWith: (NSString *)question prompt: (NSString *)prompt button1: (NSString *)button1 button2:(NSString *) button2
{
	// Create alert
	CFRunLoopRef currentLoop = CFRunLoopGetCurrent();
	ModalLoginDelegate *madelegate = [[ModalLoginDelegate alloc] initWithRunLoop:currentLoop];
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:question message:@"\n\n\n" delegate:madelegate cancelButtonTitle:button1 otherButtonTitles:button2, nil];
	
	// Build text field
	UITextField *tf = [[UITextField alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 260.0f, 30.0f)];
	tf.borderStyle = UITextBorderStyleRoundedRect;
	tf.tag = TEXT_FIELD_TAG;
	tf.placeholder = prompt;
	tf.clearButtonMode = UITextFieldViewModeWhileEditing;
	tf.keyboardType = UIKeyboardTypeAlphabet;
	tf.keyboardAppearance = UIKeyboardAppearanceAlert;
	tf.autocapitalizationType = UITextAutocapitalizationTypeNone;
	tf.autocorrectionType = UITextAutocorrectionTypeNo;
	tf.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
	
	UITextField *pwtf = [[UITextField alloc] initWithFrame:CGRectMake(0.0f, 34.0f, 260.0f, 30.0f)];
	pwtf.borderStyle = UITextBorderStyleRoundedRect;
	pwtf.tag = TEXT_PW_FIELD_TAG;
	pwtf.placeholder = @"password";
	pwtf.clearButtonMode = UITextFieldViewModeWhileEditing;
	pwtf.keyboardType = UIKeyboardTypeAlphabet;
	pwtf.keyboardAppearance = UIKeyboardAppearanceAlert;
	pwtf.autocapitalizationType = UITextAutocapitalizationTypeNone;
	pwtf.autocorrectionType = UITextAutocorrectionTypeNo;
	pwtf.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
	pwtf.secureTextEntry = YES;
	
	// Show alert and wait for it to finish displaying
	[alertView show];
	while (CGRectEqualToRect(alertView.bounds, CGRectZero));
	
	// Find the center for the text field and add it
	CGRect bounds = alertView.bounds;
	tf.center = CGPointMake(bounds.size.width / 2.0f, bounds.size.height / 2.0f - 25.0f);
	pwtf.center = CGPointMake(bounds.size.width / 2.0f, bounds.size.height / 2.0f + 9.0f);
	[alertView addSubview:tf];
	[alertView addSubview:pwtf];
	[tf release];
	[pwtf release];
	
	// Set the field to first responder and move it into place
	[madelegate performSelector:@selector(moveLoginDialog:) withObject:alertView afterDelay: 0.7f];
	
	// Start the run loop
	CFRunLoopRun();
	
	// Retrieve the user choices
	NSUInteger index = madelegate.index;
	NSMutableDictionary *answer = [[madelegate.loginDetails copy] autorelease];
	if (index == 0) answer = nil; // assumes cancel in position 0
	
	[alertView release];
	[madelegate release];
	return answer;
}

+ (NSMutableDictionary *) askLoginOrCancel: (NSString *) question withTextPrompt: (NSString *) prompt
{
	return [ModalLogin loginQueryWith:question prompt:prompt button1:@"Cancel" button2:@"Login"];
}

@end
