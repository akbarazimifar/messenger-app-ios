//
//  AppDelegate.m
//  TestMesiboUIHelper
//
//  Created by John on 14/10/17.
//  Copyright © 2018 Mesibo. All rights reserved.
//

#import "AppDelegate.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>
#import "UIColors.h"
#import "SampleAPI.h"
#import "EditSelfProfileViewController.h"
#import "SettingsViewController.h"
#import "CommonAppUtils.h"
#import "ProfileViewerController.h"
#import "UIManager.h"
#import "AppAlert.h"
#import "SettingsViewController.h"
#import "AppUIManager.h"
#import <GoogleMaps/GoogleMaps.h>
#import <GooglePlaces/GooglePlaces.h>
#import <AccountKit/AccountKit.h>
#import "NSDictionary+NilObject.h"

#import "MesiboUIHelper/MesiboUIHelper.h"
#import "ContactUtils/ContactUtils.h"
#import "MesiboCall/MesiboCall.h"
#import "SamplePushKitNotify.h"

#import <Intents/Intents.h>

@interface AppDelegate () <AKFViewControllerDelegate>

@end






@implementation AppDelegate


{
    MesiboUIHelper *mMesiboUIHelper;
    MesiboUiHelperConfig *mAppLaunchData;
    NSArray * imagesArraytest;
    NSArray * labelsArraytest;
    NSArray * imagesArray;
    
    NSString * tempName ;
    long tempgroupid ;
    NSString * temppath ;
    NSString * tempstatus ;
    MesiboUI *mMUILauncher ;
    MesiboCall *mesiboCall;
    
    SamplePushKitNotify *pushNotify;
    AKFAccountKit *_accountKit;
    BOOL _mUseAccontKit;
    BOOL _mCheckedLoginUI;
    AppDelegate *_thiz;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
   
    _thiz = self;
    _mUseAccontKit = NO;
    _mCheckedLoginUI = NO;
    
    if ([application respondsToSelector:@selector(isRegisteredForRemoteNotifications)])
    {
        // for iOS 8
        [application registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge) categories:nil]];
        [application registerForRemoteNotifications];
    }
    application.applicationIconBadgeNumber = 0;
    
    [MesiboInstance addListener:self];
    _fileTranserHandler = [[SampleAppFileTransferHandler alloc] init];
    [_fileTranserHandler initialize];
    
    [[FBSDKApplicationDelegate sharedInstance] application:application
                             didFinishLaunchingWithOptions:launchOptions];
    
    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    
    
    //([UIApplication sharedApplication]).keyWindow.rootViewController = nil;
    
    
    
    //[[UINavigationBar appearance] setBackgroundImage:image forBarMetrics:UIBarMetricsDefault];
    [[UINavigationBar appearance] setBarTintColor:[UIColor getColor:PRIMARY_COLOR]];
    [[UINavigationBar appearance] setTranslucent:NO];
    
    
    NSDictionary *attributes = @{
                                 NSUnderlineStyleAttributeName: @1,
                                 NSForegroundColorAttributeName : [UIColor getColor:TITLE_TXT_COLOR],
                                 NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue-Bold" size:17]
                                 };
    
    [[UINavigationBar appearance] setTitleTextAttributes:attributes];
    
    
    
    mMesiboUIHelper = [[MesiboUIHelper alloc] init];
    mAppLaunchData = [[MesiboUiHelperConfig alloc] init];
    
    
    [MesiboInstance addListener:self];
    
    SampleAPIInstance; // just to intitialize
    
    [SampleAPIInstance setOnLogout:^(id parent) {
         dispatch_async(dispatch_get_main_queue(), ^{
             if(parent) {
                 [(UIViewController *)parent dismissViewControllerAnimated:NO completion:nil];
             }
             [self launchLoginUI];
         });
    }];
    
    
    // If token is not nil, SampleAPI will start Mesibo as well
    if(nil != [SampleAPIInstance getToken]) {
        
        //temporrary to test
        if(NO) {
        MesiboUserProfile *sp = [MesiboInstance getSelfProfile];
            sp.name = @"";
        [MesiboInstance setSelfProfile:sp];
        }
        
        [self launchMainUI];
    } else {
        
        // we check without handler so that welcome controller can be launched in parallel
        [self checkLoginUI:nil];
        [self doLaunchWelcomeController];
    }
    
    mesiboCall = [MesiboCall sharedInstance];
    pushNotify = [SamplePushKitNotify getInstance];
    
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    [MesiboInstance setAppInForeground:self screenId:0 foreground:YES];
    //[MesiboCallInstance showCallInProgress];
}


