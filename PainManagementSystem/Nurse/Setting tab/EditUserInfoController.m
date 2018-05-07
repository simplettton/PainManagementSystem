//
//  EditUserInfoController.m
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/3/29.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import "EditUserInfoController.h"
#import "BaseHeader.h"
#import "HHDropDownList.h"

@interface EditUserInfoController ()<HHDropDownListDelegate, HHDropDownListDataSource>
@property (strong, nonatomic) IBOutletCollection(UITextField) NSArray *textFields;
@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
@property (weak, nonatomic) IBOutlet UITextField *contactTextFiled;
@property (weak, nonatomic) IBOutlet UITextField *departmentTextField;

//下拉框
@property (weak, nonatomic) IBOutlet HHDropDownList *dropDownView;
@property (strong, nonatomic) NSMutableArray *dropListArray;
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
    self.contactTextFiled.text = [UserDefault objectForKey:@"Contact"];
    self.departmentTextField.text = [UserDefault objectForKey:@"Department"];
    self.department = [UserDefault objectForKey:@"Department"];
    
    datas = [NSMutableArray arrayWithCapacity:20];
    self.dropListArray = [NSMutableArray arrayWithCapacity:20];
    
    self.dropDownView.dataSource = self;
    self.dropDownView.delegate = self;
    [self.dropDownView.layer setCornerRadius:5.0];
    self.dropDownView.highlightColor = [UIColor clearColor];
    [self.dropDownView.textLayer setAlignmentMode:kCAAlignmentLeft];

    [self getDepartmentList];

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
                                                 [self.dropListArray addObject:name];
                                                 [datas addObject:dataDic];
                                                 
                                             }
                                             
                                             [self.dropDownView.textLayer setString:self.department];
                                             [self.dropDownView reloadListData];

                                             [self.tableView reloadData];
                                         }
                                     }
                                     else{
//                                         [SVProgressHUD showErrorWithStatus:responseObject.errorString];
                                     }
                                 } failure:nil];
}
-(void)viewWillAppear:(BOOL)animated{
    
    [super viewWillAppear:YES];
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;

}
#pragma mark - HHDropDownList

- (NSArray *)listDataForDropDownList:(HHDropDownList *)dropDownList {
    
    return _dropListArray;
}
- (void)dropDownList:(HHDropDownList *)dropDownList didSelectItemName:(NSString *)itemName atIndex:(NSInteger)index {
    
    NSDictionary *dataDic = [datas objectAtIndex:index];
    
    self.departmentId = dataDic[@"id"];
    
    self.department = dataDic[@"name"];
    
}


#pragma mark - Table view data source


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 3;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.row == 2) {
        return ([self.dropListArray count]+1)*44;
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
    [self dismissViewControllerAnimated:YES completion:nil];
}
- (IBAction)save:(id)sender {
    [SVProgressHUD show];
    NSString *personName = self.nameTextField.text;
    NSString *contact = self.contactTextFiled.text;
//    NSString *department = self.departmentTextField.text;
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

@end
