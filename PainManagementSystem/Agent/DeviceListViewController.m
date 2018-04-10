//
//  DeviceListViewController.m
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/3/19.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import "DeviceListViewController.h"
#import "DeviceTableViewCell.h"
#import "EditDeviceViewController.h"
#import "BaseHeader.h"
#import "NetWorkTool.h"


@interface DeviceListViewController ()<UISearchBarDelegate>
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *deleteButton;

@property (strong,nonatomic)NSDictionary * typeDic;

@end

@implementation DeviceListViewController{
        NSMutableArray *datas;
}


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
    
    //searchBarDelegate
    self.searchBar.backgroundImage = [[UIImage alloc]init];//去除边框线
    self.searchBar.tintColor = UIColorFromHex(0x5e97fe);//出现光标
    self.searchBar.delegate = self;
    
    //tableview
    self.tableView.tableFooterView = [[UIView alloc]init];
    self.tableView.allowsMultipleSelectionDuringEditing = YES;
    

    _typeDic = @{
                 @7681:@"空气波",
                 @57119:@"血瘘",
                 @56833:@"电疗",
                 @56834:@"电疗",
                 @56836:@"电疗"

                 };
    
    [self askForData];
}

-(void)askForData{
    
    datas = [[NSMutableArray alloc]initWithCapacity:20];
    [[NetWorkTool sharedNetWorkTool]POST:[HTTPServerURLString stringByAppendingString:@"Api/DBDevice/Count"]
                                  params:@{
                                           
                                           }
                                hasToken:YES
                                 success:^(HttpResponse *responseObject) {
                                     
                                     
                                     if ([responseObject.result intValue]==1) {
                                         NSString *count = responseObject.content[@"count"];
                                         NSLog(@"count = %@",count);
                                         
                                         //页数
                                         NSInteger numberOfPages = ([count integerValue]+15-1)/15;
                                         
                                         //遍历页数获取数据
                                         for (int i =0; i<numberOfPages; i++) {
                                             
                                             [[NetWorkTool sharedNetWorkTool]POST:[HTTPServerURLString stringByAppendingString:@"Api/DBDevice/ListDBDevice"]
                                                                           params:@{
                                                                                    @"page":[NSString stringWithFormat:@"%d",i]
                                                                                    
                                                                                    }
                                                                         hasToken:YES
                                                                          success:^(HttpResponse *responseObject) {

                                                                              if ([responseObject.result intValue] == 1) {
                                                                                  NSDictionary *content = responseObject.content;
                                                                                  NSLog(@"receive content = %@",content);
                                                                                  for (NSDictionary *dic in content) {
                                                                                      [datas addObject:dic];
                                                                                  }
                                                                                  
                                                                                  [self.tableView reloadData];
                                                                              }
                                                                              else{
                                                                                  
                                                                              }
                                                                          } failure:nil];
                                         }
   
                                     }
                                 } failure:nil];

}



