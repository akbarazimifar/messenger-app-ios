#import "UIListener.h"
#import "MesiboCall/MesiboCall.h"

@implementation UIListener

- (id)init {
    self = [super init];
    if (!self) return self;
    [MesiboUI setListener:self];
    return self;
}


- (MesiboCell *)MesiboUI_onGetCustomRow:(MesiboScreen * _Nonnull)screen row:(MesiboRow * _Nonnull)row {
    return nil;
}

- (CGFloat)MesiboUI_onGetCustomRowHeight:(MesiboScreen * _Nonnull)screen row:(MesiboRow * _Nonnull)row {
    return -1;
}

- (BOOL)MesiboUI_onInitScreen:(MesiboScreen * _Nonnull)screen {
    if(screen.userList) {
        MesiboUserListScreen *us = (MesiboUserListScreen *)screen;
        if(USERLIST_MODE_MESSAGES == us.mode)
            [self initilizeUserListScreen:us];
        
        return YES;
    }
    
    MesiboMessageScreen *ms = (MesiboMessageScreen *)screen;
    [self initilizeMessagingScreen:ms];
    return YES;
}

- (BOOL)MesiboUI_onUpdateRow:(MesiboScreen * _Nonnull)screen row:(MesiboRow * _Nonnull)row last:(BOOL)last {
    if(screen.userList) {
        MesiboUserListScreen *us = (MesiboUserListScreen *)screen;
        
        // modify colors as suitable to your app
        
        return YES;
    }
    
    MesiboMessageScreen *ms = (MesiboMessageScreen *)screen;
    // modify colors, etc. as suitable to your app
    return YES;
}

-(void) initilizeUserListScreen:(MesiboUserListScreen *)screen {
    /* add custom buttons to User list screen */
    UIButton *button =  [UIButton buttonWithType:UIButtonTypeCustom];
    [button setImage:[UIImage imageNamed:@"ic_message_white"] forState:UIControlStateNormal];
    [button setFrame:CGRectMake(0, 0, 44, 44)];
    [button setTag:MESIBOUI_TAG_NEWMESSAGE];
    
    UIButton *button1 =  [UIButton buttonWithType:UIButtonTypeCustom];
    [button1 setImage:[UIImage imageNamed:@"ic_more_vert_white"] forState:UIControlStateNormal];
    [button1 setFrame:CGRectMake(0, 0, 44, 44)];
    [MesiboUI addTarget:self screen:screen view:button1 action:@selector(onShowSettings:)];
    
    screen.buttons = @[button, button1];
}

-(void) initilizeMessagingScreen:(MesiboMessageScreen *)screen {
    MesiboProfile *profile = screen.profile;
    if(!profile) return;
    
    if([profile isGroup] && ![profile isActive]) return;
        
    UIButton *button =  [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *image = [MesiboUI imageNamed:[profile isGroup]?@"ic_call_add_white":@"ic_call_white"];
    [button setImage:image forState:UIControlStateNormal];
    [button setFrame:CGRectMake(0, 0, 44, 44)];
    [MesiboUI addTarget:self screen:screen view:button action:@selector(onAudioCall:)];
        
    UIButton *vbutton =  [UIButton buttonWithType:UIButtonTypeCustom];
    image = [MesiboUI imageNamed:[profile isGroup]?@"ic_videocam_add_white":@"ic_videocam_white"];
    [vbutton setImage:image forState:UIControlStateNormal];
    [vbutton setFrame:CGRectMake(0, 0, 44, 44)];
    [MesiboUI addTarget:self screen:screen view:vbutton action:@selector(onVideoCall:)];
        
    screen.buttons = @[button, vbutton];
    
    [MesiboUI addTarget:self screen:screen view:screen.titleArea action:@selector(onShowProfile:)];
}

-(void) makeCall:(id)parent profile:(MesiboProfile *)profile video:(BOOL)video {
    dispatch_async(dispatch_get_main_queue(), ^{
        [MesiboCallInstance callUi:parent profile:profile video:video];
    });
}
-(void) onAudioCall:(id)sender {
    
    MesiboMessageScreen *screen = (MesiboMessageScreen *) [MesiboUI getParentScreen:sender];
    [self makeCall:screen.parent profile:screen.profile video:NO];
}

-(void) onVideoCall:(id)sender {
    MesiboMessageScreen *screen = (MesiboMessageScreen *) [MesiboUI getParentScreen:sender];
    [self makeCall:screen.parent profile:screen.profile video:YES];
}

-(void)onShowProfile:(id)sender {
    MesiboMessageScreen *screen = (MesiboMessageScreen *) [MesiboUI getParentScreen:sender];
    [AppUIManager launchProfile:screen.parent profile:screen.profile];
}


-(void)onShowSettings:(id)sender {
    
    MesiboUserListScreen *screen = (MesiboUserListScreen *) [MesiboUI getParentScreen:sender];
    [AppUIManager launchSettings:screen.parent];
    
}

@end
