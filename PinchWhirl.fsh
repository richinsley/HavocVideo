//
//  PinchWhirl.fsh
//  VideoTexture
//
//  Created by Richard Insley on 8/17/10.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

// set the shader version
//#version 130

#ifdef GL_ES
precision mediump float; // highp should only be used when necessary
#endif

varying lowp vec4 colorVarying;
varying highp vec2 varTexcoord;

uniform sampler2D diffuseTexture;
uniform float xscale;
uniform float yscale;
uniform float amount;
uniform float centerx;
uniform float centery;
uniform float radius;
uniform float whirl;

vec2 mirror(vec2 mv)
{
	vec2 fr = fract(abs(mv));
	vec2 mf = mv - fr;
	return abs(mf - fr);
}

void main()
{
	float xhsiz = 1.0;
	float yhsiz = 1.0;

	float x = varTexcoord.st.x;
	float y = varTexcoord.st.y;
	
	float dx = (x - centerx) * xscale;
	float dy = (y - centery) * yscale;
	
	//distance
	float d = distance( varTexcoord.st, vec2(centerx,centery) );
	
	float radius2 = radius * radius;
	
	float amnt = pow(sin(1.57079632679489661923 * sqrt(d) / radius), amount);
	
	dx *= amnt;
	dy *= amnt;
	
	float w = whirl * 3.14159265358979323846 / 180.0;
	float wfactor = 1.0 - d;
	float ang = w * wfactor * wfactor;
	float sina = sin(ang);
	float cosa = cos(ang);
	
	float needx = (cosa * dx - sina * dy) + centerx;
	float needy = (sina * dx + cosa * dy) + centery;
	
	gl_FragColor = texture2D(diffuseTexture, mirror(vec2(needx,needy))).bgra;
}

/*
float xscale <
    string UIWidget = "slider";
    float UIMin = -2.0f;
    float UIMax = 2.0f;
    float UIStep = 0.0001f;
	string UIName = "x scale";
> =1.0f;

float yscale <
    string UIWidget = "slider";
    float UIMin = -2.0f;
    float UIMax = 2.0f;
    float UIStep = 0.0001f;
	string UIName = "y scale";
> =1.0f;

float amount <
    string UIWidget = "slider";
    float UIMin = -10.0f;
    float UIMax = 10.0f;
    float UIStep = 0.0001f;
	string UIName = "Pinch Pull";
> =0.0f;

float centerx <
    string UIWidget = "slider";
    float UIMin = -1.5f;
    float UIMax = 2.5f;
    float UIStep = 0.0001f;
	string UIName = "centerx";
> =0.5f;

float centery <
    string UIWidget = "slider";
    float UIMin = -1.5f;
    float UIMax = 2.5f;
    float UIStep = 0.0001f;
	string UIName = "centery";
> =0.5f;

float radius <
    string UIWidget = "slider";
    float UIMin = -2.0f;
    float UIMax = 2.0f;
    float UIStep = 0.0001f;
	string UIName = "radius";
> = 1.0f;

float whirl <
    string UIWidget = "slider";
    float UIMin = -1000.0f;
    float UIMax = 1000.0f;
    float UIStep = 0.0001f;
	string UIName = "whirl";
> = 1.0f;

float4 PS_Textured( vertexOutput IN): COLOR
{
	float xhsiz = 1.0;
	float yhsiz = 1.0;

	float x = IN.texCoordDiffuse.x;
	float y = IN.texCoordDiffuse.y;
	
	float dx = (x - centerx) * xscale;
	float dy = (y - centery) * yscale;
	
	//distance
	float d = distance( float2(x,y),float2(centerx,centery) );
	
	float radius2 = radius * radius;
	
	float amnt = pow(sin(1.57079632679489661923 * sqrt(d) / radius), amount);
	
	dx *= amnt;
	dy *= amnt;
	
	float w = whirl * 3.14159265358979323846 / 180.0;
	float wfactor = 1.0 - d;
	float ang = w * wfactor * wfactor;
	float sina = sin(ang);
	float cosa = cos(ang);
	
	float needx = (cosa * dx - sina * dy) + centerx;
	float needy = (sina * dx + cosa * dy) + centery;
	
  float4 scnColor = tex2D(TextureSampler, float2(needx,needy));
	return scnColor;
}
*/


