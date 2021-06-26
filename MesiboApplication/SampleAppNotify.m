//
//  SampleAppNotify.m
//  TestMesiboUI
//
//  Created by John on 24/03/17.
//  Copyright © 2018 Mesibo. All rights reserved.
//

#import "SampleAppNotify.h"

//https://developer.apple.com/library/content/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/index.html#//apple_ref/doc/uid/TP40008194-CH3-SW1
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
    [center requestAuthorizationWithOptions:(UNAuthorizationOptionBadge | UNAuthorizationOptionAlert | UNAuthorizationOptionSound | UNAuthorizationOptionBadge)
                          completionHandler:^(BOOL granted, NSError * _Nullable error) {
        //NSLog(@"Notify auth %d", granted?1:0);
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
    UNTimeIntervalNotificationTrigger* trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:1.f repeats:NO];
    UNNotificationRequest* request = [UNNotificationRequest requestWithIdentifier:@"LocalNotification" content:content trigger:trigger];
    
    // Schedule the notification.
    UNUserNotificationCenter* center = [UNUserNotificationCenter currentNotificationCenter];
    [center addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
        //NSLog(@"Notification Completed: %@", error);
    }];
    
}

-(void) notifyMessage:(MesiboParams *)params message:(NSString *)message {
    if(MESIBO_ORIGIN_REALTIME != params.origin || MESIBO_MSGSTATUS_OUTBOX == params.status)
        return;
    if(!params.profile) return;
    
    if([params.profile isMuted])
        return;
            
    NSString *name = [params.profile getName];
    
    if(nil == name)
        return;
    
    if(params.groupProfile) {
        if([params.groupProfile isMuted])
            return;
        
        name = [NSString stringWithFormat:@"%@ @ %@", name, [params.groupProfile getName]];
    }
    
    
    [self notify:SAMPLEAPP_NOTIFYTYPE_MESSAGE subject:name message:message];
    return;
}

-(void) clear {
    [[UNUserNotificationCenter currentNotificationCenter] removeAllDeliveredNotifications];
}

@end
