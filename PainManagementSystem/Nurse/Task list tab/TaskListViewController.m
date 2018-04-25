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
#import "SendTreatmentSuccessView.h"
#import "SendTreatmentFailView.h"
#import "QRCodeReaderViewController.h"
#import "PopoverTreatwayController.h"
#import "Pack.h"
#import "Unpack.h"

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

@property(nonatomic,strong)NSTimer *timer;

@end

@implementation TaskListViewController{
    BabyBluetooth *baby;
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
    [baby cancelScan];
    [baby cancelAllPeripheralsConnection];
    [self endRefresh];
    if (self.timer) {
        [self closeTimer];
    }
}
-(void)initAll{
    //初始tag为待处理
    self.taskTag = TaskListTypeNotStarted;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.tableFooterView = [[UIView alloc]init];
    
    datas = [[NSMutableArray alloc]initWithCapacity:20];
    NSArray *dataArray = [NSArray arrayWithContentsOfFile:[[NSBundle mainBundle]pathForResource:@"Task" ofType:@"plist"]];
    for (NSDictionary *dataDic in dataArray) {
        TaskModel *task = [TaskModel modelWithDic:dataDic];
        [datas addObject:task];
    }

    
    //配置segmentedcontrol
    self.segmentedControl.frame = CGRectMake(self.segmentedControl.frame.origin.x, self.segmentedControl.frame.origin.y, self.segmentedControl.frame.size.width, 35);
    
    [self.segmentedControl setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}forState:UIControlStateSelected];
    
    [self.segmentedControl setTitleTextAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:15.0f]}forState:UIControlStateNormal];
    
    [self.segmentedControl addTarget:self action:@selector(didClicksegmentedControlAction:) forControlEvents:UIControlEventValueChanged];
}

