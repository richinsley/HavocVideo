//
//  EffectChooser.h
//  Havoc Video
//
//  Created by Richard Insley on 9/7/10.
//  Copyright 2010 WildWestWare. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EffectScript.h"
#import "EffectButtonPanel.h"
#import "ChangeScriptProtocol.h"

@interface EffectChooser : UIViewController < UIScrollViewDelegate  >
{
	IBOutlet UIScrollView *scrollView;
	IBOutlet UIPageControl *pageControl;
	
	int scriptCount;
	EffectScript** _scripts;
	
	// To be used when scrolls originate from the UIPageControl
    BOOL pageControlUsed;
	
	UIInterfaceOrientation currentOrientation;
	
	id <ChangeScriptProtocol> _callback;
	
	// so we can track and animate buttons
	EffectButtonPanel * panels[1024];
	
	IBOutlet UIView * menuBar;
}

-(void)initScripts:(EffectScript**)scripts ScriptCallback:(id <ChangeScriptProtocol>)callback Orientation:(UIInterfaceOrientation)orientation;
+(float)getTransformForOrientation:(UIInterfaceOrientation)interfaceOrientation;

- (IBAction)changePage:(id)sender;
- (IBAction)goBack:(id)sender;

@end
