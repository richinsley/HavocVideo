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

void main()
{
	float sx = (varTexcoord.st.x - 0.5) * scaleX + 0.5;
	float sy = (varTexcoord.st.y - 0.5) * scaleY + 0.5;
	lowp vec3 cc = texture2D(diffuseTexture, varTexcoord.st).rgb;
	lowp vec3 cc2 = texture2D(mixsampler, vec2(sx,sy)).rgb * atten;
	lowp vec3 nc = mix(cc, cc2, mixamount);
	gl_FragColor = vec4(nc, 1.0);
}
