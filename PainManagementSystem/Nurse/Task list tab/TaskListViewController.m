//
//  TaskListViewController.m
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/4/2.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import "TaskListViewController.h"
#import "TaskCell.h"
#import "TaskModel.h"
#import "LocalMachineModel.h"
#import "SendTreatmentSuccessView.h"
#import "SendTreatmentFailView.h"
#import "QRCodeReaderViewController.h"
#import "PopoverTreatwayController.h"
#import "Pack.h"
#import "Unpack.h"
#import "TreatmentCourseRecordViewController.h"

#import "BaseHeader.h"
#import <SVProgressHUD.h>

#import "MJRefresh.h"

#import <CoreBluetooth/CoreBluetooth.h>
#import "BabyBluetooth.h"

#define SERVICE_UUID           @"1b7e8251-2877-41c3-b46e-cf057c562023"
#define TX_CHARACTERISTIC_UUID @"5e9bf2a8-f93f-4481-a67e-3b2f4a07891a"
#define RX_CHARACTERISTIC_UUID @"8ac32d3f-5cb9-4d44-bec2-ee689169f626"

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
}
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong,nonatomic) QRCodeReaderViewController *reader;
@property (assign,nonatomic) NSInteger selectedRow;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;
@property (weak, nonatomic) IBOutlet UILabel *headerLastLabel;

//任务状态
@property (nonatomic,assign)int taskTag;

//蓝牙设备
@property (strong ,nonatomic) CBPeripheral *peripheral;
@property (nonatomic,strong) CBCharacteristic *sendCharacteristic;
@property (nonatomic,strong) CBCharacteristic *receiveCharacteristic;
@property (nonatomic,strong) NSString *BLEDeviceName;
@property (nonatomic,strong) NSData *BLETreatParam;
@property (nonatomic,assign) NSInteger selectedDeviceIndex;
@property (nonatomic,assign) BOOL isBLEPoweredOff;
//防止push多个相同的
@property (assign,nonatomic)BOOL pushOnce;
@property(nonatomic,strong)NSTimer *timer;

@end

@implementation TaskListViewController{
    BabyBluetooth *baby;
    NSMutableArray *datas;
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:YES];

    if (self.taskTag == TaskListTypeProcessing || self.taskTag == TaskListTypeNotStarted) {
        [self refresh];
    }
    self.tableView.mj_header.hidden = NO;
    self.isBLEPoweredOff = YES;
    self.pushOnce = 1;
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(reloadDataWithNotification:) name:@"ClickTabbarItem" object:nil];
    
}
//双击tab更新列表
-(void)reloadDataWithNotification:(NSNotification *)notification{
    if ([notification.object integerValue] == 0) {
        [self.tableView.mj_header beginRefreshing];
    }
}
- (void)viewDidLoad {
    [super viewDidLoad];
    [self initAll];
}
-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:YES];
    [baby cancelScan];
    [baby cancelAllPeripheralsConnection];
    [self endRefresh];
    if (self.timer) {
        [self closeTimer];
    }
    if ([self.presentedViewController isKindOfClass:[PopoverTreatwayController class]]) {
        [self.presentedViewController dismissViewControllerAnimated:YES completion:nil];
    }
    self.tableView.mj_header.hidden = YES;
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

-(void)initAll{
 
    self.view.multipleTouchEnabled = NO;
    self.tableView.multipleTouchEnabled = NO;
    
    //初始tag为待处理
    self.taskTag = TaskListTypeNotStarted;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.tableFooterView = [[UIView alloc]init];
    
//    UILongPressGestureRecognizer * longPressGesture =[[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(longPressToDo:)];
//
//    [self.tableView addGestureRecognizer:longPressGesture];
    
    
    datas = [[NSMutableArray alloc]initWithCapacity:20];
    
    self.isBLEPoweredOff = YES;
    
    //配置segmentedcontrol
    self.segmentedControl.frame = CGRectMake(self.segmentedControl.frame.origin.x, self.segmentedControl.frame.origin.y, self.segmentedControl.frame.size.width, 35);
    
    [self.segmentedControl setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}forState:UIControlStateSelected];
    
    [self.segmentedControl setTitleTextAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:15.0f]}forState:UIControlStateNormal];
    
    [self.segmentedControl addTarget:self action:@selector(didClicksegmentedControlAction:) forControlEvents:UIControlEventValueChanged];
    
    [self initTableHeaderAndFooter];
    self.pushOnce = 1;
}

-(void)longPressToDo:(UILongPressGestureRecognizer *)gesture
{
    
    if(gesture.state == UIGestureRecognizerStateBegan)
    {
        
        CGPoint point = [gesture locationInView:self.tableView];
        
        NSIndexPath * indexPath = [self.tableView indexPathForRowAtPoint:point];
        
        if([datas count]>0){
            TaskModel *task = datas[indexPath.row];
            
            if(indexPath == nil) return ;
            
            if (self.taskTag == TaskListTypeProcessing) {
                if (task.state == 3) {
                    self.selectedRow = indexPath.row;
                    
                    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@""
                                                                                   message:@"当前处方设备正在治疗中，是否进行治疗后vas评分强制结束治疗？"
                                                                            preferredStyle:UIAlertControllerStyleAlert];
                    
                    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleDefault
                                                                         handler:^(UIAlertAction * action) {}];
                    UIAlertAction* okAction = [UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault
                                                                     handler:^(UIAlertAction * action) {
                                                                         [self remarkAction:nil];
                                                                     }];
                    
                    [alert addAction:cancelAction];
                    [alert addAction:okAction];
                    
                    [self presentViewController:alert animated:YES completion:nil];
                }
            }
        }
    }
}

