//
//  display.fsh
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
uniform sampler2D mixsampler;
uniform float scaleX;
uniform float scaleY;
uniform float mixamount;
uniform float atten;
uniform float centerx;
uniform	float centery;

vec2 mirror(vec2 mv)
{
	vec2 fr = fract(abs(mv));
	vec2 mf = mv - fr;
	return abs(mf - fr);
}

void main()
{
	float sx = (varTexcoord.st.x - 0.5) * scaleX + centerx;
	float sy = (varTexcoord.st.y - 0.5) * scaleY + centery;
	lowp vec3 cc = texture2D(diffuseTexture, varTexcoord.st).rgb;
	lowp vec3 cc2 = texture2D(mixsampler, mirror(vec2(sx,sy))).rgb * atten;
	lowp vec3 nc = abs(cc - cc2);
	gl_FragColor = vec4(nc, 1.0);
}
