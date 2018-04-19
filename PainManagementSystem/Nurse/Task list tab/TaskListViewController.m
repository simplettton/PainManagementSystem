//
//  TaskListViewController.m
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/4/2.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import "TaskListViewController.h"
#import "TaskCell.h"
#import "SendTreatmentSuccessView.h"
#import "SendTreatmentFailView.h"
#import "QRCodeReaderViewController.h"
#import "PopoverTreatwayController.h"

#import "BaseHeader.h"
#import <SVProgressHUD.h>

#import "MJRefresh.h"

#define ElectrotherapyTypeValue 56833
#define AirProTypeValue 7681
#define AladdinTypeValue 57119

#define ElectrothetapyColor 0x0dbaa5
#define AirProColor 0xfd8574
//#define AirProColor 0x9BADC3
#define AladdinColor 0x5e97fe

@interface TaskListViewController ()<UITableViewDelegate,UITableViewDataSource,QRCodeReaderDelegate,UIPopoverPresentationControllerDelegate>{
    int page;
    int totalPage;  //总页数
    BOOL isRefreshing; //是否正在下拉刷新或者上拉加载
    BOOL isFinishList;
}
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong,nonatomic) QRCodeReaderViewController *reader;
@property (assign,nonatomic) NSInteger selectedRow;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;
@property (weak, nonatomic) IBOutlet UILabel *headerLastLabel;

@end

@implementation TaskListViewController{
    NSMutableArray *datas;
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:YES];
    [self initTableHeaderAndFooter];
    
}
- (void)viewDidLoad {
    [super viewDidLoad];
//    [self showSuccessView];
    [self initAll];

}
-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:YES];
    [self endRefresh];
}
-(void)initAll{
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.tableFooterView = [[UIView alloc]init];
    
    NSArray *dataArray = [NSArray arrayWithContentsOfFile:[[NSBundle mainBundle]pathForResource:@"Task" ofType:@"plist"]];
    datas = [dataArray mutableCopy];
    
    //配置segmentedcontrol
    self.segmentedControl.frame = CGRectMake(self.segmentedControl.frame.origin.x, self.segmentedControl.frame.origin.y, self.segmentedControl.frame.size.width, 35);
    
    [self.segmentedControl setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}forState:UIControlStateSelected];
    
    [self.segmentedControl setTitleTextAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:15.0f]}forState:UIControlStateNormal];
    
    [self.segmentedControl addTarget:self action:@selector(didClicksegmentedControlAction:) forControlEvents:UIControlEventValueChanged];
}

-(void)didClicksegmentedControlAction:(UISegmentedControl *)segmentedControl{
    
    NSInteger index = segmentedControl.selectedSegmentIndex;
    switch (index) {
        case TaskListTypeNotStarted:
            
            NSLog(@"切换代处理处方");
            isFinishList = NO;
            
            break;
        case TaskListTypeProcessing:
            
            NSLog(@"切换处理中处方");
            
            
            break;
        case TaskListTypeFinished:
            
            NSLog(@"切换已完成处方");
            isFinishList = YES;
            
            break;
        default:
            break;
    }
    
    [self.tableView.mj_header beginRefreshing];
    [self.tableView reloadData];
    
    
}
#pragma mark - refresh
-(void)initTableHeaderAndFooter{
    
    //下拉刷新

    
    MJRefreshNormalHeader *header = [MJRefreshNormalHeader headerWithRefreshingTarget:self refreshingAction:@selector(refresh)];

    
    [header setTitle:@"下拉刷新" forState:MJRefreshStateIdle];
    [header setTitle:@"松开更新" forState:MJRefreshStatePulling];
    [header setTitle:@"加载中..." forState:MJRefreshStateRefreshing];
    
    self.tableView.mj_header = header;
    
//    [self.tableView.mj_header beginRefreshing];
    
    
//    //上拉加载
//    MJRefreshAutoNormalFooter *footer = [MJRefreshAutoNormalFooter footerWithRefreshingTarget:self refreshingAction:@selector(loadMore)];
//    [footer setTitle:@"" forState:MJRefreshStateIdle];
//    [footer setTitle:@"" forState:MJRefreshStateRefreshing];
//    [footer setTitle:@"No more data" forState:MJRefreshStateNoMoreData];
//    self.tableView.mj_footer = footer;
}

