/*
 
 File: VideoBuffer.mm
 
 Abstract: Initializes the capture session by creating a video device 
 and input from the available video device. Creates the video
 output for the capture session which is used to process 
 uncompressed frames from the video device being captured. 
 Creates an OpenGL texture to hold the video output data.
 Implements the AVCaptureVideoDataOutputSampleBufferDelegate
 protocol. The delegate is called when a sample buffer 
 containing an uncompressed frame from the video being captured
 is written. When a frame is written, it is copied to an OpenGL
 texture for display.
 
 Version: 1.0
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by 
 Apple Inc. ("Apple") in consideration of your agreement to the
 following terms, and your use, installation, modification or
 redistribution of this Apple software constitutes acceptance of these
 terms.  If you do not agree with these terms, please do not use,
 install, modify or redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software. 
 Neither the name, trademarks, service marks or logos of Apple Inc. 
 may be used to endorse or promote products derived from the Apple
 Software without specific prior written permission from Apple.  Except
 as expressly stated in this notice, no other rights or licenses, express
 or implied, are granted by Apple herein, including but not limited to
 any patent rights that may be infringed by your derivative works or by
 other works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2010 Apple Inc. All Rights Reserved.
 
 */

#import "VideoBuffer.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>
#import <CoreGraphics/CoreGraphics.h>
#import "GLERROR.h"


@implementation VideoBuffer

@synthesize _session;
@synthesize previousTimestamp;
@synthesize videoFrameRate;
@synthesize videoDimensions;
@synthesize videoType;
@synthesize CameraTexture=m_textureHandle;
@synthesize skippedFrames;
@synthesize isCapturing;

-(id) initWithWidth:(int)width Audio:(bool)audio UseFrontDevice:(bool)useFrontDevice LockObject:(NSLock*)lockObject Context:(EAGLContext*)context
{
	if ((self = [super init]))
	{
		NSError * error;
		_lockObject = [lockObject retain];
		rootContext = context;
        
		isprocessing = 0;
		skippedFrames = 0;
		audioCapture = NULL;
		
		//-- Setup our Capture Session.
		self._session = [[AVCaptureSession alloc] init];
		
		[self._session beginConfiguration];
		
		_width = width;
		
		//-- Set a preset session size.
		if(width == 480)
		{
			[self._session setSessionPreset:AVCaptureSessionPresetMedium];
			//-- Pre create our texture, instead of inside of CaptureOutput.
			m_textureHandle = [self createVideoTextuerUsingWidth:480 Height:360];
		}
		else if(width == 640)
		{
			[self._session setSessionPreset:AVCaptureSessionPreset640x480];
			//-- Pre create our texture, instead of inside of CaptureOutput.
			m_textureHandle = [self createVideoTextuerUsingWidth:640 Height:480];
		}
        else if(width == 1280)
        {
            [self._session setSessionPreset:AVCaptureSessionPreset1280x720];
			//-- Pre create our texture, instead of inside of CaptureOutput.
			m_textureHandle = [self createVideoTextuerUsingWidth:1280 Height:720];
        }
		
		// get the capture devices and set to the desired one
		NSArray * captureDevices = [[NSArray alloc] initWithArray:[AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]];
		for(int i = 0; i < captureDevices.count; i++)
		{
			AVCaptureDevice * device = [captureDevices objectAtIndex:i];
			if(device.position == AVCaptureDevicePositionBack)
			{
				backDevice = device;
			}
			else 
			{
				frontDevice = device;
			}
		}
		[captureDevices release];
		
		// use the front device if specified and is available
		currentDevice = ((useFrontDevice && frontDevice) ? frontDevice : backDevice);
									
		//-- Creata a video device and input from that Device.  Add the input to the capture session.
		AVCaptureDevice * videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
		if(videoDevice == nil)
			return nil;
		
		//-- Add the video device to the session.
		currentInput = [[AVCaptureDeviceInput deviceInputWithDevice:currentDevice error:&error] retain];
		if(error)
			return nil;
		
		[self._session addInput:currentInput];
		
		//-- Create the output for the capture session.  We want 32bit BRGA for video
		AVCaptureVideoDataOutput * dataOutput = [[[AVCaptureVideoDataOutput alloc] init] autorelease];
		[dataOutput setAlwaysDiscardsLateVideoFrames:YES];
		[dataOutput setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey]]; // Necessary for manual preview
		
		// set the frame rate (if it is too high, the frames will get jammed up durring glReadPixels)
		dataOutput.minFrameDuration = CMTimeMake(1, 18);
		
		// Configure your output on a custom queue
		dispatch_queue_t queue = dispatch_queue_create("videoMediaQueue", NULL);
		[dataOutput setSampleBufferDelegate:self queue:queue];
		dispatch_release(queue);
		
		[self._session addOutput:dataOutput];
		
		// set up the audio device if selected
		if(audio)
		{
			// we want the audio capture to be handled by a different session to prevent frame rate slowdowns
			audioCapture = [[AudioCaptureBuffer alloc] init];
		}
		
		// create the queue to asynchronously broadcast video frame updates
		videoCastQueue = dispatch_queue_create("videoCastQueue", NULL);
		
		[self._session commitConfiguration];
		
		isCapturing = true;
	}
	return self;
}

