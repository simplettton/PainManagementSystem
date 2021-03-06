//
//  AddDeviceViewController.m
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/3/19.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

//蓝牙uuid = 0167ED09-0C56-6EC8-232F-4DEAB6048FF4
#import "AddDeviceViewController.h"
#import "LoginViewController.h"
#import "AddDeviceCell.h"
#import "BaseHeader.h"
#import "QRCodeReaderViewController.h"
#import "Pack.h"
#import "Unpack.h"
#import <MBProgressHUD.h>
#import <AVFoundation/AVFoundation.h>
#import "MJRefresh.h"
#import "MachineSeriesModel.h"
#import "BEButton.h"
#import "NoDataPlaceHoler.h"
#import "AppDelegate.h"

#define SERVICE_UUID           @"1b7e8251-2877-41c3-b46e-cf057c562023"
#define TX_CHARACTERISTIC_UUID @"5e9bf2a8-f93f-4481-a67e-3b2f4a07891a"
#define RX_CHARACTERISTIC_UUID @"8ac32d3f-5cb9-4d44-bec2-ee689169f626"

#define TYPE_ITEM_Height 30
#define TYPE_ITEM_INTERVAL 48
typedef NS_ENUM(NSUInteger,typeTags)
{
    electrotherapyTag = 1000,airProTag = 1001,aladdinTag = 1002,LightTag = 1003
};
@interface AddDeviceViewController ()<QRCodeReaderDelegate,UITextFieldDelegate,UIScrollViewDelegate>{
    int page;
    int totalPage;  //总页数
    BOOL isRefreshing; //是否正在下拉刷新或者上拉加载
    //类型总数
    NSMutableArray *typeItemModels;
}
@property (weak, nonatomic) IBOutlet UIView *tableBackgroundView;

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *contentView;

//条形码扫描
@property (strong,nonatomic) QRCodeReaderViewController *reader;
@property (assign,nonatomic) NSInteger selectedDeviceTag;
@property (strong, nonatomic)MachineSeriesModel *selectedMachineSeries;
@property (assign,nonatomic) NSInteger selectedRow;

@property (strong, nonatomic)MBProgressHUD * HUD;

@property (strong ,nonatomic) CBPeripheral *peripheral;
@property (nonatomic,strong) CBCharacteristic *sendCharacteristic;
@property (nonatomic,strong) CBCharacteristic *receiveCharacteristic;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
//没有记录view
@property(nonatomic,strong)NoDataPlaceHoler *nodataView;

@end

@implementation AddDeviceViewController{
    
    NSMutableArray *datas;
    BabyBluetooth *baby;
    BOOL isLocalDeviceList;
}
-(void)viewWillAppear:(BOOL)animated{
    
    [super viewWillAppear:YES];
    self.navigationItem.hidesBackButton = YES;
    self.title = @"设备管理系统";
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:46.0f/255.0f green:163.0f/255.0f blue:230.0f/255.0f alpha:1];
    self.tableView.mj_header.hidden = NO;

}
-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:YES];
    [baby cancelScan];
    [baby cancelAllPeripheralsConnection];
    [self endRefresh];
    self.tableView.mj_header.hidden = YES;

}
//关闭键盘
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
    [self hideKeyBoard];
}
-(void)hideKeyBoard{
    
    [self.view endEditing:YES];

    [self.tableView endEditing:YES];
    
}

-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    NSUInteger proposedNewLength = textField.text.length - range.length + string.length;
    if (proposedNewLength > 20) {
        return NO;//限制长度
    }
    return YES;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    [self initAll];
    
}

