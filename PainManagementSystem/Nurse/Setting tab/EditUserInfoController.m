//
//  EditUserInfoController.m
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/3/29.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import "EditUserInfoController.h"
#import "BaseHeader.h"

@interface EditUserInfoController ()
@property (strong, nonatomic) IBOutletCollection(UITextField) NSArray *textFields;
@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
@property (weak, nonatomic) IBOutlet UITextField *contactTextFiled;
@property (weak, nonatomic) IBOutlet UITextField *noteTextField;

@end

@implementation EditUserInfoController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self initAll];
    self.tableView.tableFooterView = [[UIView alloc]init];
    
}
-(void)initAll{
    

    //textField前面空出一部分
    for (UITextField *textField in self.textFields) {
        textField.layer.borderWidth = 0.5f;
        textField.layer.borderColor = UIColorFromHex(0xbbbbbb).CGColor;
        textField.leftView=[[UIView alloc] initWithFrame:CGRectMake(0, 0, 12, 51)];
        textField.leftViewMode=UITextFieldViewModeAlways;
    }
    
    self.nameTextField.text = [UserDefault objectForKey:@"PersonName"];
    self.contactTextFiled.text = [UserDefault objectForKey:@"Contact"];
    self.noteTextField.text = [UserDefault objectForKey:@"Note"];
}
-(void)viewWillAppear:(BOOL)animated{
    
    [super viewWillAppear:YES];
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;

}
#pragma mark - Table view data source


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 3;
}
-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 25;
}
-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    UIView *headerView = [[UIView alloc]init];
    headerView.backgroundColor = [UIColor whiteColor];
    return headerView;
}


- (IBAction)cancel:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}
- (IBAction)save:(id)sender {
    [SVProgressHUD show];
    NSString *personName = self.nameTextField.text;
    NSString *contact = self.contactTextFiled.text;
    NSString *note = self.noteTextField.text;
    [[NetWorkTool sharedNetWorkTool]POST:[HTTPServerURLString stringByAppendingString:@"Api/User/ChangeSelfInfo"]
                                                                             params:@{@"personname":personName,
                                                                                      @"contact":contact,
                                                                                      @"note":note
                                                                                      }
                                                                           hasToken:YES
                                                                            success:^(HttpResponse *responseObject) {
                                                                                if ([responseObject.result intValue] == 1) {
                                                                                    dispatch_async(dispatch_get_main_queue(), ^{
                                                                                        [SVProgressHUD showSuccessWithStatus:@"保存成功"];
                                                                                        [self dismissViewControllerAnimated:YES completion:nil];
                                                                                        
                                                                                        [UserDefault setObject:personName forKey:@"PersonName"];
                                                                                        [UserDefault setObject:contact forKey:@"Contact"];
                                                                                        [UserDefault setObject:note forKey:@"Note"];
                                                                                        [UserDefault synchronize];
                                                                                        
                                                                                    });
                                                                                }else{
    
                                                                                }
                                                                            
                                                                            }
                                                                            failure:nil];

}

@end
