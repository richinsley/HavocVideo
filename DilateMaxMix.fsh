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
uniform sampler2D mixtexture;

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

	lowp vec3 val = vec3(0.0, 0.0, 0.0);
	
	// Take all neighbor samples finding the brightest
	vec2 texCoord = varTexcoord.st;
	
	lowp vec3 s00 = texture2D(diffuseTexture, texCoord + vec2(-off.x, -off.y)).rgb;
	lowp vec3 s01 = texture2D(diffuseTexture, texCoord + vec2( 0.0,   -off.y)).rgb;
	lowp vec3 s02 = texture2D(diffuseTexture, texCoord + vec2( off.x, -off.y)).rgb;

	lowp vec3 s10 = texture2D(diffuseTexture, texCoord + vec2(-off.x,  0.0)).rgb;
	lowp vec3 s12 = texture2D(diffuseTexture, texCoord + vec2( off.x,  0.0)).rgb;

	lowp vec3 s20 = texture2D(diffuseTexture, texCoord + vec2(-off.x,  off.y)).rgb;
	lowp vec3 s21 = texture2D(diffuseTexture, texCoord + vec2( 0.0,    off.y)).rgb;
	lowp vec3 s22 = texture2D(diffuseTexture, texCoord + vec2( off.x,  off.y)).rgb;
	
	val = max(s00, val);
	val = max(s01, val);
	val = max(s02, val);
	val = max(s10, val);
	val = max(s12, val);
	val = max(s20, val);
	val = max(s21, val);
	val = max(s22, val);
	
	gl_FragColor = vec4(mix(texture2D(mixtexture, texCoord).rgb , val.rgb, mixamount).rgb, 1.0);
}