-(void)initAll{
    
    //非本地设备
    isLocalDeviceList = NO;
    
    self.tableView.tableFooterView = [[UIView alloc]init];

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyBoard)];
    
    [self.tableView addGestureRecognizer:tap];
    
    datas = [[NSMutableArray alloc]initWithCapacity:20];
    [self initMahineTypeModels];


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
                                                 [typeItemModels addObject:machineSeries];
                                             }
                                         }
                                         if ([typeItemModels count]>0) {
                                             //默认选中第一个
                                             self.selectedMachineSeries = typeItemModels[0];
                                             [self initScrollView];
                                         }
                                         [self initTableHeaderAndFooter];
                                     }
                                     
                                 } failure:nil];
    
}
- (void)initScrollView
{
    if ([typeItemModels count]>0) {

        CGFloat contentsizeWidth = 20;
        for (MachineSeriesModel *machineSerial in typeItemModels) {
            contentsizeWidth += machineSerial.buttonWidth + TYPE_ITEM_INTERVAL;
        }
        self.scrollView.contentSize = CGSizeMake(contentsizeWidth, self.scrollView.bounds.size.height);
        self.scrollView.delegate = self;
        self.scrollView.showsHorizontalScrollIndicator = NO;
        self.scrollView.showsVerticalScrollIndicator = NO;
        //设置scrollView滚动的减速速率
        self.scrollView.decelerationRate = 0.95f;
        
        CGFloat buttonYPositon = self.scrollView.bounds.size.height/2 - TYPE_ITEM_Height/2;
        CGFloat XPostion = 20.0f;
        for (int i = 0; i < [typeItemModels count]; i++){
            
            MachineSeriesModel *machineSerial = typeItemModels[i];

            BEButton *button = [[BEButton alloc]initWithFrame:CGRectMake(XPostion, buttonYPositon, machineSerial.buttonWidth, TYPE_ITEM_Height)];
            [button setTitle:machineSerial.name forState:UIControlStateNormal];
            button.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightLight];
            [button setTitleColor:UIColorFromHex(0X212121) forState:UIControlStateNormal];
            
            [button setBackgroundColor:UIColorFromHex(0xf8f8f8)];
            
            XPostion = button.frame.origin.x + button.frame.size.width + TYPE_ITEM_INTERVAL;
            
            button.tag = 1000 + i;
            
            [button addTarget:self action:@selector(selectDevice:) forControlEvents:UIControlEventTouchUpInside];
            
            [self.scrollView addSubview:button];
            
        }
        UIButton *firstButton = [self.scrollView viewWithTag:1000];
        [self selectDevice:firstButton];
        
    }


}
#pragma mark - refresh

