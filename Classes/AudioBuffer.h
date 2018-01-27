#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface AudioCaptureBuffer : NSObject <AVCaptureAudioDataOutputSampleBufferDelegate> 
{
	AVCaptureSession*		_session;
	AVCaptureSession*		_audioSession;
	
	CMTime previousTimestamp;
	
	float powerLevel; 
}

@property (nonatomic, retain) AVCaptureSession* _session;
@property (nonatomic, readonly) float powerLevel;

- (void) captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection;
@end
