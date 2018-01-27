//
//  FrameBuffer.m
//  VideoTexture
//
//  Created by Richard Insley on 8/22/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "FrameBuffer.h"
#import "GLERROR.h"

@implementation FrameBuffer

@synthesize isFlipped;
@synthesize texture;
@synthesize colorRenderbuffer;
@synthesize framebuffer;

-(GLubyte*)getImageBytes:(NSString*)imagePath Width:(int*)width Height:(int*)height
{
	bool isPng = [imagePath hasSuffix:@"png"];
	
	if(isPng)
	{
		FILE * infile = fopen([imagePath cStringUsingEncoding:NSUTF8StringEncoding], "rb");
		if (!infile) 
		{
			return NULL;
		}
		
		/* 
		 * Set up the PNG structs 
		 */
		png_structp png_ptr; 
		png_infop info_ptr; 
		png_infop end_ptr;
		
		png_ptr = png_create_read_struct(PNG_LIBPNG_VER_STRING, NULL, NULL, NULL);
		if (!png_ptr) 
		{
			fclose(infile);
			return NULL; /* out of memory */
		}
		
		info_ptr = png_create_info_struct(png_ptr);
		if (!info_ptr) 
		{
			png_destroy_read_struct(&png_ptr, (png_infopp) NULL, (png_infopp) NULL);
			fclose(infile);
			return NULL; 
		}
		
		end_ptr = png_create_info_struct(png_ptr);
		if (!end_ptr) 
		{
			png_destroy_read_struct(&png_ptr, &info_ptr, (png_infopp) NULL);
			fclose(infile);
			return NULL; 
		}
		
		if (setjmp(png_jmpbuf(png_ptr))) 
		{
			png_destroy_read_struct(&png_ptr, &info_ptr, &end_ptr);
			fclose(infile);
			return 0;
		}
		
		png_ptr->io_ptr = (png_voidp)infile;

		int bit_depth , color_type;
		png_read_info(png_ptr, info_ptr);
		png_get_IHDR(png_ptr, info_ptr, (png_uint_32*)&_width, (png_uint_32*)&_height, &bit_depth, 
					 &color_type, NULL, NULL, NULL);
		

		if(info_ptr->pixel_depth == 32)
		{
			png_read_update_info(png_ptr, info_ptr);
			
			 int rowbytes = png_get_rowbytes(png_ptr, info_ptr);
			
			GLubyte * image_data = NULL;
			
			if ((image_data = (GLubyte *) malloc(rowbytes * _height))==NULL) 
			{
				png_destroy_read_struct(&png_ptr, &info_ptr, NULL);
				return NULL;
			}
			
			png_byte ** row_pointers;
			if ((row_pointers = (png_bytepp)malloc(_height * sizeof(png_bytep))) == NULL) 
			{
				png_destroy_read_struct(&png_ptr, &info_ptr, NULL);
				free(image_data);
				image_data = NULL;
				return NULL;
			}
			
			for (int i = 0;  i < _height;  ++i)
			{
				row_pointers[i] = image_data + i*rowbytes;
			}
		
			png_read_image(png_ptr, row_pointers);
			
			png_destroy_read_struct(&png_ptr, &info_ptr, &end_ptr);
			fclose(infile);
			free(row_pointers);
			return image_data;
		}
		else
		{
			// we want core graphics to handle pngs that are not 32 bits
			png_destroy_read_struct(&png_ptr, &info_ptr, &end_ptr);
			fclose(infile);
			isPng = false;	
		}
	}
	
	if(!isPng)
	{
		GLubyte * idata = NULL;
		
		CGContextRef tcontext;
		CGImageRef timage = [UIImage imageWithContentsOfFile:imagePath].CGImage;
		
		// Get the width and height of the image
		_width = CGImageGetWidth(timage);
		_height = CGImageGetHeight(timage);
		size_t bpr = CGImageGetBytesPerRow(timage);
		
		if(timage)
		{
			// Allocated memory needed for the bitmap context
			idata = (GLubyte *) calloc(bpr * _height, sizeof(GLubyte));
			
			// Uses the bitmap creation function provided by the Core Graphics framework. 
			tcontext = CGBitmapContextCreate(idata, _width, _height, 8, bpr, CGImageGetColorSpace(timage), kCGImageAlphaPremultipliedLast);
			
			// make sure to duplicate the alpha channel
			CGContextSetBlendMode(tcontext, kCGBlendModeCopy);
			
			// After you create the context, you can draw the sprite image to the context.
			CGContextDrawImage(tcontext, CGRectMake(0.0, 0.0, (CGFloat)_width, (CGFloat)_height), timage);
			
			// You don't need the context at this point, so you need to release it to avoid memory leaks.
			CGContextRelease(tcontext);
			
			*width = _width;
			*height = _height;
		}
		
		return idata;
	}
}

