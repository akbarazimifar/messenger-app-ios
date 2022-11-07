
#import "SampleAppListeners.h"
#import "SampleAPI.h"
#import "NSDictionary+NilObject.h"
#import "ContactUtils/ContactUtils.h"
#import "UIManager.h"
#import "AppUIManager.h"
#import "SampleAppNotify.h"
#import "AppAlert.h"
#import "MesiboCall/MesiboCall.h"

@implementation SampleAppListeners

+(SampleAppListeners *)getInstance {
    static SampleAppListeners *myInstance = nil;
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
    [MesiboInstance addListener:self];
    //[MesiboCallInstance setListener:self];
}

-(void) Mesibo_onMessage:(MesiboMessage *)msg {
    if([MesiboInstance isReading:msg])
        return;
    

    //TBD, we need to handle missed and incoming call from here
    //currently done from MesiboCall_onNotifyIncoming (below)
    if([msg isCall]) return;
    
    [SampleAppNotifyInstance notifyMessage:msg];
}

-(void) Mesibo_OnConnectionStatus:(int)status {
    
    NSLog(@"Connection status: %d", status);
    
    if (MESIBO_STATUS_SIGNOUT == status) {
        //TBD, inform user
        [AppAlert showDialogue:@"You have been loggeed out from this device since you loggedin from another device." withTitle:@"Logged out"];
        
        [SampleAPIInstance logout:YES parent:nil];
        
    } else if (MESIBO_STATUS_AUTHFAIL == status) {
        [SampleAPIInstance logout:YES parent:nil];
    }
    
    if(MESIBO_STATUS_ONLINE == status) {
        [SampleAPIInstance startOnlineAction];
    }
    
    
}


-(void) Mesibo_onGroupJoined:(MesiboProfile *) groupProfile {
    NSString *msg = [NSString stringWithFormat:@"You have been added to the group %@", [groupProfile  getName]];
    [SampleAppNotifyInstance notify:SAMPLEAPP_NOTIFYTYPE_OTHER subject:@"New group" message:msg];
}

-(BOOL) Mesibo_onGetProfile:(MesiboProfile *)profile {

    if(!profile) return YES;
    
    if([profile getGroupId]) {
        [profile setLookedup:YES];
        return YES;
    }
    
    if(![profile getAddress]) {
        return NO;
    }

    //TBD, check if phonebook is ready
    PhonebookContact *c = [ContactUtilsInstance lookup:[profile getAddress] returnCopy:NO];
    if(!c || !c.name)
        return NO;
        
    if([SampleAPI equals:c.name old:[profile getName]])
        return NO;
        
    [profile setName:c.name];
    return YES;
}

- (void)MesiboUI_onShowProfile:(id)parent profile:(MesiboProfile *)profile {
    [AppUIManager launchProfile:parent profile:profile];
}

-(BOOL) Mesibo_onMessageFilter:(MesiboMessage *)msg {
        return YES;
}

-(void) Mesibo_onForeground:(id)parent screenId:(int)screenId foreground:(BOOL)foreground {
    //userlist is in foreground
    if(foreground && 0 == screenId) {
        //notify count clear
        [SampleAppNotifyInstance clear];
    }
    
}

-(BOOL) MesiboCall_onNotifyIncoming:(int)type profile:(MesiboProfile *)profile video:(BOOL)video {
    NSString *n = nil;
    NSString *subj = nil;
    if(MESIBOCALL_NOTIFY_INCOMING == type) {
        subj = @"Mesibo Incoming Call";
        n = [NSString stringWithFormat:@"Mesibo %scall from %@", video?"Video ":"", [profile getName]];
    } else if(MESIBOCALL_NOTIFY_MISSED == type) {
        subj = @"Mesibo Missed Call";
        n = [NSString stringWithFormat:@"You missed a Mesibo %scall from %@", video?"Video ":"", [profile getName]];
    }
    
    if(n) {
        [MesiboInstance runInThread:YES handler:^{
            [SampleAppNotifyInstance notify:2 subject:subj message:n];
        }];
    }
    
    return YES;
}

- (void)MesiboCall_OnError:(MesiboCallProperties * _Nonnull)cp error:(int)error {
    
}

- (MesiboCallProperties * _Nullable)MesiboCall_OnIncoming:(MesiboProfile * _Nonnull)profile video:(BOOL)video {
    MesiboCallProperties *cp = [MesiboCallInstance createCallProperties:video];
    
    //cp.parent = self.window.rootViewController;
    
    // any customizations goes here
    return cp;
    
}

- (BOOL)MesiboCall_OnNotify:(int)type profile:(MesiboProfile * _Nonnull)profile video:(BOOL)video {
    return NO;
}

- (BOOL)MesiboCall_OnShowUserInterface:(id)call properties:(MesiboCallProperties *)cp {
    
    // Show your own UI or return NO to show the default user interface
    
    return NO;

}

@end
