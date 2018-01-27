//
//  ES2Renderer.m
//  VideoTexture
//
//  Created by Richard Insley on 8/17/10.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import "ES2Renderer.h"

// uniform index
enum {
    UNIFORM_TRANSLATE,
    NUM_UNIFORMS
};
GLint uniforms[NUM_UNIFORMS];

// attribute index
enum {
    ATTRIB_VERTEX,
    ATTRIB_COLOR,
	ATTRIB_TEX0,	
	ATTRIB_TEX1,
    NUM_ATTRIBUTES
};

@interface ES2Renderer (PrivateMethods)
- (BOOL)loadShaders;
- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file;
- (BOOL)linkProgram:(GLuint)prog;
- (BOOL)validateProgram:(GLuint)prog;
@end

@implementation ES2Renderer

@synthesize isInitialized;
@synthesize videoTextureLock;
@synthesize orientation;

static const double kUserAccelerationLpfCutoffFrequency = 10.0;

// Create an OpenGL ES 2.0 context
- (id)init
{
    if ((self = [super init]))
    {
		_setReferenceAttitude = false;
		
		backingSet = false;
		
		scripts[0] = nil;
		currentScriptID = -1;
		
		videoTextureLock = nil;
		
		effectglobals = nil;
		
		isInitialized = false;
		_isRecording = false;
		_isPaused = false;
		
		videoWriter = nil;
		
		fb = NULL;
		fbp = NULL;
		fbl = NULL;
		
		script = NULL;
		
		// gyroscope values
		accelMode = FALSE;
		motionManager = nil;
		locationManager = nil;
		
		referenceAttitude = nil;
		translationEnabled = FALSE;
		userAccelerationLpf = [[LowpassFilter alloc] initWithCutoffFrequency:kUserAccelerationLpfCutoffFrequency];
		
		compiledShaders = [[NSMutableDictionary alloc] initWithCapacity:255];
		
        context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];

        if (!context || ![EAGLContext setCurrentContext:context] || ![self loadShaders])
        {
            [self release];
            return nil;
        }
		
		// create the default render targets for processing (one for portrait, one for landscape)
		fbp = [[FrameBuffer alloc] initWithWidth:VHEIGHT Height:VWIDTH CreateTexture:true UsesReadPixels:true];
		fbl = [[FrameBuffer alloc] initWithWidth:VWIDTH Height:VHEIGHT CreateTexture:true UsesReadPixels:true];
		
		fbl.isFlipped = fbp.isFlipped = false;
		
		// we'll default to landscape and switch to portrait only when recording portrait
		fb = fbl;
		
        // Create default framebuffer object. The backing will be allocated for the current layer in -resizeFromLayer
        GLERROR(glGenFramebuffers(1, &defaultFramebuffer));
		
        GLERROR(glGenRenderbuffers(1, &colorRenderbuffer));
        GLERROR(glBindFramebuffer(GL_FRAMEBUFFER, defaultFramebuffer));
		
        GLERROR(glBindRenderbuffer(GL_RENDERBUFFER, colorRenderbuffer));
        GLERROR(glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, colorRenderbuffer));

		
		//GLERROR(glBindFramebuffer(GL_FRAMEBUFFER, defaultFramebuffer));
		displayBuffer = [[FrameBuffer alloc] initWithFrameBuffer:defaultFramebuffer ColorBuffer:colorRenderbuffer];
		MGLBINDFRAMEBUFFER(displayBuffer);
		
		GLERROR(glEnable(GL_BLEND));
		
		// Set a blending function appropriate for premultiplied alpha pixel data
		GLERROR(glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA));
		
		GLERROR(glDisable(GL_DEPTH_TEST));
		GLERROR(glDisable(GL_CULL_FACE));
		
		// let all framebuffers know who's boss
		[GLStateManager setRootFrameBuffer:displayBuffer];
    }

    return self;
}

-(void)initMotionManager
{
	// Create our CMMotionManager instance
	if (motionManager == nil) {
		motionManager = [[CMMotionManager alloc] init];
	}
	
	// Turn on the appropriate type of data
	motionManager.accelerometerUpdateInterval = 0.01;
	motionManager.deviceMotionUpdateInterval = 0.05;
	if (accelMode) {
		[motionManager startAccelerometerUpdates];
	} else {
		[motionManager startDeviceMotionUpdates];
	}
	
	rotx = roty = rotz = 0.0;
	
	referenceAttitude = nil;	
}

-(bool)addScript:(NSString*)scriptName
{
#if DEBUG
	NSLog(@"Loading script %@" , scriptName);
#endif
	
	// create a new script and append to array of available
	EffectScript * ns = NULL;
	try {
		ns = [self loadEffect:scriptName];
		scripts[scriptCount] = ns;
		scriptCount++;
	}
	catch (...) 
	{
		NSLog(@"Error loading Effect Script");
		return false;
	}
	
	return true;
}

-(void)setCurrentScript:(int)newID
{
	if(isInitialized && currentScriptID != newID)
	{
		// prevent the video buffer from updating the opengl texture while we are busy scrambling around the new effect structure
		[videoTextureLock lock];
		
		// reset the MGL states
		MGLRESET();
		
		// deinit the current script
		if(script)
		{
			script->Deinit();
		}
		
		// get the new script and initialize it
		currentScriptID = newID;
		script = scripts[newID];
		script->Init();
		
		// update the reference to what's forward
		_setReferenceAttitude = true;
		
		[videoTextureLock unlock];
	}
}

-(EffectScript**)GetScripts
{
	return scripts;
}

- (void)incEffect
{
	if(isInitialized)
	{
		int neffect = currentScriptID;
		neffect++;
		if(neffect == scriptCount) neffect = 0;
		[self setCurrentScript:neffect];
	}
}

- (void)decEffect
{
	if(isInitialized)
	{
		int neffect = currentScriptID;
		neffect--;
		if(neffect == -1) neffect = scriptCount - 1;
		[self setCurrentScript:neffect];
	}
}

- (void)renderToSampleBuffer:(CMTime)timestamp
{
	if(isInitialized)
	{
		// MGLCAPTURESTATES();
		
		//vec3f_t translation = {0.0f, 0.0f, -0.40f};
		CMRotationMatrix rotation;
		CMAcceleration userAcceleration;
		
		// get the motion data
		if(motionManager)
		{
			CMDeviceMotion *deviceMotion = motionManager.deviceMotion;		
			CMAttitude *attitude = deviceMotion.attitude;
			CMRotationRate rotate = deviceMotion.rotationRate;
			
			// If we have a reference attitude, multiply attitude by its inverse
			// After this call, attitude will contain the rotation from referenceAttitude
			// to the current orientation instead of from the fixed reference frame to the
			// current orientation
			if(_setReferenceAttitude)
			{
				[referenceAttitude release];
				referenceAttitude = [attitude retain];
				_setReferenceAttitude = false;
			}
			
			if (referenceAttitude != nil) 
			{
				[attitude multiplyByInverseOfAttitude:referenceAttitude];
			}
			rotation = attitude.rotationMatrix;
			
			rotx = (attitude.roll + PI) / (2.0 * PI);
			roty = (attitude.pitch + PI) / (2.0 * PI);
			rotz = (attitude.yaw + PI) / (2.0 * PI);
		}
		
		// get the time from the sample buffer and convert to seconds
		double stime = CMTimeGetSeconds(timestamp);
		
		// use the script to render

		GLfloat rotMat[9];
		
		// tranpose rotation matrix
		rotMat[0] = rotation.m11;
		rotMat[1] = rotation.m21;
		rotMat[2] = rotation.m31;
		rotMat[3] = rotation.m12;
		rotMat[4] = rotation.m22;
		rotMat[5] = rotation.m32;
		rotMat[6] = rotation.m13;
		rotMat[7] = rotation.m23;
		rotMat[8] = rotation.m33;
		
		// prevent the video texture form being updated while we access opengl resources
		[videoTextureLock lock];
		
		script->Render(fb, stime, rotx, roty, rotz, [videoTexture getPowerLevel], rotMat, (int)orientation);
		
		// copy the contents of opengl backbuffer into the sample buffer
		if(_isRecording && videoWriter && !_isPaused)
		{
			if([videoWriter isReadyForMoreMediaData])
			{
				CVPixelBufferRef pb = [videoWriter getPixelBuffer];
				
				CVPixelBufferLockBaseAddress( pb, 0 );
				unsigned char* linebase = (unsigned char *)CVPixelBufferGetBaseAddress( pb );
				[fb readPixels:linebase];
				
				CVPixelBufferUnlockBaseAddress( pb, 0 );
				
				[videoWriter appendPixelBuffer:pb TimeStamp:timestamp];
			}
		}
		
		// copy media buffer to display
		[self displayMedia];
		
		[videoTextureLock unlock];
	}
}

