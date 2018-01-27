//
//  FrameBuffer.h
//  VideoTexture
//
//  Created by Richard Insley on 8/22/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import "GLStateManager.h"

extern "C" 
{
	#import "NoiseTexture.h"
	#import "png.h"
}

@interface FrameBuffer : NSObject 
{	
	int _width;
	int _height;
	int _actualWidth;
	int _actualHeight;
	
	// if created from a file, the internal and external formats of the pixels
	GLuint internal;
	GLuint format;
	
	GLuint framebuffer;
	GLuint texture;
	GLuint cubeTexture;
	GLuint colorRenderbuffer;
	
	// noise goodies
	GLuint ntex1;
	GLuint ntex2;
	GLubyte* Noise3DTexPtr;
	dispatch_queue_t noiseQueue;
	
	bool isFlipped;
}

@property (readwrite, nonatomic) bool isFlipped;
@property (readwrite, nonatomic) GLuint texture;
@property (readwrite, nonatomic) GLuint colorRenderbuffer;
@property (readwrite, nonatomic) GLuint framebuffer;

-(id)initWithFrameBuffer:(GLuint)fbo ColorBuffer:(GLuint)cbo;
-(id)initWithFile:(NSString*)imagePath;
-(id)initWithWidth:(int)width Height:(int)height CreateTexture:(bool)createTexture UsesReadPixels:(bool)glread ;
-(id)initWithCubeXP:(NSString*)xp XN:(NSString*)xn YP:(NSString*)yp YN:(NSString*)yn ZP:(NSString*)zp ZN:(NSString*)zn MipMap:(bool)genMipMap;
-(id)initWithNoise:(int)width Height:(int)height;

-(void)setRenderTarget;
-(void)readPixels:(void*)linedata;
-(int)getWidth;
-(int)getActualWidth;
-(int)getHeight;
-(GLint)getTexture;
-(bool)isCubeMap;

-(void)setNoiseTexture:(GLuint) texid;
-(GLint)getNoiseTexture:(int)index;
-(void)flipNoise;
-(bool)getIsPortrait;

@end

static GLuint generateAndBindCube()
{
	GLuint index;
	GLERROR(glGenTextures(1, &index));
	MGLBINDTEXTURECUBE(index);
	
	return index;
}
