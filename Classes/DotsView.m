//
//  DotsView.m
//  Havoc Video
//
//  Created by Richard Insley on 10/14/10.
//  Copyright 2010 WildWestWare. All rights reserved.
//

#import "DotsView.h"


@implementation DotsView

@synthesize currentPage;
@synthesize pageCount;

- (id)initWithFrame:(CGRect)frame 
{
    if ((self = [super initWithFrame:frame])) 
	{
        // Initialization code
    }
    return self;
}


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect 
{
    // Drawing code
	CGContextRef myContext = UIGraphicsGetCurrentContext();
	
	// CGContextSetLineWidth sets the pen size (default is one)
	int tsize = (dotSize * pageCount) + (dotGap * MAX(pageCount - 1 , 0));
	int startc = self.bounds.size.height / 2 - (tsize / 2);
	int left = self.bounds.size.width / 2 - dotSize / 2;
	
	CGFloat color[4];  color[0] = 1.0;color[1] = 1.0;color[2] = 1.0;color[3] = 1.0;
	CGFloat color2[4]; color2[0] = 1.0;color2[1] = 1.0;color2[2] = 1.0;color2[3] = 0.7;
	CGFloat color3[4]; color3[0] = 0.0;color3[1] = 0.0;color3[2] = 0.0;color3[3] = 0.7;
	
	CGContextSetStrokeColor(myContext, color);
	CGContextSetFillColor(myContext, color2);
	
	for(int i = 0; i < pageCount; i++)
	{
		if( i == currentPage)
		{
			CGContextSetFillColor(myContext, color2);
		}
		else
		{
			CGContextSetFillColor(myContext, color3);
		}
		
		CGContextFillEllipseInRect(myContext, CGRectMake(left, startc, dotSize, dotSize));
		CGContextStrokeEllipseInRect(myContext, CGRectMake(left, startc, dotSize, dotSize));
		startc += dotSize + dotGap;
	}
}

- (void)dealloc {
    [super dealloc];
}

-(void)setDotGap:(int)gap
{
	dotGap = gap;
	[self setNeedsDisplay];
}

-(void)setDotSize:(int)s
{
	dotSize	= s;
	[self setNeedsDisplay];
}

-(void)setPageCount:(int)count
{
	pageCount = count;
	[self setNeedsDisplay];
}

-(void)setCurrentPage:(int)page
{
	currentPage = page;
	[self setNeedsDisplay];
}

@end