// get the duration from the video writer if it is available
-(double)getDuration
{
	if(videoWriter)
	{
		return [videoWriter getDuration];
	}
	
	return 0;
}

-(void)processAudio:(CMSampleBufferRef)sampleBuffer
{
	if(isInitialized && _isRecording && videoWriter && !_isPaused)
	{
		[videoWriter appendSampleBuffer:sampleBuffer];
	}
	
	CFRelease(sampleBuffer);
}

-(void)displayMedia
{
	int width, height;
	bool isPortrait = [fb getIsPortrait];
	bool isFlipped = fb.isFlipped;
	
	// get value to scale viewports width to hide padded pixels in buffers who are not a multiple of 32
	// Curse you PowerVR, and your nifty tiled based defered rendering!
	float viewportWidthScale = 1.0;
	
	if(isPortrait)
	{
		// these will be swapped in portrait mode
		height = [fb getWidth];
		width = [fb getHeight];
		
		int awidth = [fb getActualWidth];
		if(awidth != height)
		{
			viewportWidthScale = (float)awidth / (float)height;
		}
	}
	else
	{
		width = [fb getWidth];
		height = [fb getHeight];
		
		int awidth = [fb getActualWidth];
		if(awidth != width)
		{
			viewportWidthScale = (float)awidth / (float)width;
		}
	}
	
	float ar = (float)height / (float)width;
	float iar = (float)width / (float)height;
	
	// create quad in order of TL BL BR TR
	GLfloat squareVertices[] = 
    {
		-1.0f, -1.0f * iar,
		-1.0f, 1.0f * iar,
		1.0f, 1.0f * iar,
		1.0f, -1.0f * iar
    };
	
	// we want the uv coords to keep the video oriented to the iphone's upright portrait mode
	static const GLfloat lTexCoords[] = 
	{
		1.0f, 1.0f,
		0.0f, 1.0f,
        0.0f, 0.0f,
        1.0f, 0.0f,
	};
	
	static const GLfloat pTexCoords[] = 
	{
		1.0f, 0.0f,
		1.0f, 1.0f,
		0.0f, 1.0f,
        0.0f, 0.0f,
	};
	
    // This application only creates a single context which is already set current at this point.
    // This call is redundant, but needed if dealing with multiple contexts.
    [EAGLContext setCurrentContext:self->context];
	
	
	// set the render buffer created by the CEAGLContext
	//GLERROR(glBindFramebuffer(GL_FRAMEBUFFER, self->defaultFramebuffer));
	MGLBINDFRAMEBUFFER(self->displayBuffer);
	
	int viewoffset = 54;
	
	// 426 is the magic number to keep the aspect ratio.
	// Scoot up 54 and reduce viewport height by 54 so we can place the toolbar.
	// Check if buffer width is not a multiple of 32 and extend viewport width to exclude
	// trailing pixels.
	MGLVIEWPORT(0, 0, ceil(self->backingWidth * viewportWidthScale), self->backingHeight - viewoffset);
	
    // Use th defalt display shader program
    MGLUSEPROGRAM(program);
	
	GLERROR(unsigned int loc1 = glGetUniformLocation(program , "projMat"));
	if(loc1 != -1)
	{
		GLfloat modelView[16];
		GLfloat projection[16];
		GLfloat mvp[16];
		
		mtxLoadPerspective(projection, 90, ar, 0 , 1);
		
		// translate to the inverse aspect ratio
		mtxLoadTranslate(modelView, 0, 0, -1.0 * iar);
		
		if(isPortrait)
		{
			if(!isFlipped)
			{
				mtxRotateZApply(modelView, 180.0);
			}
		}
		else
		{
			if(isFlipped)
			{
				mtxRotateZApply(modelView, 180.0);
			}
		}
		
		mtxMultiply(mvp, projection, modelView);
		
		GLERROR(glUniformMatrix4fv(loc1, 1, GL_FALSE, mvp));
	}
	
	GLERROR(glClearColor(0.0f, 0.0f, 0.0f, 1.0f));
	GLERROR(glClear(GL_COLOR_BUFFER_BIT));
	
	// set the texture to primary FrameBuffer texture
	MGLACTIVETEXTURE(GL_TEXTURE0);
	MGLBINDTEXTURE2D([self->fb getTexture]);
	
    GLERROR(glVertexAttribPointer(ATTRIB_VERTEX, 2, GL_FLOAT, 0, 0, squareVertices));
    GLERROR(glEnableVertexAttribArray(ATTRIB_VERTEX));

	GLERROR(glVertexAttribPointer(ATTRIB_TEX0, 2, GL_FLOAT, 0, 0, isPortrait ? pTexCoords : lTexCoords));
    GLERROR(glEnableVertexAttribArray(ATTRIB_TEX0));
    
    // Validate program before drawing. This is a good check, but only really necessary in a debug build.
    // DEBUG macro must be defined in your debug configurations if that's not already the case.
#if defined(DEBUG)
    if (![self validateProgram:program])
    {
        NSLog(@"Failed to validate program: %d", program);
        return;
    }
#endif
	
    // Draw
    GLERROR(glDrawArrays(GL_TRIANGLE_FAN, 0, 4));
	
  // This application only creates a single color renderbuffer which is already bound at this point.
  // This call is redundant, but needed if dealing with multiple renderbuffers.
  GLERROR(glBindRenderbuffer(GL_RENDERBUFFER, self->colorRenderbuffer));
  
  // glReadPixels should be done before calling this!!
  [self->context presentRenderbuffer:GL_RENDERBUFFER];
}

- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file
{
    GLint status;
    const GLchar *source;

    source = (GLchar *)[[NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil] UTF8String];
    if (!source)
    {
        NSLog(@"Failed to load vertex shader");
        return FALSE;
    }

    GLERROR(*shader = glCreateShader(type));
    GLERROR(glShaderSource(*shader, 1, &source, NULL));
    GLERROR(glCompileShader(*shader));

#if defined(DEBUG)
    GLint logLength;
    GLERROR(glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength));
	
    if (logLength > 0)
    {
        GLchar *log = (GLchar *)malloc(logLength);
        GLERROR(glGetShaderInfoLog(*shader, logLength, &logLength, log));
        NSLog(@"Shader compile log:\n%s", log);
        free(log);
    }
