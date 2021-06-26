//
//  SampleAPI.m
//  MesiboDevel
//
//  Updated by Grace on 23/12/19.
//  Copyright © 2018 Mesibo. All rights reserved.
//

#import "SampleAPI.h"
#import "Mesibo/Mesibo.h"
#import "NSDictionary+NilObject.h"
#import "ContactUtils/ContactUtils.h"
#import "SampleAppListeners.h"

#import "AppAlert.h"

#define APNTOKEN_KEY @"apntoken"
#define GOOGLE_KEY  @"googlekey"
#define UPLOADURL_KEY  @"upload"
#define DOWNLOADURL_KEY  @"download"
#define INVITE_KEY  @"inivte"
#define CC_KEY  @"cc"


@interface SampleAPI ( /* class extension */ )
{
    NSUserDefaults *mUserDefaults;
    NSString *mToken, *mPhone, *mInvite;
    uint64_t mContactTimestamp;
    SampleAPI_LogoutBlock mLogoutBlock;
    BOOL mResetSyncedContacts;
    BOOL mAutoDownload;
    NSString *mDeviceType;
    NSString *mApnToken;
    NSString *mApiUrl;
    NSString *mUploadUrl;
    NSString *mDownloadUrl;
    NSString *mNotice;
    NSString *mNoticeTitle;
    int mApnTokenType;
    BOOL mApnTokenSent;
    BOOL mSyncStarted;
    BOOL mInitPhonebook;
    void (^mAPNCompletionHandler)(UIBackgroundFetchResult);
}

@end

@implementation SampleAPI

+(SampleAPI *)getInstance {
    static SampleAPI *myInstance = nil;
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

-(BOOL) isValidUrl:(NSString *)url {
    return ([url hasPrefix:@"http://"] || [url hasPrefix:@"https://"]);
}

-(void)initialize {
    
    mApnToken = nil;
    mApnTokenType = 0;
    mApnTokenSent = NO;
    mInvite = nil;
    mNotice = nil;
    mNoticeTitle = nil;
    
    
    mApiUrl = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"MessengerApiUrl"];
    
   
    if (!mApiUrl || ![self isValidUrl:mApiUrl]) {
        NSLog(@"************* INVALID URL - set a valid URL in MessengerApiUrl field in Info.plist ************* ");
    }
    
    mUserDefaults = [NSUserDefaults standardUserDefaults];
    mContactTimestamp = 0;
    mToken = [mUserDefaults objectForKey:@"token"];
    
    
    mPhone = nil;
    mResetSyncedContacts = NO;
    mSyncStarted = NO;
    mInitPhonebook = NO;
    
    mDeviceType = [NSString stringWithFormat:@"%d", [MesiboInstance getDeviceType]];
    
    if([mToken length] > 0) {
        mContactTimestamp = [[mUserDefaults objectForKey:@"ts"] longLongValue];
        [self startMesibo:NO];
    }
}

-(void) setOnLogout:(SampleAPI_LogoutBlock)logOutBlock {
    mLogoutBlock = logOutBlock;
}

-(NSString *)getSavedValue:(NSString *)value key:(NSString *)key {
    if(value) {
        [MesiboInstance setKey:value value:key];
        return value;
    }
    
    return [MesiboInstance readKey:key];
}

#define SYNCEDCONTACTS_KEY @"syncedcontacts"

-(void) startMesibo:(BOOL) resetProfiles {
    
    
    [SampleAppListeners getInstance]; // will initiallize and register listener
    // early initialize for reverse lookup
    
    NSString *appdir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    [MesiboInstance setPath:appdir];
    
    [MesiboInstance setAccessToken:[SampleAPIInstance getToken]];
    [MesiboInstance setDatabase:@"mesiboapp.db" resetTables:resetProfiles?MESIBO_DBTABLE_PROFILES:0]; //TBD, change this after testing
    
    
    [self initAutoDownload];
    
    [MesiboInstance setSecureConnection:YES];
    [MesiboInstance start];
    
}

-(NSString *) getSyncedContacts {
    return [MesiboInstance readKey:SYNCEDCONTACTS_KEY];
}

