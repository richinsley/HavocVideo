//
//  VideoWriter.h
//  VideoTexture
//
//  Created by Richard Insley on 8/22/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

#define ACCAUDIOCOUNT 5

@interface VideoWriter : NSObject 
{
	AVAssetWriter* writer;
	AVAssetWriterInput* assetWriterInput;
	AVAssetWriterInput* audioAssetWriterInput;
	
	BOOL _isRecording;
	NSString *videoPath;
	NSString *audioPath;
	
	bool _gotFirstTime;
	CMTime firstTimestamp;
	
	bool _gotFirstAudioTime;
	CMTime firstAudioTimestamp;
	
	int _width;
	int _height;
	
	dispatch_queue_t encodeQueue;
	
	AVAssetWriterInputPixelBufferAdaptor * pbadapter;
	CVPixelBufferPoolRef _bufferPool; // release with CVPixelBufferPoolRelease
	
	// lock object to prevent stopping the writer while aynchronous writes are progress
	NSLock * audioLock;
	NSLock * pixelLock;
	
	double _duration;
	
	// recording orientation
	UIInterfaceOrientation recordingOrientation;
}

@property (readwrite, retain) NSString *videoPath;
@property (readwrite, retain) NSString *audioPath;
@property (readonly, nonatomic) UIInterfaceOrientation recordingOrientation;

-(id)initWithParams:(NSString*)filePath Width:(int)width Height:(int)height Audio:(bool)audio Orientation:(UIInterfaceOrientation)orientation;
-(bool)isReadyForMoreMediaData;
-(void)appendSampleBuffer:(CMSampleBufferRef)sampleBuffer;
-(void)startRecording:(CMTime)startTime;
-(void)stopRecording;
-(bool)isRecording;
-(CVPixelBufferRef)getPixelBuffer;
-(bool)appendPixelBuffer:(CVPixelBufferRef)pixelBuffer TimeStamp:(CMTime)timestamp;
-(NSString*)getPath;
-(double)getDuration;

@end
