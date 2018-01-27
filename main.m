//
//  main.m
//  VideoTexture
//
//  Created by Richard Insley on 8/17/10.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import <UIKit/UIKit.h>

int main(int argc, char *argv[]) {
    
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	int retVal = 0;
	@try
	{
		int retVal = UIApplicationMain(argc, argv, nil, nil);
	}
	@catch (NSException *exception) 
	{
		NSLog(@"main: Caught %@: %@", [exception name], [exception reason]);
	}
	
    [pool release];
    return retVal;
}