-(void) startContactSync {
    
    if(nil == self)
        return;
    
    @synchronized (self) {
        if(mSyncStarted)
            return;
        
        mSyncStarted = YES;
    }
    
    if(mResetSyncedContacts) {
        [ContactUtilsInstance reset];
        [MesiboInstance setKey:SYNCEDCONTACTS_KEY value:@""];
    }
    
    NSString *phone = [self getPhone];
    int cc = [MesiboInstance getCountryCodeFromPhone:phone];
    [ContactUtilsInstance setCountryCode:cc];
    
    
    //TBD, we need to fix contact utils to run in this thread
    // We must run in UI thread else contact change is not triggered
    [MesiboInstance runInThread:YES handler: ^{
        __block NSMutableArray *mContacts = [NSMutableArray new];
        __block NSMutableArray *mDeletedContacts = [NSMutableArray new];
        
        [ContactUtilsInstance sync:^BOOL (PhonebookContact *c, int type) {
            if(!c)
                return NO;
            
            if(CONTACTUTILS_SYNCTYPE_DELETE == type) {
                if(!c.phoneNumber) return YES;
                MesiboProfile *profile = [MesiboInstance getProfile:c.phoneNumber groupid:0];
                if(profile) {
                    [profile setContact:NO visiblity:0];
                    [profile save];
                }
                
                [mDeletedContacts addObject:c.phoneNumber];
                return YES;
            }
            //NSLog(@"Contact: %@", c);
            
            NSString *selfPhone = [self getPhone];
            if(selfPhone && c.phoneNumber && [selfPhone isEqualToString:c.phoneNumber]) {
                NSArray *selfarray = [NSArray arrayWithObject:c.phoneNumber];
                
                return YES;
            }
            
            if(c.phoneNumber)
                [mContacts addObject:c.phoneNumber];
            
            if(mContacts.count >= 100 || (nil == c.phoneNumber && mContacts.count > 0)) {
                
                if(mContacts.count) {
                    [MesiboInstance syncContacts:mContacts addContact:YES subscribe:YES visibility:0 syncNow:NO];
                    NSString *str = [ContactUtilsInstance synced:mContacts type:CONTACTUTILS_SYNCTYPE_SYNC];
                    [MesiboInstance setKey:SYNCEDCONTACTS_KEY value:str];
                    [mContacts removeAllObjects];
                }
            }
            
            if(nil == c.phoneNumber) {
                if(mDeletedContacts.count > 0) {
                    [MesiboInstance syncContacts:mDeletedContacts addContact:NO subscribe:YES visibility:0 syncNow:NO];
                    [ContactUtilsInstance synced:mDeletedContacts type:CONTACTUTILS_SYNCTYPE_DELETE];
                    [mDeletedContacts removeAllObjects];
                }
                [MesiboInstance syncContacts];
                mSyncStarted = NO; // so that it can be restarted if contact(s) change
            }
            
            
            
            
            return YES;
        }
         
         ];
    }];
}

-(NSString *) getPhone {
    if(mPhone)
        return mPhone;
    
    mPhone = [MesiboInstance getAddress];
    
    return mPhone;
}

-(NSString *) getNotice {
    return mNotice;
}

-(NSString *) getNoticeTitle {
    return mNoticeTitle;
}

-(NSString *) getInvite {
    if(mInvite && [mInvite length] > 6)
        return mInvite;
    
    mInvite = [self getSavedValue:nil key:INVITE_KEY];
    return mInvite;
}

-(NSString *) getToken {
    if([SampleAPI isEmpty:mToken])
        return nil;
    
    return mToken;
}

-(NSString *) getApiUrl {
    return mApiUrl;
}

-(NSString *) getUploadUrl {
    if(mUploadUrl && [mUploadUrl length] > 6)
        return mUploadUrl;
    
    mUploadUrl = [self getSavedValue:nil key:UPLOADURL_KEY];
    return mUploadUrl;
}

