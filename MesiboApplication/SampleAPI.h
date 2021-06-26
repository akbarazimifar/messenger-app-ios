//
//  SampleAPI.h
//  MesiboDevel
//
//  Created by John on 23/12/17.
//  Copyright © 2018 Mesibo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Mesibo/Mesibo.h"


@interface SampleAPIRespose : NSObject
@property (nonatomic) NSString *result;
@property (nonatomic) NSString *op;
@property (nonatomic) NSString *error;
@property (nonatomic) NSString *token;

@property (nonatomic) NSString *name;
@property (nonatomic) NSString *status;
@property (nonatomic) NSString *photo;
@property (nonatomic) NSString *invite;
@property (nonatomic) uint32_t gid;
@property (nonatomic) int type;
@end

#define SAMPLEAPP_RESULT_OK         0
#define SAMPLEAPP_RESULT_FAIL       1
#define SAMPLEAPP_RESULT_AUTHFAIL   2


#define VISIBILITY_HIDE         0
#define VISIBILITY_VISIBLE      1
#define VISIBILITY_UNCHANGED    2

typedef void (^SampleAPI_LogoutBlock)(id parent);
typedef void (^SampleAPI_onResponse)(int result, NSDictionary *response);

#define SampleAPIInstance [SampleAPI getInstance]

@interface SampleAPI : NSObject

+(SampleAPI *) getInstance;

-(void) initialize;
-(void) setOnLogout:(SampleAPI_LogoutBlock)logOutBlock;
-(NSString *) getToken;
-(NSString *) getPhone;
-(NSString *) getApiUrl;
-(NSString *) getUploadUrl;
-(NSString *) getDownloadUrl;
-(NSString *) getInvite;
-(NSString *) getNotice;
-(NSString *) getNoticeTitle;


-(void) startMesibo:(BOOL) resetProfiles;
-(void) startContactSync;
-(NSString *) getSyncedContacts;

-(void) resetDB;
-(void) logout:(BOOL) forced parent:(id)parent;
-(void) login:(NSString *)phone code:(NSString *)code handler:(SampleAPI_onResponse) handler;
-(BOOL) deleteGroup:(uint32_t) groupid handler:(SampleAPI_onResponse) handler ;

-(void) setAPNToken:(NSString *) token;
-(void) setMediaAutoDownload:(BOOL)autoDownload;
-(BOOL) getMediaAutoDownload;

+(BOOL) isEmpty:(NSString *)string; //utility
+(BOOL) equals:(NSString *)s old:(NSString *)old;

-(void) startOnlineAction;

-(BOOL) setAPNCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler;

@end
