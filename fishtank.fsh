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

uniform sampler2D StarSampV;
uniform sampler2D StarSampH;
uniform sampler2D uvmap;
uniform float StarBrite;

// some const, tweak for best look
const float sampleDist = 1.0;
const float sampleStrength = 2.2; 

void main()
{
	vec3 lightb = vec3(0, 0.25, 1.0);
	vec3 darkb = vec3(0.01, 0.0, 0.25);
	
	vec4 uvc = texture2D(uvmap, varTexcoord.st);
	float V = uvc.r * 0.996108949416342 + uvc.g * 0.003891050583658;
	float U = uvc.b * 0.996108949416342 + uvc.a * 0.003891050583658;
	vec2 mapped = vec2(U, V);
	float brite = (texture2D(StarSampV, mapped).r + texture2D(StarSampH, mapped).r) * StarBrite;
	gl_FragColor = vec4(mix(lightb, darkb, brite).bgr, 1.0);
}
