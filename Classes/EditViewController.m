    //
//  EditViewController.m
//  VideoTexture
//
//  Created by Richard Insley on 8/28/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "EditViewController.h"


@implementation EditViewController
@synthesize vpath;

-(id)initWithFile:(NSString*)filePath
{
	if ((self = [super init]))
    {
		vec = NULL;
		self.vpath = filePath;
	}
	
	return self;
}

// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView 
{
	if (![UIVideoEditorController canEditVideoAtPath:self.vpath])
	{
		self.title = @"Cannot Edit Video";
		printf("Cannot edit vid at path\n");
		return;
	}
	
	vec = [[UIVideoEditorController alloc] init];
	vec.videoPath = self.vpath;
	vec.delegate = self;
	self.view = vec.view;
	[super loadView];
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad 
{
    [super viewDidLoad];
}

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning 
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload 
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc 
{
	if(vec)
	{
		[vec release];
		vec = NULL;
	}
	
    [super dealloc];
}

- (void)videoEditorController:(UIVideoEditorController *)editor didSaveEditedVideoToPath:(NSString *)editedVideoPath
{
	CFShow(editedVideoPath);
	
	// can do save here. the data has *not* yet been saved to the photo album
	
	[self dismissModalViewControllerAnimated:YES];
	[editor release];
	
	// ensure the video capture restarts
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	[notificationCenter postNotificationName:@"restartCapture" object:self];
}

- (void)videoEditorControllerDidCancel:(UIVideoEditorController *)editor
{
	[self dismissModalViewControllerAnimated:YES];
	[editor release];
	
	// ensure the video capture restarts
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	[notificationCenter postNotificationName:@"restartCapture" object:self];
}

- (void)videoEditorController:(UIVideoEditorController *)editor didFailWithError:(NSError *)error
{
	[self dismissModalViewControllerAnimated:YES];
	[editor release];
	
	// ensure the video capture restarts
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	[notificationCenter postNotificationName:@"restartCapture" object:nil];
	
	NSLog(@"Fail! %@", [error localizedDescription]);
}

- (void) doEdit
{
	[self presentModalViewController:vec animated:YES];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
	// recover video URL
	NSURL *url = [info objectForKey:UIImagePickerControllerMediaURL];
	[self dismissModalViewControllerAnimated:YES];
	[picker release];
	
	CFShow([url path]);	
	self.vpath = [url path];
	//self.navigationItem.rightBarButtonItem = BARBUTTON(@"Edit", @selector(doEdit));
}

- (void) pickVideo: (id) sender
{
	UIImagePickerController *ipc = [[UIImagePickerController alloc] init];
	ipc.sourceType =  UIImagePickerControllerSourceTypePhotoLibrary;
	ipc.delegate = self;
	ipc.allowsEditing = NO;
	ipc.videoQuality = UIImagePickerControllerQualityTypeMedium;
	ipc.videoMaximumDuration = 30.0f; // 30 seconds
	ipc.mediaTypes = [NSArray arrayWithObject:@"public.movie"];
	[self presentModalViewController:ipc animated:YES];	
}

- (BOOL) videoRecordingAvailable
{
	if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) return NO;
	return [[UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeCamera] containsObject:@"public.movie"];
}


@end
