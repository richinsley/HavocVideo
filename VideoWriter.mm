//
//  VideoWriter.mm
//  VideoTexture
//
//  Created by Richard Insley on 8/22/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "VideoWriter.h"


@implementation VideoWriter

@synthesize videoPath;
@synthesize audioPath;
@synthesize recordingOrientation;

- (id)initWithParams:(NSString*)filePath Width:(int)width Height:(int)height Audio:(bool)audio Orientation:(UIInterfaceOrientation)orientation
{
    if ((self = [super init]))
    {
		_width = width;
		_height = height;
		
		recordingOrientation = orientation;
		
		_gotFirstTime = false;
		_gotFirstAudioTime = false;
		
		_isRecording = false;
		audioAssetWriterInput = NULL;
		
		audioLock = [[NSLock alloc] init];
		pixelLock = [[NSLock alloc] init];
		
		NSError *error = nil;
		videoPath = [[NSString stringWithFormat:@"%@/Documents/%@", NSHomeDirectory(), filePath] retain];

		NSURL *outputPath = [[NSURL alloc] initFileURLWithPath:videoPath];
		
		if (![outputPath isFileURL])
		{
			NSLog(@"Not file URL");
		}
		
		NSFileManager *fileManager = [NSFileManager defaultManager];
		if([fileManager fileExistsAtPath:videoPath])
		{
			[fileManager removeItemAtPath:videoPath error:nil];
		}

		writer = [AVAssetWriter assetWriterWithURL:outputPath fileType:AVFileTypeQuickTimeMovie  error:&error];
		
		if (error != nil)
		{
			NSLog(@"Creation of assetWriter resulting in a non-nil error");
		}   
		
        int scaleq = 1;
        if(width == 640)
        {
            scaleq = 3;
        }
        else if(width == 1280)
        {
            scaleq = 9;
        }
        
		NSDictionary *videoCompressionProps = [NSDictionary dictionaryWithObjectsAndKeys:
											   [NSNumber numberWithInt:1000000 * scaleq], AVVideoAverageBitRateKey,
											   nil ];
		
		NSMutableDictionary *d=[[NSMutableDictionary alloc] init];
		[d setValue: AVVideoCodecH264 forKey: AVVideoCodecKey];
		[d setValue:[NSNumber numberWithInt:_width] forKey:AVVideoWidthKey];
		[d setValue:[NSNumber numberWithInt:_height] forKey:AVVideoHeightKey];
		[d setValue:videoCompressionProps forKey:AVVideoCompressionPropertiesKey];
		
		assetWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:d];
		
		if (assetWriterInput == nil)
		{
			NSLog(@"assetWriterInput is nil");
		}
		
		// get the pixel bufer adapter
		/*
		 #pragma mark BufferAttributeKeys
		 CV_EXPORT const CFStringRef kCVPixelBufferPixelFormatTypeKey __OSX_AVAILABLE_STARTING(__MAC_10_4,__IPHONE_4_0);		    // A single CFNumber or a CFArray of CFNumbers (OSTypes)
		 CV_EXPORT const CFStringRef kCVPixelBufferMemoryAllocatorKey __OSX_AVAILABLE_STARTING(__MAC_10_4,__IPHONE_4_0);		    // CFAllocatorRef
		 CV_EXPORT const CFStringRef kCVPixelBufferWidthKey __OSX_AVAILABLE_STARTING(__MAC_10_4,__IPHONE_4_0);			    // CFNumber
		 CV_EXPORT const CFStringRef kCVPixelBufferHeightKey __OSX_AVAILABLE_STARTING(__MAC_10_4,__IPHONE_4_0);			    // CFNumber
		 CV_EXPORT const CFStringRef kCVPixelBufferExtendedPixelsLeftKey __OSX_AVAILABLE_STARTING(__MAC_10_4,__IPHONE_4_0);	    // CFNumber
		 CV_EXPORT const CFStringRef kCVPixelBufferExtendedPixelsTopKey __OSX_AVAILABLE_STARTING(__MAC_10_4,__IPHONE_4_0);		    // CFNumber
		 CV_EXPORT const CFStringRef kCVPixelBufferExtendedPixelsRightKey __OSX_AVAILABLE_STARTING(__MAC_10_4,__IPHONE_4_0);	    // CFNumber
		 CV_EXPORT const CFStringRef kCVPixelBufferExtendedPixelsBottomKey __OSX_AVAILABLE_STARTING(__MAC_10_4,__IPHONE_4_0);	    // CFNumber
		 CV_EXPORT const CFStringRef kCVPixelBufferBytesPerRowAlignmentKey __OSX_AVAILABLE_STARTING(__MAC_10_4,__IPHONE_4_0);	    // CFNumber
		 CV_EXPORT const CFStringRef kCVPixelBufferCGBitmapContextCompatibilityKey __OSX_AVAILABLE_STARTING(__MAC_10_4,__IPHONE_4_0);  // CFBoolean
		 CV_EXPORT const CFStringRef kCVPixelBufferCGImageCompatibilityKey __OSX_AVAILABLE_STARTING(__MAC_10_4,__IPHONE_4_0);	    // CFBoolean
		 CV_EXPORT const CFStringRef kCVPixelBufferOpenGLCompatibilityKey __OSX_AVAILABLE_STARTING(__MAC_10_4,__IPHONE_4_0);	    // CFBoolean
		 CV_EXPORT const CFStringRef kCVPixelBufferPlaneAlignmentKey __OSX_AVAILABLE_STARTING(__MAC_10_6,__IPHONE_4_0);		    // CFNumber
		 CV_EXPORT const CFStringRef kCVPixelBufferIOSurfacePropertiesKey __OSX_AVAILABLE_STARTING(__MAC_10_6,__IPHONE_4_0);     // CFDictionary; presence requests buffer allocation via IOSurface
		 */

		NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
							  [NSNumber numberWithInt:kCVPixelFormatType_32BGRA] , (id)kCVPixelBufferPixelFormatTypeKey,
							  [NSNumber numberWithInt:(int)_width], (id)kCVPixelBufferWidthKey,
							  [NSNumber numberWithInt:(int)_height], (id)kCVPixelBufferHeightKey,
							  [NSNumber numberWithInt:(int)128], (id)kCVPixelBufferBytesPerRowAlignmentKey, // this is needed because glReadPixels only works with widths multiple of 32
							  nil];
		pbadapter = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:assetWriterInput
																					 sourcePixelBufferAttributes:dict];
		
		// or ELSE!
		[pbadapter retain];
		
		assetWriterInput.expectsMediaDataInRealTime = YES;
		[writer addInput:assetWriterInput];
		
		if(audio)
		{
			
#ifdef USEAAC
			// create the audio assest writer input
			// AAC ancoding
			NSMutableDictionary *audioOutputSettings =[[NSMutableDictionary alloc] init];
			[audioOutputSettings setValue:[NSNumber numberWithInt:kAudioFormatMPEG4AAC_LD]  forKey: AVFormatIDKey]; // LD takes much less processing at this time
			[audioOutputSettings setValue:[NSNumber numberWithFloat:44100.0]  forKey: AVSampleRateKey];
			[audioOutputSettings setValue:[NSNumber numberWithInt:1]  forKey: AVNumberOfChannelsKey];
			[audioOutputSettings setValue:[NSNumber numberWithInt:64000]  forKey: AVEncoderBitRateKey];
			[audioOutputSettings setValue:[NSData data]  forKey:AVChannelLayoutKey];
#else
			// PCM encoding
			NSMutableDictionary *audioOutputSettings =[[NSMutableDictionary alloc] init];
			[audioOutputSettings setValue:[NSNumber numberWithInt:kAudioFormatLinearPCM]  forKey: AVFormatIDKey];
			[audioOutputSettings setValue:[NSNumber numberWithInt:16]  forKey:AVLinearPCMBitDepthKey];
			[audioOutputSettings setValue:[NSNumber numberWithBool:YES]  forKey:AVLinearPCMIsBigEndianKey];
			[audioOutputSettings setValue:[NSNumber numberWithBool:NO]  forKey:AVLinearPCMIsFloatKey];
			[audioOutputSettings setValue:[NSNumber numberWithBool:NO]  forKey:AVLinearPCMIsNonInterleaved];
			[audioOutputSettings setValue:[NSNumber numberWithFloat:44100.0]  forKey: AVSampleRateKey];
			[audioOutputSettings setValue:[NSNumber numberWithInt:1]  forKey: AVNumberOfChannelsKey];
			[audioOutputSettings setValue:[NSData data]  forKey:AVChannelLayoutKey];
#endif
			audioAssetWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:audioOutputSettings];
			
			if (audioAssetWriterInput == nil)
			{
				NSLog(@"audioAssetWriterInput is nil");
			}
			
			// add the audio input to the asset writer
			audioAssetWriterInput.expectsMediaDataInRealTime = YES;
			[writer addInput:audioAssetWriterInput];
		}
		
		writer.shouldOptimizeForNetworkUse = true;
		
		// create the output file via startWriting (we always want to start with timestamp 0)
		[writer startWriting];
		CMTime stime = CMTimeMake(0, 1000000000);
		[writer startSessionAtSourceTime:stime];
		
		// pixelBufferPool is only available after the first call to startSessionAtTime
		_bufferPool = pbadapter.pixelBufferPool;
		CVPixelBufferPoolRetain(_bufferPool);
		
		// create the queue to asynchronously encode pixelbuffers
		encodeQueue = dispatch_queue_create("encodeQueue", NULL);
		
		_isRecording = true;
		
		[writer retain];
		[assetWriterInput retain];
	}
	
	return self;
}

