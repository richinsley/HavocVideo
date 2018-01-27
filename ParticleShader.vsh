//
//  Shader.vsh
//  VideoTexture
//
//  Created by Richard Insley on 8/17/10.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

attribute vec4 position;
attribute vec2 inTexcoord;
attribute vec2 inTexcoord2;
	
varying highp vec2 varTexcoord;
varying	highp vec2 varTexcoord2;

uniform float translate;
uniform mat4 projMat;

void main()
{
    gl_Position = projMat * position;
	varTexcoord = inTexcoord;
	varTexcoord2 = inTexcoord2;
}