-(void)didClicksegmentedControlAction:(UISegmentedControl *)segmentedControl{
    [self.presentedViewController dismissViewControllerAnimated:YES completion:nil];
    NSInteger index = segmentedControl.selectedSegmentIndex;
    switch (index) {
        case 0:
            
            NSLog(@"切换代处理处方");
            self.taskTag = TaskListTypeNotStarted;
            break;
        case 1:
            
            NSLog(@"切换处理中处方");
            self.taskTag = TaskListTypeProcessing;
            
            break;
        case 2:
            
            NSLog(@"切换已完成处方");
            self.taskTag = TaskListTypeFinished;
            [baby cancelScan];
            [baby cancelAllPeripheralsConnection];
            
            break;
        default:
            break;
    }
    [SVProgressHUD dismiss];
    [datas removeAllObjects];
    [self.tableView reloadData];
    [self refresh];

}
#pragma mark - refresh
-(void)initTableHeaderAndFooter{
    
    //下拉刷新
    MJRefreshNormalHeader *header = [MJRefreshNormalHeader headerWithRefreshingTarget:self refreshingAction:@selector(refresh)];
    [header setTitle:@"下拉刷新" forState:MJRefreshStateIdle];
    [header setTitle:@"松开更新" forState:MJRefreshStatePulling];
    [header setTitle:@"加载中..." forState:MJRefreshStateRefreshing];
    
    self.tableView.mj_header = header;
    
    [self.tableView.mj_header beginRefreshing];
    //上拉加载
    MJRefreshAutoNormalFooter *footer = [MJRefreshAutoNormalFooter footerWithRefreshingTarget:self refreshingAction:@selector(loadMore)];
    [footer setTitle:@"" forState:MJRefreshStateIdle];
    [footer setTitle:@"" forState:MJRefreshStateRefreshing];
    [footer setTitle:@"没有数据了~" forState:MJRefreshStateNoMoreData];
    self.tableView.mj_footer = footer;

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
    
    NSDictionary *param = @{@"state":[NSNumber numberWithInt:self.taskTag]};
    
    [[NetWorkTool sharedNetWorkTool]POST:[HTTPServerURLString stringByAppendingString:@"Api/TaskList/List"]
                                  params:param
                                hasToken:YES
                                 success:^(HttpResponse *responseObject) {
                                     if ([responseObject.result intValue] == 1) {
                                         
                                         NSNumber *count = responseObject.count;
                                         
                                         totalPage = ([count intValue]+15-1)/15;
                                         
                                         if (totalPage <= 1) {
                                             self.tableView.mj_footer.hidden = YES;
                                         }else{
                                             self.tableView.mj_footer.hidden = NO;
                                         }
                                         if([count intValue] > 0)
                                         {
                                             self.tableView.tableHeaderView.hidden = NO;
                                             [self getNetworkData:isRefresh];
                                         }else{
                                             [datas removeAllObjects];
                                             [self endRefresh];
                                             dispatch_async(dispatch_get_main_queue(), ^{
                                                 [self.tableView reloadData];
                                             });
                                             NSString *title = [self.segmentedControl titleForSegmentAtIndex:self.segmentedControl.selectedSegmentIndex];
                                             
//                                             [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"没有%@的处方~",title]];
                                             self.tableView.tableHeaderView.hidden = YES;
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

    [mutableParam setObject:[NSNumber numberWithInt:self.taskTag] forKey:@"state"];
    [mutableParam setObject:[NSNumber numberWithInt:page] forKey:@"page"];
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
//                                             NSArray *localMachineTaskIds = [self returnLocalMachineTaskIdArray];
                                             
                                             for (NSDictionary *dic in content) {
                                                 
                                                 TaskModel *task = [TaskModel modelWithDic:dic];
                                                 
                                                 //处理中的任务 本地设备设置关注
                                                 if (self.segmentedControl.selectedSegmentIndex == 1) {
                                                     if ([task.machineType isEqualToString:@"血瘘"]) {
//                                                         if ([localMachineTaskIds containsObject:task.ID]) {
//                                                             task.isFocus = true;
//                                                         }else{
//                                                             task.isFocus = false;
//                                                         }
                                                         task.isFocus = [self checkLocalMachineFocus:task];
                                                     }
                                                 }
                                                 
                                                 if (![datas containsObject:dic]) {
                                                     [datas addObject:task];
                                                 }
                                             }

                                             dispatch_async(dispatch_get_main_queue(), ^{
                                                 [tableView reloadData];
                                             });
                                         }
                                     }else{
                                         [SVProgressHUD showErrorWithStatus:responseObject.errorString];
                                     }

                                 } failure:nil];
}

