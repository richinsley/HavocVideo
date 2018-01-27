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
uniform float sampleDist;

uniform float distscale;

// some const, tweak for best look
const float sampleStrength = 10.2; 

void main()
{
	float ascale = min(1.0, sampleDist + 0.5);

	// some sample positions
   float samples[6];
 
	samples[0] = -0.03;
	samples[1] = -0.02;
	samples[2] = -0.01;
	samples[3] = 0.01;
	samples[4] = 0.02;
	samples[5] = 0.03;

    // 0.5,0.5 is the center of the screen
    // so substracting uv from it will result in
    // a vector pointing to the middle of the screen
    vec2 dir = 0.5 - varTexcoord.st; 
 
    // calculate the distance to the center of the screen
    float dist = sqrt(dir.x*dir.x + dir.y*dir.y); 
 
    // normalize the direction (reuse the distance)
    dir = dir/dist; 
 
    // this is the original colour of this fragment
    // using only this would result in a nonblurred version
    highp vec3 color = texture2D(diffuseTexture, varTexcoord.st).rgb; 
 
    lowp vec3 sum = color;
 
    // take 10 additional blur samples in the direction towards
    // the center of the screen
	/*
    for (int i = 0; i < 10; i++)
    {
      sum += texture2D( diffuseTexture, varTexcoord.st + dir * samples[i] * sampleDist );
    }
	*/
	
	sum += texture2D( diffuseTexture, varTexcoord.st + dir * samples[0] * ascale ).rgb;
	sum += texture2D( diffuseTexture, varTexcoord.st + dir * samples[1] * ascale ).rgb;
	sum += texture2D( diffuseTexture, varTexcoord.st + dir * samples[2] * ascale ).rgb;
	sum += texture2D( diffuseTexture, varTexcoord.st + dir * samples[3] * ascale ).rgb;
	sum += texture2D( diffuseTexture, varTexcoord.st + dir * samples[4] * ascale ).rgb;
	sum += texture2D( diffuseTexture, varTexcoord.st + dir * samples[5] * ascale ).rgb;
	
    // we have taken 6 samples
	sum = sum / 5.0;
 
    //Blend the original color with the averaged pixels
	gl_FragColor = vec4(sum.bgr + color.bgr, 1.0);
}