//
//  ESRenderer.h
//  VideoTexture
//
//  Created by Richard Insley on 8/17/10.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import <OpenGLES/EAGL.h>
#import <OpenGLES/EAGLDrawable.h>

#import "FrameBuffer.h"
#import "VideoBuffer.h"
#import "VideoWriter.h"

@protocol ESRenderer <NSObject>

- (void)renderToSampleBuffer:(CMTime)timestamp;
- (void)processAudio:(CMSampleBufferRef)sampleBuffer;

- (BOOL)resizeFromLayer:(CAEAGLLayer *)layer;
- (BOOL)isRecording;
- (void)startRecording;
- (NSString*)stopRecording;
- (void)incEffect;
@end
