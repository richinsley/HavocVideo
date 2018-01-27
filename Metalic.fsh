//
//  Shader.fsh
//  VideoTexture
//
//  Created by Richard Insley on 8/17/10.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

// set the shader version
//#version 130

#ifdef GL_ES
precision highp float; // highp should only be used when necessary
#endif

varying lowp vec4 colorVarying;
varying highp vec2 varTexcoord;

uniform sampler2D diffuseTexture;
uniform sampler2D remapTexture;
uniform float offset;

//calculates the luminance for an RGB color
float luminance(vec3 c)
{
	return dot( c, vec3(0.3, 0.59, 0.11) );
}

void main()
{
	const vec3 tint = vec3(0.98, 0.97, 0.5);
	vec3 diff = texture2D(diffuseTexture, varTexcoord.st).rgb;
	float lum = luminance(diff);
	vec3 colored = lum * tint;
	float stripes = texture2D(remapTexture, vec2(lum, 0.5)).r;
    gl_FragColor = vec4( mix(lum * tint * 0.5 , mix(tint , vec3(1.0,1.0,1.0) , lum) , stripes).bgr, 1.0);
}
