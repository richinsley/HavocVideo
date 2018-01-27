//
//  EditViewController.h
//  VideoTexture
//
//  Created by Richard Insley on 8/28/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MobileCoreServices/MobileCoreServices.h>

@interface EditViewController : UIViewController <UINavigationControllerDelegate , UIImagePickerControllerDelegate, UIVideoEditorControllerDelegate>
{
	NSString *vpath;
	UIVideoEditorController *vec;
}
@property (retain) NSString *vpath;
@end