-(NSString *) getDownloadUrl {
    if(mDownloadUrl && [mDownloadUrl length] > 6)
        return mDownloadUrl;
    
    mDownloadUrl = [self getSavedValue:nil key:DOWNLOADURL_KEY];
    return mDownloadUrl;
}

-(void)save {
    [mUserDefaults setObject:mToken forKey:@"token"];
    [mUserDefaults setObject:[NSNumber numberWithUnsignedLongLong:mContactTimestamp] forKey:@"ts"];
    [mUserDefaults synchronize];
}

-(BOOL) parseResponse:(NSString *)response request:(NSDictionary*)request handler:(SampleAPI_onResponse) handler {
    NSMutableDictionary *returnedDict = nil;
    NSString *op = nil;
    int result = SAMPLEAPP_RESULT_FAIL;
    
    NSError *jsonerror = nil;
    
    //NSLog(@"Request: %@", request);
    //NSLog(@"Response: %@", response);
    
    //MUST not happen
    if(nil == response)
        return YES;
    
    //LOGD(@"Data %@", [NSString stringWithUTF8String:(const char *)[data bytes]]);
    NSData *data = [response dataUsingEncoding:NSUTF8StringEncoding];
    id jsonObject = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&jsonerror];
    
    if (jsonerror != nil) {
        if(nil != handler)
            handler(result, nil);
        return YES;
    }
    
    if ([jsonObject isKindOfClass:[NSArray class]]) {
        //LOGD(@"its an array!");
        //NSArray *jsonArray = (NSArray *)jsonObject;
        
    }
    else {
        //LOGD(@"its probably a dictionary");
        returnedDict = (NSMutableDictionary *)jsonObject;
    }
    
    if(nil == returnedDict) {
        if(nil != handler)
            handler(result, nil);
        
        return YES;
        
    }
    
    //NSString *result = (NSString *)[returnedDict objectForKeyOrNil:@"result"];
    //NSString *subresult = (NSString *)[returnedDict objectForKeyOrNil:@"subresult"];
    op = (NSString *)[returnedDict objectForKeyOrNil:@"op"];
    NSString *res = (NSString *)[returnedDict objectForKeyOrNil:@"result"];
    if([res isEqualToString:@"OK"]) {
        result = SAMPLEAPP_RESULT_OK;
    } else {
        NSString *error = (NSString *)[returnedDict objectForKeyOrNil:@"error"];
        NSString *errmsg = (NSString *)[returnedDict objectForKeyOrNil:@"errmsg"];
        NSString *errtitle = (NSString *)[returnedDict objectForKeyOrNil:@"errtitle"];
        if([error isEqualToString:@"AUTHFAIL"]) {
            result = SAMPLEAPP_RESULT_AUTHFAIL;
            [self logout:YES parent:nil];
            return NO;
        }
        
        if(errmsg) {
            if(!errtitle) errtitle = @"Failed";
            [AppAlert showDialogue:errmsg withTitle:errtitle];
        }
    }
    
   
    if(SAMPLEAPP_RESULT_OK != result) {
        if(nil != handler)
            handler(result, returnedDict);
        return NO;
    }
    
    NSString *temp = (NSString *)[returnedDict objectForKeyOrNil:@"invite"];
    if(temp && [temp length] >0) {
        mInvite = [self getSavedValue:temp key:INVITE_KEY];
    }
    
    NSDictionary *urls = (NSDictionary *)[returnedDict objectForKeyOrNil:@"urls"];
    if(urls) {
        mUploadUrl = [self getSavedValue:(NSString *)[urls objectForKeyOrNil:@"upload"] key:UPLOADURL_KEY];
        mDownloadUrl = [self getSavedValue:(NSString *)[urls objectForKeyOrNil:@"download"] key:DOWNLOADURL_KEY];
    }
    
    NSDictionary *notice = (NSDictionary *)[returnedDict objectForKeyOrNil:@"notice"];
    if(notice) {
        mNoticeTitle = (NSString *)[notice objectForKeyOrNil:@"title"];
        mNotice = (NSString *)[notice objectForKeyOrNil:@"desc"];
    }
    
    if([op isEqualToString:@"login"]) {
        mToken = (NSString *)[returnedDict objectForKeyOrNil:@"token"];
        mPhone = (NSString *)[returnedDict objectForKeyOrNil:@"phone"];
        
        
        if(![SampleAPI isEmpty:mToken]) {
            mContactTimestamp = 0;
            [self save];
            
            mResetSyncedContacts = YES;
            mSyncStarted = NO;
            
            [MesiboInstance reset];
            [self startMesibo:0];
            
        }
        
    }
    
    
    if(handler)
        handler(result, returnedDict);
    
    return YES;
    
}


