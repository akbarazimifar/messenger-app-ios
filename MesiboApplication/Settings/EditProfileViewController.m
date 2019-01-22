//
//  EditProfileViewController.m
//  LoginProcess
//
//  Created by Sarfaraz Halai on 03/12/16.
//  Copyright © 2016 Sarfaraz Halai. All rights reserved.
//

#import "EditProfileViewController.h"
#import "ImagePicker.h"


@interface EditProfileViewController ()
@property (weak, nonatomic) IBOutlet UILabel *mPhoneNumber;
@property (weak, nonatomic) IBOutlet UILabel *mStatusLabel;
@property (weak, nonatomic) IBOutlet UILabel *mSelfUserName;
@property (weak, nonatomic) IBOutlet UIImageView *mProfilePicture;
@property (weak, nonatomic) IBOutlet UIButton *mEditUserNameBtn;
@property (weak, nonatomic) IBOutlet UIButton *mPictureEditBtn;

@end

@implementation EditProfileViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.view layoutIfNeeded];
    [_mProfilePicture layoutIfNeeded];
    _mProfilePicture.layer.cornerRadius = _mProfilePicture.layer.frame.size.width/2;
    _mProfilePicture.layer.masksToBounds = YES;
    
    _mPictureEditBtn.layer.cornerRadius = _mPictureEditBtn.layer.frame.size.width/2;
    _mPictureEditBtn.layer.masksToBounds = YES;

    
    UITapGestureRecognizer *labelTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(changeStatusLabel:)];
    labelTap.numberOfTapsRequired = 1;
    labelTap.delegate = self;
    _mStatusLabel.userInteractionEnabled = YES;
    [_mStatusLabel addGestureRecognizer:labelTap];
    
}



- (IBAction)changeUserName:(id)sender {
    
    EditorViewController *evc = [self.storyboard instantiateViewControllerWithIdentifier:@"EditorViewController"];
    evc.mCharCounterLimit = 30;
    evc.delegate = self;
    [self.navigationController pushViewController:evc animated:YES];
}


- (void) changeStatusLabel : (id) sender {
    
    EditorViewController *evc = [self.storyboard instantiateViewControllerWithIdentifier:@"EditorViewController"];
    evc.mCharCounterLimit = 200;
    evc.delegate = self;
    [self.navigationController pushViewController:evc animated:YES];
    
}

- (void) setStatusLabel:(NSString *)mStatusText {
    _mStatusLabel.text = mStatusText;

}

- (void) setSelfUserName:(NSString *)mSelfUserNameText {
     _mSelfUserName.text = mSelfUserNameText;
}

- (IBAction)changeProfilePicture:(id)sender {
    
 
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Profile picture"
                                                                   message:@"Change your profile picture."
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *firstAction = [UIAlertAction actionWithTitle:@"Camera"
                                                          style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                                                              [self pickMediaWithFiletype:PICK_CAMERA_IMAGE];
                                                              
                                                          }];
    UIAlertAction *secondAction = [UIAlertAction actionWithTitle:@"PhotoGallery"
                                                           style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                                                               [self pickMediaWithFiletype:PICK_IMAGE_GALLERY];
                                                           }];
    
    UIAlertAction *thirdAction = [UIAlertAction actionWithTitle:@"Cancel"
                                                           style:UIAlertActionStyleCancel handler:^(UIAlertAction * action) {
                                                               NSLog(@"You pressed button cancel");
                                                           }];
    

    
    [alert addAction:firstAction];
    [alert addAction:secondAction];
    [alert addAction:thirdAction];
    
    [self presentViewController:alert animated:YES completion:nil];
    
    
    
}
- (void) pickMediaWithFiletype :(int)filetype{
    ImagePicker *im = [ImagePicker sharedInstance];
    im.mParent = self;
    
    [[ImagePicker sharedInstance] pickMedia:filetype :^(ImagePickerFile *picker) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"Returned data %@", [picker description]);
            [[ImagePicker sharedInstance] getImageEditor:picker.image hideEditControl:NO withBlock:^BOOL(UIImage *image, NSString *caption) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    // Your UI code //
                    _mProfilePicture.image = image;
                    
                });
                NSLog(@"message data %@",caption);
                return YES;
                
            }];
        });
        
    }];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
