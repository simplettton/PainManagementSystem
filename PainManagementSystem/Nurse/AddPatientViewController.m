//
//  AddPatientViewController.m
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/3/26.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import "AddPatientViewController.h"
#import "NSDate+BRAdd.h"
#import "BETextField.h"
#import <BRPickerView.h>
#import "BaseHeader.h"
@interface AddPatientViewController ()
@property (strong, nonatomic) IBOutletCollection(UIView) NSArray *editViews;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControll;
@property (weak, nonatomic) IBOutlet UITextField *medicalRecordNumTextField;
@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
@property (weak, nonatomic) IBOutlet UITextField *phoneTextFiled;

@property (weak, nonatomic) IBOutlet BETextField *birthdayTF;
@property (weak, nonatomic) IBOutlet UILabel *treatDateLabel;
@property (weak, nonatomic) IBOutlet UIView *birthDayView;
@property (weak, nonatomic) IBOutlet UIView *treatDayView;

@end

@implementation AddPatientViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    [self initAll];
}

-(void)initAll{
    if (self.dataDic == nil) {
        self.title = @"增加病历";
    }else{
        self.title = @"修改病历";
        self.medicalRecordNumTextField.text = [self.dataDic objectForKey:@"medicalRecordNum"];
        self.nameTextField.text = [self.dataDic objectForKey:@"name"];
        self.phoneTextFiled.text = [self.dataDic objectForKey:@"phone"];
        
        NSString *gender = [self.dataDic objectForKey:@"gender"];
        NSArray *genderArray = @[@"男",@"女",@"其他"];
        NSInteger selectedIndex = [genderArray indexOfObject:gender];
        [self.segmentedControll setSelectedSegmentIndex:selectedIndex];
        
//        UITabBarController *tabBarController = (UITabBarController *)self.navigationController.superclass;
//        
//        tabBarController.hidesBottomBarWhenPushed = YES;
    }
    for (UIView *view in self.editViews) {
        view.layer.borderWidth = 0.5f;
        view.layer.borderColor = UIColorFromHex(0xbbbbbb).CGColor;
    }
    
    CGRect frame=  self.segmentedControll.frame;
    CGFloat fNewHeight = 35.0f;
    [self.segmentedControll setFrame:CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, fNewHeight)];
    
//    UITapGestureRecognizer *birthDayTapGesture = [[UITapGestureRecognizer alloc]init];
//    [birthDayTapGesture addTarget:self action:@selector(tapBirthDayView:)];
//    [self.birthDayView addGestureRecognizer:birthDayTapGesture];
    
    
    __weak typeof(self) weakSelf = self;
    [self.birthdayTF addTapAciton:^{

        [BRDatePickerView showDatePickerWithTitle:@"出生日期"
                                         dateType:UIDatePickerModeDate
                                  defaultSelValue:weakSelf.birthdayTF.text
                                       minDateStr:nil
                                       maxDateStr:[NSDate currentDateString]
                                     isAutoSelect:NO
                                       themeColor:nil
                                      resultBlock:^(NSString *selectValue) {
            weakSelf.birthdayTF.text = selectValue;
        } cancelBlock:^{
            NSLog(@"点击了背景或取消按钮");
        }];

    }];
    
}
//-(void)tapBirthDayView:(UIGestureRecognizer *)gesture{
//
//    [BRDatePickerView showDatePickerWithTitle:@"出生日期" dateType:UIDatePickerModeDate defaultSelValue:self.birthdayTF.text minDateStr:nil maxDateStr:[NSDate currentDateString] isAutoSelect:YES themeColor:nil resultBlock:^(NSString *selectValue) {
//        self.birthdayTF.text = selectValue;
//    } cancelBlock:^{
//        NSLog(@"点击了背景或取消按钮");
//    }];
//
//}

@end