-(void) invokeApi:(NSDictionary *)post filePath:(NSString *)filePath handler:(SampleAPI_onResponse) handler {
    
    if(post) {
        [post setValue:mDeviceType forKey:@"dt"];
    }
    
    NSError *error;
    //options:NSJSONWritingPrettyPrinted
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:post options:0 error:&error];
    if(!jsonData) {
        //[[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        
    }
    
    Mesibo_onHTTPProgress progressHandler = ^BOOL(MesiboHttp *http, int state, int progress) {
        
        if(100 == progress && state == MESIBO_HTTPSTATE_DOWNLOAD) {
            [self parseResponse:[http getDataString] request:post handler:handler];
        }
        
        if(progress < 0) {
            NSLog(@"invokeAPI failed");
            if(nil != handler) {
                handler(SAMPLEAPP_RESULT_FAIL, nil);
            }
        }
        
        return YES;
        
    };
    
    MesiboHttp *http = [MesiboHttp new];
    http.url = [self getApiUrl];
    http.contentType = @"application/json";
    http.post = jsonData;
    http.uploadFile = filePath;
    http.uploadFileField = @"photo";
    http.listener = progressHandler;
    
    if(![http execute]) {
        
    }
    
}

+(BOOL) equals:(NSString *)s old:(NSString *)old {
    int sempty = (int) [s length];
    int dempty = (int) [old length];
    if(sempty != dempty) return NO;
    if(!sempty) return YES;
    
    return ([s caseInsensitiveCompare:old] == NSOrderedSame);
}

+(BOOL) isEmpty:(NSString *)string {
    if(/*[NSNull null] == string ||*/ nil == string || 0 == [string length])
        return YES;
    return NO;
}

-(NSString *) phoneBookLookup:(NSString *)phone {
    PhonebookContact *c = [ContactUtilsInstance lookup:phone returnCopy:NO];
    if(!c) return nil;
    
    return c.name;
}

#if 0
-(void) updateDeletedGroup:(uint32_t)groupid {
    if(!groupid) return;
    
    MesiboProfile *u = [MesiboInstance getGroupProfile:groupid];
    if(!u) return;
    u.flag |= MESIBO_USERFLAG_DELETED;
    u.status = @"Not a group member";
    [MesiboInstance setProfile:u refresh:NO];
}
#endif

-(void) startLogout:(SampleAPI_onResponse) handler {
    if(nil == mToken)
        return;
    
    NSMutableDictionary *post = [[NSMutableDictionary alloc] init];
    [post setValue:@"logout" forKey:@"op"];
    
    //even if token value is wrong, logout will happen due to AUTHFAIL
    [post setValue:mToken forKey:@"token"];
    
    [self invokeApi:post filePath:nil handler:handler];
    return;
}

-(void) logout:(BOOL)forced parent:(id)parent {
    if(!forced) {
        [self startLogout:^(int result, NSDictionary *response) {
            if(MESIBO_RESULT_OK == result)
                [self logout:YES parent:parent];
        }];
        return;
    }
    
    [MesiboInstance setKey:APNTOKEN_KEY value:@""];
    [MesiboInstance stop];
    mApnTokenSent = NO;
    mToken = @"";
    mPhone = nil;
    mContactTimestamp = 0;
    [self save];
    [MesiboInstance reset];
    
    if(nil != mLogoutBlock)
        mLogoutBlock(parent);
    
}

