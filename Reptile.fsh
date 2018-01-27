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
uniform sampler2D lenseTexture;
uniform sampler2D lightingTexture;
uniform float uoffset;
uniform float voffset;

uniform float Timer;
uniform float TimeScale;
uniform float Vertical;

void main()
{
	float freq = 2.0;
	
	vec2 Po = (varTexcoord.st - 0.5) * 0.9 + 0.5;
	float timeNow = (Timer * (3.14159265 * 2.0 * TimeScale));

	//Po.x = Po.x + (sin((Po.y * (3.14159265 * 2.0) * freq) + (freq * timeNow)) * Horizontal);
	Po.y = Po.y + (cos((Po.x * (3.14159265 * 2.0) * freq) + (freq * timeNow)) * Vertical);
	
	vec2 offset = vec2(uoffset, voffset);
	vec2 lensepos = fract(Po + offset);
	vec3 lense = texture2D(lenseTexture, lensepos).rgb;
	
	// get the colorps and mirror istead of clamping
	vec2 colorpos = fract(lense.rg - offset);
	
	vec3 color = texture2D(diffuseTexture, colorpos).rgb * lense.b;
	vec3 light = texture2D(lightingTexture, lensepos).rgb;
    gl_FragColor = vec4((color + light).bgr, 1.0);
}
