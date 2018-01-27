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
varying	highp vec2 varTexcoord2;

uniform sampler2D diffuseTexture;
uniform sampler2D maskTexture;

void main()
{
	vec2 holder = varTexcoord2;
	float mask = texture2D(maskTexture, varTexcoord.st).r;
    gl_FragColor = vec4(texture2D(diffuseTexture, varTexcoord.st).rgb, mask);
}
