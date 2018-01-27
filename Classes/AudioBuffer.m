#import "AudioBuffer.h"
#import <MobileCoreServices/MobileCoreServices.h>


@implementation AudioCaptureBuffer

@synthesize _session;
@synthesize powerLevel;

-(id) init
{
	if ((self = [super init]))
	{
		NSError * error;
		
		//-- Setup our Capture Session.
		self._session = [[AVCaptureSession alloc] init];
		
		[self._session beginConfiguration];
		
		// Create an audio device and input.  Add the input to the capture session
		AVCaptureDevice * audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
		if(audioDevice == nil)
			return nil;
		
		//-- Add the audio device to the session.
		AVCaptureDeviceInput *audioInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:&error];
		if(error)
			return nil;
		
		[self._session addInput:audioInput];
		
		// Create the output for the audio.
		AVCaptureAudioDataOutput * audioDataOutput = [[[AVCaptureAudioDataOutput alloc] init] autorelease];
		
		// Configure your output on a custom queue
		dispatch_queue_t audioqueue = dispatch_queue_create("audioMediaQueue", NULL);
		[audioDataOutput setSampleBufferDelegate:self queue:audioqueue];
		dispatch_release(audioqueue);
		
		[self._session addOutput:audioDataOutput];
		
		[self._session commitConfiguration];
	}
	return self;
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
	/*
	 Clients that need to reference the CMSampleBuffer object outside of the scope of this method must CFRetain it and
     then CFRelease it when they are finished with it.
	 
     Note that to maintain optimal performance, some sample buffers directly reference pools of memory that may need to be
     reused by the device system and other capture inputs. This is frequently the case for uncompressed device native
     capture where memory blocks are copied as little as possible. If multiple sample buffers reference such pools of
     memory for too long, inputs will no longer be able to copy new samples into memory and those samples will be dropped.
     If your application is causing samples to be dropped by retaining the provided CMSampleBuffer objects for too long,
     but it needs access to the sample data for a long period of time, consider copying the data into a new buffer and
     then calling CFRelease on the sample buffer if it was previously retained so that the memory it references can be
     reused.
	 */
	
	CMFormatDescriptionRef formatDesc = CMSampleBufferGetFormatDescription(sampleBuffer);
	
	// create a copy of the sample buffer so we don't block the memory usage of the capture thread
	
	CMSampleBufferRef naudio;
	CMSampleBufferCreateCopy(kCFAllocatorDefault, sampleBuffer, &naudio);
	
	// let the view know there's a new frame that needs processing
	// wrap the samplebuffer in an nsvalue
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	NSValue * ns = [NSValue valueWithPointer:naudio];
	[notificationCenter postNotificationName:@"audioNeedsProcessing" object:ns];
	
	// get the audio level
	NSArray * channels = connection.audioChannels;
	AVCaptureAudioChannel * chan = [channels objectAtIndex:0];
	
	// covert db to a normalied 0.0 - 1.0 range
	powerLevel = pow(10, chan.averagePowerLevel / 10.0);
}

- (void)dealloc 
{
	[_session release];
	
	[super dealloc];
}

-(void)start
{
	[_session startRunning];
}

-(void)stop
{
	[_session stopRunning];
}

@end
