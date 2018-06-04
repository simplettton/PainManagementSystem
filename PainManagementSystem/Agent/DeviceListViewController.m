//
//  DeviceListViewController.m
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/3/19.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import "DeviceListViewController.h"
#import "LoginViewController.h"
#import "DeviceTableViewCell.h"
#import "EditDeviceViewController.h"
#import "BaseHeader.h"
#import "NetWorkTool.h"
#import "DropdownButton.h"
#import "NoDataPlaceHoler.h"
#import "MJRefresh.h"
#import "MachineSeriesModel.h"
#import "AppDelegate.h"

@interface DeviceListViewController ()<UISearchBarDelegate>
{
    int page;
    BOOL isFirstCome; //第一次加载时候不需要传入此关键字，当需要加载下一页时：
    int totalPage;//总页数
    BOOL isJuhua;//是否正在下拉刷新或者上拉加载。default NO。
    
    BOOL isFilteredList;
    NSMutableDictionary *filterparam;
    //类型总数
    NSMutableArray *typeItemModels;
    
}
@property (weak, nonatomic) IBOutlet UIView *tableBackgroundView;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *deleteButton;
@property (weak, nonatomic) IBOutlet DropdownButton *filterButton;
//没有记录view
@property(nonatomic,strong)NoDataPlaceHoler *nodataView;
@property (strong,nonatomic)NSMutableDictionary * typeDic;

@end

@implementation DeviceListViewController{
        NSMutableArray *datas;
}
-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:YES];
    [self refresh];
    [_filterButton.titleLabel addObserver:self forKeyPath:@"text" options:NSKeyValueObservingOptionNew context:nil];
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:46.0f/255.0f green:163.0f/255.0f blue:230.0f/255.0f alpha:1];
    self.tableView.mj_header.hidden = NO;
    if (self.tableView.isEditing == YES) {
        [self.tableView setEditing:NO];
        self.deleteButton.titleLabel.text = @"删除";
        [self.deleteButton setTitle:@"删除" forState:UIControlStateNormal];
    }
    
}
-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:YES];
    [_filterButton.titleLabel removeObserver:self forKeyPath:@"text" context:nil];
    self.tableView.mj_header.hidden = YES;
    [self endRefresh];
    [self cancelAllRequest];
    [self hideKeyBoard];

}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"设备管理系统";
    [self initAll];
}
-(void)getTypeDic {
    self.typeDic = [[NSMutableDictionary alloc]initWithCapacity:20];
    [[NetWorkTool sharedNetWorkTool]POST:[HTTPServerURLString stringByAppendingString:@"Api/AgesShop/MachineList"]
                                  params:nil
                                hasToken:YES
                                 success:^(HttpResponse *responseObject) {
                                     if([responseObject.result integerValue] == 1){
                                         NSArray *content = responseObject.content;

                                         for (NSDictionary *dic in content) {
                                             MachineSeriesModel *machineModel = [MachineSeriesModel modelWithDic:dic];
                                             [self.typeDic setValue:machineModel forKey:dic[@"code"]];
                                         }
                                         AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
                                         appDelegate.typeDic = self.typeDic;
                                         
//                                         [self.tableView.mj_header beginRefreshing];
                                         [self refresh];
                                     }
                                 }
                                 failure:nil];
}
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
    [self hideKeyBoard];

}
-(void)hideKeyBoard{
    [self.view endEditing:YES];
    [self.tableView endEditing:YES];
    if (self.filterButton.isShow) {
        [self.filterButton clickedToDropDown];
    }
    
}

