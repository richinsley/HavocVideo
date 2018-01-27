//
//  Star_brite.fsh
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

#define WT9_0 1.0
#define WT9_1 0.8
#define WT9_2 0.6
#define WT9_3 0.4
#define WT9_4 0.2

#define WT9_NORMALIZE (WT9_0 + 2.0 * (WT9_1 + WT9_2 + WT9_3 + WT9_4))

varying vec2 TexCoord0;
varying vec2 TexCoord1;
varying vec2 TexCoord2;
varying vec2 TexCoord3;
varying vec2 TexCoord4;
varying vec2 TexCoord5;
varying vec2 TexCoord6;
varying vec2 TexCoord7;
varying vec2 TexCoord8;  

varying lowp vec4 colorVarying;

uniform sampler2D diffuseTexture;

void main()
{
	float OutCol = texture2D(diffuseTexture, TexCoord0).r * (WT9_1/WT9_NORMALIZE);
    OutCol += texture2D(diffuseTexture,		TexCoord1).r * (WT9_2/WT9_NORMALIZE);
    OutCol += texture2D(diffuseTexture,		TexCoord2).r * (WT9_3/WT9_NORMALIZE);
    OutCol += texture2D(diffuseTexture,		TexCoord3).r * (WT9_4/WT9_NORMALIZE);
    OutCol += texture2D(diffuseTexture,		TexCoord4).r * (WT9_0/WT9_NORMALIZE);
    OutCol += texture2D(diffuseTexture,		TexCoord5).r * (WT9_1/WT9_NORMALIZE);
    OutCol += texture2D(diffuseTexture,		TexCoord6).r * (WT9_2/WT9_NORMALIZE);
    OutCol += texture2D(diffuseTexture,		TexCoord7).r * (WT9_3/WT9_NORMALIZE);
    OutCol += texture2D(diffuseTexture,		TexCoord8).r * (WT9_3/WT9_NORMALIZE);
    gl_FragColor = vec4(OutCol, OutCol, OutCol, 1.0);
}