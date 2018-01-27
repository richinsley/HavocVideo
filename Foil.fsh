//
//  foil.fsh
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
uniform sampler2D normalTexture;
uniform samplerCube mappedtexture;
uniform float refraction; // 0.0 - 1.0
uniform mat3 rotMat;

void main()
{
	vec3 diffColor = vec3( 1.0, 1.0, 1.0 );
	vec3 specColor = vec3( 1.0, 1.0, 1.0 );
	float shininess = 10.0;
	float Brightness = 0.25; // 0.0 - 10.0
	vec3 L = vec3( 0.877, 0.577, 0.577 ); // vector position for light source
	vec3 H = L;
	
	vec3 N  = texture2D(normalTexture, varTexcoord.st).rgb - 0.5 * 0.01; // get the normals and scale
	N = N + vec3(varTexcoord.st * 2.0 - 1.0, 0.0);
	
	N = rotMat * N;
	
	// calc diffuse lighting
	vec3 diff = max(0.0, dot(N, L)) * diffColor;
	
	// calc spec color
	vec3 spec = pow(max(0.0, dot(N, H)), shininess) * specColor;
	
	
	//vec3 image = texture2D(mappedtexture, varTexcoord.st + (N.rg * refraction)).rgb;
	vec3 image = textureCube(mappedtexture, N).rgb;
	vec3 light = (1.0 - Brightness) + (Brightness * (diff + spec));
	//gl_FragColor = vec4((image * light + texture2D(diffuseTexture, varTexcoord.st).rgb) * 0.5, 1.0).bgra;
	gl_FragColor = vec4((image), 1.0).bgra;
}
