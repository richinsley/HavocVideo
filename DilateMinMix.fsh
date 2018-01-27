//
//  DilateMinMix.fsh
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
uniform sampler2D mixtexture;
uniform sampler2D sobeltexture;

uniform float diffwidth;
uniform float diffheight;
uniform float mixamount;

float luminance(vec3 c)
{
	return dot( c, vec3(0.3, 0.59, 0.11) );
}

void main()
{
	vec2 off = vec2(1.0 / diffwidth, 1.0 / diffheight);

	lowp float val = 1.0;
	
	// Take all neighbor samples finding the brightest
	vec2 texCoord = varTexcoord.st;
	
	lowp float s00 = texture2D(diffuseTexture, texCoord + vec2(-off.x, -off.y)).r;
	lowp float s01 = texture2D(diffuseTexture, texCoord + vec2( 0.0,   -off.y)).r;
	lowp float s02 = texture2D(diffuseTexture, texCoord + vec2( off.x, -off.y)).r;

	lowp float s10 = texture2D(diffuseTexture, texCoord + vec2(-off.x,  0.0)).r;
	lowp float s12 = texture2D(diffuseTexture, texCoord + vec2( off.x,  0.0)).r;

	lowp float s20 = texture2D(diffuseTexture, texCoord + vec2(-off.x,  off.y)).r;
	lowp float s21 = texture2D(diffuseTexture, texCoord + vec2( 0.0,    off.y)).r;
	lowp float s22 = texture2D(diffuseTexture, texCoord + vec2( off.x,  off.y)).r;
	
	val = min(s00, val);
	val = min(s01, val);
	val = min(s02, val);
	val = min(s10, val);
	val = min(s12, val);
	val = min(s20, val);
	val = min(s21, val);
	val = min(s22, val);

	// combine the sobel outline with the new video frame
	lowp float lum = luminance(texture2D(mixtexture, texCoord).rgb) * texture2D(sobeltexture, texCoord).r;
	
	gl_FragColor = vec4(mix( vec3(lum,lum,lum) , vec3(val,val,val), mixamount).rgb, 1.0);
}