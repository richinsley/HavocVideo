//
//  FBInputStream.h
//  Havoc Video
//
//  Created by Richard Insley on 9/30/10.
//  Copyright 2010 WildWestWare. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>

@interface FBInputStream : NSInputStream < NSStreamDelegate >
{
	id mydelegate;
	
	ALAssetRepresentation * _asset;
	NSString* _filePath;
	
	NSMutableData* _predata;
	NSMutableData* _postdata;
	
	unsigned long long datasize;
	int predatasize;
	int postdatasize;
	
	unsigned long long totalsize;
	unsigned long long readpos;
	
	NSInputStream* filestream;
	
	NSStreamStatus status;
	
	int _throttleSize;
}

- (id) initWithAssetURL:(NSURL*)assetPath PreData:(NSMutableData*)predata PostData:(NSMutableData*)postdata;
- (id) initWithFilePath:(NSString*)filePath PreData:(NSMutableData*)predata PostData:(NSMutableData*)postdata;
- (unsigned long long) getLength;
@end
