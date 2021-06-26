//
//  SampleAppListeners.h

#import <Foundation/Foundation.h>
#import "Mesibo/Mesibo.h"
#import "mesibocall/MesiboCall.h"

#define SampleAppListenersInstance [SampleAppListeners getInstance]


@interface SampleAppListeners : NSObject <MesiboDelegate, MesiboCallIncomingListener>

+(SampleAppListeners *) getInstance;

@end
