//
//  FaceBookUploader.m
//  Havoc Video
//
//  Created by Richard Insley on 10/1/10.
//  Copyright 2010 WildWestWare. All rights reserved.
//

#import "FaceBookUploader.h"

static NSString* kApiKey = @"2470201bebd55eaaaa910283edf4078e";
static NSString* kApiSecret = @"1d34e98bafb15d2d7edea5a0efb20a3e";
static NSMutableArray * uploads;
static FBSession * _session = NULL;
static int _maxl = 0;
static int _maxs = 0;

@implementation FaceBookUploader
@synthesize currentState;
@synthesize maxlength;
@synthesize throttleSize;

- (id)initWithAsset:(ALAssetRepresentation*) asset Delegate:(id)facebookDelegate
{
	if (self = [super init]) 
	{
		throttleSize = -1;
		tempFile = NULL;
		fbdelegate = facebookDelegate;
		maxlength = _maxl;
		maxsize = _maxs;
		
        // Custom initialization
		dr = [asset retain];
		dataSize = [dr size];
		
		if(!_session)
		{
			_session = [[FBSession sessionForApplication:kApiKey secret:kApiSecret delegate:self] retain];
#if DEBUG
			//[_session logout];
#endif
			if(![_session resume])
			{
				// the session needs to be re-done
				FBLoginDialog * _loginDialog = [[FBLoginDialog alloc] init];
				[_loginDialog show];
			}
			else
			{
				currentState = FUSPendingSend;
			}
		}
	}
    return self;
}

-(void)uploadWithPath:(NSString*)path Title:(NSString*)title Description:(NSString*)desc
{
	if ([UIDevice currentDevice].multitaskingSupported) 
	{
		UIApplication*    app = [UIApplication sharedApplication];
		
		bgTask = [app beginBackgroundTaskWithExpirationHandler:^
				  {
					  NSLog(@"Upload quit");
					  [app endBackgroundTask:bgTask];
					  bgTask = UIBackgroundTaskInvalid;
					  
					  if([self isBackground])
					  {
						  [uploads removeObject:self];
						  [self release];
					  }
				  }];
		
		NSMutableDictionary *args = [[[NSMutableDictionary alloc] init] autorelease]; 
		[args setObject:title forKey:@"title"];
		[args setObject:desc forKey:@"description"]; 
		[args setObject:path forKey:@"video"]; // file stream
		
		tempFile = [path retain];
		
		FBRequest *videoUpload = [[FBRequest requestWithDelegate:self] retain];
		videoUpload.throttleSize = throttleSize;
		[videoUpload call:@"facebook.video.upload" params:args];
		
		currentState = FUSUploading;
	}
	else
	{
		NSMutableDictionary *args = [[[NSMutableDictionary alloc] init] autorelease]; 
		[args setObject:title forKey:@"title"];
		[args setObject:desc forKey:@"description"]; 
		[args setObject:path forKey:@"video"]; // file stream
		
		FBRequest *videoUpload = [FBRequest requestWithDelegate:self]; 
		videoUpload.throttleSize = throttleSize;
		[videoUpload call:@"facebook.video.upload" params:args];
		
		currentState = FUSUploading;
	}
}

-(void)uploadWithTitle:(NSString*)title Description:(NSString*)desc
{	
	if ([UIDevice currentDevice].multitaskingSupported) 
	{
		UIApplication*    app = [UIApplication sharedApplication];
		
		bgTask = [app beginBackgroundTaskWithExpirationHandler:^
		{
			NSLog(@"Upload quit");
			[app endBackgroundTask:bgTask];
			bgTask = UIBackgroundTaskInvalid;
			
			if([self isBackground])
			{
				[uploads removeObject:self];
				[self release];
			}
		}];
		
		NSMutableDictionary *args = [[[NSMutableDictionary alloc] init] autorelease]; 
		[args setObject:title forKey:@"title"];
		[args setObject:desc forKey:@"description"]; 
		//[args setObject:@"/var/mobile/Applications/92BA7434-64D7-4829-983F-8A6C68E702BF/Documents/movie.mov" forKey:@"video"]; // file stream
		[args setObject:dr forKey:@"video"]; // Asset stream
		
		FBRequest *videoUpload = [[FBRequest requestWithDelegate:self] retain];
		videoUpload.throttleSize = throttleSize;
		[videoUpload call:@"facebook.video.upload" params:args];
		
		currentState = FUSUploading;
	}
	else
	{
		NSMutableDictionary *args = [[[NSMutableDictionary alloc] init] autorelease]; 
		[args setObject:title forKey:@"title"];
		[args setObject:desc forKey:@"description"]; 
		//[args setObject:@"/var/mobile/Applications/92BA7434-64D7-4829-983F-8A6C68E702BF/Documents/movie.mov" forKey:@"video"]; // file stream
		[args setObject:dr forKey:@"video"]; // Asset stream
		
		FBRequest *videoUpload = [FBRequest requestWithDelegate:self];
		videoUpload.throttleSize = throttleSize;
		[videoUpload call:@"facebook.video.upload" params:args];
		
		currentState = FUSUploading;
	}
}

+(NSMutableArray*)getUploads
{
	if(!uploads)
	{
		uploads = [[[NSMutableArray alloc] init] retain];
	}
	
	return uploads;
}

