//
//  Shader.vsh
//  VideoTexture
//
//  Created by Richard Insley on 8/17/10.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

attribute vec4 position;
attribute vec2 inTexcoord;
attribute vec4 color;
	
varying highp vec2 varTexcoord;

uniform float translate;
uniform mat4 projMat;

void main()
{
    gl_Position = projMat * position;
    vec4 nc = color; // find a way to rid ourselves of the need for this in OSX
	varTexcoord = inTexcoord;
}