-(void)initTableHeaderAndFooter{
    
    //下拉刷新

    MJRefreshNormalHeader *header = [MJRefreshNormalHeader headerWithRefreshingTarget:self refreshingAction:@selector(refresh)];
    [header setTitle:@"下拉刷新" forState:MJRefreshStateIdle];
    [header setTitle:@"松开更新" forState:MJRefreshStatePulling];
    [header setTitle:@"加载中..." forState:MJRefreshStateRefreshing];
    header.stateLabel.textColor =UIColorFromHex(0xdbdbdb);
    
    self.tableView.mj_header = header;
    [self refresh];
    
    
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
    [self hideNodataView];
    if (!isLocalDeviceList) {
        datas = [[NSMutableArray alloc]initWithCapacity:20];
        NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:20];

        [params setObject:self.selectedMachineSeries.code forKey:@"machinetype"];
        [params setObject:[NSNumber numberWithInt:0] forKey:@"isregistered"];
        
        [[NetWorkTool sharedNetWorkTool]POST:[HTTPServerURLString stringByAppendingString:@"Api/OnlineDevice/ListOnlineCount"]
                                      params:params
                                    hasToken:YES
                                     success:^(HttpResponse *responseObject) {

                                         if ([responseObject.result intValue] == 1) {
                                             NSString *count = responseObject.content[@"count"];
                                             
                                             //页数
                                             totalPage = ([count intValue]+15-1)/15;
                                             if (totalPage <= 1) {
                                                 self.tableView.mj_footer.hidden = YES;
                                             }else{
                                                 self.tableView.mj_footer.hidden = NO;
                                             }
                                             if ([count intValue] >0) {
                                                 
                                                 [self getNetworkData:isRefresh];
                                                 self.tableView.tableHeaderView.hidden = NO;
                                                 [self hideNodataView];

                                             }else{
                                                 [datas removeAllObjects];
                                                 [self showNodataViewWithTitle:@"暂无可录入设备"];
                                                 [self endRefresh];
                                                 [self.tableView reloadData];
                                            self.tableView.tableHeaderView.hidden = YES;
                                                 
                                             }
                                         }else{
                                             [SVProgressHUD showErrorWithStatus:responseObject.errorString];
                                         }
                                     } failure:nil];
        
    }
}
-(void)getNetworkData:(BOOL)isRefresh{
    
    if (isRefresh) {
        page = 0;
    }else{
        page ++;
    }
    
    //配置请求http
    NSMutableDictionary *mutableParam = [[NSMutableDictionary alloc]init];
    
//    switch (self.selectedDeviceTag) {
//        case electrotherapyTag:
//
//            [mutableParam setObject:[NSNumber numberWithInt:56832] forKey:@"machinetype"];
//
//            break;
//        case airProTag:
//
//            [mutableParam setObject:[NSNumber numberWithInt:7681] forKey:@"machinetype"];
//
//            break;
//        case LightTag:
//            [mutableParam setObject:@61184 forKey:@"machinetype"];
//            break;
//
//        default:
//            break;
//    }
    [mutableParam setObject:self.selectedMachineSeries.code forKey:@"machinetype"];
    
    [mutableParam setObject:@0 forKey:@"isregistered"];
    [mutableParam setObject:[NSNumber numberWithInt:page] forKey:@"page"];
    NSDictionary *params = (NSDictionary *)mutableParam;
    
    [[NetWorkTool sharedNetWorkTool]POST:[HTTPServerURLString stringByAppendingString:@"Api/OnlineDevice/ListOnline"]
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
                                     
                                     //上拉加载更多
                                     if (page >=totalPage) {
                                         [self endRefresh];
                                         [self.tableView.mj_footer endRefreshingWithNoMoreData];
                                         return;
                                     }

                                     if ([responseObject.result intValue] == 1) {
                                         NSArray *content = responseObject.content;
                                         if (content) {
                                             for (NSDictionary *dic in content) {
                                                 NSLog(@"device = %@",dic);
                                                 [datas addObject:dic];
                                             }
                                             [self.tableView reloadData];
                                         }

                                     }
                                 } failure:nil];
}
#pragma mark - mark NoDataView
-(void)showNodataViewWithTitle:(NSString *)title{
    if (self.nodataView == nil) {
        self.nodataView = [[[NSBundle mainBundle]loadNibNamed:@"NoDataPlaceHolder" owner:self options:nil]lastObject];

        [self.view addSubview:self.nodataView];
//
        self.nodataView.center = CGPointMake(self.view.center.x + 80 , self.view.center.y-50);
    }
    
    self.nodataView.titleLabel.text = title;
    
}
-(void)hideNodataView{
    if(self.nodataView){
        [self.nodataView removeFromSuperview];
        self.nodataView = nil;
    }
}