- (void)applicationWillTerminate:(UIApplication *)application {
}

- (void)application:(UIApplication*)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken {
    // NSLog(@"My token is: %@", deviceToken);
    NSString * deviceTokenString = [[[[deviceToken description] stringByReplacingOccurrencesOfString: @"<" withString: @""] stringByReplacingOccurrencesOfString: @">" withString: @""]   stringByReplacingOccurrencesOfString: @" " withString: @""];
    Log(@"the generated device token string is : %@",deviceTokenString);
    [SampleAPIInstance setAPNToken:deviceTokenString];
}

-(void) application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    
    [SampleAPIInstance setAPNCompletionHandler:completionHandler];
}


-(void) application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    
    if(application.applicationState == UIApplicationStateInactive) {
        
    } else if (application.applicationState == UIApplicationStateBackground) {
        
    } else {

    }
    
    [SampleAPIInstance setAPNCompletionHandler:completionHandler];
    
}






- (void)application:(UIApplication*)application didFailToRegisterForRemoteNotificationsWithError:(NSError*)error {
    Log(@"Failed to get token, error: %@", error);
}

- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void(^)(NSArray * __nullable restorableObjects))restorationHandler {
    
    INInteraction *interaction = userActivity.interaction;
    INStartAudioCallIntent *startAudioCallIntent = (INStartAudioCallIntent *)interaction.intent;
    INPerson *contact = startAudioCallIntent.contacts[0];
    INPersonHandle *personHandle = contact.personHandle;
    NSString *phoneNum = personHandle.value;
    //[CallManager sharedInstance].delegate = self;
    //[[CallManager sharedInstance] startCallWithPhoneNumber:phoneNum];
    [MesiboCallInstance call:nil callid:0 address:phoneNum video:NO incoming:NO];
    return YES;
}

-(void) Mesibo_OnConnectionStatus:(int)status {
    Log(@"OnConnectionStatus status: %d", status);
    
    if(status == MESIBO_STATUS_SIGNOUT) {
        [self logoutFromApplication:nil];
        [AppAlert showDialogue:@"You have been loggeed out from this device. Kindly signin to continue" withTitle:@"Logged out"];
        
    }else if(status == MESIBO_STATUS_AUTHFAIL) {
        [self logoutFromApplication:nil];
    }
    
}

-(void) setRootController:(UIViewController *) controller {
    self.window.rootViewController = controller;
    [self.window setRootViewController:controller];
    [self.window makeKeyAndVisible];
    //[[UIApplication sharedApplication].keyWindow setRootViewController:rootViewController];
}

- (void)  onLogin:(NSString*)phone code:(NSString*)code akToken:(NSString *)akToken caller:(id)caller handler:(PhoneVerificationResultBlock) resultHandler {
    
    [[UIManager getInstance] addProgress:((UIViewController *)(caller)).view];
    [[UIManager getInstance] showProgress];
    
    SampleAPI_onResponse handler = ^(int result, NSDictionary *response) {
        [[UIManager getInstance] hideProgress];
        NSLog(@"%@" ,response);
        NSString *op = (NSString *)[response objectForKey:@"op"];
        NSString *resultz = (NSString *)[response objectForKey:@"result"];
        if([op isEqualToString:@"login"]) {
            if(nil != [SampleAPIInstance getToken] && [resultz isEqualToString:@"OK"]) {
                [self dismissAndlaunchMainUI:(UIViewController*)caller];
            }
            
            if(resultHandler) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    resultHandler([resultz isEqualToString:@"OK"]);
                });
            }
        }
    };
    
    if(akToken != nil) {
        [SampleAPIInstance login:akToken handler:handler];
    }
    else {
        [SampleAPIInstance login:phone code:code handler:handler];
    }
}

