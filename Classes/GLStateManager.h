//
//  GLStateManager.h
//  Havoc Video
//
//  Created by Richard Insley on 9/24/10.
//  Copyright 2010 WildWestWare. All rights reserved.
//

#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import "GLERROR.h"

//#define USEMANAGEDSTATES
//#define LOGDUPLICATES

#ifdef USEMANAGEDSTATES
	#define MGLRESET()						[[GLStateManager sharedInstance] resetStates]
	#define MGLCAPTURESTATES()				[[GLStateManager sharedInstance] captureStates]
	#define MGLBINDTEXTURE2D(X)				[[GLStateManager sharedInstance] glbindtexture2d:X]
	//#define MGLBINDTEXTURECUBE(X)			[[GLStateManager sharedInstance] glbindtexturecube:X]
	#define MGLBINDTEXTURECUBE(X)	GLERROR(glBindTexture(GL_TEXTURE_CUBE_MAP, X))
	#define MGLACTIVETEXTURE(X)				[[GLStateManager sharedInstance] glactivetexture:X]
	#define MGLDELETETEXTURE(X)				[[GLStateManager sharedInstance] gldeletetexture:X]
	#define MGLUSEPROGRAM(X)				[[GLStateManager sharedInstance] gluseprogram:X]
	//#define MGLBINDFRAMEBUFFER(X)			[[GLStateManager sharedInstance] glbindframebuffer:X]
	#define MGLBINDFRAMEBUFFER(X)	GLERROR(glBindFramebuffer(GL_FRAMEBUFFER, X.framebuffer))
	#define MGLVIEWPORT(A, B, C, D)			[[GLStateManager sharedInstance] glviewportLeft:A Top:B Width:C Height:D]
	#define MGLCOPY(A, B, C)				[[GLStateManager sharedInstance] glcopy:A Width:B Height:C]
#else
	#define MGLRESET()
	#define MGLCAPTURESTATES()
	#define MGLBINDTEXTURE2D(X)		GLERROR(glBindTexture(GL_TEXTURE_2D, X))
	#define MGLBINDTEXTURECUBE(X)	GLERROR(glBindTexture(GL_TEXTURE_CUBE_MAP, X))
	#define MGLACTIVETEXTURE(X)		GLERROR(glActiveTexture(X))
	#define MGLDELETETEXTURE(X)		GLERROR(glDeleteTextures(1, &X))
	#define MGLUSEPROGRAM(X)		GLERROR(glUseProgram(X))
	#define MGLBINDFRAMEBUFFER(X)	GLERROR(glBindFramebuffer(GL_FRAMEBUFFER, X.framebuffer))
	#define MGLVIEWPORT(A, B, C, D)	GLERROR(glViewport(A, B, C, D))
	#define MGLCOPY(A, B, C)		[[GLStateManager sharedInstance] glcopy:A Width:B Height:C]
#endif

@interface GLStateManager : NSObject
{
	GLint ctexunit;
	GLint curtextures[32];
	GLint curprog;
	GLint crendertarget;
	
	int vpl, vpt, vpw, vph;
	
	bool isValidated;
	int vcount;
	
	id cboundbuffer;
}

+ (GLStateManager*)sharedInstance;
+ (id)allocWithZone:(NSZone *)zone;
- (id)copyWithZone:(NSZone *)zone;
- (id)retain;
- (unsigned)retainCount;
- (void)release;
- (id)autorelease;

- (void) captureStates;
- (void) resetStates;

- (void) glbindtexture2d:(GLuint)texture;
- (void) glbindtexturecube:(GLuint)texture;
- (void) glactivetexture:(GLuint)texunit;
- (void) gldeletetexture:(GLuint)texture;
- (void) gluseprogram:(GLuint)program;
- (void) glbindframebuffer:(id)framebuffer;
- (void) glviewportLeft:(int)left Top:(int)top Width:(int)width Height:(int)height;

+ (void)setRootFrameBuffer:(id)fb;
+ (id)getRootFrameBuffer;

@end
