//
//  CAnny.fsh
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

varying vec2 TexCoord0;
varying vec2 TexCoord1;
varying vec2 TexCoord2;
varying vec2 TexCoord3;
varying vec2 TexCoord4;
varying vec2 TexCoord5;
varying vec2 TexCoord6;
varying vec2 TexCoord7;
varying vec2 TexCoord8;  

varying lowp vec4 colorVarying;
varying highp vec2 varTexcoord;

uniform sampler2D diffuseTexture;

float luminance(vec3 c)
{
	return dot( c, vec3(0.3, 0.59, 0.11) );
}

void main()
{
	// Take all neighbor samples
	
	lowp vec3 s00 = texture2D(diffuseTexture, TexCoord0).xyz;
	lowp vec3 s01 = texture2D(diffuseTexture, TexCoord1).xyz;
	lowp vec3 s02 = texture2D(diffuseTexture, TexCoord2).xyz;

	lowp vec3 s10 = texture2D(diffuseTexture, TexCoord3).xyz;
	// s11 is center TexCoord4
	lowp vec3 s12 = texture2D(diffuseTexture, TexCoord5).xyz;

	lowp vec3 s20 = texture2D(diffuseTexture, TexCoord6).xyz;
	lowp vec3 s21 = texture2D(diffuseTexture, TexCoord7).xyz;
	lowp vec3 s22 = texture2D(diffuseTexture, TexCoord8).xyz;
	
	vec3 ul = s00 * -1.0;
	vec3 sum1 = ul + s02 + (s10 * -2.0) + (s12 * 2.0) + (s20 * -1.0) + s22;
	vec3 sum2 = ul + (s01 * -2.0) + (s02 * -1.0) + s20 + (s21 * 2.0) + s22;
	lowp float tl = 1.0 - luminance(min(((abs(sum1) + abs(sum2)) / 2.0) , 1.0));
	lowp float lum = luminance( texture2D(diffuseTexture, TexCoord4).xyz);
	vec3 c = texture2D(diffuseTexture, TexCoord4).bgr;
	gl_FragColor = vec4(c * tl, 1.0);
}
