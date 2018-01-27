//
//  Star_brite.fsh
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
varying mediump vec2 varTexcoord;

uniform sampler2D diffuseTexture;
uniform float minlum;
uniform float lumscale;

//calculates the luminance for an RGB color
float luminance(vec3 c)
{
	return dot( c, vec3(0.3, 0.59, 0.11) );
}

void main()
{
	float lum = luminance(texture2D(diffuseTexture, varTexcoord.st).rgb);
	if(lum > minlum)
	{
		lum = lum * lumscale;
		gl_FragColor = vec4(lum, lum, lum, 1.0);
	}
	else 
	{
		gl_FragColor = vec4(0.0, 0.0, 0.0, 1.0);
	}
}