-(BOOL)checkLocalMachineFocus:(TaskModel *)task{
    NSArray *localMachineTaskIds = [self returnLocalMachineTaskIdArray];
    if ([localMachineTaskIds containsObject:task.ID]) {
        return YES;
    }
    return NO;
}
-(NSArray *)returnLocalMachineTaskIdArray{
    NSString *documents = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)lastObject];
    if (!documents)
    {
        NSLog(@"目录未找到");
    }
    NSString *documentPath = [documents stringByAppendingPathComponent:@"focusLocalMachine.plist"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSMutableArray *mutableTaskIdArray = [[NSMutableArray alloc]initWithCapacity:20];
    
    if ([fileManager fileExistsAtPath:documentPath]) {
        NSData * resultdata = [[NSData alloc] initWithContentsOfFile:documentPath];
        NSKeyedUnarchiver *unArchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:resultdata];
        NSArray *savedArray = [unArchiver decodeObjectForKey:@"machineArray"];
        
        for (LocalMachineModel *savedMachine in savedArray){
            [mutableTaskIdArray addObject:savedMachine.taskId];
        }
        
    }
    NSArray *taskIdArray = [mutableTaskIdArray copy];
    return taskIdArray;
}


#pragma mark - table view delegate

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [datas count];
}
-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
    switch (self.taskTag) {
        case TaskListTypeNotStarted:
        case TaskListTypeFinished:
            tableView.separatorInset = UIEdgeInsetsMake(0, 30, 0, 20);
            break;
            
        default:
            tableView.separatorInset = UIEdgeInsetsMake(0, 12, 0, 20);
            break;
    }
}
-(CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 56;
}
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return UITableViewAutomaticDimension;

}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    TaskModel *task = datas[indexPath.row];
    
    static NSString *CellIdentifier;
    if (self.taskTag == TaskListTypeFinished) {
        CellIdentifier = @"FinishedTaskCell";
    }else{
        CellIdentifier = @"Cell";
    }
    TaskCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    if (cell == nil) {
        cell = [[TaskCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }

    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    cell.patientNameLabel.numberOfLines = 0;
    cell.patientNameLabel.lineBreakMode = NSLineBreakByWordWrapping;
    
    cell.medicalRecordNumLable.numberOfLines = 0;
    cell.medicalRecordNumLable.lineBreakMode = NSLineBreakByWordWrapping;

    cell.doctorNameLable.text = task.doctorName;
    cell.medicalRecordNumLable.text  = task.medicalRecordNum;
    cell.patientNameLabel.text = task.patientName;
    cell.typeLabel.text = task.machineType;
    
    NSString *buttonTitle = [[NSString alloc]init];
    //治疗参数详情弹窗
    if([task.treatTime integerValue]==601){
        buttonTitle = @"治疗时间:持续治疗";
    }else{
        buttonTitle = [NSString stringWithFormat:@"治疗时间:%@分钟",task.treatTime];
    }
    if([task.machineType isEqualToString:@"其他"]){
        [cell.treatmentButton setTitle:@"无" forState:UIControlStateNormal];
        [cell.treatmentButton.layer setBorderColor:UIColorFromHex(0xffffff).CGColor];
    }else{
        [cell.treatmentButton setTitle:buttonTitle forState:UIControlStateNormal];
        [cell.treatmentButton addTarget:self action:@selector(showPopover:) forControlEvents:UIControlEventTouchUpInside];
    }

    //配置治疗设备显示文字颜色
    switch ([task.machineTypeNumber integerValue]) {
            
        case ElectrotherapyTypeValue:
        case 56832:
        case 56834:
        case 56836:
            [cell setTypeLableColor:UIColorFromHex(ElectrothetapyColor)];
            break;
            
        case AladdinTypeValue:
            [cell setTypeLableColor:UIColorFromHex(AladdinColor)];
            break;
            
        case AirProTypeValue:
            [cell setTypeLableColor:UIColorFromHex(AirProColor)];
            break;
            
        default:
            [cell setTypeLableColor:UIColorFromHex(0x212121)];
            break;
    }
    
    //不同的tag配置不一样的cell
    switch (self.taskTag) {
        case TaskListTypeNotStarted:
        {
            self.headerLastLabel.hidden = NO;
 
            [cell configureWithStyle:CellStyle_UnDownLoad];
            
            //扫描action
            [cell.scanButton removeTarget:self action:@selector(remarkAction:) forControlEvents:UIControlEventTouchUpInside];
            [cell.scanButton addTarget:self action:@selector(scanAction:) forControlEvents:UIControlEventTouchUpInside];
            cell.scanButton.tag = indexPath.row;
            self.headerLastLabel.text = @"下发处方";
        }
            break;
        case TaskListTypeProcessing:
            self.headerLastLabel.hidden = YES;
            switch (task.state) {
                case 1:
                    [cell configureWithStyle:CellStyleGrey_DownLoadedUnRunning];
                    
                    //扫描action
                    [cell.scanButton removeTarget:self action:@selector(remarkAction:) forControlEvents:UIControlEventTouchUpInside];
                    [cell.scanButton removeTarget:self action:@selector(focusAction:) forControlEvents:UIControlEventTouchUpInside];
                    [cell.scanButton removeTarget:self action:@selector(unfocusAction:) forControlEvents:UIControlEventTouchUpInside];
                    [cell.scanButton addTarget:self action:@selector(scanAction:) forControlEvents:UIControlEventTouchUpInside];
                    cell.scanButton.tag = indexPath.row;
                    break;
                case 3:
                {
                    [cell configureWithStyle:CellStyleGreen_DownLoadedRunning];
                    [cell.scanButton removeTarget:self action:@selector(remarkAction:) forControlEvents:UIControlEventTouchUpInside];
                    [cell.scanButton removeTarget:self action:@selector(scanAction:) forControlEvents:UIControlEventTouchUpInside];
                    if (task.isFocus) {
                        [cell.scanButton setImage:[UIImage imageNamed:@"focus_fill"] forState:UIControlStateNormal];
                        [cell.scanButton addTarget:self action:@selector(unfocusAction:) forControlEvents:UIControlEventTouchUpInside];
                        
                    }else{
                        [cell.scanButton setImage:[UIImage imageNamed:@"focus_unfill"] forState:UIControlStateNormal];
                        [cell.scanButton addTarget:self action:@selector(focusAction:) forControlEvents:UIControlEventTouchUpInside];
                    }

                    cell.scanButton.tag = indexPath.row;

                }
                    break;
                case 7:
                    [cell configureWithStyle:CellStyleBlue_DownLoadedFinishRunning];
                    //评分action
                    [cell.scanButton removeTarget:self action:@selector(focusAction:) forControlEvents:UIControlEventTouchUpInside];
                    [cell.scanButton removeTarget:self action:@selector(unfocusAction:) forControlEvents:UIControlEventTouchUpInside];
                    [cell.scanButton removeTarget:self action:@selector(scanAction:) forControlEvents:UIControlEventTouchUpInside];
                    [cell.scanButton addTarget:self action:@selector(remarkAction:) forControlEvents:UIControlEventTouchUpInside];
                    cell.scanButton.tag = indexPath.row;
                default:
                    break;
            }

            
            break;
        case TaskListTypeFinished:
            self.headerLastLabel.hidden = NO;
            self.headerLastLabel.text = @"完成时间";
            [cell configureWithStyle:CellStyle_DownLoadedRemarked];
//            [cell setTypeLableColor:UIColorFromHex(0x212121)];
            cell.finishTimeLabel.text =[self stringFromTimeIntervalString:task.finishTimeString dateFormat:@"yyyy-MM-dd"];
            break;
        default:
            break;
    }
    
//    //第一个tab显示下发处方
//    self.headerLastLabel.hidden = (_segmentedControl.selectedSegmentIndex == TaskListTypeProcessing);

    return cell;
    
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if ([datas count]>0) {
        TaskModel *task = datas[indexPath.row];
        if (self.pushOnce == 1) {
//            if(task.state != 3){
            self.selectedRow = indexPath.row;
            [self remarkAction:nil];
//            }
            self.pushOnce = 0;
        }
    }
}

-(void)showPopover:(UIButton *)sender {
    if ([datas count]>0) {
        [self performSegueWithIdentifier:@"ShowPopover" sender:sender];
    }
}

#pragma mark - action
- (void)scanAction:(id)sender {
    if ([datas count]>0) {
        TaskModel *task = [datas objectAtIndex:[sender tag]];
        
        if ([task.machineType isEqualToString:@"血瘘"]) {
            
            //蓝牙的代理
            baby = [BabyBluetooth shareBabyBluetooth];
            [self babyDelegate];
            
//            //判断蓝牙是否打开
//            if (self.isBLEPoweredOff) {
//                [SVProgressHUD showErrorWithStatus:@"该设备没有打开蓝牙无法下发处方,请在设置中打开"];
//                return;
//            }
        }
        
        //判断相机权限是否打开
        NSString *mediaType = AVMediaTypeVideo;
        
        AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:mediaType];
        
        if(authStatus == AVAuthorizationStatusRestricted || authStatus == AVAuthorizationStatusDenied){
            
            
            
            UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"相机启用权限未开启"
                                                                           message:[NSString stringWithFormat:@"请在iPhone的“设置”-“隐私”-“相机”功能中，找到“%@”打开相机访问权限",[[[NSBundle mainBundle] infoDictionary]objectForKey:@"CFBundleDisplayName"]]
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"去设置" style:UIAlertActionStyleDefault
                                                                  handler:^(UIAlertAction * action) {
                                                                      
                                                                      NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                                                                      [[UIApplication sharedApplication] openURL:url];
                                                                      [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"prefs:root=Privacy&path=CAMERA"]];
                                                                  }];
            
            [alert addAction:defaultAction];
            [self presentViewController:alert animated:YES completion:nil];
 
            return;
            
        }
        self.selectedRow = [sender tag];
        
        NSArray *types = @[
                           AVMetadataObjectTypeEAN13Code,
                           AVMetadataObjectTypeEAN8Code,
                           AVMetadataObjectTypeUPCECode,
                           AVMetadataObjectTypeCode39Code,
                           AVMetadataObjectTypeCode39Mod43Code,
                           AVMetadataObjectTypeCode93Code,
                           AVMetadataObjectTypeCode128Code,
                           AVMetadataObjectTypePDF417Code];
        
        _reader = [QRCodeReaderViewController readerWithMetadataObjectTypes:types];
        _reader.delegate = self;
        [self presentViewController:_reader animated:YES completion:NULL];
    }

}
- (void)remarkAction:(id)sender{
    if (sender) {
        self.selectedRow = [sender tag];
    }

    [self performSegueWithIdentifier:@"TaskGoToRemarkVAS" sender:sender];
    
}
-(void)focusAction:(id)sender{
    
    if ([datas count]>0) {
        
        self.selectedRow = [sender tag];
        
        TaskModel *task = [datas objectAtIndex:self.selectedRow];
        
        [self focusMachineWithTask:task];
    }

    
}
-(void)unfocusAction:(id)sender{
    
    if ([datas count]>0) {
        self.selectedRow = [sender tag];
        
        __block TaskModel *task = [datas objectAtIndex:self.selectedRow];
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"要取消关注设备吗？"
                                                                       message:@"取消关注操作将不可恢复。"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleDefault
                                                              handler:nil];
        UIAlertAction* cancelFocusAction = [UIAlertAction actionWithTitle:@"取消关注"
                                                                    style:UIAlertActionStyleDestructive
                                                                  handler:^(UIAlertAction * _Nonnull action) {
                                                                      [self unfocusMachineWithTask:task];
                                                                  }];
        [alert addAction:defaultAction];
        
        [alert addAction:cancelFocusAction];
        
        [self presentViewController:alert animated:YES completion:nil];
    }
}

