
#import "AccelerometerFilter.h"

// Implementation of the basic filter. All it does is mirror input to output.

@implementation AccelerometerFilter

@synthesize x, y, z, adaptive, lastTimestamp;

-(void)addAcceleration:(CMAcceleration)accel withTimestamp:(NSTimeInterval)timestamp
{
	x = accel.x;
	y = accel.y;
	z = accel.z;
	lastTimestamp = timestamp;
}

-(void)setCutoffFrequency:(double)fc
{
	RC = 1.0 / fc;
}

-(NSString*)name
{
	return @"You should not see this";
}

@end

#define kAccelerometerMinStep				0.02
#define kAccelerometerNoiseAttenuation		3.0

double Norm(double x, double y, double z)
{
	return sqrt(x * x + y * y + z * z);
}

double Clamp(double v, double min, double max)
{
	if(v > max)
		return max;
	else if(v < min)
		return min;
	else
		return v;
}

// See http://en.wikipedia.org/wiki/Low-pass_filter for details low pass filtering
@implementation LowpassFilter

-(id)initWithCutoffFrequency:(double)freq
{
	self = [super init];
	if(self != nil)
	{
		RC = 1.0 / freq;
		lastTimestamp = -1.0;
	}
	return self;
}

-(void)addAcceleration:(CMAcceleration)accel withTimestamp:(NSTimeInterval)timestamp
{	
	if (lastTimestamp >= 0.0) {
		NSTimeInterval dt = timestamp - lastTimestamp;
		double filterConstant = dt / (dt + RC);
		double alpha = filterConstant;
		
		if(adaptive)
		{
			double d = Clamp(fabs(Norm(x, y, z) - Norm(accel.x, accel.y, accel.z)) / kAccelerometerMinStep - 1.0, 0.0, 1.0);
			alpha = (1.0 - d) * filterConstant / kAccelerometerNoiseAttenuation + d * filterConstant;
		}
		
		x = accel.x * alpha + x * (1.0 - alpha);
		y = accel.y * alpha + y * (1.0 - alpha);
		z = accel.z * alpha + z * (1.0 - alpha);
	}
	lastTimestamp = timestamp;
}

-(NSString*)name
{
	return adaptive ? @"Adaptive Lowpass Filter" : @"Lowpass Filter";
}

@end

// See http://en.wikipedia.org/wiki/High-pass_filter for details on high pass filtering
@implementation HighpassFilter

-(id)initWithCutoffFrequency:(double)freq
{
	self = [super init];
	if(self != nil)
	{
		RC = 1.0 / freq;
		lastTimestamp = -1.0;
	}
	return self;
}

-(void)addAcceleration:(CMAcceleration)accel withTimestamp:(NSTimeInterval)timestamp
{
	if (lastTimestamp >= 0.0) {
		NSTimeInterval dt = timestamp - lastTimestamp;
		double filterConstant = dt / (dt + RC);
		double alpha = filterConstant;
		
		if(adaptive)
		{
			double d = Clamp(fabs(Norm(x, y, z) - Norm(accel.x, accel.y, accel.z)) / kAccelerometerMinStep - 1.0, 0.0, 1.0);
			alpha = d * filterConstant / kAccelerometerNoiseAttenuation + (1.0 - d) * filterConstant;
		}
		
		x = alpha * (x + accel.x - lastX);
		y = alpha * (y + accel.y - lastY);
		z = alpha * (z + accel.z - lastZ);
	
		lastX = accel.x;
		lastY = accel.y;
		lastZ = accel.z;
	}
	lastTimestamp = timestamp;
}

-(NSString*)name
{
	return adaptive ? @"Adaptive Highpass Filter" : @"Highpass Filter";
}

@end