#endif

    GLERROR(glGetShaderiv(*shader, GL_COMPILE_STATUS, &status));
    if (status == 0)
    {
        GLERROR(glDeleteShader(*shader));
        return FALSE;
    }

    return TRUE;
}

- (BOOL)linkProgram:(GLuint)prog
{
    GLint status;

    GLERROR(glLinkProgram(prog));

#if defined(DEBUG)
    GLint logLength;
    GLERROR(glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength));
    if (logLength > 0)
    {
        GLchar *log = (GLchar *)malloc(logLength);
        GLERROR(glGetProgramInfoLog(prog, logLength, &logLength, log));
        NSLog(@"Program link log:\n%s", log);
        free(log);
    }
#endif

    GLERROR(glGetProgramiv(prog, GL_LINK_STATUS, &status));
    if (status == 0)
        return FALSE;

    return TRUE;
}

- (BOOL)validateProgram:(GLuint)prog
{
    GLint logLength, status;

    GLERROR(glValidateProgram(prog));
    GLERROR(glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength));
    if (logLength > 0)
    {
        GLchar *log = (GLchar *)malloc(logLength);
        GLERROR(glGetProgramInfoLog(prog, logLength, &logLength, log));
        NSLog(@"Program validate log:\n%s", log);
        free(log);
    }

    GLERROR(glGetProgramiv(prog, GL_VALIDATE_STATUS, &status));
    if (status == 0)
        return FALSE;

    return TRUE;
}

- (EffectScript*)loadEffect:(NSString *)effectFile
{
	// see if we already loaded the effect globals into an nsstring
	if(!effectglobals)
	{
		NSString * gpath = [[NSBundle mainBundle] pathForResource:@"ScriptGlobals" ofType:@"effect"];
		effectglobals = [NSString stringWithContentsOfFile:gpath encoding:NSUTF8StringEncoding error:nil];
	}
	
	// translate the effect file into the true package path
	NSString * path = [[NSBundle mainBundle] pathForResource:effectFile ofType:@"effect"];
	
	// load script and append to end of globals string
	unsigned char * source = (unsigned char *)[[effectglobals stringByAppendingString:[NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil]] UTF8String];
	if (!source)
    {
        NSLog(@"Failed to load vertex shader");
        return FALSE;
    }
	
	EffectScript* scr = new EffectScript(effectlib, source, (void*)self, fb, [videoTexture getVideoBuffer]);
	
	return scr;
}

- (BOOL)loadShaders
{	
    GLuint vertShader, fragShader;
    NSString *vertShaderPathname, *fragShaderPathname;

    // Create shader program
    GLERROR(program = glCreateProgram());

    // Create and compile vertex shader
    vertShaderPathname = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"vsh"];
    if (![self compileShader:&vertShader type:GL_VERTEX_SHADER file:vertShaderPathname])
    {
        NSLog(@"Failed to compile vertex shader");
        return FALSE;
    }

    // Create and compile fragment shader
    fragShaderPathname = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"fsh"];
    if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:fragShaderPathname])
    {
        NSLog(@"Failed to compile fragment shader");
        return FALSE;
    }

    // Attach vertex shader to program
    GLERROR(glAttachShader(program, vertShader));

    // Attach fragment shader to program
    GLERROR(glAttachShader(program, fragShader));

    // Bind attribute locations
    // this needs to be done prior to linking
    GLERROR(glBindAttribLocation(program, ATTRIB_VERTEX, "position"));
	GLERROR(glBindAttribLocation(program, ATTRIB_TEX0, "inTexcoord"));
    //GLERROR(glBindAttribLocation(program, ATTRIB_COLOR, "color"));

    // Link program
    if (![self linkProgram:program])
    {
        NSLog(@"Failed to link program: %d", program);

        if (vertShader)
        {
            GLERROR(glDeleteShader(vertShader));
            vertShader = 0;
        }
        if (fragShader)
        {
            GLERROR(glDeleteShader(fragShader));
            fragShader = 0;	
        }
        if (program)
        {
            GLERROR(glDeleteProgram(program));
            program = 0;
        }
        
        return FALSE;
    }

	MGLUSEPROGRAM(program);
	
    // Get uniform locations / this will assign the id for the parameter "translate" found in the vertex shader
    GLERROR(uniforms[UNIFORM_TRANSLATE] = glGetUniformLocation(program, "translate"));

	// get the uniform position for diffuseTexture
	GLERROR(GLint samplerLoc = glGetUniformLocation(program, "diffuseTexture"));
	
	// Indicate that the diffuse texture will be bound to texture unit 0
	GLint unit = 0;
	GLERROR(glUniform1i(samplerLoc, unit));
	
    // Release vertex and fragment shaders
    if (vertShader)
        glDeleteShader(vertShader);
    if (fragShader)
        glDeleteShader(fragShader);

    return TRUE;
}

- (BOOL)resizeFromLayer:(CAEAGLLayer *)layer
{
	// we only want to do this once.  If the backing is set when elements are animating, it will lock the phone
	if(!backingSet)
	{
		GLint tb;
		GLERROR(glGetIntegerv(GL_FRAMEBUFFER_BINDING, &tb));
		// Allocate color buffer backing based on the current layer size
		GLERROR(glBindRenderbuffer(GL_RENDERBUFFER, colorRenderbuffer));
		[context renderbufferStorage:GL_RENDERBUFFER fromDrawable:layer];
		GLERROR(glGetIntegerv(GL_FRAMEBUFFER_BINDING, &tb));
		
		GLERROR(glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &backingWidth));
		GLERROR(glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &backingHeight));
		
		if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
		{
			NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
			return NO;
		}
		
		[self initMotionManager];
		
		backingSet = true;
	}
	
    return YES;
}

- (void)dealloc
{	
    // Tear down GL
    if (defaultFramebuffer)
    {
        GLERROR(glDeleteFramebuffers(1, &defaultFramebuffer));
        defaultFramebuffer = 0;
    }

    if (colorRenderbuffer)
    {
        GLERROR(glDeleteRenderbuffers(1, &colorRenderbuffer));
        colorRenderbuffer = 0;
    }

    if (program)
    {
        GLERROR(glDeleteProgram(program));
        program = 0;
    }

	if(fbl)
	{
		[fbl release];
		fbl = NULL;
	}
	
	if(fbp)
	{
		[fbp release];
		fbp = NULL;
	}
	
    // Tear down context
    if ([EAGLContext currentContext] == context)
        [EAGLContext setCurrentContext:nil];

    [context release];
    context = nil;

	if(videoTextureLock)
	{
		[videoTextureLock release];
		videoTextureLock = NULL;
	}
	
    [super dealloc];
}    

- (BOOL)isRecording
{
	return (videoWriter != NULL && _isRecording);
}