-(void) launchMesiboUI {
    MesiboUiOptions *ui = [MesiboInstance getUiOptions];
    ui.emptyUserListMessage = @"No contacts! Invite your family and friends to try mesibo.";
    
    UIViewController *mesiboController = [MesiboUI getMesiboUIViewController];
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:mesiboController];
    [self setRootController:navigationController];
    
    
    [AppUIManager setDefaultParent:navigationController];
    
    //[AppUIManager launchMesiboUI:self.window.rootViewController withMainWindow:self.window];
    [MesiboCallInstance start];
}

-(void) launchMainUI {
    
    MesiboUserProfile *sp = [MesiboInstance getSelfProfile];
    if([SampleAPI isEmpty:sp.name]) {
        [MesiboInstance runInThread:YES handler:^{
            [self launchEditProfile];
        }];
        return;
    }
    
    [ContactUtilsInstance initPhonebook:^(BOOL result) {
        [SampleAPIInstance startSync];
        [MesiboInstance runInThread:YES handler:^{
            [self launchMesiboUI];
        }];
    }];
}
         
-(void) dismissAndlaunchMainUI:(UIViewController *)previousController {
    if(!previousController) {
        [self launchMainUI];
        return;
    }
    
    if(_mUseAccontKit) {
        [self launchMainUI];
        [previousController dismissViewControllerAnimated:NO completion:nil];
    } else {
        [previousController dismissViewControllerAnimated:NO completion:^{
            [self launchMainUI];
        }];
    }
}

-(void) checkLoginUI:(void (^)(BOOL useAccountKit)) handler {
    if(_mCheckedLoginUI) {
        if(handler)
            handler(_mUseAccontKit);
        return;
    }
    
    [SampleAPIInstance check_login_ui:^(int result, NSDictionary *response) {
        self->_mCheckedLoginUI = YES;
        NSString *uitype = [response objectForKeyOrNil:@"ui"];
        if([uitype isEqualToString:@"1"])
            self->_mUseAccontKit = YES;
        if(handler)
            handler(self->_mUseAccontKit);
    }];
}

-(void) launchLoginUIAfterLoginUiCheck {
    UIViewController<AKFViewController>  *loginController ;
    if(_mUseAccontKit) {
        if (_accountKit == nil) {
            _accountKit = [[AKFAccountKit alloc] initWithResponseType:AKFResponseTypeAccessToken];
        }
        
        loginController = [_accountKit viewControllerForPhoneLoginWithPhoneNumber:nil state:nil];
        
        loginController.delegate = self;
        // Optionally, you may set up backup verification methods.
        loginController.enableSendToFacebook = YES;
        loginController.enableGetACall = YES;
    }
    else {
    
        loginController = [MesiboUIHelper startMobileVerification:^(id caller, NSString *phone, NSString *code, PhoneVerificationResultBlock resultBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [(UIViewController*)caller resignFirstResponder];
            });
            [self onLogin:phone code:code akToken:nil caller:caller handler:resultBlock];
        }];
    }
    
    [self setRootController:loginController];
    mAppLaunchData.mBanners = nil;
    
}

-(void) launchLoginUI {
    [self checkLoginUI:^(BOOL useAccountKit) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self launchLoginUIAfterLoginUiCheck];
        });
    }];
}


