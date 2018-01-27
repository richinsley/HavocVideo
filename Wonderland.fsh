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
uniform sampler2D remapTexture;
uniform sampler2D ntex;
uniform mat3 rotMat;

//calculates the luminance for an RGB color
float luminance(vec3 c)
{
	return dot( c, vec3(0.3, 0.59, 0.11) );
}

vec2 mirror(vec2 mv)
{
	vec2 fr = fract(abs(mv));
	vec2 mf = mv - fr;
	return abs(mf - fr);
}

void main()
{
	vec3 c = texture2D(diffuseTexture, varTexcoord.st).rgb;
	float lum = luminance(c);
	float remap = texture2D(remapTexture, vec2(lum, 0.5)).r;
	
	vec2 r = abs(fract((rotMat * vec3(varTexcoord.st, 0.5)).xy));
	float neg = texture2D(ntex, r).r;
	
	gl_FragColor = vec4(mix( mix( vec3(0.0,0.0,0.0), vec3(0.0,0.0,1.0), remap) , mix( vec3(1.0,0.0,0.0), vec3(1.0,1.0,1.0), remap) , neg).bgr , 1.0);
}
  