- (void)startRecording:(UIInterfaceOrientation)orientation
{	
	if([self isRecording] && _isPaused)
	{
		_isPaused = false;
		return;
	}
	
	[videoTextureLock lock];
	
	// set the correct render target for the orientation
	switch (orientation)
	{
		case UIInterfaceOrientationPortrait:
			// 90 in radians
			fb = fbp;
			fb.isFlipped = false;
			videoWriter = [[VideoWriter alloc] initWithParams:@"movie.mov" Width:VHEIGHT Height:VWIDTH Audio:USEAUDIO Orientation:orientation];
			break;
		case UIInterfaceOrientationPortraitUpsideDown:
			// -90 in radians
			fb = fbp;
			fb.isFlipped = true;
			videoWriter = [[VideoWriter alloc] initWithParams:@"movie.mov" Width:VHEIGHT Height:VWIDTH Audio:USEAUDIO Orientation:orientation];
			break;
		case UIInterfaceOrientationLandscapeLeft:
			// 180 in radians
			fb = fbl;
			fb.isFlipped = true;
			videoWriter = [[VideoWriter alloc] initWithParams:@"movie.mov" Width:VWIDTH Height:VHEIGHT Audio:USEAUDIO Orientation:orientation];
			break;
		case UIInterfaceOrientationLandscapeRight:
			// do nothing, this is the natural orientation of the recording
			// assetWriterInput.transform = CGAffineTransformMakeRotation(0);
			fb = fbl;
			fb.isFlipped = false;
			videoWriter = [[VideoWriter alloc] initWithParams:@"movie.mov" Width:VWIDTH Height:VHEIGHT Audio:USEAUDIO Orientation:orientation];
			break;
		default:
			// 90 in radians
			fb = fbp;
			fb.isFlipped = false;
			videoWriter = [[VideoWriter alloc] initWithParams:@"movie.mov" Width:VHEIGHT Height:VWIDTH Audio:USEAUDIO Orientation:orientation];
			break;
	}
	
	_isRecording = true;
	
	[videoTextureLock unlock];
}

- (NSString*)stopRecording;
{	
	_isPaused = false;
	_isRecording = false;
	[videoWriter stopRecording];
	
	// set to normal landscape framebuffer
	fb = fbl;
	fb.isFlipped = false;
	
	NSLog(@"videoWriter path: %@", [videoWriter getPath]);
	NSString * path = [videoWriter getPath];
	[videoWriter release];
	videoWriter = NULL;
	
	return path;
}

-(void)pauseRecording
{
	_isPaused = true;
}

-(void)stopCapture
{
	if (videoTexture != nil && videoTexture.isCapturing) 
	{
		[videoTexture stop];
		
		// deinit the current script
		if(script)
		{
			[videoTextureLock lock];
			script->Deinit();
			[videoTextureLock unlock];
		}
	}
}

-(void)loadScripts
{
	// load all the effect scripts here so they can be aware of the video texture
	scriptCount = 0;
	
	[self addScript:@"default"];
	[self addScript:@"InverseChroma"];
	[self addScript:@"Gold"];
	[self addScript:@"Smudged"];
	[self addScript:@"sangria"];
	[self addScript:@"MandelWarp"];
	[self addScript:@"Sobel"];
	[self addScript:@"Warhol"];
	[self addScript:@"LockLUT"];
	[self addScript:@"Rose"];
	[self addScript:@"emerald"];
	[self addScript:@"Breathe"];
	[self addScript:@"heartShapedBox"];
	[self addScript:@"Flint"];
	[self addScript:@"Weave"];
	[self addScript:@"GreyDeliniate"];
	[self addScript:@"Droste"];
	[self addScript:@"Reptile"];
	[self addScript:@"UltraViolet"];
	[self addScript:@"Smiley"];
	[self addScript:@"Star"];
	[self addScript:@"Famine"];
	[self addScript:@"Bleached"];
	//[self addScript:@"Wonderland"];
	[self addScript:@"Concentric"];
	[self addScript:@"Zodiac"];
	[self addScript:@"Yarn"];
	[self addScript:@"RadiateBlur"];
	[self addScript:@"saphire"];
	[self addScript:@"Toon"];
	[self addScript:@"Feast"];
	[self addScript:@"Monochrome"];
	[self addScript:@"Etching"];
	[self addScript:@"kaleidoscope"];
	[self addScript:@"Spectrum"];
	[self addScript:@"AllStars"];
	[self addScript:@"SpinSprite"];
	[self addScript:@"Foil"];
	[self addScript:@"HotIce"];
	[self addScript:@"NegativeZone"];
	[self addScript:@"HalfTone"];
	[self addScript:@"SuperSymetry"];
	[self addScript:@"HueShift"];
	[self addScript:@"Neon"];
	[self addScript:@"Sinusoidal"];
	[self addScript:@"PinchWhirl"];
	
	[self addScript:@"divots"];
	[self addScript:@"InfZoom"];
	[self addScript:@"Shattered"];
	[self addScript:@"iris"];
	[self addScript:@"frozen"];
	[self addScript:@"qbert"];
	[self addScript:@"bumptest"];
	[self addScript:@"fishtank"];
    
	// set current script to 0
	[videoTextureLock lock];

	currentScriptID = 0;
	script = scripts[0];
	script->Init();
	
	[videoTextureLock unlock];
	
	isInitialized = true;
	
	// announce the renderer is fully initialized
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	[notificationCenter postNotificationName:@"rendererInitialized" object:NULL];
}

-(void)startCapture
{
	if (videoTexture == nil) 
	{
		// we've not been initialized yet
		videoTextureLock = [[NSLock alloc] init];
		
		// the video texture must be the first texture generated
		videoTexture = [[[VideoBuffer alloc] initWithWidth:VWIDTH Audio:USEAUDIO UseFrontDevice:false LockObject:videoTextureLock Context:context] retain];
		
		// starting the videoTexture sets the openGL rendering in motion
		[videoTexture start];
		
		[self loadScripts];
		
	}
	else if (!videoTexture.isCapturing) 
	{
		// re-init the current script
		if(script)
		{
			// reset the managed states to prevent confusion over changes made externally
			MGLRESET();
			[videoTextureLock lock];
			script->Init();
			[videoTextureLock unlock];
		}
		
		[videoTexture start];
	}
}

// camera control method pass throughs

-(bool)isFrontCamera
{
	return [videoTexture isFrontCamera];
}

-(void)setFrontCamera:(bool)useFront
{
	[videoTexture setFrontCamera:useFront];
}

-(void)enableLamp:(bool)enable
{
	[videoTexture enableLamp:enable];
}

-(bool)isLampEnabled
{
	return [videoTexture isLampEnabled];
}

@end

