//
//  SamplePushKitNotify.m
//  MesiboApplication
//
//  Created by John on 31/12/17.
//  Copyright © 2018 Mesibo. All rights reserved.
//

#import "SamplePushKitNotify.h"
#import "Mesibo/Mesibo.h"
#import "SampleAPI.h"


@interface SamplePushKitNotify ( /* class extension */ )
{
    PKPushRegistry *pushRegistry;
}

@end

@implementation SamplePushKitNotify

+(SamplePushKitNotify *)getInstance {
    static SamplePushKitNotify *myInstance = nil;
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
    return; // disabled - moved to call api. To be removed from here
    pushRegistry = [[PKPushRegistry alloc] initWithQueue:dispatch_get_main_queue()];
    pushRegistry.delegate = self;
    pushRegistry.desiredPushTypes = [NSSet setWithObject:PKPushTypeVoIP];
}

- (void)pushRegistry:(PKPushRegistry *)registry didUpdatePushCredentials:(PKPushCredentials *)credentials forType:(PKPushType)type {
    if([credentials.token length] == 0) {
        NSLog(@"token NULL");
        return;
    }
    
    if(![type isEqualToString:PKPushTypeVoIP]) {
        return;
    }
    
    NSData *data = credentials.token;
    NSUInteger capacity = data.length * 2;
    NSMutableString *sbuf = [NSMutableString stringWithCapacity:capacity];
    const unsigned char *buf = data.bytes;
    NSInteger i;
    for (i=0; i<data.length; ++i) {
        [sbuf appendFormat:@"%02X", (int)buf[i]];
    }
    
    //sbuf = @"12222222224";
    //NSLog(@"PushCredentials: %@", credentials.token);
    //NSLog(@"PushCredentials: %@", sbuf);
    [MesiboInstance setPushToken:sbuf voip:YES];
    
}


- (void)pushRegistry:(PKPushRegistry *)registry didReceiveIncomingPushWithPayload:(PKPushPayload *)payload forType:(PKPushType)type {
    
    [MesiboInstance setAppInForeground:nil screenId:-1 foreground:YES];
    
}


-(void)pushRegistry:(PKPushRegistry *)registry didReceiveIncomingPushWithPayload:(PKPushPayload *)payload forType:(PKPushType)type withCompletionHandler:(void (^)(void))completion {
    
    //Note that push may come even when user is online
    [MesiboInstance setPushRegistryCompletion:^{
        //NSLog(@"Complettion done");
        completion();
    }];
    [MesiboInstance setAppInForeground:nil screenId:-1 foreground:YES];
}
@end
