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
uniform float angle_1;
uniform float angle_2;
uniform float offset_x;
uniform float offset_y;
uniform float raycount; // pre-div PI by ray count

vec2 calc_undistorted_coords(float wx,
								float wy,
								float angle1,
								float angle2,
								float nsegs,
								float cen_x,
								float cen_y,
								float off_x,
								float off_y)
{
	float dx, dy;
	float r, ang;

	//float awidth = 3.14159265358979323846 / nsegs;
	float mult;

	dx = wx - cen_x;
	dy = wy - cen_y;

	r = sqrt(dx*dx+dy*dy);

	ang = atan(dy,dx) - angle1 - angle2;

	mult = ceil(ang / nsegs) - 1.0;
	ang = ang - mult * nsegs;

	if (mod (mult, 2.0) == 1.0) ang = nsegs - ang;
	//ang = ang * ((mod (mult, 2.0) * 2.0) - 1.0);
	
	ang = ang + angle1;  
	return vec2(r * cos(ang) + off_x, r * sin(ang) + off_y);
}

vec2 mirror(vec2 mv)
{
	vec2 fr = fract(abs(mv));
	vec2 mf = mv - fr;
	return abs(mf - fr);
}

void main()
{
	vec2 coords = calc_undistorted_coords(varTexcoord.st.x,
										varTexcoord.st.y,
										angle_1, // angle of feed
										angle_2, // angle of display
										raycount,	// ray count
										0.5,	// cen_x
										0.5,	// cen_y
										offset_x,	// off_x
										offset_y);	// off_y
	
	gl_FragColor = vec4(texture2D(diffuseTexture, mirror(coords)).bgr, 1.0);
}