int renderToFrameBuffer(lua_State *L)
{
	// void * renderer, unsigned int programid, unsigned int bufferid
	ES2Renderer * me = (ES2Renderer*)luaL_checkinteger(L, 1);
	
	if(!me)
	{
		return 0;
	}
	
	GLint program = luaL_checkinteger(L, 2);
	GLint bufferid = luaL_checkinteger(L, 3);
	bool clear = luaL_checkinteger(L, 4);
	float rotate = luaL_checknumber(L, 5);
	float scaleX = luaL_checknumber(L, 6);
	float scaleY = luaL_checknumber(L, 7);
	float posX = luaL_checknumber(L, 8);
	float posY = luaL_checknumber(L, 9);
	
	static const GLfloat texCoords[] = {
		0.0f, 1.0f,
        1.0f, 1.0f,
        1.0f, 0.0f,
        0.0f, 0.0f,
	};
	
	/*
    static const GLubyte squareColors[] = {
        255, 255, 255, 255,
        255, 255, 255, 255,
        255, 255, 255, 255,
        255, 255, 255, 255,
    };
	*/
	
    // This application only creates a single context which is already set current at this point.
    // This call is redundant, but needed if dealing with multiple contexts.
    [EAGLContext setCurrentContext:me->context];
	
	int width, height;
	
	if([me isFrontCamera] && ((FrameBuffer*)bufferid) == me->fb)
	{
		// flip the y coords if the camrea is front and rendering to the default buffer
		scaleY *= -1.0;
	}
	
	FrameBuffer* targetfb = me->fb;
	
	if(bufferid == 0)
	{
		width = me->backingWidth;
		height = me->backingHeight;
		
		// set the render buffer created by the CEAGLContext
		//GLERROR(glBindFramebuffer(GL_FRAMEBUFFER, me->defaultFramebuffer));
		MGLBINDFRAMEBUFFER(me->displayBuffer);
		
		MGLVIEWPORT(0, 0, me->backingWidth, me->backingHeight);
	}
	else 
	{
		// set the frame buffer as a render target
		targetfb = (FrameBuffer*)bufferid;
		[targetfb setRenderTarget];
		
		width = [targetfb getWidth];
		height = [targetfb getHeight];
		
		MGLVIEWPORT(0, 0, width , height);
	}
	
	bool isPortrait = [targetfb getIsPortrait];
	bool isFlipped = targetfb.isFlipped;
	
	// create quad in order of BL BR TR TL
	
	float iar;
	float ar;
	

	GLfloat squareVertices[] = 
	{
		-1.0f, 1.0f,
		1.0f, 1.0f,
		1.0f, -1.0f,
		-1.0f, -1.0f
    };
	
	if(isPortrait)
	{
		iar = (float)height / (float)width;
		ar = (float)width / (float)height;
		
		posX *= iar;
		//posY *= iar;
		
		squareVertices[1] *= ar;
		squareVertices[3] *= ar;
		squareVertices[5] *= ar;
		squareVertices[7] *= ar;
	}
	else
	{
		iar = (float)height / (float)width;
		ar = (float)width / (float)height;
		
		posX *= 1.78; // <- figure this out
		posY *= ar;
		
		squareVertices[0] *= ar;
		squareVertices[2] *= ar;
		squareVertices[4] *= ar;
		squareVertices[6] *= ar;
	}

	
	if(clear)
	{
		GLERROR(glClearColor(0.0f, 0.0f, 0.0f, (clear == 1 ? 0.0f : 1.0f)));
		GLERROR(glClear(GL_COLOR_BUFFER_BIT));
	}
	
    // Use shader program
    MGLUSEPROGRAM(program);
		
	GLERROR(unsigned int loc1 = glGetUniformLocation(program,"projMat"));
	if(loc1 != -1)
	{
		GLfloat modelView[16];
		GLfloat projection[16];
		GLfloat mvp[16];
		
		mtxLoadPerspective(projection, 90, ar, 0 , 1);
		
		if(isPortrait)
		{
			if(!isFlipped)
			{
				mtxRotateZApply(projection, 90);
			}
			else
			{
				mtxRotateZApply(projection, -90);
			}
		}
		else
		{
			if(isFlipped)
			{
				mtxRotateZApply(projection, 180.0);
			}
		}
		
		// translate to the inverse aspect ratio
		mtxLoadTranslate(modelView, posX, posY, -1.0);
		
		if(rotate != 0)
		{
			mtxRotateZApply(modelView, rotate);
		}
		
		if(scaleX != 1.0 || scaleY != 1.0)
		{
			mtxScaleApply(modelView, scaleX, scaleY, 1.0);
		}
		
		mtxMultiply(mvp, projection, modelView);
		GLERROR(glUniformMatrix4fv(loc1, 1, GL_FALSE, mvp));
	}
	
	/*
	// set the video texture to GL_TEXTURE0
	MGLACTIVETEXTURE(GL_TEXTURE0);
	MGLBINDTEXTURE2D([me->videoTexture CameraTexture]);
	*/
	
    GLERROR(glVertexAttribPointer(ATTRIB_VERTEX, 2, GL_FLOAT, 0, 0, squareVertices));
    GLERROR(glEnableVertexAttribArray(ATTRIB_VERTEX));

	GLERROR(glVertexAttribPointer(ATTRIB_TEX0, 2, GL_FLOAT, 2, 0, texCoords));
    GLERROR(glEnableVertexAttribArray(ATTRIB_TEX0));
	
    // Validate program before drawing. This is a good check, but only really necessary in a debug build.
    // DEBUG macro must be defined in your debug configurations if that's not already the case.
#if defined(DEBUG)
    if (![me validateProgram:program])
    {
        NSLog(@"Failed to validate program: %d", program);
        return 0;
    }
#endif
	
    // Draw
    GLERROR(glDrawArrays(GL_TRIANGLE_FAN, 0, 4));
	
	if(bufferid == 0)
	{
		// This application only creates a single color renderbuffer which is already bound at this point.
		// This call is redundant, but needed if dealing with multiple renderbuffers.
		GLERROR(glBindRenderbuffer(GL_RENDERBUFFER, me->colorRenderbuffer));
		
		// glReadPixels should be done before calling this!!
		[me->context presentRenderbuffer:GL_RENDERBUFFER];
	}
	
	return 0;
}

int renderParticlesToFrameBuffer(lua_State *L)
{
	// void * renderer, unsigned int programid, unsigned int bufferid
	ES2Renderer * me = (ES2Renderer*)luaL_checkinteger(L, 1);
	
	if(!me)
	{
		return 0;
	}
	
	GLint program = luaL_checkinteger(L, 2);
	GLint bufferid = luaL_checkinteger(L, 3);
	bool clear = luaL_checkinteger(L, 4);

	FloatArray *posx = (FloatArray *)lua_touserdata(L, 5);
	FloatArray *posy = (FloatArray *)lua_touserdata(L, 6);
	FloatArray *scalex = (FloatArray *)lua_touserdata(L, 7);
	FloatArray *scaley = (FloatArray *)lua_touserdata(L, 8);
	FloatArray *rot = (FloatArray *)lua_touserdata(L, 9);
	FloatArray *tu = (FloatArray *)lua_touserdata(L, 10);
	FloatArray *tv  = (FloatArray *)lua_touserdata(L, 11);
	
	static const GLfloat texCoords[] = {
		0.0f, 1.0f,
        1.0f, 1.0f,
        1.0f, 0.0f,
        0.0f, 0.0f,
	};
	
	// the secondary texture coordinates
	GLfloat uvCoords[8];
	
	/*
	 static const GLubyte squareColors[] = {
	 255, 255, 255, 255,
	 255, 255, 255, 255,
	 255, 255, 255, 255,
	 255, 255, 255, 255,
	 };
	 */
	
	
    // This application only creates a single context which is already set current at this point.
    // This call is redundant, but needed if dealing with multiple contexts.
    [EAGLContext setCurrentContext:me->context];
	
	int width, height;
	
	if(bufferid == 0)
	{
		width = me->backingWidth;
		height = me->backingHeight;
		
		// set the render buffer created by the CEAGLContext
		//GLERROR(glBindFramebuffer(GL_FRAMEBUFFER, me->defaultFramebuffer));
		MGLBINDFRAMEBUFFER(me->displayBuffer);
		
		MGLVIEWPORT(0, 0, me->backingWidth, me->backingHeight);
	}
	else 
	{
		// set the frame buffer as a render target
		FrameBuffer* rfb = (FrameBuffer*)bufferid;
		[rfb setRenderTarget];
		
		width = [rfb getWidth];
		height = [rfb getHeight];
		
		MGLVIEWPORT(0, 0, width , height);
	}
	
	// create quad in order of BL BR TR TL
	
	float iar = (float)height / (float)width;
	float ar = (float)width / (float)height;
	
	// create quad in order of TL BL BR TR ( we want particles to be square, not aspect ratio adjusted)
	GLfloat squareVertices[] = {
		-1.0f, 1.0f,
		1.0f, 1.0f,
		1.0f, -1.0f,
		-1.0f, -1.0f
    };
	
	if(clear)
	{
		GLERROR(glClearColor(0.0f, 0.0f, 0.0f, (clear == 1 ? 0.0f : 1.0f)));
		GLERROR(glClear(GL_COLOR_BUFFER_BIT));
	}
	
    // Use shader program
    MGLUSEPROGRAM(program);
	
	GLERROR(unsigned int loc1 = glGetUniformLocation(program,"projMat"));
	
	for(int i = 0; i < posx->size; i++)
	{
		GLfloat modelView[16];
		GLfloat projection[16];
		GLfloat mvp[16];
		
		
		if(loc1 != -1)
		{
			mtxLoadPerspective(projection, 90, ar, 0 , 1);
			
			// translate to the inverse aspect ratio
			mtxLoadTranslate(modelView, 0, 0, -1.0);
			
			mtxTranslateApply(modelView, posx->values[i], posy->values[i], 0.0);
			mtxScaleApply(modelView, scalex->values[i], scaley->values[i], 1.0);
			mtxRotateZApply(modelView, rot->values[i]);
			mtxMultiply(mvp, projection, modelView);
			GLERROR(glUniformMatrix4fv(loc1, 1, GL_FALSE, mvp));
		}
		
		// set the video texture to GL_TEXTURE0
		MGLACTIVETEXTURE(GL_TEXTURE0);
		MGLBINDTEXTURE2D([me->videoTexture CameraTexture]);
		
		GLERROR(glVertexAttribPointer(ATTRIB_VERTEX, 2, GL_FLOAT, 0, 0, squareVertices));
		GLERROR(glEnableVertexAttribArray(ATTRIB_VERTEX));
		
		GLERROR(glVertexAttribPointer(ATTRIB_TEX0, 2, GL_FLOAT, 0, 0, texCoords));
		GLERROR(glEnableVertexAttribArray(ATTRIB_TEX0));
		
		// do the secondary uv coords
		for(int u = 0; u < 4; u++)
		{
			uvCoords[u * 2] = tu->values[i];
			uvCoords[u * 2 + 1] = tv->values[i];
		}
		GLERROR(glVertexAttribPointer(ATTRIB_TEX1, 2, GL_FLOAT, 2, 0, uvCoords));
		GLERROR(glEnableVertexAttribArray(ATTRIB_TEX1));
		
		// Validate program before drawing. This is a good check, but only really necessary in a debug build.
		// DEBUG macro must be defined in your debug configurations if that's not already the case.
	#if defined(DEBUG)
		if (![me validateProgram:program])
		{
			NSLog(@"Failed to validate program: %d", program);
			return 0;
		}
	#endif
		
		// Draw
		GLERROR(glDrawArrays(GL_TRIANGLE_FAN, 0, 4));
	}
	
	if(bufferid == 0)
	{
		// This application only creates a single color renderbuffer which is already bound at this point.
		// This call is redundant, but needed if dealing with multiple renderbuffers.
		GLERROR(glBindRenderbuffer(GL_RENDERBUFFER, me->colorRenderbuffer));
		
		// glReadPixels should be done before calling this!!
		[me->context presentRenderbuffer:GL_RENDERBUFFER];
	}
	
	return 0;
}