-(void)showSuccessView{
    [SVProgressHUD dismiss];
    [self refresh];
    if ([datas count ]>0) {
        
        
        __block TaskModel *task = [datas objectAtIndex:self.selectedRow];
        //本地设备通知服务器绑定设备
        if([task.machineType isEqualToString:@"血瘘"]){
            [[NetWorkTool sharedNetWorkTool]POST:[HTTPServerURLString stringByAppendingString:@"Api/TaskList/BindingLocalDevice"]
                                          params:@{
                                                   @"serialnum":@"P06A17A00001",
                                                   @"id":task.ID
                                                   }
                                        hasToken:YES
                                         success:^(HttpResponse *responseObject) {
                                             if([responseObject.result integerValue] == 1){
                                                 NSLog(@"绑定成功");
                                             }else{
                                                 [SVProgressHUD showErrorWithStatus:responseObject.errorString];
                                                 NSLog(@"bind error :%@",responseObject.errorString);
                                             }
                                         }
                                         failure:nil];
        }
        
        
        [SendTreatmentSuccessView alertControllerAboveIn:self returnBlock:^{
            
            [self focusMachineWithTask:task];
            
        }];
    }
    
}
-(void)focusMachineWithTask:(TaskModel *)task{
    if ([task.machineType isEqualToString:@"血瘘"]) {
        if (!task.serialNum) {
            task.serialNum = @"P06A17A00001";
        }
        NSString *medicalNum = task.medicalRecordNum;
        if (medicalNum) {
            [[NetWorkTool sharedNetWorkTool]POST:[HTTPServerURLString stringByAppendingString:@"Api/TaskList/QueryTask"]
                                          params:@{
                                                   @"medicalrecordnum":medicalNum,
                                                   @"taskstate":@3
                                                   }
                                        hasToken:YES
                                         success:^(HttpResponse *responseObject) {
                                             
                                             if (responseObject.content) {
                                                 NSLog(@"local machine = %@",responseObject.content);
                                                 NSArray *machineArray = responseObject.content;
                                                 LocalMachineModel *machine = [LocalMachineModel modelWithDic:machineArray[0]];
                                                 machine.taskId = task.ID;
                                                 
                                                 //关注本地设备
                                                 NSString *documents = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
                                                 
                                                 
                                                 if (!documents)
                                                 {
                                                     NSLog(@"目录未找到");
                                                 }
                                                 NSString *documentPath = [documents stringByAppendingPathComponent:@"focusLocalMachine.plist"];
                                                 NSFileManager *fileManager = [NSFileManager defaultManager];
                                                 //machine Array
                                                 NSArray *localMachineArray = [[NSArray alloc]init];
                                                 if (![fileManager fileExistsAtPath:documentPath])
                                                 {
                                                     //没有文件就新建文件
                                                     [fileManager createFileAtPath:documentPath contents:nil attributes:nil];
                                                 }else{
                                                     //有文件就去取文件中的数据
                                                     
                                                     NSData * resultdata = [[NSData alloc] initWithContentsOfFile:documentPath];
                                                     NSKeyedUnarchiver *unArchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:resultdata];
                                                     localMachineArray = [unArchiver decodeObjectForKey:@"machineArray"];
                                                 }
                                                 
                                                 NSMutableArray *array = [NSMutableArray arrayWithArray:localMachineArray];
                                                 BOOL isBinded = NO;
                                                 //病历号重复则重新绑定
                                                 for (LocalMachineModel *savedMachine in array) {
                                                     if ([savedMachine.userMedicalNum isEqualToString:machine.userMedicalNum]) {
                                                         NSUInteger index = [array indexOfObject:savedMachine];
                                                         [array replaceObjectAtIndex:index withObject:machine];
                                                         isBinded = YES;
                                                         break;
                                                     }
                                                 }
                                                 if (!isBinded) {
                                                     [array addObject:machine];
                                                 }
                                                 localMachineArray = [array copy];
                                                 
                                                 //写入文件
                                                 NSMutableData *data = [[NSMutableData alloc] init] ;
                                                 NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data] ;
                                                 [archiver encodeObject:localMachineArray forKey:@"machineArray"];
                                                 [archiver finishEncoding];
                                                 
                                                 BOOL success = [data writeToFile:documentPath atomically:YES];
                                                 if (!success)
                                                 {
                                                     NSLog(@"写入文件失败");
                                                     [SVProgressHUD showErrorWithStatus:@"关注失败"];
                                                 }else{
                                                     NSLog(@"写入文件成功");
                                                     [SVProgressHUD showSuccessWithStatus:@"已关注设备"];
                                                     task.isFocus = YES;
                                                     [self.tableView reloadData];
                                                 }
                                                
                                             }
                                         }failure:nil];
        }

    }
    else if (task.serialNum) {
            [[NetWorkTool sharedNetWorkTool]POST:[HTTPServerURLString stringByAppendingString:@"Api/Myfocus/Add"]
                                          params:@{@"serialnum":task.serialNum}
                                        hasToken:YES
                                         success:^(HttpResponse *responseObject) {
                                             if ([responseObject.result intValue]==1) {
                                                 NSLog(@"关注设备成功");
                                                 [SVProgressHUD showSuccessWithStatus:@"已关注设备"];

                                                 task.isFocus = true;

                                                 [self.tableView reloadData];
                                             }else{
                                                 [SVProgressHUD showErrorWithStatus:responseObject.errorString];
                                                 
                                             }
                                         }
                                         failure:nil];
        }
    
}
-(void)unfocusMachineWithTask:(TaskModel *)task{
    if ([task.machineType isEqualToString:@"血瘘"]) {
        if(!task.serialNum){
            task.serialNum = @"P06A17A00001";
        }
        NSString *documents = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
        NSString *documentPath = [documents stringByAppendingPathComponent:@"focusLocalMachine.plist"];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        //machine Array
        NSArray *machineArray = [[NSArray alloc]init];
        if ([fileManager fileExistsAtPath:documentPath]) {
            
            NSData * resultdata = [[NSData alloc] initWithContentsOfFile:documentPath];
            NSKeyedUnarchiver *unArchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:resultdata];
            machineArray = [unArchiver decodeObjectForKey:@"machineArray"];
            NSMutableArray *array = [NSMutableArray arrayWithArray:machineArray];
            
            for (LocalMachineModel *savedMachine in array) {
                if ([savedMachine.userMedicalNum isEqualToString:task.medicalRecordNum]) {
                    NSUInteger index = [array indexOfObject:savedMachine];
                    [array removeObjectAtIndex:index];
                    break;
                }
                
            }
            machineArray = [array copy];
            //写入文件
            NSMutableData *data = [[NSMutableData alloc] init] ;
            NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data] ;
            [archiver encodeObject:machineArray forKey:@"machineArray"];
            [archiver finishEncoding];
            
            BOOL success = [data writeToFile:documentPath atomically:YES];
            if (!success)
            {
                NSLog(@"取消关注失败");
                [SVProgressHUD showErrorWithStatus:@"无法取消关注"];

            }else{
                [SVProgressHUD showSuccessWithStatus:@"已取消关注"];
                task.isFocus = NO;
                [self.tableView reloadData];
            }
        }
    }
    else if(task.serialNum){
        [[NetWorkTool sharedNetWorkTool]POST:[HTTPServerURLString stringByAppendingString:@"Api/Myfocus/Delete"]
                                      params:@{@"serialnum":task.serialNum}
                                    hasToken:YES
                                     success:^(HttpResponse *responseObject) {
                                         
                                         if([responseObject.result intValue] == 1){
                                             [SVProgressHUD showErrorWithStatus:@"已取消关注"];
                                             task.isFocus = false;
                                             [self.tableView reloadData];

                                         }else{
                                             NSLog(@"取消关注错误:%@",responseObject.errorString);
                                             [SVProgressHUD showErrorWithStatus:responseObject.errorString];
                                         }
                                         
                                     }
                                     failure:nil];
    }
}

