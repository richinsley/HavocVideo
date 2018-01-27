/*
 
 File: VideoBuffer.h
 
 Abstract: Initializes the capture session by creating a video device 
 and input from the available video device. Creates the video
 output for the capture session which is used to process 
 uncompressed frames from the video device being captured. 
 Creates an OpenGL texture to hold the video output data.
 Implements the AVCaptureVideoDataOutputSampleBufferDelegate
 protocol. The delegate is called when a sample buffer 
 containing an uncompressed frame from the video being captured
 is written. When a frame is written, it is copied to an OpenGL
 texture for later display.
 
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

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import "VideoWriter.h"
#import "FrameBuffer.h"
#import "AudioBuffer.h"
#import "GLStateManager.h"

#include <libkern/OSAtomic.h>

//#define USESNAPS "carl"

@interface VideoBuffer : NSObject <AVCaptureVideoDataOutputSampleBufferDelegate , AVCaptureAudioDataOutputSampleBufferDelegate> 
{
	
	int _width;
	
	AVCaptureSession*		_session;
	AVCaptureSession*		_audioSession;
	
	CMTime previousTimestamp;
	
	Float64 videoFrameRate;
	CMVideoDimensions videoDimensions;
	CMVideoCodecType videoType;
	
	AVCaptureAudioDataOutput * audioDataOutput;
	
	FrameBuffer * texture;
	uint m_textureHandle;
	
	dispatch_queue_t videoCastQueue;
	int volatile isprocessing; 
	
	int skippedFrames;
	
	AudioCaptureBuffer * audioCapture;
	
	AVCaptureDevice * backDevice;
	AVCaptureDevice * frontDevice;
	AVCaptureDevice * currentDevice;
	AVCaptureDeviceInput * currentInput;
	
	NSLock * _lockObject;
	
	bool isCapturing;
    
    EAGLContext * rootContext;
}

@property (nonatomic, retain) AVCaptureSession* _session;
@property (readwrite) Float64 videoFrameRate;
@property (readwrite) CMVideoDimensions videoDimensions;
@property (readwrite) CMVideoCodecType videoType;
@property (readwrite) CMTime previousTimestamp;
@property (readwrite) int skippedFrames;
@property (readonly) bool isCapturing;

@property (readwrite) uint CameraTexture;

-(id)initWithWidth:(int)width Audio:(bool)audio UseFrontDevice:(bool)useFrontDevice LockObject:(NSLock*)lockObject Context:(EAGLContext*)context;
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection;
- (GLuint)createVideoTextuerUsingWidth:(GLuint)w Height:(GLuint)h;
- (void)resetWithSize:(GLuint)w Height:(GLuint)h;
- (FrameBuffer*)getVideoBuffer;
- (float)getPowerLevel;

-(void)start;
-(void)stop;

-(bool)isFrontCamera;
-(void)setFrontCamera:(bool)useFront;
-(void)enableLamp:(bool)enable;
-(bool)isLampEnabled;

@end
