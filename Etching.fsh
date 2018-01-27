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
uniform sampler2D paperImage;
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
	vec3 refc = texture2D(diffuseTexture, varTexcoord.st).bgr;
	float lum = luminance(refc);
	
	// clamp lum to glyph count
	float ci = (lum * glyphcount) - fract(lum * glyphcount);
	lum = ci / glyphcount;
	
	float xoff = mod(videowidth * varTexcoord.st.x, glyphwidth) / glyphwidth;
	float yoff = mod(videoheight * varTexcoord.st.y, glyphheight) / glyphheight;
	
	xoff = xscale * xoff + lum;
	
	float glyphlum = texture2D(glyphImage, vec2(xoff , yoff)).r;
	vec3 paper = texture2D(paperImage, varTexcoord.st).bgr;
    gl_FragColor =  vec4(paper * glyphlum, 1.0);
}
