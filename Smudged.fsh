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
uniform sampler2D uvTexture1;
uniform sampler2D uvTexture2;
uniform float mixuv;

void main()
{
	vec4 uvc1 = texture2D(uvTexture1, varTexcoord.st);
	vec4 uvc2 = texture2D(uvTexture2, varTexcoord.st);
	
	vec2 uv1 = vec2(uvc1.r * 0.996108949416342 + uvc1.g * 0.003891050583658 , uvc1.b * 0.996108949416342 + uvc1.a * 0.003891050583658 );
	vec2 uv2 = vec2(uvc2.r * 0.996108949416342 + uvc2.g * 0.003891050583658 , uvc2.b * 0.996108949416342 + uvc2.a * 0.003891050583658 );
	vec2 uv = mix(mix(uv1, uv2, mixuv).yx, varTexcoord.st, distance(vec2(0.5,0.5), varTexcoord.st) * 1.5);
	vec3 color = texture2D(diffuseTexture, uv).rgb;

    gl_FragColor = vec4(color.bgr * 0.5, 1.0);
}
