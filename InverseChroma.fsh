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

float luminance(vec3 c)
{
	return dot( c, vec3(0.3, 0.59, 0.11) );
}

float saturation(vec3 c)
{
	float minv = c.r;
	minv = min(minv, c.g);
	minv = min(minv, c.b);
	
	float maxv = c.r;
	maxv = max(maxv, c.g);
	maxv = max(maxv, c.b);
	
	return ((maxv - 0.5) + (0.5 - minv)) / 1.0;
}

void main (void)
{
    vec3  color = texture2D(diffuseTexture, varTexcoord.st).rgb;
	float l = luminance(color);
	float sat = saturation(color);
	gl_FragColor = vec4( mix( 1.0 - vec3(l,l,l), vec3(0.0, 0.0, 1.0), sat ).bgr ,1.0);
}