#ifdef USESNAPS
NSString * getPathForImageFile(const char * name)
{
	NSString *textureName = [ NSString stringWithCString: name encoding: NSASCIIStringEncoding ];
	
	textureName = [[NSBundle mainBundle] pathForResource:textureName ofType:@"png"];
	if(!textureName)
	{
		// try jpeg
		textureName = [ NSString stringWithCString: name encoding: NSASCIIStringEncoding ];
		textureName = [[NSBundle mainBundle] pathForResource:textureName ofType:@"jpg"];
	}
	
	return textureName;
}
#endif

-(GLuint)createVideoTextuerUsingWidth:(GLuint)w Height:(GLuint)h
{
#ifdef USESNAPS
	NSString * textureName = getPathForImageFile(USESNAPS);
	texture = [[FrameBuffer alloc] initWithFile:textureName];
#else
	texture = [[FrameBuffer alloc] initWithWidth:w Height:h CreateTexture:true UsesReadPixels:false];
#endif
	
	GLuint handle = [texture getTexture];
	return handle;
}

- (FrameBuffer*)getVideoBuffer
{
	return texture;
}

- (void) resetWithSize:(GLuint)w Height:(GLuint)h
{
	[_session beginConfiguration];
	
	//-- Match the wxh with a preset.
	if(w == 1280 && h == 720)
	{
		[_session setSessionPreset:AVCaptureSessionPreset1280x720];
	}
	else if(w == 640)
	{
		[_session setSessionPreset:AVCaptureSessionPreset640x480];
	}
	else if(w == 480)
	{
		[_session setSessionPreset:AVCaptureSessionPresetMedium];
	}
	else if(w == 192)
	{
		[_session setSessionPreset:AVCaptureSessionPresetLow];
	}
	
	[_session commitConfiguration];
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
	
	CMTime timestamp = CMSampleBufferGetPresentationTimeStamp( sampleBuffer );
	if (CMTIME_IS_VALID( self.previousTimestamp ))
		self.videoFrameRate = 1.0 / CMTimeGetSeconds( CMTimeSubtract( timestamp, self.previousTimestamp ) );
	
	previousTimestamp = timestamp;
	
	self.videoDimensions = CMVideoFormatDescriptionGetDimensions(formatDesc);
	
	CMVideoCodecType type = CMFormatDescriptionGetMediaSubType(formatDesc);
#if defined(__LITTLE_ENDIAN__)
	type = OSSwapInt32(type);
#endif
	self.videoType = type;
	
	
	//-- If we haven't created the video texture, do so now so it's on the same thread as the casting queue
	if(m_textureHandle == 0)
	{
		m_textureHandle = [self createVideoTextuerUsingWidth:videoDimensions.width Height:videoDimensions.width];
	}
	
	bool set = OSAtomicTestAndSet(0, &isprocessing);
	
	// let the view know there's a new frame that needs processing
	if(!set)
	{
		CVImageBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
		CVPixelBufferLockBaseAddress( pixelBuffer, 0 );
		
		[_lockObject lock];

		MGLBINDTEXTURE2D(m_textureHandle);
		
#ifndef USESNAPS
		if(![EAGLContext setCurrentContext:rootContext])
        {
            NSLog(@"unable to set context on video capture thread");
        }
		unsigned char* linebase = (unsigned char *)CVPixelBufferGetBaseAddress( pixelBuffer );
		// changing an effect at the same time as updating the video texure causes things to get all explodey
        GLERROR(glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, videoDimensions.width, videoDimensions.height, 0, GL_BGRA_EXT, GL_UNSIGNED_BYTE, linebase));
		//GLERROR(glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, videoDimensions.width, videoDimensions.height, GL_BGRA_EXT, GL_UNSIGNED_BYTE, linebase));
#endif
		[_lockObject unlock];
		
		CVPixelBufferUnlockBaseAddress( pixelBuffer, 0 );
		
		dispatch_async(videoCastQueue, ^(void)
					   {
						   NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
						   [notificationCenter postNotificationName:@"frameNeedsProcessing" object:[NSValue valueWithCMTime:timestamp]];
						   // unset isprocessing so we know there is no pending processed frame
						   OSAtomicTestAndClear(0, &isprocessing);
					   });
	}
	else 
	{
		skippedFrames++;
	}
}

