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
uniform highp float time;
uniform sampler2D ntex1;
uniform sampler2D ntex2;

void main()
{
	float nscale = 4.0;
	vec4 noise1 = mix(texture2D(ntex1, fract(varTexcoord.st * nscale)) , texture2D(ntex2, fract(varTexcoord.st * nscale)) , time);
	float intensity1 = (abs(noise1.r - 0.25) + abs(noise1.g - 0.125) + abs(noise1.b - 0.0625) + abs(noise1.a - 0.03125));
	intensity1 = 1.0 - clamp(intensity1 * 12.0 , 0.0, 1.0);
	vec3 R0 = texture2D(diffuseTexture, varTexcoord.st).bgr;
	
	//gl_FragColor = vec4(1.0,1.0,1.0,1.0);
	gl_FragColor = vec4(R0 * intensity1, 1.0);
	//gl_FragColor = vec4( mix( vec3( dot( R0, vec3( 0.2125, 0.7154, 0.0721 ) ) ), R0, intensity1 ), 1.0 );
}
