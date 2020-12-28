//
//  SampleAppNotify.m
//  TestMesiboUI
//
//  Created by John on 24/03/17.
//  Copyright © 2018 Mesibo. All rights reserved.
//

#import "SampleAppNotify.h"

@implementation SampleAppNotify 

+(SampleAppNotify *)getInstance {
    static SampleAppNotify *myInstance = nil;
    if(nil == myInstance) {
        @synchronized(self) {
            if (nil == myInstance) {
                myInstance = [[self alloc] init];
                [myInstance initialize];
            }
        }
    }
    return myInstance;
}

-(void) initialize {
    UNUserNotificationCenter* center = [UNUserNotificationCenter currentNotificationCenter];
    [center requestAuthorizationWithOptions:(UNAuthorizationOptionAlert | UNAuthorizationOptionSound | UNAuthorizationOptionBadge)
                          completionHandler:^(BOOL granted, NSError * _Nullable error) {
                          }];
    
}

-(void) notify:(int)type subject:(NSString *)subject message:(NSString *)message {
    if(![message length]) return;
    
    UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
    content.title = subject;
    content.body = message;
    content.sound = [UNNotificationSound defaultSound];
    //Set Badge Number
    content.badge = @([[UIApplication sharedApplication] applicationIconBadgeNumber] + 1);
    content.categoryIdentifier = [NSString stringWithFormat:@"%d", type];

    
    // Deliver the notification in five seconds.
    UNTimeIntervalNotificationTrigger* trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:1 repeats:NO];
    UNNotificationRequest* request = [UNNotificationRequest requestWithIdentifier:@"LocalNotification" content:content trigger:trigger];
    
    // Schedule the notification.
    UNUserNotificationCenter* center = [UNUserNotificationCenter currentNotificationCenter];
    [center addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
        NSLog(@"Notification Completed: %@", error);
    }];
    
}

-(void) notifyMessage:(MesiboParams *)params message:(NSString *)message {
    if(MESIBO_ORIGIN_REALTIME != params.origin || MESIBO_MSGSTATUS_OUTBOX == params.status)
        return;
    
    NSString *name = params.peer;
    if(params.profile) {
        if([params.profile isMuted])
            return;
            
        name = params.profile.name;
        
    }
    
    if(nil == name)
        return;
    
    if(params.groupProfile) {
        if([params.groupProfile isMuted])
            return;
        
        name = [NSString stringWithFormat:@"%@ @ %@", name, params.groupProfile.name];
    }
    
    
    [self notify:SAMPLEAPP_NOTIFYTYPE_MESSAGE subject:name message:message];
    return;

}

-(void) clear {
    [[UNUserNotificationCenter currentNotificationCenter] removeAllDeliveredNotifications];
}

@end
