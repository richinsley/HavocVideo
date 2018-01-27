attribute vec4 position;
attribute vec4 color;
attribute float pointSize;

varying vec4 fragColor;
 
void main()
{
	fragColor = color;
	gl_Position = position;
	gl_PointSize = pointSize;
}