-(NSString*)getPath
{
	return videoPath;
}

-(bool)isReadyForMoreMediaData
{
	return [assetWriterInput isReadyForMoreMediaData];
}

-(bool)isRecording
{
	return _isRecording;
}

-(CVPixelBufferRef)getPixelBuffer
{
	// this is how to allocate a pixel buffer
	CVPixelBufferRef pixelBuffer;
	CVReturn err = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, _bufferPool, &pixelBuffer);
	
	if(!err)
	{
		return pixelBuffer;
	}
	
	return nil;
}

-(bool)appendPixelBuffer:(CVPixelBufferRef)pixelBuffer TimeStamp:(CMTime)timestamp
{
	if(_isRecording)
	{
		if(!_gotFirstTime)
		{
			firstTimestamp = timestamp;
			_gotFirstTime = true;
		}
		
		timestamp.value = timestamp.value - firstTimestamp.value;
		_duration = CMTimeGetSeconds(timestamp);
		
		dispatch_async(encodeQueue, ^(void)
					   {
							[pixelLock lock]; // this is not superfluous.  The first lock is for the capture thread, this will lock the encode dispatch

							if(_isRecording)
							{
								if (![pbadapter appendPixelBuffer:pixelBuffer withPresentationTime:timestamp])
								{
									NSLog(@"Failed to append pixel buffer");
								}
							}

						   CVPixelBufferRelease(pixelBuffer);
						   
							[pixelLock unlock];
					   });
	}
	return true;
}

