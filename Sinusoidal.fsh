//
//  Sinusoidal.fsh
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
uniform float Timer;
uniform float TimeScale;
uniform float Vertical;
uniform float Horizontal;

vec2 mirror(vec2 mv)
{
	vec2 fr = fract(abs(mv));
	vec2 mf = mv - fr;
	return abs(mf - fr);
}

void main()
{
	float freq = 2.0;
	
	vec2 Po = varTexcoord.st;
	float timeNow = (Timer * (3.14159265 * 2.0 * TimeScale));

	Po.x = Po.x + (sin((Po.y * (3.14159265 * 2.0) * freq) + (freq * timeNow)) * Horizontal);
	Po.y = Po.y + (cos((Po.x * (3.14159265 * 2.0) * freq) + (freq * timeNow)) * Vertical);
	
	gl_FragColor = vec4(texture2D(diffuseTexture, mirror(Po)).bgr , 1.0);
}