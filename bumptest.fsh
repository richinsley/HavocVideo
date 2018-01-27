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
uniform sampler2D bumpTexture;
uniform sampler2D diffmap;
uniform float offsetx;
uniform float offsety;
uniform mat3 rotMat;

// some const, tweak for best look
const float sampleDist = 1.0;
const float sampleStrength = 2.2; 

void main()
{
	vec3 ObjectSpaceNormal = vec3(0.0, 0.0, 1.0);
	vec3 ObjectSpaceTangent = vec3(0.0, 1.0, 0.0);
	vec3 AmbientMaterial = vec3(0.25, 0.25, 0.25);
	vec3 SpecularMaterial = vec3(1.0, 1.0, 1.0);
	float Shininess = 4.0;	
	
	vec3 LightVector = rotMat * vec3(0.0, 0.0, 1.0);
	
	vec3 EyeVector = vec3(0.0, 0.0, -1.0);
	float Refraction = 0.05;
	
	vec3 n = normalize(ObjectSpaceNormal);
	vec3 t = normalize(ObjectSpaceTangent);
	vec3 b = normalize(cross(n , t));
	
	vec3 tangentSpaceNormal = texture2D(bumpTexture, fract(varTexcoord.st + vec2(offsetx, offsety))).rgb * 2.0 - 0.5;
	mat3 basis = mat3(n, t, b);
	vec3 N = basis * tangentSpaceNormal;
	
	vec3 H = normalize(LightVector + EyeVector);
	float df = max(0.0, dot(N, LightVector));
	float sf = max(0.0, dot(N, H));
	sf = pow(sf, Shininess);
	
	lowp vec3 diffm = texture2D(diffmap, fract(varTexcoord.st + vec2(offsetx, offsety))).rgb;
	lowp vec3 diffuse = texture2D(diffuseTexture, varTexcoord.st + (tangentSpaceNormal.xy * Refraction)).rgb;
	lowp vec3 color = AmbientMaterial + df *  diffuse + sf * SpecularMaterial;
		
    gl_FragColor = vec4(color.bgr * diffm.bgr, 1.0);
}
