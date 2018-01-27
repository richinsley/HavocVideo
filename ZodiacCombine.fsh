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
precision mediump float; // highp should only be used when necessary
#endif

varying lowp vec4 colorVarying;
varying mediump vec2 varTexcoord;

uniform sampler2D diffuseTexture;
uniform sampler2D StarSampV;
uniform sampler2D StarSampH;
uniform float StarBrite;

uniform samplerCube mappedtexture;
uniform mat3 rotMat;

// some const, tweak for best look
const float sampleDist = 1.0;
const float sampleStrength = 2.2; 

void main()
{

	float brite = (texture2D(StarSampV, varTexcoord.st).r + texture2D(StarSampH, varTexcoord.st).r);
	vec3 N = normalize(vec3(varTexcoord.st * 2.0 - 1.0, 1.0));
	N = rotMat * N;
	vec3 nebula = textureCube(mappedtexture, N).bgr * 0.25;
	gl_FragColor = vec4(nebula + (brite * StarBrite) , 1.0);
}