-(void)initAll{

    [self getTypeDic];
    [self initMahineTypeModels];

    //pageControll
    
    page = 0;
    isFirstCome = YES;
    isJuhua = NO;
    isFilteredList = NO;
    datas = [[NSMutableArray alloc]initWithCapacity:20];
    
    //searchBarDelegate
    self.searchBar.backgroundImage = [[UIImage alloc]init];//去除边框线
    self.searchBar.tintColor = UIColorFromHex(0x5e97fe);//出现光标
    self.searchBar.delegate = self;
    UITextField * searchField = [_searchBar valueForKey:@"_searchField"];
    [searchField setValue:[UIFont systemFontOfSize:15 weight:UIFontWeightLight] forKeyPath:@"_placeholderLabel.font"];
    
    //tableview
    self.tableView.tableFooterView = [[UIView alloc]init];
    self.tableView.allowsMultipleSelectionDuringEditing = YES;
    
    //隐藏键盘手势
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyBoard)];
    tapGestureRecognizer.cancelsTouchesInView = NO;
    
    [self.tableView addGestureRecognizer:tapGestureRecognizer];
    
    
    [self initTableHeaderAndFooter];
    [self getTypeDic];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    if ([keyPath isEqualToString:@"text"]) {
        NSString *string = [_filterButton titleForState:UIControlStateNormal];
        self.searchBar.text = string;
        [self search:nil];
    }
}
-(void)initMahineTypeModels{
    typeItemModels = [NSMutableArray arrayWithCapacity:20];
    [[NetWorkTool sharedNetWorkTool]POST:[HTTPServerURLString stringByAppendingString:@"Api/AgesShop/MachineSeries"]
                                  params:nil
                                hasToken:YES
                                 success:^(HttpResponse *responseObject) {
                                     if([responseObject.result integerValue] == 1){
                                         NSArray *dataArray = responseObject.content;
                                         
                                         if ([dataArray count]>0) {
                                             for (NSDictionary *dic in dataArray) {
                                                 MachineSeriesModel *machineSeries = [MachineSeriesModel modelWithDic:dic];
                                                 if (![typeItemModels containsObject:machineSeries]) {
                                                     [typeItemModels addObject:machineSeries];
                                                 }
                                             }
                                             NSMutableArray *machineNameArray = [NSMutableArray arrayWithCapacity:20];
                                             for (MachineSeriesModel *machineModel in typeItemModels) {
                                                 [machineNameArray addObject:machineModel.name];
                                             }
                                             _filterButton.list = machineNameArray;
                                         }
                                     }
                                 } failure:nil];
}
#pragma mark - refresh
-(void)initTableHeaderAndFooter{
    
    //下拉刷新
//    self.tableView.mj_header = [MJChiBaoZiHeader headerWithRefreshingTarget:self refreshingAction:@selector(refresh)];
    MJRefreshNormalHeader *header = [MJRefreshNormalHeader headerWithRefreshingTarget:self refreshingAction:@selector(refresh)];
    [header setTitle:@"下拉刷新" forState:MJRefreshStateIdle];
    [header setTitle:@"松开更新" forState:MJRefreshStatePulling];
    [header setTitle:@"加载中..." forState:MJRefreshStateRefreshing];
    
    self.tableView.mj_header = header;
//    [self.tableView.mj_header beginRefreshing];
    //上拉加载
    MJRefreshAutoNormalFooter *footer = [MJRefreshAutoNormalFooter footerWithRefreshingTarget:self refreshingAction:@selector(loadMore)];
    [footer setTitle:@"" forState:MJRefreshStateIdle];
    [footer setTitle:@"" forState:MJRefreshStateRefreshing];
    [footer setTitle:@"没有数据了~" forState:MJRefreshStateNoMoreData];
    self.tableView.mj_footer = footer;
}

