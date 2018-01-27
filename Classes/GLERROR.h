/*
 *  GLERROR.h
 *  VideoTexture
 *
 *  Created by Richard Insley on 8/29/10.
 *  Copyright 2010 __MyCompanyName__. All rights reserved.
 *
 */

#import <OpenGLES/EAGL.h>
#import <OpenGLES/EAGLDrawable.h>

#ifndef GLERRORH
#define GLERRORH

#define USEGLERROR

#if defined(USEGLERROR) && defined(DEBUG)
	#define GLERROR(X) X; GetGlError()
#else
	#define GLERROR(X) X
#endif

static void GetGlError()
{
	GLenum err = glGetError();
	if(err)
	{
		const char *str;
		switch( err )
		{
			case GL_NO_ERROR:
				str = NULL;
				break;
			case GL_INVALID_ENUM:
				str = "GL_INVALID_ENUM";
				break;
			case GL_INVALID_VALUE:
				str = "GL_INVALID_VALUE";
				break;
			case GL_INVALID_OPERATION:
				str = "GL_INVALID_OPERATION";
				break;			
#ifdef __gl_h_
			case GL_STACK_OVERFLOW:
				str = "GL_STACK_OVERFLOW";
				break;
			case GL_STACK_UNDERFLOW:
				str = "GL_STACK_UNDERFLOW";
				break;
			case GL_OUT_OF_MEMORY:
				str = "GL_OUT_OF_MEMORY";
				break;
			case GL_TABLE_TOO_LARGE:
				str = "GL_TABLE_TOO_LARGE";
				break;
#endif
#if GL_EXT_framebuffer_object
			case GL_INVALID_FRAMEBUFFER_OPERATION_EXT:
				str = "GL_INVALID_FRAMEBUFFER_OPERATION_EXT";
				break;
#endif
			default:
				str = "(ERROR: Unknown Error Enum)";
				break;
		}
		
		if(str)
		{
			NSLog(@"GL Error:\n%s", str);
		}
	}
}

#endif
