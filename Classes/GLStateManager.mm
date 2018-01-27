//
//  GLStateManager.m
//  Havoc Video
//
//  Created by Richard Insley on 9/24/10.
//  Copyright 2010 WildWestWare. All rights reserved.
//

#import "GLStateManager.h"
#import "FrameBuffer.h"

static GLStateManager *sharedInstance = nil;
static id rootframebuffer = NULL;

@implementation GLStateManager

#pragma mark -
#pragma mark class instance methods

#pragma mark -
#pragma mark Singleton methods

+(void)setRootFrameBuffer:(id)fb
{
	rootframebuffer = fb;
}

+(id)getRootFrameBuffer
{
	return rootframebuffer;
}

+ (GLStateManager*)sharedInstance
{
    if (sharedInstance == nil)
	{
		sharedInstance = [[GLStateManager alloc] init];
	}
    return sharedInstance;
}

+ (id)allocWithZone:(NSZone *)zone 
{
    @synchronized(self) 
	{
        if (sharedInstance == nil) 
		{
			sharedInstance = [super allocWithZone:zone];
            return sharedInstance;  // assignment and return on first allocation
        }
    }
    return nil; // on subsequent allocation attempts return nil
}

- (void) captureStates
{
	// initialize the states
	GLERROR(glGetIntegerv(GL_CURRENT_PROGRAM, &curprog));
	
	ctexunit = -1;
	for(int i = 0; i < 32; i++)
	{
		curtextures[i] = -1;
	}
}

- (void) resetStates
{
	isValidated = false;
	vcount = 0;
	crendertarget = -1;
	cboundbuffer = NULL;
	vpl = vpt = vpw = vph = -1;
	
	ctexunit = -1;
	for(int i = 0; i < 32; i++)
	{
		curtextures[i] = -1;
	}
}

// test if openGL is in a state where we can access and modify states and bindings
- (bool)validate
{
	if(isValidated) return true;
	
	vcount ++;
	if(vcount > 500)
	{
		// if we are now valid, get a snapshot of the gl states we are interested in
		[self captureStates];
		isValidated = true;
	}
	return isValidated;
}

- (id)init
{
	if ((self = [super init]))
	{
		isValidated = false;
		vcount = 0;
		crendertarget = -1;
		cboundbuffer = NULL;
		vpl = vpt = vpw = vph = -1;
	}
	return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

- (id)retain 
{
    return self;
}

- (unsigned)retainCount 
{
    return UINT_MAX;  // denotes an object that cannot be released
}

- (void)release 
{
    //do nothing
}

- (id)autorelease 
{
    return self;
}

- (void) gluseprogram:(GLuint)program
{
	if([self validate])
	{
		if(program != curprog)
		{
			GLERROR(glUseProgram(program));
			curprog = program;
		}
		#if defined(DEBUG) && defined(LOGDUPLICATES)
		else
		{
			NSLog(@"Duplicate glUseProgram");
		}
		#endif
	}
	else
	{
		GLERROR(glUseProgram(program));
	}
}

- (void) glcopy:(GLuint)dest Width:(int)width Height:(int)height
{
	GLint currentt;
	GLERROR(glGetIntegerv(GL_TEXTURE_BINDING_2D, &currentt));
	GLERROR(glBindTexture(GL_TEXTURE_2D, dest));
	GLERROR(glCopyTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 0, 0, width, height, 0));
	GLERROR(glBindTexture(GL_TEXTURE_2D, currentt));
}

- (void) glbindtexture2d:(GLuint)texture
{
	if([self validate])
	{
		if(curtextures[ctexunit] != texture)
		{
			GLERROR(glBindTexture(GL_TEXTURE_2D, texture));
			curtextures[ctexunit] = texture;
		}
		#if defined(DEBUG) && defined(LOGDUPLICATES)
		else
		{
			NSLog(@"Duplicate glBindTexture 2d for TEXUNIT%d" , ctexunit);
			GLint currentt;
			GLERROR(glGetIntegerv(GL_TEXTURE_BINDING_2D, &currentt));
			if(currentt != texture)
			{
				NSLog(@"Dup bind found %d at address", currentt);
			}
		}
		#endif
	}
	else
	{
		GLERROR(glBindTexture(GL_TEXTURE_2D, texture));
	}
}