-(void)refresh
{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if(!appDelegate.typeDic){
        NSMutableDictionary *typeDic = [[NSMutableDictionary alloc]initWithCapacity:20];
        [[NetWorkTool sharedNetWorkTool]POST:[HTTPServerURLString stringByAppendingString:@"Api/AgesShop/MachineList"]
                                      params:nil
                                    hasToken:YES
                                     success:^(HttpResponse *responseObject) {
                                         if([responseObject.result integerValue] == 1){
                                             NSArray *content = responseObject.content;
                                             for (NSDictionary *dic in content) {
                                                 MachineSeriesModel *machineModel = [MachineSeriesModel modelWithDic:dic];
                                                 [typeDic setValue:machineModel forKey:dic[@"code"]];
                                             }
                                             AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
                                             appDelegate.typeDic = typeDic;
                                             self.typeDic = typeDic;
                                         }
                                     }
                                     failure:nil];
                if ([self.searchBar.text length]>0) {
                    [self search:nil];
                }else{
                    isFilteredList = NO;
                    [self askForData:YES isFiltered:NO];
                }
                [self.searchBar resignFirstResponder];
                [self hideKeyBoard];
    }else{
        if ([self.searchBar.text length]>0) {
            [self search:nil];
        }else{
            isFilteredList = NO;
            [self askForData:YES isFiltered:NO];
        }
        [self.searchBar resignFirstResponder];
        [self hideKeyBoard];
    }


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
                                     
                                     [self.searchBar resignFirstResponder];
                                     [self hideKeyBoard];
                                     
                                     if ([responseObject.result intValue] == 1) {
                                         
                                         NSString *count = responseObject.content[@"count"];
                                         
                                         totalPage = ([count intValue]+15-1)/15;
                                         
                                         if (totalPage <= 1) {
                                             self.tableView.mj_footer.hidden = YES;
                                         }else{
                                             self.tableView.mj_footer.hidden = NO;
                                         }
                                         
                                         if ([count intValue]>0) {
                                              [self getNetworkData:isRefresh isFiltered:iSFiltered];
                                             [self hideNodataView];
                                              self.tableView.tableHeaderView.hidden = NO;
                                         }else{
                                             [datas removeAllObjects];
                                             [self showNodataViewWithTitle:@"暂无已录入设备"];
                                        dispatch_async(dispatch_get_main_queue(), ^{
                                                 [self.tableView reloadData];
                                             });
                                             self.tableView.tableHeaderView.hidden = YES;
                                         }
                                         
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
                                     if (page >=totalPage) {
                                         [self endRefresh];
                                         [tableView.mj_footer endRefreshingWithNoMoreData];
                                         return;
                                     }
                                     
                                     if ([responseObject.result intValue] == 1) {
                                         NSArray *content = responseObject.content;

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
#pragma mark - mark NoDataView
-(void)showNodataViewWithTitle:(NSString *)title{
    if (self.nodataView == nil) {
        self.nodataView = [[[NSBundle mainBundle]loadNibNamed:@"NoDataPlaceHolder" owner:self options:nil]lastObject];
        self.nodataView.center = CGPointMake(self.tableBackgroundView.center.x, self.tableBackgroundView.center.y-150);
        [self.view addSubview:self.nodataView];
    }
    
    self.nodataView.titleLabel.text = title;
    
}
-(void)hideNodataView{
    if(self.nodataView){
        [self.nodataView removeFromSuperview];
        self.nodataView = nil;
    }
}


#pragma mark - tableview dataSource
-(CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 44;
}
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return UITableViewAutomaticDimension;
}

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
            
            cell.typeLabel.numberOfLines = 0;
            cell.typeLabel.lineBreakMode = NSLineBreakByWordWrapping;
            [cell.typeLabel sizeToFit];
            MachineSeriesModel *machineSeries = _typeDic[[dataDic objectForKey:@"machinetype"]];;
            cell.typeLabel.text = machineSeries.name;
           
            
            cell.serialNumLabel.text = [dataDic objectForKey:@"serialnum"];
            
            if (![[dataDic objectForKey:@"nick"] isEqual:[NSNull null]]) {
                
                cell.nameLabel.text = [dataDic objectForKey:@"nick"];
            }

            
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
        
        NSMutableArray *deleteArray = [NSMutableArray array];
        
        //header跟着tableview 左移
        CGRect frame = self.tableView.tableHeaderView.frame;
        frame.origin.x -= 36;
        self.tableView.tableHeaderView.frame = frame;
        
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

                                                     [self refresh];
                                                     
                                                     //完成删除后不给选中cell
                                                     for (DeviceTableViewCell *cell in self.tableView.visibleCells) {
                                                         cell.selectionStyle = UITableViewCellSelectionStyleNone;
                                                     }

                                                 });
                                             }else{
                                                 NSString *error = responseObject.errorString;
                                                 dispatch_async(dispatch_get_main_queue(), ^{
                                                     [SVProgressHUD showErrorWithStatus:error];
                                                     [self.tableView reloadData];
                                                 });
                                             }
                                         }
                                         failure:nil];

        }
    
    }else{
        self.deleteButton.titleLabel.text = @"完成";
        [self.deleteButton setTitle:@"完成" forState:UIControlStateNormal];
        for (DeviceTableViewCell *cell in self.tableView.visibleCells) {
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
        }
        //header跟着tableview右移
        CGRect frame = self.tableView.tableHeaderView.frame;
        frame.origin.x += 36;
        self.tableView.tableHeaderView.frame = frame;
    }
    
    [self.tableView setEditing:!self.tableView.editing animated:NO];
}
- (IBAction)logout:(id)sender {
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@""
                                                                   message:@"退出后不会删除任何历史数据，下次登录依然可以使用本账号。"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * action) {}];
    
    [alert addAction:cancelAction];
    
    UIAlertAction* logoutAction = [UIAlertAction actionWithTitle:@"退出登录" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {

        [UserDefault setBool:NO forKey:@"IsLogined"];
        
        [UserDefault synchronize];
        
        [[[UIApplication sharedApplication].delegate window].rootViewController removeFromParentViewController];
        
        UIStoryboard *mainStoryBoard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        
        LoginViewController *vc = (LoginViewController *)[mainStoryBoard instantiateViewControllerWithIdentifier:@"LoginViewController"];
        
        [UIView transitionWithView:[[UIApplication sharedApplication].delegate window]
                          duration:0.25
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{
                            [[UIApplication sharedApplication].delegate window].rootViewController = vc;
                        }
                        completion:nil];
        
        [[[UIApplication sharedApplication].delegate window] makeKeyAndVisible];
    }];
    
    [alert addAction:logoutAction];
    
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - segue

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if([segue.identifier isEqualToString:@"EditDevice"]){
//        UINavigationController *navi = (UINavigationController  *)segue.destinationViewController;
        DeviceTableViewCell *cell= (DeviceTableViewCell *)sender;
//        EditDeviceViewController *controller = [navi.viewControllers firstObject];
        
        EditDeviceViewController *controller = (EditDeviceViewController *)segue.destinationViewController;
        controller.type = cell.typeLabel.text;
        controller.name = cell.nameLabel.text;
        controller.macString = cell.macString;
        controller.serialNum = cell.serialNumLabel.text;
    
    }
}

