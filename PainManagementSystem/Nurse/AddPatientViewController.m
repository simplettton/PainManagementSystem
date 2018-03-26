//
//  AddPatientViewController.m
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/3/26.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import "AddPatientViewController.h"
#import "BaseHeader.h"
@interface AddPatientViewController ()
@property (strong, nonatomic) IBOutletCollection(UIView) NSArray *editViews;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControll;
@property (weak, nonatomic) IBOutlet UITextField *medicalRecordNumTextField;
@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
@property (weak, nonatomic) IBOutlet UITextField *phoneTextFiled;
@property (weak, nonatomic) IBOutlet UILabel *treatDateLabel;

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
}

@end
