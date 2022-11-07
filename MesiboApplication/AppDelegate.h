//
//  AppDelegate.h
//
//  Updated by Lee on 14/10/20.
//  Copyright © 2022 Mesibo. All rights reserved.


#import <UIKit/UIKit.h>
#import <mesibo/mesibo.h>
#import "SampleAppFileTransferHandler.h"
#import <mesibouihelper/mesibouihelper.h>
#import "logs.h"
#import <UserNotifications/UserNotifications.h>




@interface AppDelegate : UIResponder <UIApplicationDelegate, MesiboDelegate, UNUserNotificationCenterDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong,nonatomic) SampleAppFileTransferHandler *fileTranserHandler;
@end
