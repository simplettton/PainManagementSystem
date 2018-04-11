//
//  DeviceListViewController.m
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/3/19.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import "DeviceListViewController.h"
#import "DeviceTableViewCell.h"
#import "MJChiBaoZiHeader.h"
#import "EditDeviceViewController.h"
#import "BaseHeader.h"
#import "NetWorkTool.h"

#import "MJRefresh.h"

@interface DeviceListViewController ()<UISearchBarDelegate>
{
    int page;
    BOOL isFirstCome; //第一次加载时候不需要传入此关键字，当需要加载下一页时：
    int totalPage;//总页数
    BOOL isJuhua;//是否正在下拉刷新或者上拉加载。default NO。
    
    BOOL isFilteredList;
    NSMutableDictionary *filterparam;
    
}
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *deleteButton;

@property (strong,nonatomic)NSDictionary * typeDic;

@end

@implementation DeviceListViewController{
        NSMutableArray *datas;
}
-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:YES];
    
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:46.0f/255.0f green:163.0f/255.0f blue:230.0f/255.0f alpha:1];
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"设备管理系统";
    [self initAll];
    

    //下拉刷新
    self.tableView.mj_header = [MJChiBaoZiHeader headerWithRefreshingTarget:self refreshingAction:@selector(refresh)];
    [self.tableView.mj_header beginRefreshing];

    
    //上拉加载
    MJRefreshAutoNormalFooter *footer = [MJRefreshAutoNormalFooter footerWithRefreshingTarget:self refreshingAction:@selector(loadMore)];
    [footer setTitle:@"" forState:MJRefreshStateIdle];
    [footer setTitle:@"" forState:MJRefreshStateRefreshing];
    [footer setTitle:@"No more data" forState:MJRefreshStateNoMoreData];
    self.tableView.mj_footer = footer;
    
}

-(void)refresh
{
    
    isFilteredList = NO;
    [self askForData:YES isFiltered:NO];

}

-(void)loadMore
{
    if ([self.searchBar.text length]>0 && isFilteredList) {
        
        [self askForData:NO isFiltered:YES];
        
    }else{
        [self askForData:NO isFiltered:NO];
    }

}

/**
 *  停止刷新
 */
-(void)endRefresh{
    
    if (page == 0) {
        [self.tableView.mj_header endRefreshing];
    }
    [self.tableView.mj_footer endRefreshing];
}

-(void)askForData:(BOOL)isRefresh isFiltered:(BOOL)iSFiltered{

    NSString *url;
    NSDictionary *params = [[NSDictionary alloc]init];
    if (iSFiltered) {
        
        url = [HTTPServerURLString stringByAppendingString:@"Api/DBDevice/CountFuzzy"];
        params = (NSDictionary *)filterparam;
        
    }else{
        url = [HTTPServerURLString stringByAppendingString:@"Api/DBDevice/Count"];
    }
    
    
    [[NetWorkTool sharedNetWorkTool]POST:url
                                  params:params
                                hasToken:YES
                                 success:^(HttpResponse *responseObject) {
                                     
                                     if ([responseObject.result intValue] == 1) {
                                         
                                         NSString *count = responseObject.content[@"count"];
                                         
                                         totalPage = ([count intValue]+15-1)/15;
                                         
                                        NSLog(@"totalPage = %d",totalPage);
                                         
                                         
                                         [self getNetworkData:isRefresh isFiltered:iSFiltered];
                                         
                                     }else{
                                         [SVProgressHUD showErrorWithStatus:responseObject.errorString];
                                     }
                                 } failure:nil];
    
}