-(id)initWithFrameBuffer:(GLuint)fbo ColorBuffer:(GLuint)cbo;
{
	if ((self = [super init]))
    {
		// wrap an existing framebuffer and color render buffer
		framebuffer = fbo;
		colorRenderbuffer = cbo;
	}
	return self;
}

-(id)initWithFile:(NSString*)imagePath
{	
	if ((self = [super init]))
    {
		Noise3DTexPtr = NULL;
		ntex1 = ntex2 = colorRenderbuffer = framebuffer = texture = cubeTexture = -1;
		
		GLubyte * idata = [self getImageBytes:imagePath Width:&_width Height:&_height];
		_actualWidth = _width;
		_actualHeight = _height;
		
		if(idata)
		{
			// Use OpenGL ES to generate a name for the texture.
			GLERROR(glGenTextures(1, &texture));
			
			// get the current bound texture
			GLint currentt;
			GLERROR(glGetIntegerv(GL_TEXTURE_BINDING_2D, &currentt));
			
			//[self genBufferWithTexture:_width Height:_height];
			
			// Bind the texture name. 
			MGLBINDTEXTURE2D(texture);
			
			// Set the texture parameters to use a minifying filter and a linear filer (weighted average)
			GLERROR(glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR));
			GLERROR(glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR));
			GLERROR(glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE));
			GLERROR(glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE));
			
			// Specify a 2D texture image, providing the a pointer to the image data in memory
			GLERROR(glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, _width, _height, 0, GL_RGBA, GL_UNSIGNED_BYTE, idata));
			
			
			// Release the image data
			free(idata);	
			
			// set the current texture back
			MGLBINDTEXTURE2D(currentt);
		}
		
	}
	
	return self;
}

-(id)initWithCubeXP:(NSString*)xp XN:(NSString*)xn YP:(NSString*)yp YN:(NSString*)yn ZP:(NSString*)zp ZN:(NSString*)zn MipMap:(bool)genMipMap
{
	if ((self = [super init]))
    {
		Noise3DTexPtr = NULL;
		ntex1 = ntex2 = colorRenderbuffer = framebuffer = texture = cubeTexture = -1;
		
		cubeTexture = generateAndBindCube();
		
		GLERROR(glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR));
        GLERROR(glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MAG_FILTER, GL_LINEAR));
        GLERROR(glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE));
        GLERROR(glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE));
		
		GLubyte * idata = NULL;
		
		idata = [self getImageBytes:yp Width:&_width Height:&_height];
		GLERROR(glTexImage2D(GL_TEXTURE_CUBE_MAP_POSITIVE_Y, 0, GL_RGBA, _width, _height, 0, GL_RGBA, GL_UNSIGNED_BYTE, idata));
		free(idata);
		
		idata = [self getImageBytes:yn Width:&_width Height:&_height];
		GLERROR(glTexImage2D(GL_TEXTURE_CUBE_MAP_NEGATIVE_Y, 0, GL_RGBA, _width, _height, 0, GL_RGBA, GL_UNSIGNED_BYTE, idata));
		free(idata);
		
		idata = [self getImageBytes:zp Width:&_width Height:&_height];
		GLERROR(glTexImage2D(GL_TEXTURE_CUBE_MAP_POSITIVE_Z, 0, GL_RGBA, _width, _height, 0, GL_RGBA, GL_UNSIGNED_BYTE, idata));
		free(idata);
		
		idata = [self getImageBytes:zn Width:&_width Height:&_height];
		GLERROR(glTexImage2D(GL_TEXTURE_CUBE_MAP_NEGATIVE_Z, 0, GL_RGBA, _width, _height, 0, GL_RGBA, GL_UNSIGNED_BYTE, idata));
		free(idata);
		
		idata = [self getImageBytes:xp Width:&_width Height:&_height];
		GLERROR(glTexImage2D(GL_TEXTURE_CUBE_MAP_POSITIVE_X, 0, GL_RGBA, _width, _height, 0, GL_RGBA, GL_UNSIGNED_BYTE, idata));
		free(idata);
		
		idata = [self getImageBytes:xn Width:&_width Height:&_height];
		GLERROR(glTexImage2D(GL_TEXTURE_CUBE_MAP_NEGATIVE_X, 0, GL_RGBA, _width, _height, 0, GL_RGBA, GL_UNSIGNED_BYTE, idata));
		free(idata);
		
		_actualWidth = _width;
		_actualHeight = _height;
		
		if(genMipMap)
		{
			GLERROR(glGenerateMipmap(GL_TEXTURE_CUBE_MAP));
		}
		
	}
	
	return self;
}

    