-(void)refresh{
    [self askForData:YES];
}

-(void)loadMore{
    [self askForData:NO];
}

-(void)endRefresh{
    if (page == 0) {
        [self.tableView.mj_header endRefreshing];
    }
    [self.tableView.mj_footer endRefreshing];
}

-(void)askForData:(BOOL)isRefresh{
    
    switch (self.segmentedControl.selectedSegmentIndex) {
            
        //待处理
        case TaskListTypeNotStarted:
            
            break;
        //处理中
        case TaskListTypeProcessing:
            
            break;
        //已完成
        case TaskListTypeFinished:
            
            break;
            
        default:
            break;
    }
    
    [[NetWorkTool sharedNetWorkTool]POST:[HTTPServerURLString stringByAppendingString:@"Api/TaskList/ListCount"]
                                  params:nil
                                hasToken:YES
                                 success:^(HttpResponse *responseObject) {
                                     if ([responseObject.result intValue] == 1) {
                                         
                                         NSString *count = responseObject.content[@"count"];
                                         
                                         totalPage = ([count intValue]+15-1)/15;
                                         
                                         NSLog(@"totalPage = %d",totalPage);
                                         
                                         if([count intValue] > 0)
                                         {
                                             [self getNetworkData:isRefresh];
                                         }else{

                                         }
                                         
                                     }else{
                                         [SVProgressHUD showErrorWithStatus:responseObject.errorString];
                                     }
                                 }
                                 failure:nil];
}

-(void)getNetworkData:(BOOL)isRefresh{
    
    if (isRefresh) {
        page = 0;
    }else{
        page ++;
    }
    
    
    //配置请求http
    NSMutableDictionary *mutableParam = [[NSMutableDictionary alloc]init];
    NSNumber *value = [NSNumber numberWithInteger:isFinishList?1:0];
    [mutableParam setObject:value forKey:@"isfinish"];
    NSDictionary *params = (NSDictionary *)mutableParam;
    
    __weak UITableView *tableView = self.tableView;
    [[NetWorkTool sharedNetWorkTool]POST:[HTTPServerURLString stringByAppendingString:@"Api/TaskList/List"]
                                  params:params
                                hasToken:YES
                                 success:^(HttpResponse *responseObject) {
                                     [self endRefresh];
                                     isRefreshing = NO;//数据获取成功后，设置为NO
                                     
                                     if (page == 0) {
                                         [datas removeAllObjects];
                                     }
                                     //判断是否正在加载，如果有，判断当前页数是不是大于最大页数，是的话就不让加载，直接return；（因为下拉的当前页永远是最小的，所以直接return）
                                     if (isRefreshing) {
                                         if (page >= totalPage) {
                                             [self endRefresh];
                                         }
                                         return;
                                     }
                                     
                                     isRefreshing = YES;
                                     
                                     //上拉加载更多
                                     if (page >=totalPage) {
                                         [self endRefresh];
                                         [tableView.mj_footer endRefreshingWithNoMoreData];
                                         return;
                                     }
                                     
                                     //返回成功
                                     
                                     if ([responseObject.result intValue] == 1) {
                                         NSArray *content = responseObject.content;
                                         
                                         if (content) {
                                             for (NSDictionary *dic in content) {
                                                 if (![datas containsObject:dic]) {
                                                     
                                                     
                                                 }
                                             }
                                             
                                             dispatch_async(dispatch_get_main_queue(), ^{
                                                 [tableView reloadData];
                                             });
                                         }
                                     }
                                     
                                     
                                 } failure:nil];
}

