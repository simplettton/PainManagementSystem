//
//  EditPasswordController.m
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/3/26.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import "EditPasswordController.h"
#import "BaseHeader.h"
@interface EditPasswordController ()<UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UITextField *oldPasswordTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UITextField *confirmPassWordTextField;
@property (strong, nonatomic) IBOutletCollection(UITextField) NSArray *textFields;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *finishButton;

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
        [SVProgressHUD showErrorWithStatus:@"请输入相同的密码"];
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
                                             [SVProgressHUD showErrorWithStatus:responseObject.errorString];
                                         }
                                        
                                     } failure:nil];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"设置密码";

    [self initAll];

    self.tableView.tableFooterView = [[UIView alloc]init];
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyBoard)];
    tapGestureRecognizer.cancelsTouchesInView = NO;
    [self.tableView addGestureRecognizer:tapGestureRecognizer];
}
-(void)hideKeyBoard{
    [self.view endEditing:YES];
    [self.tableView endEditing:YES];
    
}
-(void)initAll{
    
    for (UITextField *textField in self.textFields) {
        textField.layer.borderWidth = 0.5f;
        textField.layer.borderColor = UIColorFromHex(0xbbbbbb).CGColor;
        textField.leftView=[[UIView alloc] initWithFrame:CGRectMake(0, 0, 12, 51)];
        textField.leftViewMode=UITextFieldViewModeAlways;
        textField.layer.cornerRadius = 5.0f;
        
        textField.delegate = self;
    }
    
    self.finishButton.enabled = NO;
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:YES];
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;

}
#pragma mark - UITextField Delegate

-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    
    BOOL hasBlankTextFiled = NO;
    for (UITextField *textField in self.textFields) {
        if ([textField.text length] == 0) {
            hasBlankTextFiled = YES;
            if (textField.text.length >= 12) {
                textField.text = [textField.text substringToIndex:12];
            }
        }
    }
    if(!hasBlankTextFiled){
        self.finishButton.enabled = YES;
    }
    
    return YES;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 3;
}


@end
