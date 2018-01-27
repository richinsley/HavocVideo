//
//  FaceBookUploaderViewController.m
//  Havoc Video
//
//  Created by Richard Insley on 9/22/10.
//  Copyright 2010 WildWestWare. All rights reserved.
//

#import "FaceBookUploaderViewController.h"

@implementation FaceBookUploaderViewController

- (id)initWithAsset:(NSURL*) asset HasWifi:(bool)haswifi
{
	if (self = [super init]) 
	{
        // Custom initialization
		currentAsset = asset;
		_hasWifi = haswifi;
    }
    return self;
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad 
{	
    [super viewDidLoad];
	
	self.title = @"Facebook";
	
	// add a post button
	anotherButton = [[[UIBarButtonItem alloc] initWithTitle:@"Post" style:UIBarButtonItemStylePlain target:self action:@selector(postButton:)] retain];          
	self.navigationItem.rightBarButtonItem = anotherButton;
	anotherButton.tag = 0;
	
	ALAssetsLibraryAssetForURLResultBlock arblock = ^(ALAsset *asset)
	{
		// get the thumbnail from the asset and set it to the image of the recent button
		CGImageRef thumbnail = [asset thumbnail];
		[image setImage:[UIImage imageWithCGImage:thumbnail]];
		
		// we want the default representations URL
		dr = [[asset defaultRepresentation] retain];
		_duration = [[asset valueForProperty:@"ALAssetPropertyDuration"] doubleValue];
		dataSize = [dr size];
		
		double dur = _duration;
		if (dur < 60)
		{
			durationLabel.text = [NSString stringWithFormat:@"00:%02d", (int)dur];
		}
		else
		{
			int secs = (int)dur % 60;
			int min = (int)(dur / 60);
			durationLabel.text = [NSString stringWithFormat:@"Video Length: %d:%02d", min, secs];
		}

		sizeLabel.text = [NSString stringWithFormat:@"Video Size: %@", [FaceBookUploaderViewController stringFromFileSize:dataSize]];
	};
	
	ALAssetsLibraryAccessFailureBlock afblock = ^(NSError *error)
	{
		// we just wont have a thumbnail for this oddity
		int br = 0;
	};
	
	assetsLibrary = [[ALAssetsLibrary alloc] init];
	[assetsLibrary assetForURL:currentAsset resultBlock:arblock failureBlock:afblock];
	
	isEditing = false;
	[titletf setDelegate:self];
	[descriptiontf setDelegate:self];
	
	uploader = [[FaceBookUploader alloc] initWithAsset:dr Delegate:self];
	uploader.throttleSize = _hasWifi ? -1 : 255;
}

-(void)viewWillDisappear:(BOOL)animated
{
	// set the current upload to happen in the background
	if(uploader.currentState == FUSUploading)
	{
		[uploader popDelegate];
		NSMutableArray * uploads = [FaceBookUploader getUploads];
		[uploads addObject:uploader];
	}
}

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField 
{
	// allow the keyboard to close
	[textField resignFirstResponder];
	return YES;
}

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
    [super dealloc];
	
	if(assetsLibrary)
	{
		[assetsLibrary release];
		assetsLibrary = NULL;
	}
	
	if(dr)
	{
		[dr release];
		dr = NULL;
	}
	
	[anotherButton release];
	anotherButton = NULL;
}

- (void) cancelButton:(id)sender
{
	[self dismissModalViewControllerAnimated:YES];
}

-(void)FaceBookUploaderProgress:(float)progressValue
{
	[progress setProgress:progressValue];
}

-(void)FaceBookUploaderComplete
{
	[self.navigationController popViewControllerAnimated:true];
}

