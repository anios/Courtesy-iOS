//
//  CourtesyProfileTableViewController.m
//  Courtesy
//
//  Created by Zheng on 2/26/16.
//  Copyright © 2016 82Flex. All rights reserved.
//

#import "CourtesyProfileTableViewController.h"
#import "CourtesyAccountProfileModel.h"
#import "AppDelegate.h"

#define kProfileAvatarReuseIdentifier @"kProfileAvatarReuseIdentifier"
#define kProfileNickReuseIdentifier @"kProfileNickReuseIdentifier"
#define kProfileGenderReuseIdentifier @"kProfileGenderReuseIdentifier"
#define kProfileBirthdayReuseIdentifier @"kProfileBirthdayReuseIdentifier"
#define kProfileMobileReuseIdentifier @"kProfileMobileReuseIdentifier"
#define kProfileFromWhereReuseIdentifier @"kProfileFromWhereReuseIdentifier"
#define kProfileConstellationReuseIdentifier @"kProfileConstellationReuseIdentifier"
#define kProfileIntroductionReuseIdentifier @"kProfileIntroductionReuseIdentifier"

enum {
    kAvatarSection = 0,
    kBasicSection,
    kReadonlySection
};

enum {
    kNickIndex = 0,
    kGenderIndex,
    kBirthdayIndex,
    kMobileIndex,
    kFromWhereIndex,
    kConstellationIndex,
    kIntroductionIndex
};

@interface CourtesyProfileTableViewController () <CourtesyEditProfileDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (weak, nonatomic) IBOutlet UILabel *avatarNickLabel;
@property (weak, nonatomic) IBOutlet UILabel *avatarDetailLabel;

@property (weak, nonatomic) IBOutlet UILabel *nickDetailLabel;
@property (weak, nonatomic) IBOutlet UILabel *genderDetailLabel;
@property (weak, nonatomic) IBOutlet UILabel *birthdayDetailLabel;
@property (weak, nonatomic) IBOutlet UILabel *mobileDetailLabel;
@property (weak, nonatomic) IBOutlet UILabel *fromWhereDetailLabel;
@property (weak, nonatomic) IBOutlet UILabel *constellationDetailLabel;
@property (weak, nonatomic) IBOutlet UILabel *emailDetailLabel;
@property (weak, nonatomic) IBOutlet UILabel *registeredAtDetailLabel;
@property (weak, nonatomic) IBOutlet UILabel *lastLoginAtDetailLabel;
@property (weak, nonatomic) IBOutlet UITextView *introductionLabel;

@end

@implementation CourtesyProfileTableViewController {
    id last_hash;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    last_hash = [[kProfile toDictionary] mutableCopy];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    _avatarNickLabel.text = kProfile.nick;
    _avatarDetailLabel.text = kAccount.email;
    _nickDetailLabel.text = kProfile.nick;
    if (kProfile.gender == 0) {
        _genderDetailLabel.text = @"Boy";
    } else if (kProfile.gender == 1) {
        _genderDetailLabel.text = @"Girl";
    } else if (kProfile.gender == 2) {
        _genderDetailLabel.text = @"Androgynous";
    }
    _birthdayDetailLabel.text = kProfile.birthday;
    _mobileDetailLabel.text = kProfile.mobile;
    _fromWhereDetailLabel.text = [NSString stringWithFormat:@"%@ - %@ - %@", kProfile.province, kProfile.city, kProfile.area];
    if (![[kProfile birthday] isEmpty]) {
        @try {
            NSDate *birthday = [NSDate dateWithString:kProfile.birthday format:@"yyyy-MM-dd"];
            _constellationDetailLabel.text = [birthday constellationString];
        }
        @catch (NSException *exception) {}
        @finally {}
    }
    _introductionLabel.text = kProfile.introduction;
    _emailDetailLabel.text = kAccount.email;
    _registeredAtDetailLabel.text = [[NSDate dateWithTimeIntervalSince1970:(float)kAccount.registered_at] stringWithFormat:@"yyyy-MM-dd HH:mm:ss"];
    _lastLoginAtDetailLabel.text = [[NSDate dateWithTimeIntervalSince1970:(float)kAccount.last_login_at] stringWithFormat:@"yyyy-MM-dd HH:mm:ss"];
    if (![[kProfile toDictionary] isEqual:last_hash]) { // 判断是否进行过修改
        [self.tableView reloadData];
        last_hash = [[kProfile toDictionary] mutableCopy]; // 更新备份
        if (![kProfile isEditing]) {
            [JDStatusBarNotification showWithStatus:@"资料更新中"
                                          styleName:JDStatusBarStyleDefault];
            [JDStatusBarNotification showActivityIndicator:YES indicatorStyle:UIActivityIndicatorViewStyleGray];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^() {
                [kProfile setDelegate:self]; // 设置请求代理
                [kProfile editProfile];
            });
        }
    }
}

#pragma mark - 个人资料导航栏按钮

- (IBAction)actionToggleLeftDrawer:(id)sender {
    [[AppDelegate globalDelegate] toggleLeftDrawer:self animated:YES];
}

- (IBAction)actionShareMyProfile:(id)sender {
    CYLog(@"Action share my profile!");
}

#pragma mark - 自定义选择器

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == kAvatarSection && indexPath.row == 0) {
        [self openMenu];
    }
}

- (void)openMenu {
    LGAlertView *alert = [[LGAlertView alloc] initWithTitle:@"上传头像" message:@"请选择一种方式" style:LGAlertViewStyleActionSheet buttonTitles:@[@"相机", @"本地相册"] cancelButtonTitle:@"取消" destructiveButtonTitle:nil actionHandler:^(LGAlertView *alertView, NSString *title, NSUInteger index) {
        if (index == 0) {
            UIImagePickerController *picker = [[UIImagePickerController alloc] init];
            picker.sourceType = UIImagePickerControllerSourceTypeCamera;
            picker.delegate = self;
            picker.allowsEditing = YES;
            [self presentViewController:picker animated:YES completion:nil];
        } else {
            UIImagePickerController *picker = [[UIImagePickerController alloc] init];
            picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            picker.delegate = self;
            picker.allowsEditing = YES;
            [self presentViewController:picker animated:YES completion:nil];
        }
    } cancelHandler:nil destructiveHandler:nil];
    [alert showAnimated:YES completionHandler:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

-(void)imagePickerController:(UIImagePickerController*)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [picker dismissViewControllerAnimated:YES completion:nil];
    __block UIImage* image = [info objectForKey:UIImagePickerControllerEditedImage];
    if (!image){
        image = [info objectForKey:UIImagePickerControllerOriginalImage];
    }
    
    // 上传
}

#pragma mark - 修改资料请求回调

- (void)editProfileSucceed:(CourtesyAccountProfileModel *)sender {
    [JDStatusBarNotification showWithStatus:@"资料更新成功" dismissAfter:2.0
                                  styleName:JDStatusBarStyleSuccess];
}

- (void)editProfileFailed:(CourtesyAccountProfileModel *)sender
             errorMessage:(NSString *)message {
    [JDStatusBarNotification showWithStatus:[NSString stringWithFormat:@"资料更新失败 - %@", message] dismissAfter:2.0
                                  styleName:JDStatusBarStyleError];
}

@end