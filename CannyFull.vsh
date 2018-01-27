//
//  Star_Vblur.vsh
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
uniform float diffwidth;
uniform float diffheight;

void main()
{
    gl_Position = projMat * position;
    vec4 nc = color; // find a way to rid ourselves of the need for this in OSX
	
	//varTexcoord = inTexcoord;
	
	// compute the texel offsets from the video width
	float tx = inTexcoord.st.x;
	float ty = inTexcoord.st.y;
	
	float txi = 1.0 / diffwidth;
	float tyi = 1.0 / diffheight;
	TexCoord0 = vec2(tx - txi,	ty - tyi);
    TexCoord1 = vec2(tx,		ty - tyi);
    TexCoord2 = vec2(tx + txi,	ty - tyi);
    TexCoord3 = vec2(tx - txi,	ty);
    TexCoord4 = vec2(tx,		ty);
    TexCoord5 = vec2(tx + txi,	ty);
    TexCoord6 = vec2(tx - txi,	ty + tyi);
    TexCoord7 = vec2(tx,		ty + tyi);
    TexCoord8 = vec2(tx + txi,	ty + tyi);
}
