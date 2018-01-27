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

varying highp vec2 varTexcoord;

uniform sampler2D diffuseTexture;

float luminance(vec3 c)
{
	return dot( c, vec3(0.3, 0.59, 0.11) );
}

// combine with dilate to perform phantom
void main()
{
	highp float lum = luminance(texture2D(diffuseTexture, varTexcoord.st).rgb);
	//float ci = (lum * 16.0) - fract(lum * 16.0);
	//lum = ci / 16.0;
    gl_FragColor = vec4(lum, lum, lum, 1.0);
}
