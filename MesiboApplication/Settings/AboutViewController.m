//
//  AboutViewController.m
//  MesiboApplication
//
//  Created by Mesibo on 28/01/17.
//  Copyright © 2018 Mesibo. All rights reserved.
//

#import "AboutViewController.h"
#import "CommonAppUtils.h"

@interface AboutViewController ()

@end

@implementation AboutViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    UIButton *button =  [UIButton buttonWithType:UIButtonTypeCustom];
    [button setImage:[CommonAppUtils imageNamed:@"ic_arrow_back_white.png"] forState:UIControlStateNormal];
    [button addTarget:self action:@selector(backButtonPressed)forControlEvents:UIControlEventTouchUpInside];
    [button setFrame:CGRectMake(0, 0, 24, 24)];
    UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithCustomView:button];
    self.navigationItem.leftBarButtonItem = barButton;
    
    NSString *version = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)@"CFBundleShortVersionString"];
    
    NSString *revision = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey];
    
    NSString *v = [NSString stringWithFormat:@"Version: %@ Rev %@", version, revision];
    
    [_mVersion setText:v];

}
- (void) backButtonPressed {
    [self.navigationController popViewControllerAnimated:YES];
    
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
