//
//  AppDelegate.h
//  TestMesiboUIHelper
//
//  Created by John on 14/10/17.
//  Copyright © 2018 Mesibo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <mesibo/mesibo.h>
#import "SampleAppFileTransferHandler.h"
#import <mesibouihelper/mesibouihelper.h>
#import "logs.h"



@interface AppDelegate : UIResponder <UIApplicationDelegate, MesiboDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong,nonatomic) SampleAppFileTransferHandler *fileTranserHandler;
@end