-(bool)isBackground
{
	if(!uploads) return false;
	
	for(int i = 0; i < uploads.count; i++)
	{
		if([uploads objectAtIndex:i] == self)
		{
			return true;
		}
	}
	
	return false;
}

-(void)popDelegate
{
	fbdelegate = NULL;
}

/**
 * Called when a user has successfully logged in and begun a session.
 */
- (void)session:(FBSession*)session didLogin:(FBUID)uid
{
	FBRequest *sizerequest = [FBRequest requestWithDelegate:self]; 
    [sizerequest call:@"video.getUploadLimits" params:NULL];
	
	FBPermissionDialog* dialog = [[[FBPermissionDialog alloc] init] autorelease];
	dialog.delegate = self;
	dialog.permission = @"publish_stream , user_videos";  // we must have access to publish and retreive vieo information
	[dialog show];
}

/**
 * Called when a user closes the login dialog without logging in.
 */
- (void)sessionDidNotLogin:(FBSession*)session
{
	// if we are here, the user did not log in
	currentState = FUSUserDenied;
	[self error:@"User canceled login"];
	_session = NULL;
}

- (void)dialogDidSucceed:(FBDialog*)dialog 
{
	// if we are here, the user logged in and agreed to the required permissions
	currentState = FUSPendingSend;
	
	FBRequest *sizerequest = [FBRequest requestWithDelegate:self]; 
    [sizerequest call:@"video.getUploadLimits" params:NULL];
}

- (void)dialogDidCancel:(FBDialog*)dialog 
{
	// if we are here, the user logged in, but did not agree to the required permissions
	currentState = FUSUserDenied;
	[self error:@"User denied stream access"];
	_session = NULL;
}

-(void)uploadComplete
{
	currentState = FUSComplete;
	
	UIApplication* app = [UIApplication sharedApplication];
	[app endBackgroundTask:bgTask];
	
	// delete the temp file if there is one
	[self deleteTemp];
	
	if(fbdelegate)
	{
		[fbdelegate FaceBookUploaderComplete];
	}
	
	if([self isBackground])
	{
		[uploads removeObject:self];
		[self release];
	}
}

-(void)error:(NSString*)reason
{
	if([self isBackground])
	{
		UIApplication* app = [UIApplication sharedApplication];
		[app endBackgroundTask:bgTask];
		
		[uploads removeObject:self];
		[self release];
	}
	
	[self deleteTemp];
	
	if(fbdelegate)
	{
		[fbdelegate FaceBookUploaderError:reason FacebookUploadState:currentState];
	}
}

- (void)videoUploadProgress:(NSInteger)bytesWritten bytesExpected:(NSInteger)expected
{
	if(currentState == FUSUploading && fbdelegate)
	{
		[fbdelegate FaceBookUploaderProgress:(float)bytesWritten / (float)expected];
	}
}

// Callback when a request receives Response
- (void)request:(FBRequest*)request didReceiveResponse:(NSURLResponse*)response
{
	NSLog(@"received response");
};

// Called when an error prevents the request from completing successfully.
- (void)request:(FBRequest*)request didFailWithError:(NSError*)error
{
	if(_session)
	{
		[_session logout];
		_session = NULL;
	}
	
	// "Service temporarily unavailable"
	[self error:[error localizedDescription]];
};

/**
 * Called when a request returns and its response has been parsed into an object.
 * The resulting object may be a dictionary, an array, a string, or a number, depending
 * on thee format of the API response.
 */
- (void)request:(FBRequest*)request didLoad:(id)result 
{
	if ([result isKindOfClass:[NSString class]]) 
	{
		// reply from stream.publish
		NSLog(@"String response %@ with state %d" , result, currentState);
	}
	else
	{
		if ([result isKindOfClass:[NSArray class]]) 
		{
			if([result count])
			{
				result = [result objectAtIndex:0];
			}
		}
		
		// log all keys and values
#if DEBUG
		NSArray * allkeys = [result allKeys];
		for(int i = 0; i < [allkeys count]; i++)
		{
			NSString * val = [result objectForKey:[allkeys objectAtIndex:i]];
			NSLog(@"%@ , %@" , [allkeys objectAtIndex:i], val);
		}
		NSLog(@"");
#endif
		// see if this is for the video max time/duration
		NSString * l = [result objectForKey:@"length"];
		if(l)
		{
			maxlength = _maxl = MIN([l intValue], 600); // we'll limit it to 10 minutes for now
			maxsize = _maxs = [[result objectForKey:@"size"] intValue];
			return;
		}
		
		if ([result objectForKey:@"vid"]) 
		{
			[self uploadComplete];
		} 
	}
};

-(void)deleteTemp
{
	@synchronized(self)
	{
		if(tempFile)
		{
			@try
			{
				NSFileManager* def = [NSFileManager defaultManager];
				[def removeItemAtPath:tempFile error:NULL];
				[tempFile release];
				tempFile = NULL;
			}
			@catch (id ex)
			{
				NSLog(@"%@", ex);
			}
		}
	}
}

- (void)dealloc 
{
	[super dealloc];
	
	if(dr)
	{
		[dr release];
		dr = NULL;
	}
	
	if(tempFile)
	{
		[tempFile release];
	}
}
@end