#pragma mark - tableview dataSource
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [datas count];
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *CellIdentifier = @"Cell";
    DeviceTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    if (cell == nil) {
        cell = [[DeviceTableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    NSDictionary *dataDic = [datas objectAtIndex:indexPath.row];
    
    
    cell.typeLabel.text = _typeDic[[dataDic objectForKey:@"machinetype"]];

    cell.serialNumLabel.text = [dataDic objectForKey:@"serialnum"];

    cell.nameLabel.text = [dataDic objectForKey:@"nick"];
    
    cell.macString = [dataDic objectForKey:@"cpuid"];
    
    cell.editButton.tag = indexPath.row;
    
    [cell.editButton addTarget:self action:@selector(edit:) forControlEvents:UIControlEventTouchUpInside];
    
    //改变编辑状态下左侧圆圈勾选颜色
    cell.tintColor = UIColorFromHex(0x37BD9C);
    return cell;
}
-(NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [self.searchBar resignFirstResponder];
    return indexPath;
}

#pragma mark - action
-(void)edit:(UIButton *)sender{
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:sender.tag inSection:0];
    DeviceTableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    [self performSegueWithIdentifier:@"EditDevice" sender:cell];
}

- (IBAction)delete:(id)sender {
    
    if (self.tableView.editing) {
        
    //完成删除之后的操作
        self.deleteButton.titleLabel.text = @"删除";
        [self.deleteButton setTitle:@"删除" forState:UIControlStateNormal];
        
        [SVProgressHUD setDefaultStyle:SVProgressHUDStyleDark];
        
        [SVProgressHUD show];

        NSMutableArray *deleteArray = [NSMutableArray array];
        
        for (NSIndexPath *indexPath in self.tableView.indexPathsForSelectedRows) {
            [deleteArray addObject:datas[indexPath.row]];
            
            NSString *cpuid = [datas[indexPath.row]objectForKey:@"cpuid"];

            [[NetWorkTool sharedNetWorkTool]POST:[HTTPServerURLString stringByAppendingString:@"Api/DBDevice/Delete"]
                                          params:@{
                                                   @"cpuid":cpuid
                                                   }
                                        hasToken:YES
                                         success:^(HttpResponse *responseObject) {
                                             if ([responseObject.result intValue]==1) {
                                                 dispatch_async(dispatch_get_main_queue(), ^{
                                                     [SVProgressHUD dismiss];
                                                     

                                                     
                                                 });
                                             }else{
                                                 NSString *error = responseObject.errorString;
                                                 dispatch_async(dispatch_get_main_queue(), ^{
                                                     [SVProgressHUD showErrorWithStatus:error];
                                                 });
                                             }
                                         }
                                         failure:nil];
        }
        

        NSMutableArray *currentArray = datas;
        [currentArray removeObjectsInArray:deleteArray];
        
        datas = currentArray;
        
        [self.tableView deleteRowsAtIndexPaths:self.tableView.indexPathsForSelectedRows withRowAnimation:UITableViewRowAnimationLeft];//删除对应数据的cell
        
        dispatch_time_t delayTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC));
        dispatch_after(delayTime, dispatch_get_main_queue(), ^{
            
            [self.tableView reloadData];
        });
        
        //完成删除后不给选中cell
        for (DeviceTableViewCell *cell in self.tableView.visibleCells) {
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        
        
    }else{
        self.deleteButton.titleLabel.text = @"完成";
        [self.deleteButton setTitle:@"完成" forState:UIControlStateNormal];
        for (DeviceTableViewCell *cell in self.tableView.visibleCells) {
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
        }
    }
    
    [self.tableView setEditing:!self.tableView.editing animated:NO];
}

#pragma mark - segue

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if([segue.identifier isEqualToString:@"EditDevice"]){
        UINavigationController *navi = (UINavigationController  *)segue.destinationViewController;
        DeviceTableViewCell *cell= (DeviceTableViewCell *)sender;
        EditDeviceViewController *controller = [navi.viewControllers firstObject];
        controller.type = cell.typeLabel.text;
        controller.name = cell.nameLabel.text;
        controller.macString = cell.macString;
        controller.serialNum = cell.serialNumLabel.text;
    
    }
}

#pragma mark - searchBar delegate

-(void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText{
    NSString *searchResult = self.searchBar.text;

}

-(void)searchBarSearchButtonClicked:(UISearchBar *)searchBar{
    if ([searchBar.text length]>0) {
        NSLog(@"------search: %@-----",searchBar.text);
    }

    [searchBar resignFirstResponder];
}


- (IBAction)search:(id)sender {
    if ([self.searchBar.text length]>0) {

        
        datas = [[NSMutableArray alloc]initWithCapacity:20];
        

        NSMutableDictionary *paramDic = [[NSMutableDictionary alloc]initWithCapacity:20];
        if ([[_typeDic allValues]containsObject:self.searchBar.text]) {
            
                    //机器类型转换
            [_typeDic enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                
                if([obj isEqualToString:self.searchBar.text]){
                    
                    [paramDic setObject:key forKey:@"machinetype"];
                    [self searchRequestWithParam:paramDic];
                }
            }];
            
        }else{
                    //搜索序列号或者名称
            [paramDic setObject:self.searchBar.text forKey:@"key"];
            [self searchRequestWithParam:paramDic];
            
        }


        
    [self.searchBar resignFirstResponder];
    
    }
}
-(void)searchRequestWithParam:(NSMutableDictionary *)dictionary{
    
    NSDictionary *param = (NSDictionary *)dictionary;
    
    [[NetWorkTool sharedNetWorkTool]POST:[HTTPServerURLString stringByAppendingString:@"Api/DBDevice/ListDBDeviceFuzzy"]
                                  params:@{@"machinetype":@"7681"}
                                hasToken:YES
                                 success:^(HttpResponse *responseObject) {
                                     if ([responseObject.result intValue] == 1) {
                                         NSDictionary *content = responseObject.content;
                                         NSLog(@"receive content = %@",content);
                                         for (NSDictionary *dic in content) {
                                             [datas addObject:dic];
                                         }
                                         [self.tableView reloadData];

                                     }
                                     
                                 }
                                 failure:nil];

}

//关闭键盘
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {

    [self.view endEditing:YES];
}

@end