//extern void *query_mesibo_webrtc();
- (void) doLaunchWelcomeController {
    
    int countryCode = [ContactUtilsInstance getCountryCode];
    if(countryCode < 1)
        countryCode = 1;
    
    //query_mesibo_webrtc();
    
    mAppLaunchData.mCountryCode = [NSString stringWithFormat:@"%d", countryCode];
    mAppLaunchData.mAppName = @"Mesibo";
    mAppLaunchData.mAppTag = @"Messaging and Beyond";
    mAppLaunchData.mAppUrl = @"https://www.mesibo.com";
    mAppLaunchData.mAppWriteUp = @"";
    
    mAppLaunchData.mTextColor = 0xFF172727;
    mAppLaunchData.mBackgroundColor = 0xFFFFFFFF;
    mAppLaunchData.mButtonBackgroundColor = 0xFF00868b;
    mAppLaunchData.mButtonTextColor = 0xFFFFFFFF;
    mAppLaunchData.mSecondaryTextColor = 0xFF666666;
    mAppLaunchData.mBannerTitleColor = 0xFFFFFFFF;
    mAppLaunchData.mBannerDescColor =  0xEEFFFFFF;
    
    NSMutableArray *banners = [NSMutableArray new];
    
    WelcomeBanner *banner = nil;
    
    banner = [WelcomeBanner new];
    banner.mTitle = @"Messaging in your apps";
    banner.mDescription = @"Over 79% of all apps require some form of communications. Mesibo is built from ground-up to power this!";
    banner.mImage = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"welcome"] ofType:@"png"]];
    banner.mColor = 0xff00868b; //0xff0f9d58;
    [banners addObject:banner];
    
    banner = [WelcomeBanner new];
    banner.mTitle = @"Messaging, Voice, & Video";
    banner.mDescription = @"Complete infrastructure with powerful APIs to get you started, rightaway!";
    banner.mImage = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"plug_play"] ofType:@"png"]];
    banner.mColor = 0xff0f9d58; //0xff00bcd4; //0xfff4b400;
    [banners addObject:banner];
    
#if 0
    banner = [WelcomeBanner new];
    banner.mTitle = @"Plug & Play Modules";
    banner.mDescription = @"Not just the API, you can even use mesibo UI modules to quickly enable Voice, Video & Messaging in your app";
    banner.mImage = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"plug_play"] ofType:@"png"]];
    banner.mColor = 0xfff4b400; //0xfff4b400;
    [banners addObject:banner];
#endif
    
    banner = [WelcomeBanner new];
    banner.mTitle = @"Open & Free Platform";
    banner.mDescription = @"Quickly integrate Mesibo in your own app using freely available source code";
    banner.mImage = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"opensource_ios"] ofType:@"png"]];
    banner.mColor = 0xff054a61; //0xfff4b400;
    [banners addObject:banner];
    
#if 0
    banner = [WelcomeBanner new];
    banner.mTitle = @"No Sweat Pricing";
    banner.mDescription = @"Start free & only pay as you grow!";
    banner.mImage = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"users"] ofType:@"png"]];
    banner.mColor = 0xff00bcd4;
    [banners addObject:banner];
#endif
    
    mAppLaunchData.mBanners = banners;
    
    [MesiboUIHelper setUiConfig:mAppLaunchData];
    
    UIViewController *welcomeController = [MesiboUIHelper getWelcomeViewController:^(UIViewController *parent, BOOL result) {
        
        [self launchLoginUI];
        [parent dismissViewControllerAnimated:NO completion:nil];
    }];
    
    [self setRootController:welcomeController];
}


#pragma mark - AKFViewControllerDelegate;

// handle callback on successful login to show authorization code
- (void)                 viewController:(UIViewController<AKFViewController> *)viewController
  didCompleteLoginWithAuthorizationCode:(NSString *)code
                                  state:(NSString *)state
{
}

- (void)viewController:(UIViewController<AKFViewController> *)viewController didCompleteLoginWithAccessToken:(id<AKFAccessToken>)accessToken state:(NSString *)state
{
    NSString *token = [accessToken tokenString];
    //NSLog(@"AK access token: %@", token);
    [self onLogin:nil code:nil akToken:token caller:viewController handler:nil];
}

