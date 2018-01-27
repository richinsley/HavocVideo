//
//  ES2Renderer.h
//  VideoTexture
//
//  Created by Richard Insley on 8/17/10.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#include "EffectScript.h"
#import "FrameBuffer.h"

#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

#import <QuartzCore/QuartzCore.h>
#import <CoreMotion/CoreMotion.h>
#import <CoreLocation/CoreLocation.h>

#import <OpenGLES/EAGL.h>
#import <OpenGLES/EAGLDrawable.h>

#import "AccelerometerFilter.h"
#import "FrameBuffer.h"
#import "VideoBuffer.h"
#import "VideoWriter.h"
#import "ChangeScriptProtocol.h"
#import "GLStateManager.h"

extern "C" 
{
	#import "matrixUtil.h"
	#import "GLERROR.h"
}

	// medium quality
	#define VWIDTH 480
	#define VHEIGHT 360

	// high quality
	//#define VWIDTH 640
	//#define VHEIGHT 480

    // high definition
    //#define VWIDTH 1280
    //#define VHEIGHT 720


#define MAXSCRIPTS 1024

#define USEAUDIO true
#define USEAAC

#define PI	 3.1415926535897932384626433832795
#define PI_OVER_180	 0.017453292519943295769236907684886
#define PI_OVER_360	 0.0087266462599716478846184538424431

enum OscilatorType 
{
	OSCSAW = 0,
	OSCTRI = 1,
	OSCSIN = 2,
	OSCSQR = 3
};

enum MinMaxOp
{
	FMMBOUNCE = 0,
	FMMCLAMP = 1,
	FMMLOOP = 2
};

@interface ES2Renderer : NSObject < ChangeScriptProtocol >
{
@public
	bool _isRecording;
	bool _isPaused;
	
	bool isInitialized;
	
    EAGLContext *context;

    // The pixel dimensions of the CAEAGLLayer
    GLint backingWidth;
    GLint backingHeight;

    GLuint program;
	
	// array of scripts
	EffectScript * scripts[MAXSCRIPTS];
	
	// count of scripts in scripts array
	int scriptCount;
	
	VideoBuffer* videoTexture;
	VideoWriter* videoWriter;
	
	// the current effect script
	EffectScript * script;
	
	// the current effect id
	unsigned int currentScriptID;
	
	// The OpenGL ES names for the framebuffer and renderbuffer used to render to this view
    GLuint defaultFramebuffer, colorRenderbuffer;
	FrameBuffer * displayBuffer;
	
	// frame buffers that effects are rendered into
	FrameBuffer * fbl; // for landscape media
	FrameBuffer * fbp; // for portrait media
	
	// the currently used frame buffer
	FrameBuffer * fb;
	
	// keep track of shaders that are already compiled
	NSMutableDictionary * compiledShaders;
	
	// string containing the lua effect global values
	NSString * effectglobals;

	// YES when we're only using the accelerometer, NO when we're using device motion
	BOOL accelMode;
	
	// for our gyroscopic sampling
	CMMotionManager *motionManager;
	
	// for the tesla meter
	CLLocationManager *locationManager;
	
	bool _setReferenceAttitude;
	
	// referenceAttitude
	// Only used when accelMode==NO
	CMAttitude *referenceAttitude;
	
	// Whether translation based on user acceleration is enabled
	// Only used when accelMode==NO
	BOOL translationEnabled;
	
	// Low-pass filter for user acceleration
	// Only used when accelMode==NO
	LowpassFilter *userAccelerationLpf;
	
	NSLock * videoTextureLock;
	
	bool backingSet;
	
	double rotx;
	double roty;
	double rotz;
	
	// current orientation
	UIInterfaceOrientation orientation;
}

@property (readonly, nonatomic) bool isInitialized;
@property (readonly, nonatomic) NSLock * videoTextureLock;
@property (readwrite) UIInterfaceOrientation orientation;

-(void)displayMedia;
-(bool)addScript:(NSString*)scriptName;
- (EffectScript*)loadEffect:(NSString *)effectFile;
-(void)setCurrentScript:(int)newID;