-(void)showFailView{
    [SVProgressHUD dismiss];
    [baby cancelScan];
    [baby cancelAllPeripheralsConnection];
    [SendTreatmentFailView alertControllerAboveIn:self];
}
-(void)startTimer{
    self.timer = [NSTimer scheduledTimerWithTimeInterval:12 target:self selector:@selector(showFailView) userInfo:nil repeats:NO];
}
-(void)closeTimer{
    // 停止定时器
    [self.timer invalidate];
    self.timer = nil;
}

#pragma mark - QRCodeReader Delegate Methods
- (void)reader:(QRCodeReaderViewController *)reader didScanResult:(NSString *)result
{
    [self dismissViewControllerAnimated:YES completion:^{
        
        if (![self checkSerailNum:result]) {
            [SVProgressHUD showErrorWithStatus:@"请扫描有效序列号"];
        }else{
            //去取对应的病人病历号
            TaskModel *task = [datas objectAtIndex:self.selectedRow];
            
            NSString *taskId = task.ID;
            
            NSLog(@"%@", [NSString stringWithFormat:@"medicalnum = %@",task.medicalRecordNum]);
            
            
            if ([task.machineType isEqualToString:@"血瘘"]) {
                
                
                [SVProgressHUD showWithStatus:@"处方下发中……"];
                
                if ([result isEqualToString:@"P06A17A00001"]) {
                    self.BLEDeviceName = @"ALX420";
                }else{
                    self.BLEDeviceName = result;
                }
                
                NSArray *paramArray = task.treatParam[@"paramlist"];
                
                NSString *time = [[paramArray objectAtIndex:0]objectForKey:@"value"];
                NSDictionary *levelDic = @{@"一级":@"1",@"二级":@"2",@"三级":@"3"};
                NSString *level = [[paramArray objectAtIndex:1]objectForKey:@"value"];
                
                Byte bytes[2] = {[time intValue],[levelDic[level] intValue]};
                self.BLETreatParam = [NSData dataWithBytes:bytes length:2];
                
                //检查设备是否被其他病人绑定了
                [[NetWorkTool sharedNetWorkTool]POST:[HTTPServerURLString stringByAppendingString:@"Api/TaskList/CheckDeviceEnabled"]
                                              params:@{@"serialnum":result}
                                            hasToken:YES
                                             success:^(HttpResponse *responseObject) {
                                                 if ([responseObject.result integerValue]== 1) {
                                                     NSString *mac = responseObject.content[@"cpuid"];
                                                     NSNumber *enabled = responseObject.content[@"enabled"];
                                                     
                                                     if ([enabled integerValue] ==1) {
                                                         //连接设备
                                                         [self BLEConnectDevice];
                                                         [self startTimer];
                                                         
                                                     }else{
                                                         [SVProgressHUD showErrorWithStatus:@"设备正忙"];
                                                     }
                                                 }else{
                                                     [SVProgressHUD showErrorWithStatus:responseObject.errorString];
                                                 }
                                             }
                                             failure:nil];
                
            }else{
                [SVProgressHUD showWithStatus:@"处方下发中……"];
                
                NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:20];
                
                [params setObject:result forKey:@"serialnum"];
                
                [params setObject:taskId forKey:@"id"];
                
                [[NetWorkTool sharedNetWorkTool]POST:[HTTPServerURLString stringByAppendingString:@"Api/TaskList/TreatmentParamDownload"]
                                              params:params
                                            hasToken:YES
                                             success:^(HttpResponse *responseObject) {
                                                 if ([responseObject.result intValue]==1) {
                                                     //保存扫描到的序列号到处方中
                                                     task.serialNum = result;
                                                     [self showSuccessView];
                                                     
                                                 }else{
                                                     [SVProgressHUD showErrorWithStatus:responseObject.errorString];
                                                     //                                                 [self showFailView];
                                                     
                                                 }
                                                 
                                             } failure:nil];
            }
            
            NSLog(@"QRretult == %@", result);
        }
 
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

#pragma mark - BLE

-(void)BLEConnectDevice{
    
    if (self.BLEDeviceName) {
        

        baby.scanForPeripherals().begin();
    }
}
-(void)BLEDownLoadTreatment{

    [self writeWithCmdid:0x9A data:self.BLETreatParam];
}
-(void)babyDelegate{
    
    __weak typeof(self) weakSelf = self;
    __weak typeof(BabyBluetooth*) weakBaby = baby;
    [baby setBlockOnCentralManagerDidUpdateState:^(CBCentralManager *central) {
        if (@available(iOS 10.0, *)) {
            if (central.state == CBManagerStatePoweredOff) {
                if (weakSelf.view) {
                    [SVProgressHUD showErrorWithStatus:@"该设备尚未打开蓝牙,请在设置中打开"];
                    NSLog(@"BLE off");
                    weakSelf.isBLEPoweredOff = YES;
                }
            }else if(central.state == CBManagerStatePoweredOn) {
//                weakBaby.scanForPeripherals().begin();
                NSLog(@"BLE on");
                weakSelf.isBLEPoweredOff = NO;
            }
        } else {
            // Fallback on earlier versions
        }
    }];
    [baby setBlockOnConnected:^(CBCentralManager *central, CBPeripheral *peripheral) {

        NSLog(@"连接成功");

    }];
    [baby setBlockOnDisconnect:^(CBCentralManager *central, CBPeripheral *peripheral, NSError *error) {
        
        NSLog(@"断开连接");
        
    }];
    
    //发现service的Characteristics
    [baby setBlockOnDiscoverCharacteristics:^(CBPeripheral *peripheral, CBService *service, NSError *error) {
        if ([service.UUID isEqual:[CBUUID UUIDWithString:SERVICE_UUID]]) {
            
            for (CBCharacteristic *characteristic in service.characteristics)
            {
                if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:RX_CHARACTERISTIC_UUID]])
                {
                    weakSelf.receiveCharacteristic = characteristic;
                    if (![characteristic isNotifying]) {
                        [weakSelf setNotify:characteristic];
                    }
                }
                if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:TX_CHARACTERISTIC_UUID]])
                {
                    weakSelf.sendCharacteristic = characteristic;
                    
                    [weakSelf performSelector:@selector(BLEDownLoadTreatment) withObject:nil afterDelay:0.5];

                }
                
            }
        }
        
    }];
    [baby setBlockOnDiscoverToPeripherals:^(CBCentralManager *central, CBPeripheral *peripheral, NSDictionary *advertisementData, NSNumber *RSSI) {
        NSLog(@"advertisementData = %@",advertisementData);
        //连接设备
        if ([peripheral.name isEqualToString:weakSelf.BLEDeviceName]) {
            [weakBaby cancelScan];
            weakSelf.peripheral = peripheral; weakBaby.having(peripheral).connectToPeripherals().discoverServices().discoverCharacteristics().readValueForCharacteristic().discoverDescriptorsForCharacteristic().readValueForDescriptors().begin();
        }
    }];
    [baby setFilterOnDiscoverPeripherals:^BOOL(NSString *peripheralName, NSDictionary *advertisementData, NSNumber *RSSI) {
        if (peripheralName.length > 0 && [peripheralName isEqualToString:@"ALX420"]) {
            
            return YES;
            
        }
        return NO;
    }];
    
    NSDictionary *scanForPeripheralsWithOptions = @{CBCentralManagerScanOptionAllowDuplicatesKey:@YES};
    [baby setBabyOptionsWithScanForPeripheralsWithOptions:scanForPeripheralsWithOptions connectPeripheralWithOptions:nil scanForPeripheralsWithServices:nil discoverWithServices:nil discoverWithCharacteristics:nil];
}
//接收数据
- (void)setNotify:(CBCharacteristic *)characteristic {
    __weak typeof(self)weakSelf = self;
    [weakSelf.peripheral setNotifyValue:YES forCharacteristic:characteristic];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [baby notify:weakSelf.peripheral
      characteristic:characteristic
               block:^(CBPeripheral *peripheral, CBCharacteristic *characteristics, NSError *error) {
                   NSLog(@"----------------------------------------------");
                   NSData *data = characteristic.value;
                   if (data) {
                       [weakSelf handleCompleteData:data];
                   }
                   
               }];
    });
}
-(void)handleCompleteData:(NSData *)complateData{
     NSData *data = [Unpack unpackData:complateData];
    if (data) {
        Byte *bytes = (Byte *)[data bytes];
        Byte cmdid = bytes[0];
        Byte dataByte = bytes[1];
        if (cmdid == 0x9A) {
            if (dataByte == 1) {
                [self showSuccessView];
                [baby cancelScan];
                [baby cancelAllPeripheralsConnection];
                if (self.timer) {
                    [self closeTimer];
                }
            }else{
                [self showFailView];
            }
        }
    }
}

