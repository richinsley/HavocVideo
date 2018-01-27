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
uniform float time;

float Hue_2_RGB(float v1, float v2, float vH )
{
	lowp float ret = v1;
	
	vH = fract(vH + 1.0);
	
	if ( ( 6.0 * vH ) < 1.0 )
		ret = ( v1 + ( v2 - v1 ) * 6.0 * vH );
	else if ( ( 2.0 * vH ) < 1.0 )
		ret = ( v2 );
	else if ( ( 3.0 * vH ) < 2.0 )
		ret = ( v1 + ( v2 - v1 ) * ( ( 2.0 / 3.0 ) - vH ) * 6.0 );
		
	return ret;
}

void main()
{
    lowp vec3 hsl = texture2D(diffuseTexture, varTexcoord.st).rgb;
	
	// convert back to RGB
	float H = abs(fract(hsl.r + time));
	float S = hsl.g;
	float L = hsl.b;
	
	float var_2, var_1;

	float rounddown = floor(L + 0.5);
	float roundup = abs(rounddown - 1.0);
	var_2 = (L * ( 1.0 + S ) * roundup) + ((( L + S ) - ( S * L )) * rounddown);
	
	var_1 = 2.0 * L - var_2;

	lowp float B = Hue_2_RGB( var_1, var_2, H + ( 1.0 / 3.0 ) );
	lowp float G = Hue_2_RGB( var_1, var_2, H );
	lowp float R = Hue_2_RGB( var_1, var_2, H - ( 1.0 / 3.0 ) );

	gl_FragColor = vec4(R, G, B, 1.0);
}
