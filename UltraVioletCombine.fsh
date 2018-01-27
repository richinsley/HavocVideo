//  Shader.fsh
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
uniform sampler2D StarSampV;
uniform sampler2D StarSampH;
uniform float StarBrite;

// some const, tweak for best look
const float sampleDist = 1.0;
const float sampleStrength = 2.2; 

void main()
{

	float brite = (texture2D(StarSampV, varTexcoord.st).r + texture2D(StarSampH, varTexcoord.st).r) * StarBrite;
	vec3 s = texture2D(diffuseTexture, varTexcoord.st).bgr;
	gl_FragColor = vec4(s + brite, 1.0);
}