-(void) login:(NSString *)phone code:(NSString *)code handler:(SampleAPI_onResponse) handler {
    NSMutableDictionary *post = [[NSMutableDictionary alloc] init];
    [post setValue:@"login" forKey:@"op"];
    NSString *packageName = [[NSBundle mainBundle] bundleIdentifier];
    [post setValue:packageName forKey:@"appid"];
    
    [post setValue:phone forKey:@"phone"];
    if(nil != code) {
        [post setValue:code forKey:@"otp"];
    }
    
    [self invokeApi:post filePath:nil handler:handler];
}


-(void) sendAPNToken {
    //first check in non-synronized stage. If this is called in response to sendAPNToken request itself, mApnTokenSent will be set and it will return so it can't go recursive
    if(!mApnToken || mApnTokenSent)
        return;
    
    if(nil == mToken || [mToken length] == 0)
        return;
    
    @synchronized (self) {
        if(mApnTokenSent)
            return;
        mApnTokenSent = YES; // so that next time it will not be called
    }
    
    //[MesiboInstance setPushToken:mApnToken];
}

-(void) setAPNToken:(NSString *)token {
    return; // We are disabling sending APN token, instead we sending Push token
    // TBD. later send both
    
    mApnToken = token;
    mApnTokenType = 0;
    [self sendAPNToken];
}

-(void) setPushToken:(NSString *)token {
    mApnToken = token;
    mApnTokenType = 1;
    [self sendAPNToken];
}



-(void) executeAPNCompletion:(double) delayInSeconds {
    if(!mAPNCompletionHandler)
        return;
    
    if(delayInSeconds < 0.01) {
        @synchronized (self) {
            if(mAPNCompletionHandler)
                mAPNCompletionHandler(UIBackgroundFetchResultNewData);
            mAPNCompletionHandler = nil;
        }
        return;
    }
    
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        //code to be executed on the main queue after delay
        
        [self executeAPNCompletion:0];
    });
    
}

-(BOOL) setAPNCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    [self executeAPNCompletion:0]; // complete existing
    
    mAPNCompletionHandler = completionHandler;
    [MesiboInstance setAppInForeground:nil screenId:-1 foreground:YES];
    [self executeAPNCompletion:10.0];
    return YES;
}

-(void) startOnlineAction {
    [self sendAPNToken]; // this will also be called on online status to ensure that APN token is sent
    [self executeAPNCompletion:3.0];
}

-(void) resetDB {
    [MesiboInstance resetDatabase:MESIBO_DBTABLE_ALL];
}

#define AUTODOWNLOAD_KEY    @"autodownload"
-(void) initAutoDownload {
    NSString *autodownload = [MesiboInstance readKey:AUTODOWNLOAD_KEY];
    mAutoDownload = (!autodownload || [autodownload isEqualToString:@"1"]);
}

-(void) setMediaAutoDownload:(BOOL)autoDownload {
    mAutoDownload = autoDownload;
    [MesiboInstance setKey:AUTODOWNLOAD_KEY value:mAutoDownload?@"1":@"0"];
}

-(BOOL)getMediaAutoDownload {
    return mAutoDownload;
}

BOOL isAppStoreVersion(void) {
#if TARGET_OS_SIMULATOR
    return NO;
#endif
    
    NSURL *appStoreReceiptURL = NSBundle.mainBundle.appStoreReceiptURL;
    NSString *appStoreReceiptLastComponent = appStoreReceiptURL.lastPathComponent;
    BOOL isSandboxReceipt = [appStoreReceiptLastComponent isEqualToString:@"sandboxReceipt"];
    
    if(isSandboxReceipt) return NO;
    
    return [NSBundle.mainBundle respondsToSelector:@selector(appStoreReceiptURL)];
}

BOOL localVerson(void) {
    BOOL hasEmbeddedMobileProvision = !![[NSBundle mainBundle] pathForResource:@"embedded" ofType:@"mobileprovision"];
    return hasEmbeddedMobileProvision;
}

-(BOOL) isAppStoreBuild {
#if TARGET_OS_SIMULATOR
    return NO;
#endif
    
    // MobilePovision profiles are a clear indicator for Ad-Hoc distribution
    if (localVerson()) {
        return NO;
    }
    
    return isAppStoreVersion();
}


@end
