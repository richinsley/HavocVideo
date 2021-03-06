//
//  Shader.vsh
//  VideoTexture
//
//  Created by Richard Insley on 8/17/10.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

varying vec2 TexCoord0;
varying vec2 TexCoord1;
varying vec2 TexCoord2;
varying vec2 TexCoord3;
varying vec2 TexCoord4;
varying vec2 TexCoord5;
varying vec2 TexCoord6;
varying vec2 TexCoord7;
varying vec2 TexCoord8;   

attribute vec4 position;
attribute vec2 inTexcoord;
attribute vec4 color;

uniform float translate;
uniform mat4 projMat;
uniform float videowidth;

void main()
{
    gl_Position = projMat * position;
    vec4 nc = color; // find a way to rid ourselves of the need for this in OSX
	
	// compute the texel offsets from the video width
	float tx = inTexcoord.st.x;
	float ty = inTexcoord.st.y;
	
	float TexelIncrement = 1.0 / videowidth;
	TexCoord0 = vec2(tx + TexelIncrement, ty);
    TexCoord1 = vec2(tx + TexelIncrement * 2.0, ty);
    TexCoord2 = vec2(tx + TexelIncrement * 3.0, ty);
    TexCoord3 = vec2(tx + TexelIncrement * 4.0, ty);
    TexCoord4 = vec2(tx, ty);
    TexCoord5 = vec2(tx - TexelIncrement, ty);
    TexCoord6 = vec2(tx - TexelIncrement * 2.0, ty);
    TexCoord7 = vec2(tx - TexelIncrement * 3.0, ty);
    TexCoord8 = vec2(tx - TexelIncrement * 4.0, ty);
}