- (void)viewController:(UIViewController<AKFViewController> *)viewController didFailWithError:(NSError *)error
{
    NSLog(@"%@ did fail with error: %@", viewController, error);
}

-(void) launchEditProfile {
    UIStoryboard *storybord = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    EditSelfProfileViewController *editSelfProfileController =[storybord instantiateViewControllerWithIdentifier:@"EditSelfProfileViewController"];
    
    [editSelfProfileController setLaunchMesiboCallback:^{
        [self launchMainUI]; //don't launch mesibo ui directly
    }];
    
    [self setRootController:editSelfProfileController];
   
   // [AppUIManager launchEditProfile:self.window.rootViewController  withMainWindow:self.window];
}

-(NSArray *) Mesibo_onGetMenu:(id)parent type:(int) type profile:(MesiboUserProfile *)profile {
    
    NSArray*btns = nil;
    
    if(type == 0) {
        UIButton *button =  [UIButton buttonWithType:UIButtonTypeCustom];
        [button setImage:[UIImage imageNamed:@"ic_message_white"] forState:UIControlStateNormal];
        [button setFrame:CGRectMake(0, 0, 44, 44)];
        [button setTag:0];
        
        UIButton *button1 =  [UIButton buttonWithType:UIButtonTypeCustom];
        [button1 setImage:[UIImage imageNamed:@"ic_more_vert_white"] forState:UIControlStateNormal];
        [button1 setFrame:CGRectMake(0, 0, 44, 44)];
        [button1 setTag:1];
        
#if 0
        UIButton *button2 =  [UIButton buttonWithType:UIButtonTypeCustom];
        [button2 setImage:[UIImage imageNamed:@"ic_favorite_border_white"] forState:UIControlStateNormal];
        [button2 setFrame:CGRectMake(0, 0, 44, 44)];
        [button2 setTag:2];
#endif
        
        btns = @[button, button1];
    } else {
        if(profile && !profile.groupid) {
            UIButton *button =  [UIButton buttonWithType:UIButtonTypeCustom];
            [button setImage:[UIImage imageNamed:@"ic_call_white"] forState:UIControlStateNormal];
            [button setFrame:CGRectMake(0, 0, 44, 44)];
            [button setTag:0];
            
            UIButton *vbutton =  [UIButton buttonWithType:UIButtonTypeCustom];
            [vbutton setImage:[UIImage imageNamed:@"ic_videocam_white"] forState:UIControlStateNormal];
            [vbutton setFrame:CGRectMake(0, 0, 44, 44)];
            [vbutton setTag:1];
            
            btns = @[vbutton, button];
        }
        
    }
    
    return btns;
    
}

- (BOOL)Mesibo_onMenuItemSelected:(id)parent type:(int)type profile:(MesiboUserProfile *)profile item:(int)item {
    // userlist menu are active
    if(type == 0) { // USERLIST
        if(item == 1) {   //item == 0 is reserved
            [AppUIManager launchSettings:parent];
            
        }
        
    } else { // MESSAGEBOX
        if(item == 0) {
            NSLog(@"Menu btn from messagebox pressed");
            [MesiboCallInstance call:parent callid:0 address:profile.address video:NO incoming:NO];
        }else if (item ==1) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [MesiboCallInstance call:parent callid:0 address:profile.address video:YES incoming:NO];
                
            });
        }
        
        
    }
    return true;
}

- (void)Mesibo_onShowProfile:(id)parent profile:(MesiboUserProfile *)profile {
    [AppUIManager launchProfile:parent profile:profile];
    
}


- (void) Mesibo_onDeleteProfile:(id)parent profile:(MesiboUserProfile *)profile handler:(Mesibo_onSetGroupHandler)handler{
    
    
}

-(void) logoutFromApplication:(UIViewController *)sender {
    [self launchLoginUI];
    
    //dispatch_async(dispatch_get_main_queue(), ^{
         //[self doLaunchWelcomeController];
    //});
}


@end
