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

vec2 mirror(vec2 mv)
{
	vec2 fr = fract(abs(mv));
	vec2 mf = mv - fr;
	return abs(mf - fr);
}

void main()
{
	vec3 N  = texture2D(normalTexture, varTexcoord.st).rgb - 0.5 * 0.01; // get the normals and scale
	vec3 dc = texture2D(normalTexture, mirror(varTexcoord.st + N.xy)).rgb;
	gl_FragColor = vec4(dc * vec3(1.0, 0.0, 0.0), 1.0).bgra;
}