int setShaderFloatUniform(lua_State *L)
{
	// void * renderer, unsigned int programid, unsigned int uniformid, float value
	ES2Renderer * me = (ES2Renderer*)luaL_checkinteger(L, 1);
	
	if(!me)
	{
		return 0;
	}
	
	GLint program = luaL_checkinteger(L, 2);
	GLint uid = luaL_checkinteger(L, 3);
	GLfloat val = luaL_checknumber(L,4);
	
	MGLUSEPROGRAM(program);
	
    //GLERROR(glUseProgram(program));
	GLERROR(glUniform1f(uid, val));
	
	return 0;
}

int setShaderMatrixUniform(lua_State *L)
{
	// void * renderer, unsigned int programid, unsigned int uniformid, float value
	ES2Renderer * me = (ES2Renderer*)luaL_checkinteger(L, 1);
	
	if(!me)
	{
		return 0;
	}
	
	GLint program = luaL_checkinteger(L, 2);
	GLint uid = luaL_checkinteger(L, 3);
	GLfloat * val = (GLfloat *)luaL_checkinteger(L,4);
	
	MGLUSEPROGRAM(program);
	
	GLERROR(glUniformMatrix3fv(uid, 1, GL_FALSE, val));
	
	return 0;
}

int copyTexture(lua_State *L)
{
	// void * renderer, unsigned int programid, unsigned int uniformid, float value
	ES2Renderer * me = (ES2Renderer*)luaL_checkinteger(L, 1);
	
	if(!me)
	{
		return 0;
	}
	
	GLint source = luaL_checkinteger(L, 2);
	GLint target = luaL_checkinteger(L, 3);

	FrameBuffer* st = (FrameBuffer*)source;
	FrameBuffer* tt = (FrameBuffer*)target;
	[tt copyFrom:st];
	
	return 0;
}

// programid, uniformid, texture unit (never 0), FrameBuffer *
// if FrameBuffer * is null, the uniform and texture unit are unset
int setShaderSampler(lua_State *L)
{
	// void * renderer, unsigned int programid, unsigned int uniformid, float value
	ES2Renderer * me = (ES2Renderer*)luaL_checkinteger(L, 1);
	
	if(!me)
	{
		return 0;
	}
	
	GLint program = luaL_checkinteger(L, 2);
	GLint uid = luaL_checkinteger(L, 3);
	GLint tunit = luaL_checknumber(L,4);
	unsigned int fbi = luaL_checkinteger(L, 5);
	FrameBuffer * fptr = (FrameBuffer*)fbi;
	
	MGLUSEPROGRAM(program);
	
	// set the active texture unit
	MGLACTIVETEXTURE(GL_TEXTURE0 + tunit);
	
	// bind the texture to texture unit tuint
	if(fptr)
	{
		GLint tex = [fptr getTexture];
		
		if([fptr isCubeMap])
		{
			MGLBINDTEXTURECUBE(tex);
		}
		else 
		{
			MGLBINDTEXTURE2D(tex);
		}
		
		// Indicate that the diffuse texture will be bound to texture unit tunit
		GLERROR(glUniform1i(uid, tunit));
	}
	else 
	{
		MGLBINDTEXTURE2D(0);
		
		// unset the uniform
		GLERROR(glUniform1i(uid, 0));
	}
	
	return 0;
}

// swap the two noise textures and generate new noise in the second texture
int flipNoiseTextures(lua_State *L)
{
	// void * renderer, unsigned int programid, unsigned int uniformid, float value
	ES2Renderer * me = (ES2Renderer*)luaL_checkinteger(L, 1);
	
	if(!me)
	{
		return 0;
	}
	
	unsigned int fbi = luaL_checkinteger(L, 2);
	FrameBuffer * fptr = (FrameBuffer*)fbi;
	[fptr flipNoise];
	
	return 0;
}

// programid, uniformid, texture unit (never 0), FrameBuffer *
// if FrameBuffer * is null, the uniform and texture unit are unset
int setShaderNoiseSampler(lua_State *L)
{
	// void * renderer, unsigned int programid, unsigned int uniformid, float value
	ES2Renderer * me = (ES2Renderer*)luaL_checkinteger(L, 1);
	
	if(!me)
	{
		return 0;
	}
	
	GLint program = luaL_checkinteger(L, 2);
	GLint uid = luaL_checkinteger(L, 3);
	GLint tunit = luaL_checknumber(L,4);
	unsigned int fbi = luaL_checkinteger(L, 5);
	FrameBuffer * fptr = (FrameBuffer*)fbi;
	int index = luaL_checkinteger(L, 6);
	
	MGLUSEPROGRAM(program);
	
	// set the active texture unit
	MGLACTIVETEXTURE(GL_TEXTURE0 + tunit);
	
	// bind the texture to texture unit tuint
	if(fptr)
	{
		GLint tex = [fptr getNoiseTexture:index];
		
		MGLBINDTEXTURE2D(tex);
		
		// Indicate that the diffuse texture will be bound to texture unit tunit
		GLERROR(glUniform1i(uid, tunit));
	}
	else 
	{
		MGLBINDTEXTURE2D(0);
		
		// unset the uniform
		GLERROR(glUniform1i(uid, 0));
	}
	
	return 0;
}

