//
//  UV2.fsh
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

uniform float offx;
uniform float offy;

void main()
{
	vec4 uvc = texture2D(uvTexture, varTexcoord.st);
	
	vec2 uv = vec2(fract((uvc.r * 0.996108949416342 + uvc.g * 0.003891050583658) + offx) , fract((uvc.b * 0.996108949416342 + uvc.a * 0.003891050583658) + offy) );

	vec3 color = texture2D(diffuseTexture, uv).rgb;
	vec3 light = texture2D(diffuseTexture, mix(varTexcoord.st , uv, 0.25) ).rgb;
    gl_FragColor = vec4((color + light).bgr * 0.5, 1.0);
}
