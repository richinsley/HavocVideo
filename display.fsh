//
//  display.fsh
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
	if(varTexcoord.st.x == 0)
	{
		gl_FragColor = vec4(1.0, 0.0, 0.0, 1.0);
	}
	else
	{
		lowp vec4 cc = texture2D(diffuseTexture, varTexcoord.st);
		gl_FragColor = vec4(cc.bgr, 1.0);
	}
}
