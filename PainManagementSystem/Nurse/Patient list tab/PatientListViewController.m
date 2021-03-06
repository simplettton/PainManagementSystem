//
//  PatientListViewController.m
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/3/23.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import "PatientListViewController.h"
#import "AddPatientViewController.h"
#import "TreatmentCourseRecordViewController.h"
#import "PatientTableViewCell.h"
#import "BaseHeader.h"
#import "PatientModel.h"

#import "MJRefresh.h"
#import "NoDataPlaceHoler.h"

@interface PatientListViewController()<UITableViewDelegate,UITableViewDataSource,UISearchBarDelegate,UITextFieldDelegate>{
    int page;
    int totalPage;  //总页数
    BOOL isRefreshing; //是否正在下拉刷新或者上拉加载
    BOOL isFilteredList; //是否筛选
    NSMutableDictionary *filterparam;//筛选关键字
}
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
//没有记录view
@property(nonatomic,strong)NoDataPlaceHoler *nodataView;

@end

@implementation PatientListViewController{
    NSMutableArray *datas;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initAll];
}
-(BOOL)isCurrentViewControllerVisible:(UIViewController *)viewController {
    return (viewController.isViewLoaded && viewController.view.window);
}
//关闭键盘
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
    [self hideKeyBoard];
}
-(void)hideKeyBoard{
    
    [self.view endEditing:YES];
    [self.tableView endEditing:YES];
    [self.searchBar resignFirstResponder];
    
}

-(void)initAll{

    //navigation 返回导航栏的样式
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc]init];
    backButton.title = @"";
    self.navigationItem.backBarButtonItem = backButton;

    //searchbar style
    self.searchBar.delegate = self;
    self.searchBar.backgroundImage = [[UIImage alloc]init];//去除边框线
    self.searchBar.tintColor = UIColorFromHex(0x5E97FE);//出现光标
    UITextField * searchField = [_searchBar valueForKey:@"_searchField"];
    [searchField setValue:[UIFont systemFontOfSize:15 weight:UIFontWeightLight] forKeyPath:@"_placeholderLabel.font"];


    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.tableFooterView = [[UIView alloc]init];
    self.tableView.separatorInset = UIEdgeInsetsMake(0, 5, 0, 20);
    
    self.tableView.estimatedRowHeight = 53;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyBoard)];
    tapGestureRecognizer.cancelsTouchesInView = NO;
    
    [self.tableView addGestureRecognizer:tapGestureRecognizer];
    
    datas = [[NSMutableArray alloc]initWithCapacity:20];
    [self initTableHeaderAndFooter];

}

-(void)viewWillAppear:(BOOL)animated{
    
    [super viewWillAppear:YES];
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.navigationController.navigationBar.barTintColor = UIColorFromHex(0x2EA3E6);
    self.tableView.mj_header.hidden = NO;
    
    BOOL isNewPatientAdded = true;
    if (self.patient) {
        for (PatientModel *patient in datas) {
            if ([patient.medicalRecordNum isEqualToString:self.patient.medicalRecordNum]) {
                
                NSInteger index = [datas indexOfObject:patient];
                
                [datas replaceObjectAtIndex:index withObject:self.patient];
                
                [self.tableView reloadData];
                
                isNewPatientAdded = false;
                
                break;
            }
        }
        if (isNewPatientAdded) {
            [self refresh];
        }
    }else{
//        [self refresh];
    }
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(reloadDataWithNotification:) name:@"ClickTabbarItem" object:nil];
}
-(void)reloadDataWithNotification:(NSNotification *)notification{
    if ([notification.object integerValue] == 1) {
        [self.tableView.mj_header beginRefreshing];
    }
}
-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:YES];
    if (self.tableView.mj_header.isRefreshing) {
        [self.tableView.mj_header endRefreshing];
        
    }
    self.tableView.mj_header.hidden = YES;
    [self endRefresh];
    [[NSNotificationCenter defaultCenter]removeObserver:self];
    [[UIMenuController sharedMenuController] setMenuVisible:NO animated: YES];
}

