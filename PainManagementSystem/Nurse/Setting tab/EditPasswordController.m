//
//  EditPasswordController.m
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/3/26.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import "EditPasswordController.h"
#import "BaseHeader.h"
@interface EditPasswordController ()
@property (weak, nonatomic) IBOutlet UITextField *oldPasswordTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UITextField *confirmPassWordTextField;
@property (strong, nonatomic) IBOutletCollection(UITextField) NSArray *textFields;

@end

@implementation EditPasswordController
- (IBAction)cancel:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}
- (IBAction)done:(id)sender {
    NSString *newPwd = self.passwordTextField.text;
    NSString *oldPwd = self.oldPasswordTextField.text;
    [SVProgressHUD show];
    if (![self.confirmPassWordTextField.text isEqualToString:newPwd]) {
        [SVProgressHUD showInfoWithStatus:@"请输入相同的密码"];
    }else{
        [[NetWorkTool sharedNetWorkTool]POST:[HTTPServerURLString stringByAppendingString:@"Api/User/ChangeSelfPwd"]
                                      params:@{@"newpwd":newPwd,
                                               @"oldpwd":oldPwd
                                               }
                                    hasToken:YES
                                     success:^(HttpResponse *responseObject) {
                                         if ([responseObject.result intValue] == 1) {
                                             dispatch_async(dispatch_get_main_queue(), ^{
                                                 [SVProgressHUD showSuccessWithStatus:@"修改成功"];
                                             });
                                                 [self dismissViewControllerAnimated:YES completion:nil];
                                         }else{
                                             NSLog(@"error = %@",responseObject.errorString);
                                         }
                                        
                                     } failure:nil];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"设置密码";

    [self initAll];
    self.tableView.tableFooterView = [[UIView alloc]init];
 
}
-(void)initAll{
    
    for (UITextField *textField in self.textFields) {
        textField.layer.borderWidth = 0.5f;
        textField.layer.borderColor = UIColorFromHex(0xbbbbbb).CGColor;
        textField.leftView=[[UIView alloc] initWithFrame:CGRectMake(0, 0, 12, 51)];
        textField.leftViewMode=UITextFieldViewModeAlways;
    }
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:YES];
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
//    self.navigationController.navigationBar.barTintColor = UIColorFromHex(0x2EA3E6);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 3;
}




@end