-(void)writeWithCmdid:(Byte)cmdid data:(NSData*)data{
    
    [self.peripheral writeValue:[Pack packetWithCmdid:cmdid
                                          dataEnabled:YES
                                                 data:data]
              forCharacteristic:self.sendCharacteristic
                           type:CBCharacteristicWriteWithResponse];
}

#pragma mark - prepareForSegue

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([segue.identifier isEqualToString:@"ShowPopover"]) {
        PopoverTreatwayController *destination = (PopoverTreatwayController *)segue.destinationViewController;
        UIPopoverPresentationController *popover = destination.popoverPresentationController;
        popover.delegate = self;
        
        if ([datas count]>0) {
            //获取某个cell的数据
            UIView *contentView = [(UIView *)sender superview];
            
            TaskCell *cell = (TaskCell*)[contentView superview];
            
            NSIndexPath* index = [self.tableView indexPathForCell:cell];

            TaskModel *task = [datas objectAtIndex:index.row];
            
            destination.treatParamDic = task.treatParam;
            
            UIButton *button = sender;
            popover.sourceView = button;
            popover.sourceRect = button.bounds;
        }

    }else if ([segue.identifier isEqualToString:@"TaskGoToRemarkVAS"]){
        TreatmentCourseRecordViewController *controller = segue.destinationViewController;
        TaskModel *task = [datas objectAtIndex:self.selectedRow];
        controller.medicalRecordNum = task.medicalRecordNum;
        if (task.state == 3) {
            controller.isFocusToStop = TRUE;
        }
    }
}

-(UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller {
    return UIModalPresentationNone;
}
//时间戳字符串转化为日期或时间
- (NSString *)stringFromTimeIntervalString:(NSString *)timeString dateFormat:(NSString*)dateFormat
{
    // 格式化时间
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    [formatter setTimeZone: [NSTimeZone timeZoneWithName:@"Asia/Beijing"]];
    [formatter setDateStyle:NSDateFormatterMediumStyle];
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    [formatter setDateFormat:dateFormat];
    
    // 毫秒值转化为秒
    NSDate* date = [NSDate dateWithTimeIntervalSince1970:[timeString doubleValue]];
    NSString* dateString = [formatter stringFromDate:date];
    
    return dateString;
}
//序列号正则
- (BOOL)checkSerailNum:(NSString *)inputString {
    if (inputString.length == 0) return NO;
    NSString *regex =@"^[A-Z]{1}[A-Z0-9]{3}\\d{2}[A-C1-9]{1}[A-Z0-9]{1}\\d{4}$";
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"SELF MATCHES %@",regex];
    return [pred evaluateWithObject:inputString];
}
@end
