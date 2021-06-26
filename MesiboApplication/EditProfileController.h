//
//  EditProfileViewController.h
//  MesiboUIHelper
//
//  Created by Mesibo on 03/12/17.
//  Copyright © 2018 Mesibo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Includes.h"

typedef void (^LaunchMesiboBlock)();

@interface EditProfileController : UIViewController <UIGestureRecognizerDelegate>

@property (strong, nonatomic) LaunchMesiboBlock mLaunchMesibo ;

- (void) setLaunchMesiboCallback:(LaunchMesiboBlock) handler;
- (void) setProfile:(MesiboProfile *) profile;
@end
