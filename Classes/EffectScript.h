/*
 EffectScript.h - Simple access to the Lua library
 */

#include "FrameBuffer.h"

#define LUA_LIB

extern "C" 
{
#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"
}

class EffectScript
{
private:
	lua_State *luaState;
	bool _isCurrent;
public:
	EffectScript(const luaL_reg * functions, unsigned char * script, void * userdata, FrameBuffer * defaultFrameBuffer, FrameBuffer * videoTexture );
	void loadScript(unsigned char * script);
	void Render(FrameBuffer * currentfb, double time, double rotx, double roty, double rotz, double audioLevel, GLfloat * rotm, int orientation);
	void Init();
	void Deinit();
	~EffectScript();
	void runFunction(const char * name);
	
	char * getGlobalString(const char *  name);
	void setGlobalString(const char * name, const char * value);
	double getGlobalNumber(const char *  name);
	void setGlobalNumber(const char *  name, double value);
	bool getGlobalBoolean(const char * name);
	void setGlobalBoolean(const char * name, bool value);
	lua_Integer getGlobalInt(const char * name);
	void setGlobalInt(const char * name, lua_Integer value);
	bool isCurrent();
	
	NSString * scriptName;
};