int createNoiseTextures(lua_State *L)
{
	// void * renderer, unsigned char * vertex, unsigned char * fragment
	ES2Renderer * me = (ES2Renderer*)luaL_checkinteger(L, 1);
	
	if(!me)
	{
		return 0;
	}
	
	int width = luaL_checkinteger(L, 2);
	int height = luaL_checkinteger(L, 3);
	
	FrameBuffer * fbr = [[FrameBuffer alloc] initWithNoise:width Height:height];
	
	// push the FrameBuffer reference
	lua_pushinteger(L, (lua_Integer)fbr);
	return 1;
}

int getShaderUniform(lua_State *L)
{
	// even if a uniform is defined in a shader, if it is not used, the compiler will remove it
	
	// void * renderer, unsigned int program id, unsigned char * uniformname
	ES2Renderer * me = (ES2Renderer*)luaL_checkinteger(L, 1);
	
	if(!me)
	{
		return 0;
	}
	
	GLint program = luaL_checkinteger(L, 2);
	const char * uniformname = luaL_checkstring(L, 3);
	
	MGLUSEPROGRAM(program);
	
	GLERROR(GLint uniform = glGetUniformLocation(program, uniformname));
	
	// push the uniform position and return 1 for the result count
	lua_pushinteger(L, (unsigned int)uniform);
	
    return 1;
}

int freeFrameBuffer(lua_State *L)
{
	// void * renderer, unsigned char * vertex, unsigned char * fragment
	ES2Renderer * me = (ES2Renderer*)luaL_checkinteger(L, 1);
	
	if(!me)
	{
		return 0;
	}
	
	FrameBuffer* fb = (FrameBuffer*)luaL_checkinteger(L, 2);
	[fb release];
	fb = NULL;
	return 0;
}

int createFrameBuffer(lua_State *L)
{
	// void * renderer, unsigned char * vertex, unsigned char * fragment
	ES2Renderer * me = (ES2Renderer*)luaL_checkinteger(L, 1);
	
	if(!me)
	{
		return 0;
	}
	
	int width = luaL_checkinteger(L, 2);
	int height = luaL_checkinteger(L, 3);
	
	FrameBuffer* fb = [[FrameBuffer alloc] initWithWidth:width Height:height CreateTexture:true UsesReadPixels:false];
	
	lua_pushinteger(L, (lua_Integer)fb);
	
    return 1;
}

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

int createFrameBufferFromFile(lua_State *L)
{
	// void * renderer, unsigned char * vertex, unsigned char * fragment
	ES2Renderer * me = (ES2Renderer*)luaL_checkinteger(L, 1);
	
	if(!me)
	{
		return 0;
	}
	
	const char * name = luaL_checkstring(L, 2);
	
	NSString * textureName = getPathForImageFile(name);
	
	FrameBuffer * fbr = [[FrameBuffer alloc] initWithFile:textureName];
	// push the FrameBuffer reference
	lua_pushinteger(L, (lua_Integer)fbr);
	return 1;
}

int createCubeMap(lua_State *L)
{
	// void * renderer, unsigned char * vertex, unsigned char * fragment
	ES2Renderer * me = (ES2Renderer*)luaL_checkinteger(L, 1);
	
	if(!me)
	{
		return 0;
	}
	
	const char * namexp = luaL_checkstring(L, 2);
	NSString * xp = getPathForImageFile(namexp);
	
	const char * namexn = luaL_checkstring(L, 3);
	NSString * xn = getPathForImageFile(namexn);
	
	const char * nameyp = luaL_checkstring(L, 4);
	NSString * yp = getPathForImageFile(nameyp);
	
	const char * nameyn = luaL_checkstring(L, 5);
	NSString * yn = getPathForImageFile(nameyn);
	
	const char * namezp = luaL_checkstring(L, 6);
	NSString * zp = getPathForImageFile(namezp);
	
	const char * namezn = luaL_checkstring(L, 7);
	NSString * zn = getPathForImageFile(namezn);
	
	int usemipmap = luaL_checkinteger(L, 8);
	
	FrameBuffer * fbr = [[FrameBuffer alloc] initWithCubeXP:xp XN:xn YP:yp YN:yn ZP:zp ZN:zn MipMap:usemipmap != 0];
	
	// push the FrameBuffer reference
	lua_pushinteger(L, (lua_Integer)fbr);
	return 1;
}

int setFrameBufferFiltering(lua_State *L)
{
	// void * renderer, unsigned char * vertex, unsigned char * fragment
	ES2Renderer * me = (ES2Renderer*)luaL_checkinteger(L, 1);
	
	if(!me)
	{
		return 0;
	}
	
	FrameBuffer * fbr = (FrameBuffer *)luaL_checkinteger(L, 2);
	int linear = luaL_checkinteger(L, 3);
	
	[fbr setLinearFiltering:(linear == 0 ? false : true)];
	
	return 0;
}