-(void)FaceBookUploaderError:(NSString*)reason FacebookUploadState:(FacebookUploadState)state
{
	UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Error Sharing to Facebook" message:reason delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease];
	[alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	[self.navigationController popViewControllerAnimated:true];
}

- (void) editButton:(id)sender
{
	// show the spinny thing and copy the file to local storage
	spinnyThing.hidden = false;
	[spinnyThing startAnimating];
	self.view.userInteractionEnabled = FALSE;
	
	dispatch_queue_t moveq = dispatch_queue_create("moveq", NULL);
	dispatch_async(moveq, ^(void)
				   {
					   // copy the asset to a temp file
					   uint8_t* buffer = (uint8_t*)malloc(16000);
					   pretrimtemp = [[NSTemporaryDirectory() stringByAppendingPathComponent: [NSString stringWithFormat: @"%.0f.%@", [NSDate timeIntervalSinceReferenceDate] * 1000.0, @"mov"]] retain];
					   // create empty file
					   [@"" writeToFile:pretrimtemp atomically:NO];
					   NSFileHandle* outf = [NSFileHandle fileHandleForWritingAtPath:pretrimtemp];
					   
					   NSError* err = NULL;
					   int br = 0;
					   br = [dr getBytes:buffer fromOffset:0 length:16000 error:&err];
					   int rp = br;
					   while(br)
					   {
						   NSData * db = [NSData dataWithBytes:buffer length:br];
						   [outf writeData:db];
						   br = [dr getBytes:buffer fromOffset:rp length:16000 error:&err];
						   rp += br;
						   if(err)
						   {
							   break;
						   }
					   }
					   [outf closeFile];
					   free(buffer);
					   
					   dispatch_async(dispatch_get_main_queue(), ^(void)
									  {
										  [spinnyThing stopAnimating];
										  spinnyThing.hidden = true;
										  self.view.userInteractionEnabled = TRUE;
										  
										  // show the edit dialog
										  UIVideoEditorController* vec = [[UIVideoEditorController alloc] init];
										  vec.videoMaximumDuration = (NSTimeInterval)uploader.maxlength;
										  vec.videoPath = pretrimtemp;
										  vec.delegate = (id)self;
										  [self presentModalViewController:vec animated:true];
										  dispatch_release(moveq);
									  });
				   });
}

- (void) postButton:(id)sender
{	
	if((int)_duration > uploader.maxlength)
	{
		// ask user if they want to trim the video to fit into the aloted time for facebook
		[self editButton:self];
		
	}
	else
	{
		[self lockInterface];
		[uploader uploadWithTitle:titletf.text Description:descriptiontf.text];
	}
}

-(void) lockInterface
{
	// set the UI in upload mode
	trimButton.hidden = TRUE;
	titletf.enabled = FALSE;
	descriptiontf.enabled = FALSE;
	self.navigationItem.rightBarButtonItem = NULL;
	[progress setProgress:0];
	[progress setHidden:false];
}

- (void)videoEditorController:(UIVideoEditorController *)editor didSaveEditedVideoToPath:(NSString *)editedVideoPath
{
	// delete the pre trim temp file
	NSFileManager * def = [NSFileManager defaultManager];
	[def removeItemAtPath:pretrimtemp error:NULL];
	
	// update the size and duration label
	sizeLabel.text = [NSString stringWithFormat:@"Video Size: %@", [FaceBookUploaderViewController stringFromFileSize:[[def attributesOfItemAtPath:editedVideoPath error:NULL] fileSize]]];
	 
	[self lockInterface];
	[uploader uploadWithPath:editedVideoPath Title:titletf.text Description:descriptiontf.text];
	
	[self dismissModalViewControllerAnimated:true];
}

- (void)videoEditorControllerDidCancel:(UIVideoEditorController *)editor
{
	// delete the pre trim temp file
	NSFileManager * def = [NSFileManager defaultManager];
	[def removeItemAtPath:pretrimtemp error:NULL];
	
	[self dismissModalViewControllerAnimated:true];
}

+ (NSString *)stringFromFileSize:(int)theSize {
	float floatSize = theSize;
	if (theSize<1023)
		return([NSString stringWithFormat:@"%i bytes",theSize]);
	floatSize = floatSize / 1024;
	if (floatSize<1023)
		return([NSString stringWithFormat:@"%1.1f KB",floatSize]);
	floatSize = floatSize / 1024;
	if (floatSize<1023)
		return([NSString stringWithFormat:@"%1.1f MB",floatSize]);
	floatSize = floatSize / 1024;
	
	return([NSString stringWithFormat:@"%1.1f GB",floatSize]);
}

- (void) startEdit:(id)sender
{

}

- (void) endEdit:(id)sender
{
	
}

@end