#pragma mark - searchBar delegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    if (searchBar.text.length == 0) {
        [self refresh];
    }
}
-(void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    
    [self search:nil];
}

- (IBAction)search:(id)sender {
    if ([self.searchBar.text length]>0) {

        isFilteredList = YES;
        //清空列表
        datas = [[NSMutableArray alloc]initWithCapacity:20];

        NSMutableDictionary *paramDic = [[NSMutableDictionary alloc]initWithCapacity:20];
        for (MachineSeriesModel *model in typeItemModels) {
            if ([self.searchBar.text isEqualToString:model.name]) {
                [paramDic setObject:model.code forKey:@"machinetype"];
                filterparam = paramDic;
                [self askForData:YES isFiltered:YES];
                [self.searchBar resignFirstResponder];
                return;
            }
        }
        //搜索序列号或者名称
        [paramDic setObject:self.searchBar.text forKey:@"key"];
        
        filterparam = paramDic;
        
        [self askForData:YES isFiltered:YES];

    
    }else{
        //没有关键字显示全部
        isFilteredList = NO;
        [self.tableView.mj_header beginRefreshing];
        [self askForData:YES isFiltered:NO];
    }
        [self.searchBar resignFirstResponder];
}

- (void)cancelAllRequest
{
    [[NetWorkTool sharedNetWorkTool].operationQueue cancelAllOperations];
}

@end
