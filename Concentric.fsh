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
uniform sampler2D lighting;
uniform float offset;

void main()
{
	vec4 uvc = texture2D(uvTexture, varTexcoord.st);
	vec2 light = texture2D(lighting, varTexcoord.st).rg;
	
	vec2 UV1 = vec2( (uvc.r * 0.996108949416342 + uvc.g * 0.003891050583658) , fract( (uvc.b * 0.996108949416342 + uvc.a * 0.003891050583658) + offset ));
	vec2 UV2 = mix((varTexcoord.st - 0.5) * 1.25 + 0.5, UV1, light.g);

	gl_FragColor = vec4(texture2D(diffuseTexture, UV2).bgr * light.r, 1.0);
}
