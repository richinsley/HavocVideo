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

void main()
{
	// reverse the color channels
	gl_FragColor = texture2D(diffuseTexture, varTexcoord.st, 0.0).bgra;
	//gl_FragColor = vec4(varTexcoord.st, 1.0, 1.0);
}
