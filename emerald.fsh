//
//  foil.fsh
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
varying highp vec2 varTexcoord;

uniform sampler2D diffuseTexture;
uniform sampler2D normalTexture;
uniform sampler2D lightTexture;

vec2 mirror(vec2 mv)
{
	vec2 fr = fract(abs(mv));
	vec2 mf = mv - fr;
	return abs(mf - fr);
}

void main()
{
	vec3 N  = texture2D(normalTexture, varTexcoord.st).rgb - 0.5 * 0.01; // get the normals and scale
	//N = normalize(N + vec3(varTexcoord.st * 2.0 - 1.0, 1.0));
	vec3 dc = texture2D(normalTexture, mirror(varTexcoord.st + N.xy)).rgb;
	float light = texture2D(lightTexture, varTexcoord.st).r;
	gl_FragColor = vec4(dc * vec3(0.0, 1.0, 0.0) * light, 1.0).bgra;
}
