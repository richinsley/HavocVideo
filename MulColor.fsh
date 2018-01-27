//
//  DefaultNoFlip.fsh
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
uniform	float red;
uniform	float green;
uniform	float blue;

void main()
{
	vec3 cv = vec3(red, green, blue);
    gl_FragColor = vec4(texture2D(diffuseTexture, varTexcoord.st).rgb * cv, 1.0);
}