-(void)didClicksegmentedControlAction:(UISegmentedControl *)segmentedControl{
    
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
    
    [self.tableView.mj_header beginRefreshing];
    
    
    //上拉加载
    MJRefreshAutoNormalFooter *footer = [MJRefreshAutoNormalFooter footerWithRefreshingTarget:self refreshingAction:@selector(loadMore)];
    [footer setTitle:@"" forState:MJRefreshStateIdle];
    [footer setTitle:@"" forState:MJRefreshStateRefreshing];
    [footer setTitle:@"No more data" forState:MJRefreshStateNoMoreData];
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
    
    [[NetWorkTool sharedNetWorkTool]POST:[HTTPServerURLString stringByAppendingString:@"Api/TaskList/Count"]
                                  params:param
                                hasToken:YES
                                 success:^(HttpResponse *responseObject) {
                                     if ([responseObject.result intValue] == 1) {
                                         
                                         NSString *count = responseObject.content[@"count"];
                                         
                                         totalPage = ([count intValue]+15-1)/15;
                                         
                                         NSLog(@"totalPage = %d",totalPage);
                                         
                                         if([count intValue] > 0)
                                         {
                                             self.tableView.tableHeaderView.hidden = NO;
                                             [self getNetworkData:isRefresh];
                                         }else{
                                             [datas removeAllObjects];
                                             dispatch_async(dispatch_get_main_queue(), ^{
                                                 [self.tableView reloadData];
                                             });
                                             NSString *title = [self.segmentedControl titleForSegmentAtIndex:self.segmentedControl.selectedSegmentIndex];
                                             
                                             [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"没有%@的处方~",title]];
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
                                             for (NSDictionary *dic in content) {
                                                 NSLog(@"dic = %@",dic);
                                                 TaskModel *task = [TaskModel modelWithDic:dic];
                                                 
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

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    static NSString *CellIdentifier = @"Cell";
    TaskCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    if (cell == nil) {
        cell = [[TaskCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    

    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    TaskModel *task = datas[indexPath.row];
    cell.doctorNameLable.text = task.doctorName;
    cell.medicalRecordNumLable.text  = task.medicalRecordNum;
    cell.patientNameLabel.text = task.patientName;
    cell.typeLabel.text = task.machineType;
    
    //治疗参数详情弹窗
    [cell.treatmentButton setTitle:[NSString stringWithFormat:@"治疗时间:%@分钟",task.treatTime] forState:UIControlStateNormal];
    [cell.treatmentButton addTarget:self action:@selector(showPopover:) forControlEvents:UIControlEventTouchUpInside];

    //不同的tag配置不一样的cell
    switch (self.taskTag) {
        case TaskListTypeNotStarted:
        {
            //配置治疗设备显示文字
            switch ([task.machineTypeNumber integerValue]) {
                    
                case ElectrotherapyTypeValue:
                    [cell setTypeLableColor:UIColorFromHex(ElectrothetapyColor)];
                    break;
                    
                case AladdinTypeValue:
                    [cell setTypeLableColor:UIColorFromHex(AladdinColor)];
                    break;
                    
                case AirProTypeValue:
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
            switch (task.state) {
                case 1:
                    [cell configureWithStyle:CellStyleGrey_DownLoadedUnRunning];
                    
                    //扫描action
                    [cell.scanButton removeTarget:self action:@selector(remarkAction:) forControlEvents:UIControlEventTouchUpInside];
                    [cell.scanButton addTarget:self action:@selector(scanAction:) forControlEvents:UIControlEventTouchUpInside];
                    cell.scanButton.tag = indexPath.row;
                    break;
                case 3:
                {
                   [cell configureWithStyle:CellStyleGreen_DownLoadedRunning];
//                    UILongPressGestureRecognizer * longPressGesture =[[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(remarkAction:)];
//
//                    longPressGesture.minimumPressDuration=1.5f;//设置长按 时间
//                    [cell addGestureRecognizer:longPressGesture];
                }
                    break;
                case 7:
                    [cell configureWithStyle:CellStyleBlue_DownLoadedFinishRunning];
                    //评分action
                    [cell.scanButton removeTarget:self action:@selector(scanAction:) forControlEvents:UIControlEventTouchUpInside];
                    [cell.scanButton addTarget:self action:@selector(remarkAction:) forControlEvents:UIControlEventTouchUpInside];
                    cell.scanButton.tag = indexPath.row;
                default:
                    break;
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
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    TaskModel *task = datas[indexPath.row];
    switch (self.taskTag) {
        case TaskListTypeProcessing:
            if(task.state == 3){
                [self remarkAction:nil];
            }
            break;

        default:
            break;
    }
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
    _reader.delegate = self;
    [self presentViewController:_reader animated:YES completion:NULL];
    
}
- (void)remarkAction:(id)sender{
    
//    self.selectedRow = [sender tag];
    [self performSegueWithIdentifier:@"TaskGoToRemarkVAS" sender:sender];
    
}

-(void)showSuccessView{
    [SVProgressHUD dismiss];
    [SendTreatmentSuccessView alertControllerAboveIn:self returnBlock:^{
        NSLog(@"send to server设置关注 ");
        TaskModel *task = [datas objectAtIndex:self.selectedRow];
        NSString *serialNum = task.serialNum;
        if([task.machineType isEqualToString:@"血瘘"]){
            serialNum = @"P06A17A00001";
        }

        if(serialNum){
            [[NetWorkTool sharedNetWorkTool]POST:[HTTPServerURLString stringByAppendingString:@"Api/Myfocus/Add"]
        params:@{@"serialnum":serialNum}
        hasToken:YES
        success:^(HttpResponse *responseObject) {
            if ([responseObject.result intValue]==1) {
                NSLog(@"关注设备成功");
                [SVProgressHUD showSuccessWithStatus:@"已关注设备"];
            }else{
                [SVProgressHUD showErrorWithStatus:responseObject.errorString];
            }
        }
        failure:nil];
        }
    }];
    
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
        
        //去取对应的病人病历号
        TaskModel *task = [datas objectAtIndex:self.selectedRow];
        //保存扫描到的序列号到处方中
        task.serialNum = result;
        
        NSString *taskId = task.ID;
        NSLog(@"medical  = %@",taskId);

        [SVProgressHUD showWithStatus:@"处方下发中……"];
        
        if ([task.machineType isEqualToString:@"血瘘"]) {
            self.BLEDeviceName = result;
            NSArray *paramArray = task.treatParam[@"paramlist"];
            
            NSString *time = [[paramArray objectAtIndex:0]objectForKey:@"value"];
            NSDictionary *levelDic = @{@"一级":@"1",@"二级":@"2",@"三级":@"3"};
            NSString *level = [[paramArray objectAtIndex:1]objectForKey:@"value"];
            
            Byte bytes[2] = {[time intValue],[levelDic[level] intValue]};
            self.BLETreatParam = [NSData dataWithBytes:bytes length:2];
            
            //连接设备
            [self BLEConnectDevice];
            [self startTimer];
            
            
        }else{
            NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:20];
            
            [params setObject:result forKey:@"serialnum"];
            
            [params setObject:taskId forKey:@"id"];
            
            [[NetWorkTool sharedNetWorkTool]POST:[HTTPServerURLString stringByAppendingString:@"Api/TaskList/TreatmentParamDownload"]
                                          params:params
                                        hasToken:YES
                                         success:^(HttpResponse *responseObject) {
                                             if ([responseObject.result intValue]==1) {
                                                 
                                                 [self showSuccessView];
                                                 
                                                 
                                             }else{
                                                 [SVProgressHUD showErrorWithStatus:responseObject.errorString];
//                                                 [self showFailView];
                                                 
                                             }
                                             
                                         } failure:nil];
        }
        //send treatment to server

        
        
        
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

#pragma mark - BLE

-(void)BLEConnectDevice{
    
    if (self.BLEDeviceName) {
        
        baby = [BabyBluetooth shareBabyBluetooth];
        [self babyDelegate];
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
        if (central.state == CBManagerStatePoweredOff) {
            if (weakSelf.view) {
                [SVProgressHUD showErrorWithStatus:@"该设备尚未打开蓝牙,请在设置中打开"];
            }
        }else if(central.state == CBManagerStatePoweredOn) {
                weakBaby.scanForPeripherals().begin();
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
        
        //获取某个cell的数据
        UIView *contentView = [(UIView *)sender superview];
        
        TaskCell *cell = (TaskCell*)[contentView superview];
        
        NSIndexPath* index = [self.tableView indexPathForCell:cell];
        
//        NSDictionary *dataDic = [datas objectAtIndex:index.row];
//        NSDictionary *treatWayDic = dataDic[@"physicaltreat"][@"treatway"];
//
//        destination.treatWayDic = treatWayDic;
        TaskModel *task = [datas objectAtIndex:index.row];
        
        destination.treatParamDic = task.treatParam;
        
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
