//
//  UV.fsh
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
uniform sampler2D uvTexture;

void main()
{
	vec4 uvc = texture2D(uvTexture, varTexcoord.st);
	
	float V = uvc.r * 0.996108949416342 + uvc.g * 0.003891050583658;
	float U = uvc.b * 0.996108949416342 + uvc.a * 0.003891050583658;

	gl_FragColor = vec4(texture2D(diffuseTexture, vec2(U,V)).bgr, 1.0);
}
