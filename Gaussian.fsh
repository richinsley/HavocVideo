//
//  Gaussian.fsh
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

varying vec2 TexCoord0;
varying vec2 TexCoord1;
varying vec2 TexCoord2;
varying vec2 TexCoord3;
varying vec2 TexCoord4;
varying vec2 TexCoord5;
varying vec2 TexCoord6;
varying vec2 TexCoord7;
varying vec2 TexCoord8;  

varying lowp vec4 colorVarying;
varying highp vec2 varTexcoord;

uniform sampler2D diffuseTexture;

void main()
{
	// Gaussian kernel
	// 1 2 1
	// 2 4 2
	// 1 2 1	
	
	vec3 s00 = texture2D(diffuseTexture, TexCoord0).xyz * (1.0/16.0);
	s00 += texture2D(diffuseTexture, TexCoord1).xyz * (2.0/16.0);
	s00 += texture2D(diffuseTexture, TexCoord2).xyz * (1.0/16.0);

	s00 += texture2D(diffuseTexture, TexCoord3).xyz * (2.0/16.0);
	s00 += texture2D(diffuseTexture, TexCoord4).xyz * (4.0/16.0);
	s00 += texture2D(diffuseTexture, TexCoord5).xyz * (2.0/16.0);

	s00 += texture2D(diffuseTexture, TexCoord6).xyz * (1.0/16.0);
	s00 += texture2D(diffuseTexture, TexCoord7).xyz * (2.0/16.0);
	s00 += texture2D(diffuseTexture, TexCoord8).xyz * (1.0/16.0);
	
	gl_FragColor = vec4(s00.bgr, 1.0);
}
