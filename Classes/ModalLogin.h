//
//  ModalLogin.h
//  SteelMagnolia
//
//  Created by Nathan Walker on 9/21/10.
//  Copyright 2010 Vision Worx Productions. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ModalAlert.h"

@interface ModalLogin : ModalAlert {

}

+ (NSMutableDictionary *) askLoginOrCancel: (NSString *) question withTextPrompt: (NSString *) prompt;

@end
