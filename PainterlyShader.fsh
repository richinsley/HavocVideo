//
//  PainterlyShader.fsh
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
varying	highp vec2 varTexcoord2;

uniform sampler2D diffuseTexture;
uniform sampler2D brushTexture;

float luminance(vec3 c)
{
	return dot( c, vec3(0.3, 0.59, 0.11) );
}

void main()
{
	lowp float alpha = texture2D(brushTexture, varTexcoord.st).r;
	//lowp float luma = luminance(texture2D(diffuseTexture, varTexcoord.st).rgb);
    //gl_FragColor = vec4(vec3(luma, luma, luma) * texture2D(diffuseTexture, varTexcoord2.st).rgb, alpha);
	gl_FragColor = vec4(vec3(1.0, 1.0, 1.0) * texture2D(diffuseTexture, varTexcoord2.st).rgb, alpha);
}