#pragma mark - changeDevice
-(void)selectDevice:(UIButton *)sender{
    [self hideNodataView];
    self.selectedDeviceTag = [sender tag];
    self.selectedMachineSeries = typeItemModels[([sender tag])-1000];
    for (int i = 1000; i<1000 + [typeItemModels count]; i++) {
        UIButton *btn = (UIButton *)[self.scrollView viewWithTag:i];
        //配置选中按钮
        if ([btn tag] == [(UIButton *)sender tag]) {
            btn.backgroundColor = UIColorFromHex(0x37bd9c);
            [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        }else{
            btn.backgroundColor = UIColorFromHex(0xf8f8f8);
            [btn setTitleColor:UIColorFromHex(0x212121) forState:UIControlStateNormal];
        }
    }
    if (self.selectedMachineSeries.isLocal) {
        
        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        
        if (appDelegate.isBLEPoweredOff) {
            [SVProgressHUD showErrorWithStatus:@"打开蓝牙才可以录入该设备"];
            return;
        }
        isLocalDeviceList = YES;
        datas = [[NSMutableArray alloc]initWithCapacity:20];
        baby = [BabyBluetooth shareBabyBluetooth];
        [self babyDelegate];
        baby.scanForPeripherals().begin();
        self.tableView.mj_header.hidden = YES;
        self.tableView.mj_footer = nil;
    }else{
        [baby cancelScan];
        [baby cancelAllPeripheralsConnection];
        isLocalDeviceList = NO;
        self.tableView.mj_header.hidden = NO;
        [self refresh];
    }
        [self.tableView reloadData];
    
}

#pragma mark - BLE
-(void)babyDelegate {
    __weak typeof(self) weakSelf = self;
    
    [baby setBlockOnConnected:^(CBCentralManager *central, CBPeripheral *peripheral) {
        
        NSString *uuid = peripheral.identifier.UUIDString;
        
        [UserDefault setObject:uuid forKey:@"BLEUuid"];
        
        [UserDefault synchronize];
        
        NSLog(@"连接成功");
        
    }];
    
    [baby setBlockOnDisconnect:^(CBCentralManager *central, CBPeripheral *peripheral, NSError *error) {
        NSLog(@"断开连接");
    }];
    
    //发现service的Characteristics
    [baby setBlockOnDiscoverCharacteristics:^(CBPeripheral *peripheral, CBService *service, NSError *error) {
        if (weakSelf.selectedMachineSeries.serviceUUID) {
            if ([service.UUID isEqual:[CBUUID UUIDWithString:weakSelf.selectedMachineSeries.serviceUUID]]) {
                
                for (CBCharacteristic *characteristic in service.characteristics)
                {
                    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:weakSelf.selectedMachineSeries.rxCharacteristicUUID]])
                    {
                        weakSelf.receiveCharacteristic = characteristic;
                        if (![characteristic isNotifying]) {
                            [weakSelf setNotify:characteristic];
                        }
                    }
                    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:weakSelf.selectedMachineSeries.txCharacteristicUUID]])
                    {
                        weakSelf.sendCharacteristic = characteristic;
                        [weakSelf BleBeep];
                    }
                }
            }
        }
 
    }];
    
    [baby setBlockOnDiscoverToPeripherals:^(CBCentralManager *central, CBPeripheral *peripheral, NSDictionary *advertisementData, NSNumber *RSSI) {
        [weakSelf insertTableView:peripheral advertisementData:advertisementData RSSI:RSSI];
    }];
    
    [baby setFilterOnDiscoverPeripherals:^BOOL(NSString *peripheralName, NSDictionary *advertisementData, NSNumber *RSSI) {
        if (weakSelf.selectedMachineSeries.name) {
            if (peripheralName.length > 0 && [peripheralName isEqualToString:weakSelf.selectedMachineSeries.broadcastName]) {
                
                return YES;
                
            }
        }
        return NO;
    }];
    
    NSDictionary *scanForPeripheralsWithOptions = @{CBCentralManagerScanOptionAllowDuplicatesKey:@YES};
    [baby setBabyOptionsWithScanForPeripheralsWithOptions:scanForPeripheralsWithOptions connectPeripheralWithOptions:nil scanForPeripheralsWithServices:nil discoverWithServices:nil discoverWithCharacteristics:nil];
}
//插入table数据
-(void)insertTableView:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI{
    
    NSArray *peripherals = [datas valueForKey:@"peripheral"];
    if(![peripherals containsObject:peripheral]) {
        NSMutableArray *indexPaths = [[NSMutableArray alloc] init];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:peripherals.count inSection:0];
        [indexPaths addObject:indexPath];
        
        NSMutableDictionary *item = [[NSMutableDictionary alloc] init];
        [item setValue:peripheral forKey:@"peripheral"];
        [item setValue:RSSI forKey:@"RSSI"];
        [item setValue:advertisementData forKey:@"advertisementData"];
        NSLog(@"peripheral = %@",peripheral.name);
        NSLog(@"advertisementData = %@",advertisementData);
        
        [datas addObject:item];
        [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
    }
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
                   NSLog(@"data = %@",datas);
                   if (data) {
                       
                   }
                   
               }];
    });
}

//发送数据

-(void)writeWithCmdid:(Byte)cmdid dataString:(NSString *)dataString{
    
    [self.peripheral writeValue:[Pack packetWithCmdid:cmdid
                                          dataEnabled:YES
                                                 data:[self convertHexStrToData:dataString]]
              forCharacteristic:self.sendCharacteristic
                           type:CBCharacteristicWriteWithResponse];
}

