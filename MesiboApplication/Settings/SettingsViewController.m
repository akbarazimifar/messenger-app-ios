//
//  SettingsViewController.m
//
//  Created by Anuradha on 28/11/17.
//  Copyright © 2018 Mesibo. All rights reserved.
//

#import "SettingsViewController.h"
#import "CommonAppUtils.h"
#import "EditProfileController.h"
#import "SampleAPI.h"
#import <mesibo/mesibo.h>
#import "AppUIManager.h"
#import "MesiboCall/MesiboCall.h"

@interface SettingsViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *mSelfProfileImageView;
@property (weak, nonatomic) IBOutlet UITableViewCell *mProfileCell;

@property (weak, nonatomic) IBOutlet UITableViewCell *mDataUsageCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *mAboutCell;

@property (weak, nonatomic) IBOutlet UITableViewCell *mLogoutCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *mInviteCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *mRoomCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *mE2EECell;

@end

@implementation SettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.view layoutIfNeeded];
    
    _mSelfProfileImageView.layer.cornerRadius = _mSelfProfileImageView.layer.frame.size.height/2;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    //_mNavigationItem setB
    
    
    UIButton *button =  [UIButton buttonWithType:UIButtonTypeCustom];
    [button setImage:[CommonAppUtils imageNamed:@"ic_arrow_back_white.png"] forState:UIControlStateNormal];
    [button addTarget:self action:@selector(backButtonPressed)forControlEvents:UIControlEventTouchUpInside];
    [button setFrame:CGRectMake(0, 0, 24, 24)];
    UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithCustomView:button];
    self.navigationItem.leftBarButtonItem = barButton;
    
    [CommonAppUtils styleLight:self.view];
    

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) backButtonPressed {
    [self dismissViewControllerAnimated:YES completion:nil];
    
}
- (void) viewWillAppear:(BOOL)animated {
    [self.tableView reloadData];
    
}
#pragma mark - Table view data source

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;
       switch (indexPath.row) {
        case 0: {
            cell = _mProfileCell;
            UIImageView *imageView = [cell viewWithTag:100];
            [imageView layoutIfNeeded];
            [cell layoutIfNeeded];
            imageView.layer.cornerRadius = imageView.layer.frame.size.width/2;
            imageView.layer.masksToBounds = YES;
            
            MesiboProfile *up = [MesiboInstance getSelfProfile];
            NSString *status = [up getStatus];
            imageView.image = [up getImageOrThumbnail];
            if(!imageView.image) imageView.image = [AppUIManager getDefaultImage:NO];
    
            
            UILabel *nameLabel = [cell viewWithTag:101];
            nameLabel.text = [up getName];
            UILabel *statusLabel = [cell viewWithTag:102];
            statusLabel.text = [up getStatus];
            
        }
            break;
            
        case 1: {
            cell = _mRoomCell;
        }
            break;
        case 2: {
            cell = _mE2EECell;
        }
            break;
            
        case 3: {
            cell = _mDataUsageCell;
        }
            break;
        case 4: {
            cell = _mInviteCell;
        }
            break;
        case 5: {
            cell = _mAboutCell;
        }
            break;
            
        case 6: {
            cell = _mLogoutCell;
        }
            break;
            
    }
    return cell;}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *theCellClicked = [tableView cellForRowAtIndexPath:indexPath];
    if(theCellClicked == _mRoomCell) {
        [self dismissViewControllerAnimated:NO completion:nil];
        [MesiboCallInstance groupCallJoinRoomUi:_mParent];
    }
    else if (theCellClicked == _mProfileCell) {
        UIStoryboard *storyboard  = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
        EditProfileController *epc = [storyboard instantiateViewControllerWithIdentifier:@"EditSelfProfileViewController"];
        [self.navigationController pushViewController:epc animated:YES];
    }
    else if(theCellClicked == _mLogoutCell) {
        //[self.delegate logoutFromApplication:self];
        [SampleAPIInstance logout:NO parent:self];
        
    }
    
    else if(theCellClicked == _mInviteCell) {
        //[self.delegate logoutFromApplication:self];
        NSString *textToShare = [[SampleAPI getInstance] getInvite];
        [CommonAppUtils shareText:textToShare parent:self];
    }
    else if(theCellClicked == _mE2EECell) {
        [MesiboUI showEndToEncEncryptionInfo:self profile:[MesiboInstance getSelfProfile]];
    }
}

@end
