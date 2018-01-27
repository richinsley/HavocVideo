//
//  AssetPlayerProtocol.h
//  Havoc Video
//
//  Created by Richard Insley on 9/17/10.
//  Copyright 2010 WildWestWare. All rights reserved.
//

#import <UIKit/UIKit.h>


@protocol AssetPlayerProtocol

- (void) playerClosed:(id)sender Asset:(NSURL*)newAsset;

@end