//大端
-(NSData *) convertHexStrToData:(NSString *)hexString {
    NSMutableData* data = [NSMutableData data];
    int idx;
    for (idx = 0; idx+2 <= hexString.length; idx+=2) {
        NSRange range = NSMakeRange(idx, 2);
        NSString* hexStr = [hexString substringWithRange:range];
        NSScanner* scanner = [NSScanner scannerWithString:hexStr];
        unsigned int intValue;
        [scanner scanHexInt:&intValue];
        [data appendBytes:&intValue length:1];
    }
    return data;
}

-(void)askForDeviceState {
    
    [self writeWithCmdid:CMDID_DEVICE_TYPE dataString:nil];
}

-(void)BleBeep{
    [self writeWithCmdid:CMDID_CHANGE_STATE dataString:nil];
}


#pragma mark - action
- (void)scanAction:(id)sender {
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

-(void)ring:(UIButton *)button{
    if (!isLocalDeviceList) {
        AddDeviceCell *cell = (AddDeviceCell *)[[button superview]superview];
        
        NSString *cpuid = cell.ringButton.titleLabel.text;
        
        
        [[NetWorkTool sharedNetWorkTool]POST:[HTTPServerURLString stringByAppendingString:@"Api/OnlineDevice/Beep"]
                                      params:@{
                                               @"cpuid":cpuid
                                               }
                                    hasToken:YES success:^(HttpResponse *responseObject) {
                                        if ([responseObject.result intValue]!=1) {
                                            [SVProgressHUD showErrorWithStatus:responseObject.errorString];
                                        }
                                    } failure:nil];
    }
}

-(void)localRing:(UIButton *)button{
    
    
    AddDeviceCell *cell = (AddDeviceCell *)[[button superview]superview];
    
    NSInteger interger = [self.tableView.visibleCells indexOfObject:cell];
    
    NSDictionary *item = [datas objectAtIndex:interger];
    
    CBPeripheral *peripheral = [item objectForKey:@"peripheral"];
    
    self.peripheral = peripheral;
    
    //开始连接设备
 baby.having(self.peripheral).connectToPeripherals().discoverServices().discoverCharacteristics().readValueForCharacteristic().discoverDescriptorsForCharacteristic().readValueForDescriptors().begin();

}

- (IBAction)saveAll:(id)sender {
    
    NSArray *cells = self.tableView.visibleCells;
    NSMutableArray *saveArray = [NSMutableArray array];
    NSString *api;
    if (isLocalDeviceList) {
        api = @"Api/LocalDevice/registered";
    }else{
        api = @"Api/OnlineDevice/registered";
    }
    if ([cells count]>0) {
        for (AddDeviceCell *cell in cells) {
            
            //序列号输入了才录入
            if (cell.serialNumTextField.text.length>0 ) {

                NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithCapacity:20];

                if (isLocalDeviceList) {
                    [dic setObject:@"900C84002DC2" forKey:@"cpuid"];
                    [dic setObject:[NSNumber numberWithInteger:57119] forKey:@"machinetype"];
                
                }else{
                    [dic setObject:cell.ringButton.titleLabel.text forKey:@"cpuid"];
                }

                if ([cell.nameTextField.text length]>0) {
                    [dic setObject:cell.nameTextField.text forKey:@"nick"];
                }
                
                [dic setObject:cell.serialNumTextField.text forKey:@"serialnum"];
                
                //保存的数组
                [saveArray addObject:dic];
            }
        }
    }
    NSLog(@"send to server -----------add device array :%@",saveArray);
    
    [self registerDeviceWithApi:api saveArray:saveArray];

}
-(void)registerDeviceWithApi:(NSString *)api saveArray:(NSMutableArray *)saveArray{
    
    if ([saveArray count]>0) {
        
        NSDictionary *param = [saveArray lastObject];
        [[NetWorkTool sharedNetWorkTool]POST:[HTTPServerURLString stringByAppendingString:api]
                                      params:param
                                    hasToken:YES
                                     success:^(HttpResponse *responseObject) {
                                         if ([responseObject.result intValue] == 1) {
                                             [SVProgressHUD showSuccessWithStatus:@"录入成功"];
                                             
                                             [saveArray removeLastObject];
                                             
                                             if ([saveArray count] == 0) {
                                                 [self refresh];
                                             }
                                             else{
                                                 [self registerDeviceWithApi:api saveArray:saveArray];
                                             }

                                         }else{
                                             [SVProgressHUD showErrorWithStatus:responseObject.errorString];
                                         }
                                     }
                                     failure:nil];
    }
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


#pragma mark - QRCodeReader Delegate Methods
- (void)reader:(QRCodeReaderViewController *)reader didScanResult:(NSString *)result
{
    [self dismissViewControllerAnimated:YES completion:^{
        if (![self checkSerailNum:result]) {
            [SVProgressHUD showErrorWithStatus:@"请扫描有效序列号"];
        }else{
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.selectedRow inSection:0];
            AddDeviceCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
            cell.serialNumTextField.text = result;
        }

    }];
}

