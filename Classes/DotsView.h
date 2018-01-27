//
//  DotsView.h
//  Havoc Video
//
//  Created by Richard Insley on 10/14/10.
//  Copyright 2010 WildWestWare. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface DotsView : UIView {
	int pageCount;
	int currentPage;
	int dotSize;
	int dotGap;
}

@property (readonly, nonatomic) int currentPage;
@property (readonly, nonatomic) int pageCount;

-(void)setDotGap:(int)gap;
-(void)setDotSize:(int)s;
-(void)setPageCount:(int)count;
-(void)setCurrentPage:(int)page;

@end