int createShaderProgram(lua_State *L)
{
	// void * renderer, unsigned char * vertex, unsigned char * fragment
	ES2Renderer * me = (ES2Renderer*)luaL_checkinteger(L, 1);
	
	if(!me)
	{
		return 0;
	}
	
	const char * vertex = luaL_checkstring(L, 2);
	const char * fragment = luaL_checkstring(L, 3);
	int hasUV2 = luaL_checkinteger(L, 4);
	
	GLuint vertShader, fragShader;
    NSString *vertShaderPathname = [ NSString stringWithCString: vertex encoding: NSASCIIStringEncoding ];
	NSString *fragShaderPathname = [ NSString stringWithCString: fragment encoding: NSASCIIStringEncoding ];
	
	// get the absolute paths for the shaders
	vertShaderPathname = [[NSBundle mainBundle] pathForResource:vertShaderPathname ofType:@"vsh"];
	fragShaderPathname = [[NSBundle mainBundle] pathForResource:fragShaderPathname ofType:@"fsh"];
	
	if(!vertShaderPathname || !fragShaderPathname)
	{
		// someone's missing!
		NSLog(@"Vertex or Fragment shader file not found vert:%s frag:%s" , vertex, fragment );
		return 0;
	}
	
	// combine the paths to see if we have this combination program already built
	NSString * catprog = [vertShaderPathname stringByAppendingString:fragShaderPathname];
	
	// see if we already have this shader program i our dictionary
	NSArray * allkeys = [me->compiledShaders allKeys];
	NSEnumerator *enumerator = [allkeys objectEnumerator];
	id keystr;
	while (keystr = [enumerator nextObject]) 
	{
		/* code to act on each element as it is returned */
		NSString * str = (NSString*)keystr;
		if([str isEqualToString:catprog])
		{
			// get the nsvalue for this key which holds the original GLInt for the shader program
			NSValue * kval = [me->compiledShaders objectForKey:keystr];
			
			GLint vprog = 0;
			[kval getValue:&vprog];
			
			// push the program and return 1 for the result count
			lua_pushinteger(L, (unsigned int)vprog);
			
			return 1;
		}
	}
	
    // Create shader program
    GLERROR(GLuint program = glCreateProgram());
	
    // Create and compile vertex shader
    if (![me compileShader:&vertShader type:GL_VERTEX_SHADER file:vertShaderPathname])
    {
        NSLog(@"Failed to compile vertex shader");
        return 0;
    }
	
    // Create and compile fragment shader
    if (![me compileShader:&fragShader type:GL_FRAGMENT_SHADER file:fragShaderPathname])
    {
        NSLog(@"Failed to compile fragment shader");
        return 0;
    }
	
    // Attach vertex shader to program
    GLERROR(glAttachShader(program, vertShader));
	
    // Attach fragment shader to program
    GLERROR(glAttachShader(program, fragShader));
	
    // Bind attribute locations
    // this needs to be done prior to linking
    GLERROR(glBindAttribLocation(program, ATTRIB_VERTEX, "position"));
	GLERROR(glBindAttribLocation(program, ATTRIB_TEX0, "inTexcoord"));
	
	if(hasUV2)
	{
		GLERROR(glBindAttribLocation(program, ATTRIB_TEX1, "inTexcoord2"));
	}
	
    // Link program
    if (![me linkProgram:program])
    {
        NSLog(@"Failed to link program: %d", program);
		
        if (vertShader)
        {
            GLERROR(glDeleteShader(vertShader));
            vertShader = 0;
        }
        if (fragShader)
        {
            GLERROR(glDeleteShader(fragShader));
            fragShader = 0;	
        }
        if (program)
        {
            GLERROR(glDeleteProgram(program));
            program = 0;
        }
        return 0;
    }
	
	MGLUSEPROGRAM(program);
			
    // Get default uniform locations
	// get the uniform position for diffuseTexture
	GLERROR(GLint samplerLoc = glGetUniformLocation(program, "diffuseTexture"));
	if(samplerLoc == -1)
	{
		NSLog(@"Failed to locate diffuseTexture uniform in: %d", program);
        return 0;
	}
	
	// Indicate that the diffuse texture will be bound to texture unit 0
	GLint unit = 0;
	GLERROR(glUniform1i(samplerLoc, unit));
	
    // Release vertex and fragment shaders
    if (vertShader)
        GLERROR(glDeleteShader(vertShader));
    if (fragShader)
        GLERROR(glDeleteShader(fragShader));
	
	// add to list of programs created
	[me->compiledShaders setObject:[NSValue value:&program withObjCType:@encode(int*)] forKey:catprog];
	
	// push the program and return 1 for the result count
	lua_pushinteger(L, (unsigned int)program);
	
    return 1;
}

int createFloatArray(lua_State *L)
{
	int n = luaL_checkint(L, 1);
	size_t nbytes = sizeof(FloatArray) + (n - 1)*sizeof(float);
	FloatArray *a = (FloatArray *)lua_newuserdata(L, nbytes);
	a->size = n;
	return 1;  /* new userdatum is already on the stack */
}

int setFloatArrayValue(lua_State *L)
{
	FloatArray *a = (FloatArray *)lua_touserdata(L, 1);
	int index = luaL_checkint(L, 2);
	float value = luaL_checknumber(L, 3);
    
	luaL_argcheck(L, a != NULL, 1, "`array' expected");
    
	luaL_argcheck(L, 1 <= index && index <= a->size, 2,
				  "index out of range");
    
	a->values[index-1] = value;
	return 0;
}

int addFloat(lua_State *L)
{
	FloatArray *a = (FloatArray *)lua_touserdata(L, 1);
	float val = luaL_checknumber(L, 2);
	
	for(int i = 0; i < a->size; i++)
	{
		a->values[i] = a->values[i] + val;
	}
	
	return 0;
}

int mulFloat(lua_State *L)
{
	FloatArray *a = (FloatArray *)lua_touserdata(L, 1);
	float val = luaL_checknumber(L, 2);
	
	for(int i = 0; i < a->size; i++)
	{
		a->values[i] = a->values[i] * val;
	}
	
	return 0;
}

int addFloats(lua_State *L)
{
	FloatArray *a = (FloatArray *)lua_touserdata(L, 1);
	FloatArray *vals = (FloatArray *)lua_touserdata(L, 2);
	
	for(int i = 0; i < a->size; i++)
	{
		a->values[i] = a->values[i] + vals->values[i];
	}
	
	return 0;
}

int copyFloats(lua_State *L)
{
	FloatArray *src = (FloatArray *)lua_touserdata(L, 1);
	FloatArray *dest = (FloatArray *)lua_touserdata(L, 2);
	memcpy((void*)dest->values, (void*)src->values, src->size * sizeof(float));
	return 0;
}

int mulFloats(lua_State *L)
{
	FloatArray *a = (FloatArray *)lua_touserdata(L, 1);
	FloatArray *vals = (FloatArray *)lua_touserdata(L, 2);
	
	for(int i = 0; i < a->size; i++)
	{
		a->values[i] = a->values[i] * vals->values[i];
	}
	
	return 0;
}

int addMMFloat(lua_State *L)
{
	FloatArray *a = (FloatArray *)lua_touserdata(L, 1);
	FloatArray *vals = (FloatArray *)lua_touserdata(L, 2);
	float minv = luaL_checknumber(L, 3);
	float maxv = luaL_checknumber(L, 4);
	int mmop = luaL_checkint(L, 5);
	
	for(int i = 0; i < a->size; i++)
	{
		a->values[i] += vals->values[i];
		if(a->values[i] <= minv)
		{
			switch (mmop) {
				case FMMBOUNCE:
					vals->values[i] = vals->values[i] * -1.0;
					a->values[i] = minv;
					break;
				case FMMCLAMP:
					a->values[i] = minv;
					break;
				case FMMLOOP:
					a->values[i] = maxv;
					break;
				default:
					break;
			}
		}
		else if(a->values[i] >= maxv)
		{
			switch (mmop) {
				case FMMBOUNCE:
					vals->values[i] = vals->values[i] * -1.0;
					a->values[i] = maxv;
					break;
				case FMMCLAMP:
					a->values[i] = maxv;
					break;
				case FMMLOOP:
					a->values[i] = minv;
					break;
				default:
					break;
			}
		}
	}
	
	return 0;
}

int getFloatArrayValue(lua_State *L)
{
	FloatArray *a = (FloatArray *)lua_touserdata(L, 1);
	int index = luaL_checkint(L, 2);
    
	luaL_argcheck(L, a != NULL, 1, "`array' expected");
    
	luaL_argcheck(L, 1 <= index && index <= a->size, 2,
				  "index out of range");
    
	lua_pushnumber(L, a->values[index-1]);
	return 1;
}
	
int getFloatArraySize(lua_State *L)
{
	FloatArray *a = (FloatArray *)lua_touserdata(L, 1);
	luaL_argcheck(L, a != NULL, 1, "`array' expected");
	lua_pushnumber(L, a->size);
	return 1;	
}

// time, scale, oscilator type
int scaleTime(lua_State *L)
{
	// void * renderer, unsigned char * vertex, unsigned char * fragment
	float time = luaL_checknumber(L, 1);
	float scale = luaL_checknumber(L, 2);
	OscilatorType otype = (OscilatorType)luaL_checkinteger(L, 3);
	
	float tscale = 1000.0 * (1.0 / scale);
	int clippedt = (int)(time * 1000.0) % (int)tscale;
	float ntime = (float)clippedt / tscale;
	switch (otype) {
		case OSCSAW:
		{
			lua_pushnumber(L, ntime);
		}
			break;
			case OSCSIN:
		{
			// normalize sine to 0.0 - 1.0
			float sval = sin(ntime * (2 * PI)) * 0.5 + 0.5;
			lua_pushnumber(L, sval);
		}
				break;

		default:
			break;
	}

	return 1;
}