- (void)readerDidCancel:(QRCodeReaderViewController *)reader
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (IBAction)backToDeviceList:(id)sender {
    [self.navigationController popViewControllerAnimated:NO];
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
    AddDeviceCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    if (cell == nil) {
        cell = [[AddDeviceCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    cell.nameTextField.delegate = self;
    if ([datas count]>0) {
        self.tableView.tableHeaderView.hidden = NO;
    }else{
        self.tableView.tableHeaderView.hidden = YES;
    }
    //wifi设备
    if (!isLocalDeviceList) {
        
        if([datas count]>0){
            NSDictionary *dataDic = [datas objectAtIndex:indexPath.row];
            
            [cell.ringButton setTitle:[dataDic objectForKey:@"cpuid"] forState:UIControlStateNormal];
            [cell.ringButton addTarget:self action:@selector(ring:) forControlEvents:UIControlEventTouchUpInside];
            cell.nameTextField.text = @"";
            NSString *serialNum = [dataDic objectForKey:@"serialnum"];
            if ([serialNum isEqual:[NSNull null]]) {
                cell.serialNumTextField.text = @"";
            }
        }
    }
    else{
        //蓝牙设备
        if([datas count]>0){
            NSDictionary *item = [datas objectAtIndex:indexPath.row];
            
            CBPeripheral *peripheral = [item objectForKey:@"peripheral"];
            if (peripheral) {
                NSDictionary *advertisementData = [item objectForKey:@"advertisementData"];
                cell.nameTextField.text = peripheral.name;
                
                //BLE的mac地址
                NSData *data = (NSData *)[advertisementData objectForKey:@"kCBAdvDataManufacturerData"];
                NSMutableArray *array = [NSMutableArray arrayWithCapacity:20];
                if (data) {
                    Byte *dataByte = (Byte *)[data bytes];
                    for (int i =0 ; i < 6; i++) {
                        [array addObject:[NSString stringWithFormat:@"%x",dataByte[i]]];
                    }
                }
                NSString *mac = [array componentsJoinedByString:@""];
                
                
                if(!data) {
                    [cell.ringButton setTitle:peripheral.identifier.UUIDString forState:UIControlStateNormal];
                    NSLog(@"uuid = %@",peripheral.identifier.UUIDString);
                }else {
                    [cell.ringButton setTitle:mac forState:UIControlStateNormal];
                }
                
                [cell.ringButton addTarget:self action:@selector(localRing:) forControlEvents:UIControlEventTouchUpInside];
        }

        }
    }

    
    [cell.scanButton addTarget:self action:@selector(scanAction:) forControlEvents:UIControlEventTouchUpInside];
    cell.scanButton.tag = indexPath.row;

    return cell;
}

-(NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [self.tableView endEditing:YES];
    return indexPath;
}

- (BOOL)checkSerailNum:(NSString *)inputString {
    if (inputString.length == 0) return NO;
    NSString *regex =@"^[A-Z]{1}[A-Z0-9]{3}\\d{2}[A-C1-9]{1}[A-Z0-9]{1}\\d{4}$";
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"SELF MATCHES %@",regex];
    return [pred evaluateWithObject:inputString];
}

@end