// return the power level of the audio
- (float)getPowerLevel
{
	if(audioCapture)
	{
		return audioCapture.powerLevel;
	}
	
	return 0;
}

-(void)start
{
	[_session startRunning];
	if(audioCapture)
	{
		[audioCapture start];
	}
	isCapturing = true;
}

-(void)stop
{
	[_session stopRunning];
	if(audioCapture)
	{
		[audioCapture stop];
	}
	isCapturing = false;
}

-(bool)isFrontCamera
{
	return currentDevice == frontDevice;
}

-(void)setFrontCamera:(bool)useFront
{
	if(!frontDevice)
	{
		// there is no front facing camera
		return;
	}
	
	if((useFront && frontDevice == currentDevice) || (!useFront && backDevice == currentDevice))
	{
		// we're already there Mary
		return;
	}
	
	NSError * error;
	
	// get the new capture device
	AVCaptureDevice * newdevice = (currentDevice == frontDevice ? backDevice : frontDevice);
	
	[currentDevice lockForConfiguration:nil];
	
	// remove the old input
	[self._session removeInput:currentInput];
	[currentInput release];
	
	// add the new input
	AVCaptureDeviceInput *newInput = [[AVCaptureDeviceInput deviceInputWithDevice:newdevice error:&error] retain];
	if(error) return;
	
	[self._session addInput:newInput];
	
	[currentDevice unlockForConfiguration];
	
	// save the new input and capture device
	currentInput = newInput;
	currentDevice = newdevice;
}

- (void)enableLamp:(bool)enable
{
	//lockForConfiguration
	if([currentDevice hasTorch])
	{
		[currentDevice lockForConfiguration:nil];
		currentDevice.torchMode = enable ? AVCaptureTorchModeOn : AVCaptureTorchModeOff;
		[currentDevice unlockForConfiguration];
	}
}

-(bool)isLampEnabled
{
	return currentDevice.torchMode == AVCaptureTorchModeOn;
}

- (void)dealloc 
{
	[super dealloc];
	
	[_session release];
	
	if(currentInput)
	{
		[currentInput release];
	}
	
	if(audioCapture)
	{
		[audioCapture release];
	}
	
	[_lockObject release];
}

@end
