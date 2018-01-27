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

float luminance(vec3 c)
{
	return dot( c, vec3(0.3, 0.59, 0.11) );
}

float numeric_stroke(float val,float Period,float Bal,float SampleWidth)
{
    float edge = Period * Bal;
    float width = 0.05;//abs(dFdx(val)) + abs(dFdy(val));
    float w = width * SampleWidth / Period;
    float x0 = val / Period - (w/2.0);
    float x1 = x0 + w;
    float nedge = edge / Period;
    float i0 = (1.0 - nedge) * floor(x0) + max(0.0, fract(x0) - nedge);
    float i1 = (1.0 - nedge) * floor(x1) + max(0.0, fract(x1) - nedge);
    float s = (i1 - i0) / w;
    s = min(1.0, max(0.0,s));
	return s;
}

void main()
{
	vec3 SurfColor = vec3(1.0, 0.0, 0.0);
	vec3 StrokeColor = vec3(0.0, 0.0, 1.0);
	vec3 SpecColor = vec3(1.0 , 1.0 , 1.0);
	
	float PeriodD = 0.05;
	float PeriodS = 0.11;
	float SWidth = 1.0;
	
	highp float lum = luminance(texture2D(diffuseTexture, varTexcoord.st).rgb);
	
	float s = numeric_stroke(lum  , PeriodD , lum , SWidth);
    vec3 diffContrib = mix(SurfColor , StrokeColor , s);
	s = numeric_stroke(lum , PeriodS , lum, SWidth);
    vec3 result = mix(SpecColor , diffContrib , s);
    gl_FragColor = vec4(result, 1.0);
}