- (void) glbindtexturecube:(GLuint)texture
{
	if([self validate])
	{
		if(curtextures[ctexunit] != texture)
		{
			GLERROR(glBindTexture(GL_TEXTURE_CUBE_MAP, texture));
			curtextures[ctexunit] = texture;
		}
		#if defined(DEBUG) && defined(LOGDUPLICATES)
		else
		{
			NSLog(@"Duplicate glBindTexture cube for TEXUNIT%d",ctexunit);
		}
		#endif
	}
	else
	{
		GLERROR(glBindTexture(GL_TEXTURE_CUBE_MAP, texture));
	}
}

- (void) glactivetexture:(GLuint)texunit
{
	if([self validate])
	{
		if(texunit - GL_TEXTURE0 != ctexunit)
		{
			GLERROR(glActiveTexture(texunit));
			ctexunit = texunit - GL_TEXTURE0;
		}
		#if defined(DEBUG) && defined(LOGDUPLICATES)
		else
		{
			NSLog(@"Duplicate glActiveTexture");
		}
		#endif
	}
	else
	{
		GLERROR(glActiveTexture(texunit));
	}
}

- (void) gldeletetexture:(GLuint)texture
{
	GLERROR(glDeleteTextures(1, &texture));
	
	if([self validate])
	{
		// remove any references to this texture
		for(int i= 0; i < 32; i++)
		{
			if(curtextures[i] == texture)
			{
				curtextures[i] = -1;
			}
		}
	}
}

- (void) glviewportLeft:(int)left Top:(int)top Width:(int)width Height:(int)height
{
	if([self validate])
	{
		if(left != vpl || top != vpt || width != vpw || height != vph)
		{
			GLERROR(glViewport(left, top, width, height));
			vpl = left;
			vpt = top;
			vph = height;
			vpw = width;
		}
	}
	else
	{
		GLERROR(glViewport(left, top, width, height));
	}
}

- (void) glbindframebuffer:(id)framebuffer
{
	// GLERROR(glBindFramebuffer(GL_FRAMEBUFFER, ((FrameBuffer*)framebuffer).framebuffer));
	
	if([self validate])
	{
		if(cboundbuffer != framebuffer)
		{
			GLERROR(glBindFramebuffer(GL_FRAMEBUFFER, ((FrameBuffer*)framebuffer).framebuffer));
			cboundbuffer = framebuffer;
		}
	}
	else
	{
		GLERROR(glBindFramebuffer(GL_FRAMEBUFFER, ((FrameBuffer*)framebuffer).framebuffer));
	}
	
	/*
	if([self validate])
	{
		if(!cboundbuffer)
		{
			GLERROR(glBindFramebuffer(GL_FRAMEBUFFER, ((FrameBuffer*)rootframebuffer).framebuffer));
			cboundbuffer = rootframebuffer;
			crendertarget = ((FrameBuffer*)rootframebuffer).colorRenderbuffer;
		}
		
		if(((FrameBuffer*)framebuffer).colorRenderbuffer != -1)
		{
			if(((FrameBuffer*)framebuffer).colorRenderbuffer != crendertarget)
			{
				// set the color connection point to the colorRenderbuffer
				//GLERROR(glBindRenderbuffer(GL_RENDERBUFFER, ((FrameBuffer*)framebuffer).colorRenderbuffer));
				GLint nfb = ((FrameBuffer*)framebuffer).colorRenderbuffer;
				GLERROR(glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, nfb));
				crendertarget = nfb;
				
				// Test the framebuffer for completeness.
				GLERROR(GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER)) ;
				if(status != GL_FRAMEBUFFER_COMPLETE) 
				{
					NSLog(@"failed to make complete framebuffer object %x", status);
				}
			}
		}
		else
		{
			if(((FrameBuffer*)framebuffer).texture != crendertarget)
			{
				// get the current bound texture
				GLint currentt;
				//GLERROR(glGetIntegerv(GL_TEXTURE_BINDING_2D, &currentt));
				
				// bind the texure to the color connection point
				//GLERROR(glBindTexture(GL_TEXTURE_2D, ((FrameBuffer*)framebuffer).texture));
				GLERROR(glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, ((FrameBuffer*)framebuffer).texture, 0));
				
				//GLERROR(glBindTexture(GL_TEXTURE_2D, currentt));
				
				crendertarget = ((FrameBuffer*)framebuffer).texture;
			}
		}
	}
	else
	{
		GLERROR(glBindFramebuffer(GL_FRAMEBUFFER, ((FrameBuffer*)framebuffer).framebuffer));
	}
	*/
}

@end
