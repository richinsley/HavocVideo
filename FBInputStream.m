//
//  FBInputStream.m
//  Havoc Video
//
//  Created by Richard Insley on 9/30/10.
//  Copyright 2010 WildWestWare. All rights reserved.
//

#import "FBInputStream.h"


@implementation FBInputStream

- (id) initWithAsset:(ALAssetRepresentation *)asset PreData:(NSMutableData*)predata PostData:(NSMutableData*)postdata ThrottleSize:(int)throttleSize
{
	if((self = [super init]))
	{
		_throttleSize = throttleSize;
		mydelegate = self;
		
		status = NSStreamStatusNotOpen;
		_asset = [asset retain];
		_filePath = NULL;
		filestream = NULL;
		
		_predata = [predata retain];
		_postdata = [postdata retain];
		
		predatasize = [_predata length];
		postdatasize = [_postdata length];
		datasize = [_asset size];
		totalsize = datasize + predatasize + postdatasize;
		
		readpos = 0;
	}
	return self;
}

- (id) initWithFilePath:(NSString*)filePath PreData:(NSMutableData*)predata PostData:(NSMutableData*)postdata ThrottleSize:(int)throttleSize
{
	if((self = [super init]))
	{
		_throttleSize = throttleSize;
		mydelegate = self;
		
		status = NSStreamStatusNotOpen;
		
		_filePath = [filePath retain];
		_asset = NULL;
		
		_predata = [predata retain];
		_postdata = [postdata retain];
		
		predatasize = [_predata length];
		postdatasize = [_postdata length];
		
		NSFileManager* fm = [NSFileManager defaultManager];
		NSDictionary* fatr = [fm attributesOfItemAtPath:filePath error:NULL];
		NSNumber * flen = [fatr objectForKey:@"NSFileSize"];
		datasize = [flen unsignedLongLongValue];

		totalsize = datasize + predatasize + postdatasize;
		readpos = 0;
		
		// create the NSInputStream for the given file
		filestream = [[NSInputStream inputStreamWithFileAtPath:filePath] retain];
		[filestream open];
	}
	return self;
}

- (void)dealloc 
{
	[super dealloc];
	
	if(filestream)
	{
		[filestream release];
		filestream = NULL;
	}
	
	if(_asset)
	{
		[_asset release];
		_asset = NULL;
	}
	
	if(_filePath)
	{
		[_filePath release];
		_filePath = NULL;
	}
	
	[_predata release];
	[_postdata release];
}

- (NSInteger)read:(uint8_t *)buffer maxLength:(NSUInteger)len
{
	if(readpos >= totalsize)
	{
		// all done
		status = NSStreamStatusAtEnd;
		return 0;
	}
	
	status = NSStreamStatusReading;
	
	// throttle the packet size if needed
	if(_throttleSize != -1)
	{
		len = MIN(_throttleSize, len);
	}
	
	if(readpos < predatasize)
	{
		// send data from pre data
		int dread = MIN(predatasize - readpos, len);
		[_predata getBytes:buffer range:NSMakeRange(readpos, dread)];
		readpos += dread;
		return dread;
	}
	else if(readpos < predatasize + datasize)
	{
		if(filestream)
		{
			// get the data from the file stream
			int dread = MIN((predatasize + datasize) - readpos, len);
			int br = [filestream read:buffer maxLength:dread];
			if (br > -1)
			{
				readpos += br; // read can return a negative value for an error
			}
			
			return br;
		}
		else
		{
			// get the data from the asset representation
			NSError* err = NULL;
			int dread = MIN((predatasize + datasize) - readpos, len);
			//int br = [filestream read:buffer maxLength:dread];
			int br = [_asset getBytes:buffer fromOffset:readpos - predatasize length:dread error:&err];
			if(err)
			{
				int br = 0;
			}
			readpos += br;
			return br;
		}
	}
	else
	{
		// send data from post data
		int dread = MIN(totalsize - readpos, len);
		NSRange nr = NSMakeRange(readpos - (predatasize + datasize), dread);
		[_postdata getBytes:buffer range:nr];
		readpos += dread;
		
		if(readpos >= totalsize)
		{
			// all done
			status = NSStreamStatusAtEnd;
			[mydelegate stream:self handleEvent:NSStreamEventEndEncountered];
		}
		
		return dread;
	}
}

- (BOOL)getBuffer:(uint8_t **)buffer length:(NSUInteger *)len
{
	// this would not be possible with our mixed data sources
	return NO;
}

- (unsigned long long) getLength
{
	return totalsize;
}

- (BOOL)hasBytesAvailable
{
	return readpos != totalsize;
}

-(void)open
{
	// HA! we're here
	status = NSStreamStatusOpen;
}

- (void)close
{
	if(filestream)
	{
		[filestream close];
	}
	status = NSStreamStatusClosed;
}

- (NSStreamStatus)streamStatus
{
	return status;
}

- (id) delegate
{
	return mydelegate;
}

- (void) setDelegate:(id)delegate
{
	mydelegate = delegate;
}

- (id) propertyForKey:(NSString*)key
{
	return nil;
}

- (BOOL) setProperty:(id)property forKey:(NSString*)key
{
	return NO;
}

-(NSError *)streamError
{
	return NULL;
}

- (void)stream:(NSStream *)theStream handleEvent:(NSStreamEvent)streamEvent
{
	;
}

- (void) scheduleInRunLoop:(NSRunLoop*)aRunLoop forMode:(NSString*)mode
{
	;
}

- (void) removeFromRunLoop:(NSRunLoop*)aRunLoop forMode:(NSString*)mode
{
	;
}

// Internal SPI required to be implemented for subclasses of NSStream to work 
- (BOOL) _setCFClientFlags:(CFOptionFlags)streamEvents callback:(CFReadStreamClientCallBack)clientCB context:(CFStreamClientContext*)clientContext
{
	return NO;
}

// Internal SPI required to be implemented for subclasses of NSStream to work 
- (void) _scheduleInCFRunLoop:(CFRunLoopRef)runLoop forMode:(CFStringRef)runLoopMode
{
	;
}

// Internal SPI required to be implemented for subclasses of NSStream to work 
- (void) _unscheduleFromCFRunLoop:(CFRunLoopRef)runLoop forMode:(CFStringRef)runLoopMode
{
	;
}

@end
