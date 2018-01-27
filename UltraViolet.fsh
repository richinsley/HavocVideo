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

varying highp vec2 varTexcoord;

uniform sampler2D diffuseTexture;

const vec3 black = vec3( 0.0, 0.0, 0.0 );
const vec3 red = vec3( 1.0, 0.0, 0.0 );
const vec3 teal = vec3( 0.0, 1.0, 1.0 );
const vec3 yellow = vec3( 1.0, 1.0, 0.0 );
const vec3 green = vec3( 0.0, 1.0, 0.0 );
const vec3 blue = vec3( 0.0 , 0.0, 1.0 );
const vec3 violet = vec3( 1.0, 0.0, 1.0 );

const vec3 mblack = vec3( 0.0, 0.0, 0.0 );
const vec3 mred = vec3( 0.5, 0.0, 0.0 );
const vec3 mteal = vec3( 0.0, 0.5, 0.5 );
const vec3 myellow = vec3( 0.5, 0.5, 0.0 );
const vec3 mgreen = vec3( 0.0, 0.5, 0.0 );
const vec3 mblue = vec3( 0.0 , 0.0, 0.5 );
const vec3 mviolet = vec3( 0.5, 0.0, 0.5 );
const vec3 mwhite = vec3(0.5, 0.5, 0.5 );

void main()
{
	// set to black first
	vec3 act = texture2D(diffuseTexture, varTexcoord.st).rgb;
	float cdist = distance(act, black);
	vec3 cur = black;
	
	float ndist = distance(act, mred);
	if(ndist < cdist)
	{
		cdist = ndist;
		cur = red;
	}
	
	ndist = distance(act, mteal);
	if(ndist < cdist)
	{
		cdist = ndist;
		cur = teal;
	}
	
	ndist = distance(act, myellow);
	if(ndist < cdist)
	{
		cdist = ndist;
		cur = yellow;
	}
	
	ndist = distance(act, mgreen);
	if(ndist < cdist)
	{
		cdist = ndist;
		cur = green;
	}
	
	ndist = distance(act, mblue);
	if(ndist < cdist)
	{
		cdist = ndist;
		cur = blue;
	}
	
	ndist = distance(act, mviolet);
	if(ndist < cdist)
	{
		cdist = ndist;
		cur = violet;
	}
	
	ndist = distance(act, mwhite);
	if(ndist < cdist)
	{
		cur = black;
	}
	
    gl_FragColor = vec4(cur.rgb, 1.0);
}
