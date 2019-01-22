//
//  UIAlerts.m
//  Mesibo
//
//  Created by rkb on 10/15/17.
//  Copyright © 2018 Mesibo. All rights reserved.
//

#import "AppAlert.h"

@implementation AppAlert


+ (UIViewController*) topMostController {
    UIViewController *topController = [UIApplication sharedApplication].keyWindow.rootViewController;
    
    while (topController.presentedViewController) {
        topController = topController.presentedViewController;
    }
    
    return topController;
}

+ (void)showDialogue:(NSString*)message withTitle :(NSString *) title {
    UIAlertController* alert = [UIAlertController
                                alertControllerWithTitle:title
                                message:message
                                preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* defaultAction = [UIAlertAction
                                    actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                    handler:^(UIAlertAction * action) {
                                        
                                        
                                        [alert removeFromParentViewController];
                                        
                                    }];
    
    [alert addAction:defaultAction];
    [[AppAlert topMostController] presentViewController:alert animated:YES completion:nil];
}



@end