- (void)renderToSampleBuffer:(CMTime)timestamp;
-(void)processAudio:(CMSampleBufferRef)sampleBuffer;

- (BOOL)resizeFromLayer:(CAEAGLLayer *)layer;
- (void)incEffect;

- (BOOL)isRecording;
- (void)startRecording:(UIInterfaceOrientation)orientation;
- (NSString*)stopRecording;

// start and stop video feed from camera
-(void)stopCapture;
-(void)startCapture;
-(double)getDuration;

// camera control methods
-(bool)isFrontCamera;
-(void)setFrontCamera:(bool)useFront;
-(void)enableLamp:(bool)enable;
-(bool)isLampEnabled;

-(EffectScript**)GetScripts;

@end

// helper type for maintaining an array of native float float values in lua
typedef struct FloatArray {
	int size;
	float values[1];  // decalre it as a size of one only as a place holder
} FloatArray;

// functions that need to be passed into the effect scripts
static int createShaderProgram(lua_State *L);
static int getShaderUniform(lua_State *L);
static int setShaderFloatUniform(lua_State *L);
static int setShaderMatrixUniform(lua_State *L);
static int setShaderSampler(lua_State *L);
static int renderToFrameBuffer(lua_State *L);
static int renderParticlesToFrameBuffer(lua_State *L);
static int createFrameBuffer(lua_State *L);
static int createFrameBufferFromFile(lua_State *L);
static int setFrameBufferFiltering(lua_State *L);
static int scaleTime(lua_State *L);
static int freeFrameBuffer(lua_State *L);

static int createFloatArray(lua_State *L);
static int setFloatArrayValue(lua_State *L);
static int getFloatArrayValue(lua_State *L);
static int getFloatArraySize(lua_State *L);
static int addMMFloat(lua_State *L);
static int addFloat(lua_State *L);
static int mulFloat(lua_State *L);
static int addFloats(lua_State *L);
static int mulFloats(lua_State *L);
static int copyFloats(lua_State *L);
static int createCubeMap(lua_State *L);
static int setShaderNoiseSampler(lua_State *L);
static int createNoiseTextures(lua_State *L);
static int flipNoiseTextures(lua_State *L);
static int copyTexture(lua_State *L);
static NSString * getPathForImageFile(const char * name);

// list of functions and thier names to be registered into each effect
static const struct luaL_reg effectlib [] = {
	{"createShaderProgram", createShaderProgram},
	{"getShaderUniform", getShaderUniform},
	{"setShaderSampler", setShaderSampler},
	{"setShaderFloatUniform", setShaderFloatUniform},
	{"setShaderMatrixUniform", setShaderMatrixUniform},
	{"renderToFrameBuffer", renderToFrameBuffer},
	{"renderParticlesToFrameBuffer", renderParticlesToFrameBuffer},
	{"createFrameBuffer", createFrameBuffer},
	{"createFrameBufferFromFile", createFrameBufferFromFile},
	{"createCubeMap", createCubeMap},
	{"setFrameBufferFiltering", setFrameBufferFiltering},
	{"scaleTime", scaleTime},
	{"freeFrameBuffer", freeFrameBuffer},
	{"createFloatArray", createFloatArray},
	{"setFloatArrayValue", setFloatArrayValue},
	{"getFloatArrayValue",getFloatArrayValue},
	{"getFloatArraySize", getFloatArraySize},
	{"addMMFloat" , addMMFloat},
	{"addFloat" , addFloat},
	{"mulFloat", mulFloat},
	{"addFloats" , addFloats},
	{"mulFloats", mulFloats},
	{"copyFloats", copyFloats},
	{"setShaderNoiseSampler", setShaderNoiseSampler},
	{"createNoiseTextures", createNoiseTextures},
	{"flipNoiseTextures", flipNoiseTextures},
	{"copyTexture", copyTexture},
	{NULL, NULL}  /* sentinel */
};