-(double)getDuration
{
	return _duration;
}

// append an audio samplebuffer
-(void)appendSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
	//[audioLock lock];
	
	if(_isRecording)
	{
		CMTime timestamp = CMSampleBufferGetPresentationTimeStamp( sampleBuffer );
		
		if(!_gotFirstAudioTime)
		{
			firstAudioTimestamp = timestamp;
			_gotFirstAudioTime = true;
		}
		
		// get the count of the SampleTimingInfoArrays
		CMItemCount scount = 0;
		CMSampleBufferGetOutputSampleTimingInfoArray(sampleBuffer, 0, NULL, &scount);
		
		if(scount < 256)
		{
			// get the actual SampleTimingInfoArrays
			CMSampleTimingInfo timingArrayOut[256];
			CMSampleBufferGetOutputSampleTimingInfoArray(sampleBuffer, scount, timingArrayOut, &scount);
			
			// adjust timestamps to 0 based
			for(int i = 0; i < scount; i++)
			{
				timingArrayOut[i].presentationTimeStamp.value = timingArrayOut[i].presentationTimeStamp.value - firstAudioTimestamp.value;
			}
			
			// create a copy of the sample buffer with new timing
			CMSampleBufferRef newsbuffer = NULL;
			OSStatus err = CMSampleBufferCreateCopyWithNewTiming(kCFAllocatorDefault, sampleBuffer, scount, timingArrayOut, &newsbuffer);
			
			dispatch_async(encodeQueue, ^(void)
						   {
							   // prevent writing during closing operations
							   [audioLock lock];
							   
							   if(_isRecording)
							   {
								   if (![audioAssetWriterInput appendSampleBuffer:newsbuffer])
								   {
									   NSLog(@"Failed to append pixel buffer");
								   }
							   }
							   
							   CFRelease(newsbuffer);
							   
							   [audioLock unlock];
						   });		}
		else 
		{
			NSLog(@"CMSampleBufferGetOutputSampleTimingInfoArray in append exceeded 256 values");
		}
	}
	// [audioLock unlock];
}

- (void)dealloc
{	
	// clean up
	// ...
	
	// ensure we're not recording
	[self stopRecording];
	
	if(pixelLock)
	{
		[pixelLock release];
		pixelLock = NULL;
	}
	
	if(audioLock)
	{
		[audioLock release];
		audioLock = NULL;
	}
	
	if(writer)
	{
		[writer release];
		writer = NULL;
	}
	
	if(pbadapter)
	{
		[pbadapter release];
		pbadapter = NULL;
	}
	
	if(_bufferPool)
	{
		CVPixelBufferPoolRelease(_bufferPool);
		_bufferPool = NULL;
	}
	
	[super dealloc];
}

-(void)startRecording:(CMTime)startTime
{
	
}

-(void)stopRecording
{
	[pixelLock lock];
	[audioLock lock];
	
	if(_isRecording)
	{
		_isRecording = false;
		[assetWriterInput markAsFinished];
		[writer finishWriting];
	}
	
	[audioLock unlock];
	[pixelLock unlock];
}
@end