-(void)setLinearFiltering:(bool)linear
{
	GLint ct;
	GLERROR(glGetIntegerv(GL_TEXTURE_BINDING_2D, &ct));
	MGLBINDTEXTURE2D(texture);
	
	if(linear)
	{
		GLERROR(glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR));
		GLERROR(glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR));
	}
	else 
	{
		GLERROR(glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST));
		GLERROR(glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST));
	}

	MGLBINDTEXTURE2D(ct);
}

- (id)initWithWidth:(int)width Height:(int)height CreateTexture:(bool)createTexture UsesReadPixels:(bool)glread 
{
	if ((self = [super init]))
    {
		Noise3DTexPtr = NULL;
		ntex1 = ntex2 = colorRenderbuffer = framebuffer = texture = cubeTexture = -1;
		
		_actualWidth = _width = width;
		_actualHeight = _height = height;
		
		// ensure the width and height are multiples of 32 for glreadpixels to work correctly
		if(glread)
		{
			_actualWidth = (int)(32.0 * ceil((float)width / 32.0));
			_actualHeight = _height;
		}
		
		// get the current frame buffer
		GLint currentFb;
		GLERROR(glGetIntegerv(GL_FRAMEBUFFER_BINDING, &currentFb));
		
		if(!createTexture)
		{
			// Create the framebuffer and bind it so that future OpenGL ES framebuffer commands are directed to it.
			GLERROR(glGenFramebuffers(1, &framebuffer));
			GLERROR(glBindFramebuffer(GL_FRAMEBUFFER, framebuffer));
			
			// Create a color renderbuffer, allocate storage for it, and attach it to the framebuffer.
			GLERROR(glGenRenderbuffers(1, &colorRenderbuffer));
			GLERROR(glBindRenderbuffer(GL_RENDERBUFFER, colorRenderbuffer));
			GLERROR(glRenderbufferStorage(GL_RENDERBUFFER, GL_RGBA8_OES, _actualWidth, _actualHeight));
			GLERROR(glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, colorRenderbuffer));
			
			// Test the framebuffer for completeness.
			GLERROR(GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER)) ;
			if(status != GL_FRAMEBUFFER_COMPLETE) 
			{
				NSLog(@"failed to make complete framebuffer object %x", status);
			}
		}
		else 
		{
			// Create the framebuffer and bind it so that future OpenGL ES framebuffer commands are directed to it.
			GLERROR(glGenFramebuffers(1, &framebuffer));
			GLERROR(glBindFramebuffer(GL_FRAMEBUFFER, framebuffer));
			
			// get the current bound texture
			GLint currentt;
			GLERROR(glGetIntegerv(GL_TEXTURE_BINDING_2D, &currentt));
			
			[self genBufferWithTexture:_actualWidth Height:_actualHeight];
			
			// set the current texture back
			MGLBINDTEXTURE2D(currentt);
		}
		
		// set the old frame buffer back
		GLERROR(glBindFramebuffer(GL_FRAMEBUFFER, currentFb));
	}
	
	return self;
}

-(id)initWithNoise:(int)width Height:(int)height 
{
	if ((self = [super init]))
    {
		_actualWidth = _width = width;
		_actualHeight = _height = height;
		
		// we'll keep a buffer around to prevent having to realloc whenever we want to flip the noise
		Noise3DTexPtr = (GLubyte*)malloc(width * height * 4);
		
		ntex1 = ntex2 = colorRenderbuffer = framebuffer = texture = cubeTexture = -1;
		
		// get the current bound texture
		GLint currentt;
		GLERROR(glGetIntegerv(GL_TEXTURE_BINDING_2D, &currentt));
		
		// Use OpenGL ES to generate a name for the texture.
		GLERROR(glGenTextures(1, &ntex1));
		
		// Bind the texture name. 
		MGLBINDTEXTURE2D(ntex1);
		
		// Set the texture parameters to use a minifying filter and a linear filer (weighted average)
		GLERROR(glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR));
		GLERROR(glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR));
		GLERROR(glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE));
		GLERROR(glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE));
		
		make3DNoiseTexture(_width, _height, 1, Noise3DTexPtr);
		[self setNoiseTexture:ntex1];
		
		// Use OpenGL ES to generate a name for the texture.
		GLERROR(glGenTextures(1, &ntex2));
		
		// Bind the texture name. 
		MGLBINDTEXTURE2D(ntex2);
		
		// Set the texture parameters to use a minifying filter and a linear filer (weighted average)
		GLERROR(glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR));
		GLERROR(glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR));
		GLERROR(glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE));
		GLERROR(glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE));
		
		make3DNoiseTexture(_width, _height, 1, Noise3DTexPtr);
		[self setNoiseTexture:ntex2];
		
		// set the current texture back
		MGLBINDTEXTURE2D(currentt);
		
		// create the queue to asynchronously generate next noise texture on another thread
		noiseQueue = dispatch_queue_create("noiseQueue", NULL);
		
		// start generating the next noise texture
		make3DNoiseTexture(_width, _height, 1, Noise3DTexPtr);
	}
	
	return self;
}