#pragma mark - table view delegate

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [datas count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    static NSString *CellIdentifier = @"Cell";
    TaskCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    if (cell == nil) {
        cell = [[TaskCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    

    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    //治疗参数详情弹窗
    [cell.treatmentButton addTarget:self action:@selector(showPopover:) forControlEvents:UIControlEventTouchUpInside];
    
    NSDictionary *dataDic = datas[indexPath.row];
    cell.doctorNameLable.text = dataDic[@"creater"];
    cell.medicalRecordNumLable.text = dataDic[@"sickhistorynum"];
    cell.patientNameLabel.text = dataDic[@"patientname"];
    
    NSDictionary *physicalTreatDic = dataDic[@"physicaltreat"];
    NSString *type = physicalTreatDic[@"type"];
    

    
    //不同的tag配置不一样的cell
    switch (self.segmentedControl.selectedSegmentIndex) {
        case TaskListTypeNotStarted:
        {
            //配置治疗设备显示文字
            switch ([type integerValue]) {
                    
                case ElectrotherapyTypeValue:
                    cell.typeLabel.text = @"电疗";
                    [cell setTypeLableColor:UIColorFromHex(ElectrothetapyColor)];
                    break;
                    
                case AladdinTypeValue:
                    cell.typeLabel.text = @"血瘘";
                    [cell setTypeLableColor:UIColorFromHex(AladdinColor)];
                    break;
                    
                case AirProTypeValue:
                    cell.typeLabel.text = @"空气波";
                    [cell setTypeLableColor:UIColorFromHex(AirProColor)];
                    break;
                    
                default:
                    break;
            }
                [cell configureWithStyle:CellStyle_UnDownLoad];
            
            //扫描action
            [cell.scanButton removeTarget:self action:@selector(remarkAction:) forControlEvents:UIControlEventTouchUpInside];
            [cell.scanButton addTarget:self action:@selector(scanAction:) forControlEvents:UIControlEventTouchUpInside];
            cell.scanButton.tag = indexPath.row;
        }

            break;
        case TaskListTypeProcessing:
            if (indexPath.row %3 == 0) {
                [cell configureWithStyle:CellStyleBlue_DownLoadedFinishRunning];
                //评分action
                [cell.scanButton removeTarget:self action:@selector(scanAction:) forControlEvents:UIControlEventTouchUpInside];
                [cell.scanButton addTarget:self action:@selector(remarkAction:) forControlEvents:UIControlEventTouchUpInside];
                cell.scanButton.tag = indexPath.row;
                
            }else if(indexPath.row %3 == 1){
                [cell configureWithStyle:CellStyleGreen_DownLoadedRunning];
            }else{
                [cell configureWithStyle:CellStyleGrey_DownLoadedUnRunning];

                //扫描action
                [cell.scanButton removeTarget:self action:@selector(remarkAction:) forControlEvents:UIControlEventTouchUpInside];
                [cell.scanButton addTarget:self action:@selector(scanAction:) forControlEvents:UIControlEventTouchUpInside];
                cell.scanButton.tag = indexPath.row;
            }
            //类型颜色恢复
            [cell setTypeLableColor:UIColorFromHex(0x212121)];
            
            break;
        case TaskListTypeFinished:
            [cell configureWithStyle:CellStyle_DownLoadedRemarked];
            [cell setTypeLableColor:UIColorFromHex(0x212121)];
            break;
        default:
            break;
    }
    
    //第一个tab显示下发处方
    self.headerLastLabel.hidden = _segmentedControl.selectedSegmentIndex != TaskListTypeNotStarted;

    
    return cell;
    
}

-(void)showPopover:(UIButton *)sender {

    [self performSegueWithIdentifier:@"ShowPopover" sender:sender];
}

#pragma mark - action
- (void)scanAction:(id)sender {
    
    self.selectedRow = [sender tag];
    
    NSArray *types = @[AVMetadataObjectTypeQRCode,
                       AVMetadataObjectTypeEAN13Code,
                       AVMetadataObjectTypeEAN8Code,
                       AVMetadataObjectTypeUPCECode,
                       AVMetadataObjectTypeCode39Code,
                       AVMetadataObjectTypeCode39Mod43Code,
                       AVMetadataObjectTypeCode93Code,
                       AVMetadataObjectTypeCode128Code,
                       AVMetadataObjectTypePDF417Code];
    
    _reader = [QRCodeReaderViewController readerWithMetadataObjectTypes:types];
    
    // Using delegate methods
    _reader.delegate = self;
    
    
    [self presentViewController:_reader animated:YES completion:NULL];
    
}
- (void)remarkAction:(id)sender{
    
    self.selectedRow = [sender tag];
    [self performSegueWithIdentifier:@"TaskGoToRemarkVAS" sender:sender];
    
}

-(void)showSuccessView{
    [SVProgressHUD dismiss];
    [SendTreatmentSuccessView alertControllerAboveIn:self returnBlock:^{
        NSLog(@"send to server设置关注 ");
    }];
    
}

-(void)showFailView{
    [SVProgressHUD dismiss];
    [SendTreatmentFailView alertControllerAboveIn:self];
}


#pragma mark - QRCodeReader Delegate Methods
- (void)reader:(QRCodeReaderViewController *)reader didScanResult:(NSString *)result
{
    [self dismissViewControllerAnimated:YES completion:^{
        
        //去除对应的病人病历号
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.selectedRow inSection:0];
        
        [SVProgressHUD showWithStatus:@"处方下发中……"];
        
        //send treatment to server
        
        [self performSelector:@selector(showFailView) withObject:nil afterDelay:5.0];
        
        NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:20];
        
        [params setObject:result forKey:@"serialnum"];
        
        
        [[NetWorkTool sharedNetWorkTool]POST:[HTTPServerURLString stringByAppendingString:@"Api/Tasklist/TreatmentParamDownload"]
                                                                                   params:params
                                                                                 hasToken:YES
                                                                                  success:^(HttpResponse *responseObject) {
                                                                                      if ([responseObject.result intValue]==1) {
                                                                                          
                                                                                          [self showSuccessView];
                                                                                          
                                                                                      }else{
                                                                                          [SVProgressHUD showErrorWithStatus:responseObject.errorString];
                                                                                          
                                                                                      }

                                                                                  } failure:nil];
        
        NSLog(@"QRretult == %@", result);
    }];
}

- (void)readerDidCancel:(QRCodeReaderViewController *)reader
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (IBAction)backToDeviceList:(id)sender {
    
    [self.navigationController popViewControllerAnimated:NO];
    [self dismissViewControllerAnimated:NO completion:nil];
}

#pragma mark - prepareForSegue

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([segue.identifier isEqualToString:@"ShowPopover"]) {
        PopoverTreatwayController *destination = (PopoverTreatwayController *)segue.destinationViewController;
        UIPopoverPresentationController *popover = destination.popoverPresentationController;
        popover.delegate = self;
        
        //获取某个cell的数据
        UIView *contentView = [(UIView *)sender superview];
        
        TaskCell *cell = (TaskCell*)[contentView superview];
        
        NSIndexPath* index = [self.tableView indexPathForCell:cell];
        
        NSDictionary *dataDic = [datas objectAtIndex:index.row];
        NSDictionary *treatWayDic = dataDic[@"physicaltreat"][@"treatway"];
        
        destination.treatWayDic = treatWayDic;
        
        UIButton *button = sender;
        popover.sourceView = button;
        popover.sourceRect = button.bounds;
    }else if ([segue.identifier isEqualToString:@"TaskGoToRemarkVAS"]){
        
    }
}

-(UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller {
    return UIModalPresentationNone;
}

@end
