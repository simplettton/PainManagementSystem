//
//  EditUserInfoController.m
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/3/29.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import "EditUserInfoController.h"
#import "BaseHeader.h"
#import "BETextField.h"

#import <BRPickerView.h>

@interface EditUserInfoController ()<UITextFieldDelegate>
@property (strong, nonatomic) IBOutletCollection(UITextField) NSArray *textFields;
@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
@property (weak, nonatomic) IBOutlet UITextField *contactTextFiled;

@property (weak, nonatomic) IBOutlet BETextField *departmentTextField;

//下拉框

@property (strong, nonatomic) NSMutableArray *departmentNameArray;
@property (strong, nonatomic) NSString *departmentId;
@property (strong, nonatomic) NSString *department;

@end

@implementation EditUserInfoController{
    NSMutableArray *datas;
}

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
        textField.layer.cornerRadius = 5.0f;
    }
    
    self.nameTextField.text = [UserDefault objectForKey:@"PersonName"];
    
    NSString *contactString = [[UserDefault objectForKey:@"Contact"]stringByReplacingOccurrencesOfString:@"-" withString:@""];
    self.contactTextFiled.text = contactString;
    
    self.departmentTextField.text = [UserDefault objectForKey:@"Department"];
    self.department = [UserDefault objectForKey:@"Department"];
    self.contactTextFiled.delegate = self;
    
    datas = [NSMutableArray arrayWithCapacity:20];
    self.departmentNameArray = [NSMutableArray arrayWithCapacity:20];

    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyBoard)];
    tapGestureRecognizer.cancelsTouchesInView = NO;
    [self.tableView addGestureRecognizer:tapGestureRecognizer];
    [self getDepartmentList];

}
-(void)hideKeyBoard{
    [self.view endEditing:YES];
    [self.tableView endEditing:YES];
    
}
-(void)getDepartmentList{
    [[NetWorkTool sharedNetWorkTool]POST:[HTTPServerURLString stringByAppendingFormat:@"Api/Department/List"]
                                  params:nil
                                hasToken:YES
                                 success:^(HttpResponse *responseObject) {
                                     if ([responseObject.result intValue] == 1) {
                                         if (responseObject.content) {
                                             
                                             
                                             for (NSDictionary *dataDic in responseObject.content) {
                                                 NSString *name = dataDic[@"name"];
                                                 [self.departmentNameArray addObject:name];
                                                 [datas addObject:dataDic];
                                                 
                                             }
                                             if (datas) {
                                                 
                                                 NSArray *nameArray = [self.departmentNameArray copy];
                                                 __weak typeof(self) weakSelf = self;
                                                 
                                                 [self.departmentTextField addTapAciton:^{
                                                     [BRStringPickerView showStringPickerWithTitle:@"科室" dataSource:nameArray defaultSelValue:self.department resultBlock:^(id selectValue) {
                                                         
                                                         weakSelf.departmentTextField.text = selectValue;
                                                         NSInteger index = [self.departmentNameArray indexOfObject:selectValue];
                                                         weakSelf.department = selectValue;
                                                         weakSelf.departmentId = datas[index][@"id"];
                                                     }];
                                                 }];
                                             }
                                             
//                                             [self.dropDownView.textLayer setString:self.department];
//                                             [self.dropDownView reloadListData];

//                                             [self.tableView reloadData];
                                         }
                                     }
                                     else{
//                                         [SVProgressHUD showErrorWithStatus:responseObject.errorString];
                                     }
                                 } failure:nil];
}
-(void)viewWillAppear:(BOOL)animated{
    
    [super viewWillAppear:YES];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textFieldDidChange) name:UITextFieldTextDidChangeNotification object:nil];
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;

}
-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:YES];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextFieldTextDidChangeNotification object:nil];
}
-(void)textFieldDidChange{
    if (self.nameTextField.text.length > 20) {
        self.nameTextField.text = [self.nameTextField.text substringToIndex:20];
    }
    if (self.contactTextFiled.text.length > 11) {
        self.contactTextFiled.text = [self.contactTextFiled.text substringToIndex:11];
    }
}
-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    NSCharacterSet*cs;
    
    cs = [[NSCharacterSet characterSetWithCharactersInString:@"0123456789"] invertedSet];
    NSString*filtered = [[string componentsSeparatedByCharactersInSet:cs] componentsJoinedByString:@""];
    BOOL basicTest = [string isEqualToString:filtered];
    if (!basicTest) {
        return NO;
    }
    return YES;
}

#pragma mark - Table view data source


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 3;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.row == 2) {
//        return ([self.dropListArray count]+1)*44;
        return 44;
    }else{
        return 44;
    }
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
    [self hideKeyBoard];
    [self dismissViewControllerAnimated:YES completion:nil];
}
- (IBAction)save:(id)sender {
    [self hideKeyBoard];
    if (self.nameTextField.text.length == 0 || self.contactTextFiled.text.length == 0) {
        [SVProgressHUD showErrorWithStatus:@"请填写完整信息"];
        return;
    }else{
            [SVProgressHUD show];
        NSString *personName = self.nameTextField.text;
        NSString *contact = self.contactTextFiled.text;
        
        NSMutableDictionary *params = [[NSMutableDictionary alloc]initWithCapacity:20];
        [params setObject:personName forKey:@"personname"];
        [params setObject:contact forKey:@"contact"];
        if (self.departmentId) {
            [params setObject:self.departmentId forKey:@"department"];
        }
        [[NetWorkTool sharedNetWorkTool]POST:[HTTPServerURLString stringByAppendingString:@"Api/User/ChangeSelfInfo"]
                                      params:params
                                    hasToken:YES
                                     success:^(HttpResponse *responseObject) {
                                         if ([responseObject.result intValue] == 1) {
                                             dispatch_async(dispatch_get_main_queue(), ^{
                                                 
                                                 [SVProgressHUD showSuccessWithStatus:@"保存成功"];
                                                 [self dismissViewControllerAnimated:YES completion:nil];
                                                 
                                                 [UserDefault setObject:personName forKey:@"PersonName"];
                                                 [UserDefault setObject:contact forKey:@"Contact"];
                                                 [UserDefault setObject:self.department forKey:@"Department"];
                                                 [UserDefault synchronize];
                                                 
                                             });
                                         }else{
                                             [SVProgressHUD showErrorWithStatus:responseObject.errorString];
                                         }
                                         
                                     }
                                     failure:nil];
    }
}
@end