-(void)getNetworkData:(BOOL)isRefresh isFiltered:(BOOL)isFiltered{
    
    
    if (isRefresh) {
        page = 0;
        isFirstCome = YES;
    }else{
        page ++;
    }
    
    NSString *url;
    NSDictionary *params;
    if (isFiltered) {
        
        url = [HTTPServerURLString stringByAppendingString:@"Api/DBDevice/ListDBDeviceFuzzy"];
        [filterparam setObject:[NSNumber numberWithInt:page] forKey:@"page"];
        params = (NSDictionary *)filterparam;
        
        
    }else{
        url = [HTTPServerURLString stringByAppendingString:@"Api/DBDevice/ListDBDevice"];
        params = @{
                  @"page":[NSNumber numberWithInt:page]
                  };
    }
    
    
    __weak UITableView *tableView = self.tableView;
    
    [[NetWorkTool sharedNetWorkTool]POST:url
                                  params:params
                                hasToken:YES
                                 success:^(HttpResponse *responseObject) {
                                     
                                     [self endRefresh];
                                     
                                     isJuhua = NO; //数据获取成功后，设置为NO
                                     
                                     if (page == 0) {
                                         [datas removeAllObjects];
                                     }
                                     
                                     //判断是否正在加载，如果有，判断当前页数是不是大于最大页数，是的话就不让加载，直接return；（因为下拉的当前页永远是最小的，所以直接return）
                                     
                                     if (isJuhua) {
                                         if (page >= totalPage) {
                                             [self endRefresh];
                                         }
                                         return ;
                                     }
                                     
                                     //没有加载，所以设置yes
                                     isJuhua = YES;
                                     
                                     //适用于上拉加载更多
                                     if (page >totalPage) {
                                         [self endRefresh];
                                         [tableView.mj_footer endRefreshingWithNoMoreData];
                                         return;
                                     }
                                     
                                     if ([responseObject.result intValue] == 1) {
                                         NSDictionary *content = responseObject.content;
                                         
                                         NSLog(@"请求 = =");
                                         if (![content isEqual:[NSNull null]]) {
                                             for (NSDictionary *dic in content) {
                                                 if (![datas containsObject:dic]) {
                                                     [datas addObject:dic];
                                                 }
                                             }
                                             
                                             dispatch_async(dispatch_get_main_queue(), ^{
                                                 [tableView reloadData];
                                             });
                                         }
   
                                     }else{
                                         [SVProgressHUD showErrorWithStatus:responseObject.errorString];
                                     }
                                     
                                     isFirstCome = NO;
                                     
                                 } failure:nil];
    
}

-(void)initAll{
    
    //pageControll
    
    page = 0;
    isFirstCome = YES;
    isJuhua = NO;
    isFilteredList = NO;
    //
    datas = [[NSMutableArray alloc]initWithCapacity:20];
    
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
    
//    if ([datas count]>0) {

        if (indexPath.row < [datas count]) {
            NSDictionary *dataDic = [datas objectAtIndex:indexPath.row];
            
            cell.typeLabel.text = _typeDic[[dataDic objectForKey:@"machinetype"]];
            
            cell.serialNumLabel.text = [dataDic objectForKey:@"serialnum"];
            
            cell.nameLabel.text = [dataDic objectForKey:@"nick"];
            
            cell.macString = [dataDic objectForKey:@"cpuid"];
            
            cell.editButton.tag = indexPath.row;
            
            [cell.editButton addTarget:self action:@selector(edit:) forControlEvents:UIControlEventTouchUpInside];

        }

//    }


    
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

//-(void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText{
//    NSString *searchResult = self.searchBar.text;
//
//}
//
-(void)searchBarSearchButtonClicked:(UISearchBar *)searchBar{

    [self search:searchBar];

}


- (IBAction)search:(id)sender {
    if ([self.searchBar.text length]>0) {

        isFilteredList = YES;
        //清空列表
        datas = [[NSMutableArray alloc]initWithCapacity:20];

        NSMutableDictionary *paramDic = [[NSMutableDictionary alloc]initWithCapacity:20];
        
        if ([[_typeDic allValues]containsObject:self.searchBar.text]) {
            
            //机器类型转换
            [_typeDic enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                
                if([obj isEqualToString:self.searchBar.text]){
                    
                    [paramDic setObject:key forKey:@"machinetype"];
                    
                    filterparam = paramDic;
                    
                    [self askForData:YES isFiltered:YES];
                }
            }];
            
        }else{
            
            //搜索序列号或者名称
            [paramDic setObject:self.searchBar.text forKey:@"key"];
            
            filterparam = paramDic;
            
            [self askForData:YES isFiltered:YES];
            
        }
    
    }else{
        //没有关键字显示全部
        [self askForData:NO isFiltered:NO];
    }
        [self.searchBar resignFirstResponder];
}




//关闭键盘
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {

    [self.view endEditing:YES];
}

@end
