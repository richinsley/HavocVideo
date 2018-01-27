//
//  bleachbypass.fsh
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
uniform float Opacity;

//calculates the luminance for an RGB color
float luminance(vec3 c)
{
	return dot( c, vec3(0.3, 0.59, 0.11) );
}

void main()
{
	vec4 base = texture2D(diffuseTexture, varTexcoord.st, 0.0);
	float lum = luminance(base.xyz);
	vec3 blend = vec3(lum,lum,lum);
    float L = min(1.0,max(0.0,10.0*(lum- 0.45)));
    vec3 result1 = 2.0 * base.rgb * blend;
    vec3 result2 = 1.0 - 2.0*(1.0-blend)*(1.0-base.rgb);
	vec3 newColor = mix(result1,result2,L);
    float A2 = Opacity * base.a;
    vec3 mixRGB = A2 * newColor.rgb;
    mixRGB += ((1.0-A2) * base.rgb);
	gl_FragColor = vec4(mixRGB.bgr, 1.0);
}