-(void)setNoiseTexture:(GLuint) texid 
{	
	// get the current bound texture
	GLint currentt;
	GLERROR(glGetIntegerv(GL_TEXTURE_BINDING_2D, &currentt));
	
	// Bind the texture name. 
	MGLBINDTEXTURE2D(texid);

	// Specify a 2D texture image, providing the a pointer to the image data in memory
	GLERROR(glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, _width, _height, 0, GL_RGBA, GL_UNSIGNED_BYTE, Noise3DTexPtr));
	
	// set the current texture back
	MGLBINDTEXTURE2D(currentt);
}

-(void)flipNoise
{
	GLuint t = ntex1;
	ntex1 = ntex2;
	ntex2 = t;
	@synchronized(self)
	{
		[self setNoiseTexture:ntex2];
	}
	
	// start generating the next noise texture
	dispatch_sync(noiseQueue, ^(void)
				   {
					   @synchronized(self)
					   {
						   if(Noise3DTexPtr)
						   {
							   make3DNoiseTexture(_width, _height, 1, Noise3DTexPtr);
						   }
					   }
				   });
}

-(void)genBufferWithTexture:(int)width Height:(int)height
{	
	GLERROR(glGenTextures(1, &texture));
	MGLBINDTEXTURE2D(texture);
	
	GLERROR(glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL));
	
	/*
	 #define GL_REPEAT                         0x2901
	 #define GL_CLAMP_TO_EDGE                  0x812F
	 #define GL_MIRRORED_REPEAT                0x8370
	 */
	
	GLERROR(glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR)); // use GL_NEAREST when not resampling
	GLERROR(glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR));
	GLERROR(glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE));
	GLERROR(glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE));
	GLERROR(glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, texture, 0));
	
	// Test the framebuffer for completeness.
	GLERROR(GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER)) ;
	if(status != GL_FRAMEBUFFER_COMPLETE) 
	{
		NSLog(@"failed to make complete framebuffer object %x", status);
	}
}

-(void)dealloc
{	
	if(texture != -1)
	{
		MGLDELETETEXTURE(texture);
		texture = -1;
	}
	
	if(cubeTexture != -1)
	{
		MGLDELETETEXTURE(cubeTexture);
		cubeTexture = -1;
	}
	
	if(ntex1 != -1)
	{
		MGLDELETETEXTURE(ntex1);
		ntex1 = -1;
	}
	
	if(ntex2 != -1)
	{
		MGLDELETETEXTURE(ntex2);
		ntex2 = -1;
	}
	
	@synchronized(self)
	{
		if(Noise3DTexPtr)
		{
			free(Noise3DTexPtr);
			Noise3DTexPtr = NULL;
		}
	}
	
	if(colorRenderbuffer != -1)
	{
		GLERROR(glDeleteRenderbuffers(1, &colorRenderbuffer));
		colorRenderbuffer = -1;
	}
	
	if(framebuffer != -1)
	{
		GLERROR(glDeleteFramebuffers(1, &framebuffer));
		framebuffer = -1;
	}
	
	[super dealloc];
}

-(void)setRenderTarget
{
	//GLERROR(glBindFramebuffer(GL_FRAMEBUFFER, framebuffer));
	MGLBINDFRAMEBUFFER(self);
}

-(void)copyFrom:(FrameBuffer*)source
{
	MGLBINDFRAMEBUFFER(source);
	MGLCOPY(self.texture, _actualWidth, _actualHeight);
}

-(void)readPixels:(void*)linedata
{	
	// for this to work on 4.0/4.1 the width seems to need to be a multpile of 32
	
	[self setRenderTarget];
	
	GLERROR(glPixelStorei(GL_PACK_ALIGNMENT, 4));
	GLERROR(glReadPixels(0, 0, _actualWidth, _actualHeight, GL_RGBA, GL_UNSIGNED_BYTE, linedata));
}

-(int)getWidth
{
	return _width;
}

-(int)getActualWidth
{
	return _actualWidth;
}

-(int)getHeight
{
	return _height;
}

-(bool)isCubeMap
{
	return cubeTexture != -1;
}

-(GLint)getNoiseTexture:(int)index
{
	if(index == 0)
	{
		return ntex1;
	}
	
	return ntex2;
}

-(bool)getIsPortrait
{
	return _width <= _height;
}

-(GLint)getTexture
{
	return (cubeTexture == -1 ? texture : cubeTexture);
}
@end
