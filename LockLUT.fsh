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
uniform sampler2D diff2;
uniform sampler2D lut;
uniform float time;

float luminance(vec3 c)
{
	return dot( c, vec3(0.3, 0.59, 0.11) );
}

void main()
{
	vec3 diff = texture2D(diffuseTexture, varTexcoord.st).rgb;
	vec3 mask = texture2D(diff2, varTexcoord.st).rgb;
	vec2 lutCoord = vec2(clamp((luminance(mask) * 0.4) + (0.6 * time), 0.1, 0.9), 0.5);
	float lutt =  texture2D(lut, lutCoord).r;
    gl_FragColor = vec4(mix(diff, mask, lutt).bgr, 1.0);
}
