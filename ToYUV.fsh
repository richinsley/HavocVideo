//
//  ToYUV.fsh
//  VideoTexture
//
//  Created by Richard Insley on 8/17/10.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#ifdef GL_ES
precision highp float; // highp should only be used when necessary
#endif

varying lowp vec4 colorVarying;
varying vec2 varTexcoord;

uniform sampler2D diffuseTexture;

vec3 rgb_to_yuv(vec3 RGB)
{
    vec3 y = dot(RGB,vec3(0.299, 0.587, 0.114));
    vec3 u = (RGB.z - y) * 0.565;
    vec3 v = (RGB.x - y) * 0.713;
    return vec3(y,u,v);
}

vec3 yuv_to_rgb(vec3 YUV)
{
   vec3 u = YUV.y;
   vec3 v = YUV.z;
   vec3 r = YUV.x + 1.403*v;
   vec3 g = YUV.x - 0.344*u - 1.403*v;
   vec3 b = YUV.x + 1.770*u;
   return vec3(r,g,b);
}

main()
{
	vec3 R0 = texture2D(diffuseTexture, varTexcoord.st, 0.0).rgb;
	vec3 yuv = rgb_to_yuv(r0);
	gl_FragColor = vec4(yuv.x, yuv.y + 0.5, yuv.z + 0.5, 1.0); // normalize UV to 0.0 - 1.0
}