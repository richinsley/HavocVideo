/*
 EffectScript.mm - Simple access to the Lua library
 */
#include "EffectScript.h"

EffectScript::~EffectScript()
{
	runFunction("dealloc");
	lua_close(luaState);	
}

// initialize a new script given the list of c function pointer/name pairs
EffectScript::EffectScript(const luaL_reg * functions, unsigned char * script, void * userdata, FrameBuffer * defaultFrameBuffer, FrameBuffer * videoTexture )
{	
	/* initialize Lua */
	luaState = lua_open();
	
	/* load various Lua libraries */
	luaL_openlibs(luaState);
	
	int fcount = 0;
	while(functions[fcount].name != NULL && functions[fcount].func != NULL)
	{
		lua_pushcfunction(luaState, functions[fcount].func);
		lua_setglobal(luaState, functions[fcount].name);
		fcount++;
	}
	
	// execute the script from the supplied string
	loadScript(script);
	
	// get the script's name
	scriptName = [NSString stringWithCString:this->getGlobalString("EFFECTNAME") encoding:NSUTF8StringEncoding];
	
	// broadcast the orientation change
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	[notificationCenter postNotificationName:@"effectLoading" object:scriptName];
	
	// set default values
	setGlobalInt("DEFAULTFRAMEBUFFER", (lua_Integer)defaultFrameBuffer);
	setGlobalInt("VIDEOTEXTURE", (lua_Integer)videoTexture);
	setGlobalInt("VIDEOWIDTH" , [videoTexture getWidth]);
	setGlobalInt("VIDEOHEIGHT", [videoTexture getHeight]);
								 
	// call the init with the supplied user data
	lua_getglobal(luaState, "alloc");
	lua_pushinteger(luaState, (lua_Integer)userdata);
	// call the function
	lua_call(luaState, 1, 0);
}

void EffectScript::loadScript(unsigned char * script)
{
	if(luaL_dostring(luaState, (const char *)script))
	{
		// whoopsy daisy! Show what's wrong in the console
		NSLog(@"Error in lua script: %s" , lua_tostring(luaState, -1));
	}
}

void EffectScript::Render(FrameBuffer * currentfb, double time, double rotx, double roty, double rotz, double audioLevel, GLfloat * rotm, int orientation)
{
	// the current fb can change when starting recording due to orintation changes
	setGlobalInt("DEFAULTFRAMEBUFFER", (lua_Integer)currentfb);
	
	// pass the time into lua and call the render function
	lua_getglobal(luaState, "render");
	lua_pushnumber(luaState, (lua_Number)time);
	lua_pushnumber(luaState, (lua_Number)rotx);
	lua_pushnumber(luaState, (lua_Number)roty);
	lua_pushnumber(luaState, (lua_Number)rotz);
	lua_pushnumber(luaState, (lua_Number)audioLevel);
	lua_pushinteger(luaState, (LUA_INTEGER)rotm);
	lua_pushinteger(luaState, orientation);
	// call the function
	lua_call(luaState, 7, 0);
}

// prepare the effect for use
void EffectScript::Init()
{
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	[notificationCenter postNotificationName:@"effectChanged" object:[NSNumber numberWithUnsignedInt:(lua_Integer)this]];
	
	runFunction("init");
	_isCurrent = true;
}

// shut down effect after use
void EffectScript::Deinit()
{
	runFunction("deinit");
	_isCurrent = false;
}

// returns true if this is the currently enabled effect
bool EffectScript::isCurrent()
{
	return _isCurrent;
}

void EffectScript::runFunction(const char * name)
{
	//call script function, 0 args, 0 retvals
	// lua_getglobal pushes the function onto the stack
	lua_getglobal(luaState, name);
	
	// call the function
	lua_call(luaState, 0, 0);
}
 
char * EffectScript::getGlobalString(const char *  name)
 {
	 char * retv = NULL;
	 try {
		 lua_getglobal(luaState, name);
		 retv = (char *)lua_tostring(luaState, -1);
		 lua_pop(luaState, 1);
	 }
	 catch(...) {
	 }
	 return retv;
 }
 
 void EffectScript::setGlobalString(const char * name, const char * value)
 {
	 lua_pushstring(luaState, value);
	 lua_setglobal(luaState, name);
 }
 
 double EffectScript::getGlobalNumber(const char *  name)
 {
	 double value = 0.0;
	 try {
		 lua_getglobal(luaState, name);
		 value = lua_tonumber(luaState, -1);
		 lua_pop(luaState, 1);
	 }
	 catch(...) { 
	 }
	 return value;
 }
 
 void EffectScript::setGlobalNumber(const char *  name, double value)
 {
	 lua_pushnumber(luaState, (int)value);
	 lua_setglobal(luaState, name);
 }
 
 bool EffectScript::getGlobalBoolean(const char * name)
 {
	 bool value = 0;
	 try 
	 {
		 lua_getglobal(luaState, name);
		 value = (bool) lua_toboolean(luaState, -1);
		 lua_pop(luaState, 1);
	 }
	 catch(...) 
	 { 
	 }
	 return value;
 }   
 
 void EffectScript::setGlobalBoolean(const char * name, bool value)
 {
	 lua_pushboolean(luaState, (int)value);
	 lua_setglobal(luaState, name);
 }

lua_Integer EffectScript::getGlobalInt(const char * name)
{
	bool value = 0;
	try {
		lua_getglobal(luaState, name);
		value = (int) lua_tointeger(luaState, -1);
		lua_pop(luaState, 1);
	}
	catch(...) { 
	}
	return value;
}   

void EffectScript::setGlobalInt(const char * name, lua_Integer value)
{
	lua_pushinteger(luaState, (int)value);
	lua_setglobal(luaState, name);
}

