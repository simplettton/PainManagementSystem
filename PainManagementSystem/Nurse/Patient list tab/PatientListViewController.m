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
#import "MJChiBaoZiHeader.h"

@interface PatientListViewController()<UITableViewDelegate,UITableViewDataSource,UISearchBarDelegate,UITextFieldDelegate>{
    int page;
    int totalPage;  //总页数
    BOOL isRefreshing; //是否正在下拉刷新或者上拉加载
    BOOL isFilteredList; //是否筛选
    NSMutableDictionary *filterparam;//筛选关键字
}
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation PatientListViewController{
    NSMutableArray *datas;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"疼痛管理系统";
    
    [self initAll];
}

-(void)initAll{
    
    //navigation 返回导航栏的样式
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc]init];
    backButton.title = @"";
    self.navigationItem.backBarButtonItem = backButton;

    
    self.searchBar.delegate = self;
    self.searchBar.backgroundImage = [[UIImage alloc]init];//去除边框线
    self.searchBar.tintColor = UIColorFromHex(0x5E97FE);//出现光标
    
    
    //通过KVC获得到UISearchBar的私有变量
    //searchField
    UITextField *searchField = [self.searchBar valueForKey:@"searchField"];
    if (searchField) {
        
        [searchField setBackgroundColor:[UIColor whiteColor]];
        searchField.layer.cornerRadius = 5.0f;
        searchField.layer.borderColor = UIColorFromHex(0xBBBBBB).CGColor;
        searchField.layer.borderWidth = 1;
        searchField.layer.masksToBounds = YES;
    }


    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.tableFooterView = [[UIView alloc]init];
    self.tableView.separatorInset = UIEdgeInsetsMake(0, 15, 0, 20);
    
    datas = [[NSMutableArray alloc]initWithCapacity:20];

}

-(void)viewWillAppear:(BOOL)animated{
    
    [super viewWillAppear:YES];
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.navigationController.navigationBar.barTintColor = UIColorFromHex(0x2EA3E6);
    
    [self initTableHeaderAndFooter];
    
}
-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:YES];
    [self endRefresh];
}

#pragma mark - refresh
-(void)initTableHeaderAndFooter{
    
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
    //清空搜索框的文字
    if ([self.searchBar.text length]>0) {
        self.searchBar.text = @"";
    }
    [self.searchBar resignFirstResponder];
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
                                         
                                         NSLog(@"totalPage = %d",totalPage);
                                         
                                         if([count intValue] > 0)
                                         {
                                             self.tableView.tableHeaderView.hidden = NO;
                                              [self getNetworkData:isRefresh isFiltered:iSFiltered];
                                         }else{
                                             [datas removeAllObjects];
                                             self.tableView.tableHeaderView.hidden = NO;
                                             dispatch_async(dispatch_get_main_queue(), ^{
                                                 [self.tableView reloadData];
                                             });
                                             [SVProgressHUD showErrorWithStatus:@"系统中没有病历~"];
                                         }
 
                                     }else{
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
                                                 if (![datas containsObject:dic]) {
                                                     
                                                     PatientModel *patient = [PatientModel modelWithDic:dic];
                                                     [datas addObject:patient];
                                                 }
                                             }
                                             
                                             dispatch_async(dispatch_get_main_queue(), ^{
                                                 [tableView reloadData];
                                             });
                                         }
                                     }
                                     
                                  } failure:nil];
    
}

#pragma mark - searchBar delegate

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
        
        datas = [[NSMutableArray alloc]initWithCapacity:20];
        
        NSMutableDictionary *paramDic = [[NSMutableDictionary alloc]initWithCapacity:20];
        
        [paramDic setObject:self.searchBar.text forKey:@"key"];
        
        filterparam = paramDic;
        
        [self askForData:YES isFiltered:YES];
    }else{
        
        [self.tableView.mj_header beginRefreshing];
//        [self askForData:YES isFiltered:NO];
    }
    [self.searchBar resignFirstResponder];
}



#pragma mark - table view delegate
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 53;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [datas count];
}
-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{

//    cell.selectedBackgroundView = [[UIView alloc] initWithFrame:cell.frame];
//    cell.selectedBackgroundView.backgroundColor = [UIColor clearColor];
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *CellIdentifier = @"Cell";
    
    PatientTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    if (cell == nil) {
        cell = [[PatientTableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    PatientModel *patient = datas[indexPath.row];
    cell.medicalRecordNumLabel.text = patient.medicalRecordNum;
    cell.nameLabel.text = patient.name;
    cell.genderLabel.text = patient.gender;
    cell.bedNumLabel.text = patient.bednum;
    cell.ageLabel.text = patient.age;

    
    
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
