//
//  Glyph.fsh
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

varying highp vec2 varTexcoord;

uniform sampler2D diffuseTexture;
uniform sampler2D glyphImage;
uniform sampler2D SoftLUT;
uniform	float ttime;
uniform float videowidth;
uniform float videoheight;
uniform float glyphcount;
uniform float xscale;
uniform float glyphwidth;
uniform float glyphheight;

// glyphs should always be 16x16 for simplicity

float luminance(vec3 c)
{
	return dot( c, vec3(0.3, 0.59, 0.11) );
}

void main()
{
	vec3 refc = texture2D(diffuseTexture, varTexcoord.st).rgb;

    lowp float R = refc.r;
    lowp float G = refc.g;
    lowp float B = refc.b;
	
	// calc the saturation
    lowp float Cmax = max (R, max (G, B));
    lowp float Cmin = min (R, min (G, B));
    lowp float L = (Cmax + Cmin) / 2.0;
	lowp float D = Cmax - Cmin;
	float S = 0.0;
	
	if(Cmax != Cmin)
	{
		if (L < 0.5)
		{
		  S = D / (Cmax + Cmin);
		}
		else
		{
		  S = D / (2.0 - (Cmax + Cmin));
		}
	}
	float lum = luminance(refc) * 0.25;
	
	// clamp lum to glyph count
	float ci = (lum * glyphcount) - fract(lum * glyphcount);
	lum = ci / glyphcount;
	
	// flip and inverse the glyoh dots
	float xoff = 1.0 - mod(videowidth * varTexcoord.st.x, glyphwidth) / glyphwidth;
	float yoff = mod(videoheight * varTexcoord.st.y, glyphheight) / glyphheight;
	
	xoff = xscale * xoff + lum;
	
	lowp vec3 gcolor = 1.0 - (texture2D(glyphImage, vec2(xoff , yoff)).bgr * 2.0);
	
	// use the lut table to trim the saturated image
	vec2 lutCoord = vec2(S * ttime, 0.5);
	float lutTexture = texture2D(SoftLUT, lutCoord).r;
	
	//gl_FragColor = vec4(mix(gcolor , refc.bgr, S), 1.0);
	gl_FragColor = vec4(mix(gcolor , refc.bgr , lutTexture), 1.0);
	//gl_FragColor = vec4(lutTexture , lutTexture , lutTexture, 1.0);
}
