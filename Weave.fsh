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
uniform sampler2D lenseTexture;
uniform sampler2D lightingTexture;
uniform float uoffset;
uniform float voffset;

float luminance(vec3 c)
{
	return dot( c, vec3(0.3, 0.59, 0.11) );
}

void main()
{
	const vec3 weaveVolor = vec3(1.0, 0.5, 0.1);
	const vec3 backColor = vec3(1.0, 1.0, 1.0);
	
	float freq = 2.0;
	
	vec2 Po = (varTexcoord.st);
	
	vec2 offset = vec2(uoffset, voffset);
	vec2 lensepos = fract(Po + offset);
	vec3 lense = texture2D(lenseTexture, lensepos).rgb;
	
	// get the colorps and mirror istead of clamping
	vec2 colorpos = fract(lense.rg - offset);
	
	float saturation = texture2D(lightingTexture, lensepos).r;
	vec3 color = texture2D(diffuseTexture, colorpos).rgb * lense.b;
	float lum = luminance(color);
	color = mix(lum * weaveVolor, lum * backColor, saturation);
    gl_FragColor = vec4((color).bgr, 1.0);
}