#pragma mark - refresh
-(void)initTableHeaderAndFooter{
    
    //下拉刷新
    MJRefreshNormalHeader *header = [MJRefreshNormalHeader headerWithRefreshingTarget:self refreshingAction:@selector(refresh)];
    [header setTitle:@"加载中..." forState:MJRefreshStateRefreshing];
    header.stateLabel.textColor =UIColorFromHex(0xdbdbdb);
    header.lastUpdatedTimeLabel.hidden = YES;
    self.tableView.mj_header = header;
    
    [self.tableView.mj_header beginRefreshing];
    
    //上拉加载
    MJRefreshAutoNormalFooter *footer = [MJRefreshAutoNormalFooter footerWithRefreshingTarget:self refreshingAction:@selector(loadMore)];
    [footer setTitle:@"" forState:MJRefreshStateIdle];
    [footer setTitle:@"" forState:MJRefreshStateRefreshing];
    [footer setTitle:@"没有更多数据了" forState:MJRefreshStateNoMoreData];
    self.tableView.mj_footer = footer;
}

-(void)refresh
{

    //清空搜索框的文字
    if ([self.searchBar.text length]>0) {
        [self search:nil];
    }else{
        isFilteredList = NO;
        [self askForData:YES isFiltered:NO];
    }
    [self.searchBar resignFirstResponder];

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
        
        url = [HTTPServerURLString stringByAppendingString:@"Api/Patient/CountFuzzy"];
        params = (NSDictionary *)filterparam;
        
    }else{
        url = [HTTPServerURLString stringByAppendingString:@"Api/Patient/CountByQuery"];
    }
    
    [[NetWorkTool sharedNetWorkTool]POST:url
                                  params:params
                                hasToken:YES
                                 success:^(HttpResponse *responseObject) {
                                     
                                     if ([responseObject.result intValue] == 1) {
                                         
                                         NSString *count = responseObject.content[@"count"];
                                         
                                         totalPage = ([count intValue]+15-1)/15;

                                         if (totalPage <= 1) {
                                             self.tableView.mj_footer.hidden = YES;
                                         }else{
                                             self.tableView.mj_footer.hidden = NO;
                                         }
                                         
                                         if([count intValue] > 0)
                                         {
                                             self.tableView.tableHeaderView.hidden = NO;
                                             [self getNetworkData:isRefresh isFiltered:iSFiltered];
                                             [self hideNodataView];
                                         }else{
                                             [datas removeAllObjects];
                                             self.tableView.tableHeaderView.hidden = YES;
                                             dispatch_async(dispatch_get_main_queue(), ^{
                                                 [self.tableView reloadData];
                                             });
                                             if (iSFiltered) {
                                                 [SVProgressHUD showErrorWithStatus:@"没有找到该病人"];
                                             }else{
                                                 [self showNodataViewWithTitle:@"暂无记录"];
                                             }

                                         }
 
                                     }else{
                                         if(iSFiltered){
                                             if ([self.searchBar.text length]>0) {
                                                 self.searchBar.text = @"";
                                             }
                                         }
                                         [SVProgressHUD showErrorWithStatus:responseObject.errorString];
                                     }
                                     
                                 } failure:nil];
    
    
}
-(void)getNetworkData:(BOOL)isRefresh isFiltered:(BOOL)isFiltered{
    
    if (isRefresh) {
        page = 0;
    }else{
        page ++;
    }
    
    //配置请求http
    NSString *url;
    NSDictionary *params;
    if (isFiltered) {
        
        url = [HTTPServerURLString stringByAppendingString:@"Api/Patient/ListFuzzy"];
        [filterparam setObject:[NSNumber numberWithInt:page] forKey:@"page"];
        params = (NSDictionary *)filterparam;
        
    }else{
        
        url = [HTTPServerURLString stringByAppendingString:@"Api/Patient/ListByQuery"];
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
                                     isRefreshing = NO;
                                     
                                     if (page == 0) {
                                         [datas removeAllObjects];
                                     }
                                     
                                     if (isRefreshing) {
                                         if (page >= totalPage) {
                                             [self endRefresh];
                                         }
                                         return;
                                     }
                                     
                                     isRefreshing = YES;
                                     
                                     if (page >=totalPage) {
                                         [self endRefresh];
                                         [tableView.mj_footer endRefreshingWithNoMoreData];
                                         return;
                                     }
                                     
                                     if ([responseObject.result intValue] == 1) {
                                         NSArray *content = responseObject.content;
                                         
                                         if (content) {
                                             for (NSDictionary *dic in content) {
                                                     PatientModel *patient = [PatientModel modelWithDic:dic];
                                                     [datas addObject:patient];
                                             }
                                             dispatch_async(dispatch_get_main_queue(), ^{
                                                 [tableView reloadData];
                                             });
                                         }
                                     }
                                     
                                  } failure:nil];
    
}
#pragma mark - mark NoDataView
-(void)showNodataViewWithTitle:(NSString *)title{
    if (self.nodataView == nil) {
        self.nodataView = [[[NSBundle mainBundle]loadNibNamed:@"NoDataPlaceHolder" owner:self options:nil]lastObject];
        self.nodataView.center = self.view.center;
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
-(BOOL)textFieldShouldReturn:(UITextField *)textField{
    [self search:textField];
    return YES;
}
- (IBAction)search:(id)sender {
    if ([self.searchBar.text length]>0) {
        
        isFilteredList = YES;

        NSMutableDictionary *paramDic = [[NSMutableDictionary alloc]initWithCapacity:20];
        
        [paramDic setObject:self.searchBar.text forKey:@"key"];
        
        filterparam = paramDic;
        
        [self askForData:YES isFiltered:YES];
    }else{
        isFilteredList = NO;
        [self.tableView.mj_header beginRefreshing];
    }
    [self.searchBar resignFirstResponder];
}



#pragma mark - table view delegate


-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}
//-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
//
//    UIView *header = [[UIView alloc]initWithFrame:CGRectMake(0, 0, self.tableView.bounds.size.width, 30)];
//    return header;
////    return self.tableView.tableHeaderView;
//}


-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [datas count];
}
-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *CellIdentifier = @"Cell";
    
    PatientTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    if (cell == nil) {
        cell = [[PatientTableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    PatientModel *patient = datas[indexPath.row];
    cell.medicalRecordNumLabel.text = patient.medicalRecordNum;
    cell.nameLabel.text = patient.name;
    cell.genderLabel.text = patient.gender;
    cell.bedNumLabel.text = patient.bednum;
    cell.ageLabel.text = patient.age;
    cell.unfinishImage.hidden = !patient.isInTheTask;
    
    //病历号和名字过长自动分行
    cell.nameLabel.numberOfLines = 0;
    cell.nameLabel.lineBreakMode = NSLineBreakByWordWrapping;
    cell.medicalRecordNumLabel.numberOfLines = 0;
    cell.medicalRecordNumLabel.lineBreakMode = NSLineBreakByWordWrapping;
 
    
    cell.editButton.tag = indexPath.row;
    [cell.editButton addTarget:self action:@selector(editPatientInfomation:) forControlEvents:UIControlEventTouchUpInside];
//
//    [cell.inquireButton addTarget:self action:@selector(showRecord:) forControlEvents:UIControlEventTouchUpInside];
    
    
    return cell;
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    PatientModel *patientInfo = datas[indexPath.row];
    [self performSegueWithIdentifier:@"ShowTreatmentCourseRecord" sender:patientInfo];
}
-(void)editPatientInfomation:(UIButton *)sender{

    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:sender.tag inSection:0];
    
    PatientModel *patientInfo = datas[indexPath.row];
    [self performSegueWithIdentifier:@"EditPatientInfomation" sender:patientInfo];


}
-(void)showRecord:(UIButton *)sender{
    
    UIView* contentView = [sender superview];
    PatientTableViewCell *cell = (PatientTableViewCell *)[contentView superview];
    
    NSInteger interger = [self.tableView.visibleCells indexOfObject:cell];
    
    PatientModel *patientInfo = datas[interger];
    
    [self performSegueWithIdentifier:@"ShowTreatmentCourseRecord" sender:patientInfo];
    
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([segue.identifier isEqualToString:@"EditPatientInfomation"]) {
        AddPatientViewController *controller = (AddPatientViewController *)segue.destinationViewController;
        
        //传数据,segue手动
        controller.patient = sender;
    }else if ([segue.identifier isEqualToString:@"ShowTreatmentCourseRecord"]){
        TreatmentCourseRecordViewController *controller = (TreatmentCourseRecordViewController *)segue.destinationViewController;
        controller.patient = sender;
    }
}
@end
