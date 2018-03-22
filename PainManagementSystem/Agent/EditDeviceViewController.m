//
//  EditDeviceViewController.m
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/3/20.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import "EditDeviceViewController.h"
//#import "QuartzCore/QuartzCore.h"
#import "BaseHeader.h"
@interface EditDeviceViewController ()
@property (weak, nonatomic) IBOutlet UITextField *typeTextField;
@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
@property (weak, nonatomic) IBOutlet UITextField *serialNumTextField;
@property (weak, nonatomic) IBOutlet UILabel *macLabel;

@end

@implementation EditDeviceViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"设备管理系统";
    [self initAll];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:YES];
    
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:46.0f/255.0f green:163.0f/255.0f blue:230.0f/255.0f alpha:1];
}

-(void)initAll{
    self.macLabel.text = self.macString;
    
    self.typeTextField.layer.borderWidth = 1.0f;
    self.typeTextField.layer.borderColor = UIColorFromHex(0xBBBBBB).CGColor;
    self.typeTextField.text = self.type;
    
    self.nameTextField.layer.borderWidth = 1.0f;
    self.nameTextField.layer.borderColor = UIColorFromHex(0xBBBBBB).CGColor;
    self.nameTextField.text = self.name;
    
    self.serialNumTextField.layer.borderWidth = 1.0f;
    self.serialNumTextField.layer.borderColor = UIColorFromHex(0xBBBBBB).CGColor;
    self.serialNumTextField.text = self.serialNum;
}
- (IBAction)submit:(id)sender {
    NSLog(@"send to server ------------edit   cpuid:%@--------",_macString);
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
