//
//  Neon.fsh
//  VideoTexture
//
//  Created by Richard Insley on 8/17/10.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

// set the shader version
//#version 130

#ifdef GL_ES
precision mediump float; // highp should only be used when necessary
#endif

varying lowp vec4 colorVarying;
varying highp vec2 varTexcoord;

uniform sampler2D diffuseTexture;

uniform float diffwidth;
uniform float diffheight;

uniform highp float time;
uniform sampler2D noiseTexture;

float luminance(vec3 c)
{
	return dot( c, vec3(0.3, 0.59, 0.11) );
}

void main()
{
	vec2 off = vec2(1.0 / diffwidth, 1.0 / diffheight);

	// Take all neighbor samples
	vec2 texCoord = varTexcoord.st;
	
	lowp vec3 s00 = texture2D(diffuseTexture, texCoord + vec2(-off.x, -off.y)).xyz;
	lowp vec3 s01 = texture2D(diffuseTexture, texCoord + vec2( 0.0,   -off.y)).xyz;
	lowp vec3 s02 = texture2D(diffuseTexture, texCoord + vec2( off.x, -off.y)).xyz;

	lowp vec3 s10 = texture2D(diffuseTexture, texCoord + vec2(-off.x,  0.0)).xyz;
	lowp vec3 s12 = texture2D(diffuseTexture, texCoord + vec2( off.x,  0.0)).xyz;

	lowp vec3 s20 = texture2D(diffuseTexture, texCoord + vec2(-off.x,  off.y)).xyz;
	lowp vec3 s21 = texture2D(diffuseTexture, texCoord + vec2( 0.0,    off.y)).xyz;
	lowp vec3 s22 = texture2D(diffuseTexture, texCoord + vec2( off.x,  off.y)).xyz;
	

	lowp vec3 Gx = -(s00 + 2.0 * s10 + s20) + (s02 + 2.0 * s12 + s22);
	lowp vec3 Gy = -(s00 + 2.0 * s01 + s02) + (s20 + 2.0 * s21 + s22);

	lowp vec3 color = sqrt((Gx * Gx) + (Gy + Gy));
	lowp float lum = luminance(color);
	
	vec2 nst = fract(varTexcoord.st * 3.0);
	float noise = texture2D(noiseTexture, vec2( fract(time + varTexcoord.st.x), varTexcoord.st.y)).r;
	
	if(lum < 0.7) 
	{	
		lum = 0.0;
	}
	else 
	{
		lum = noise;
	}

	gl_FragColor = vec4(lum, lum, lum, 1.0);
}