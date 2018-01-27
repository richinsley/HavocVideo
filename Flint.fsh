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
uniform sampler2D lenseTexture;
uniform sampler2D lightingTexture;

void main()
{
	vec3 lense = texture2D(lenseTexture, varTexcoord.st).rgb;
	vec3 color = texture2D(diffuseTexture, lense.rg).rgb;
	vec3 light = texture2D(lightingTexture, varTexcoord.st).rgb;
    gl_FragColor = vec4( (color + ((light  - 0.5) * 2.0)).bgr , 1.0);
}
