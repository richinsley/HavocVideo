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
precision mediump float; // highp should only be used when necessary
#endif

varying lowp vec4 colorVarying;
varying highp vec2 varTexcoord;

uniform sampler2D diffuseTexture;

void main (void)
{
    vec3  color;

    lowp float Cmax, Cmin;
    lowp float D;
   
    float H, S, L;
    float R, G, B;

    // get fragment color
    color = texture2D(diffuseTexture, varTexcoord.st).rgb;

    R = color.r;
    G = color.g;
    B = color.b;

	// convert to HSL
    Cmax = max (R, max (G, B));
    Cmin = min (R, min (G, B));

	// calculate lightness
    L = (Cmax + Cmin) / 2.0;
	
	D = Cmax - Cmin; // we know D != 0 so we cas safely divide by it

	float rounddown = floor(L + 0.5);
	float roundup = abs(rounddown - 1.0);
	S = ((D / (Cmax + Cmin)) * roundup) + (D / (2.0 - (Cmax + Cmin)) * rounddown);
	
	// calculate Hue
	H = 4.0 + (R - G) / D;
	if (R == Cmax)
	{
		H = (G - B) / D;
	}
	else  if (G == Cmax)
	{
		H = 2.0 + (B - R) /D;
	}
	
	H = H / 6.0;

	gl_FragColor = vec4(H, S, L, 1.0);	
}
