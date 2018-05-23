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
#import "MJChiBaoZiHeader.h"

#define SERVICE_UUID           @"1b7e8251-2877-41c3-b46e-cf057c562023"
#define TX_CHARACTERISTIC_UUID @"5e9bf2a8-f93f-4481-a67e-3b2f4a07891a"
#define RX_CHARACTERISTIC_UUID @"8ac32d3f-5cb9-4d44-bec2-ee689169f626"

typedef NS_ENUM(NSUInteger,typeTags)
{
    electrotherapyTag = 1000,airProTag = 1001,aladdinTag = 1002,LightTag = 1003
};
@interface AddDeviceViewController ()<QRCodeReaderDelegate,UITextFieldDelegate>{
    int page;
    int totalPage;  //总页数
    BOOL isRefreshing; //是否正在下拉刷新或者上拉加载
}

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *contentView;

//条形码扫描
@property (strong,nonatomic) QRCodeReaderViewController *reader;
@property (assign,nonatomic) NSInteger selectedDeviceTag;
@property (assign,nonatomic) NSInteger selectedRow;

@property (strong, nonatomic)MBProgressHUD * HUD;

@property (strong ,nonatomic) CBPeripheral *peripheral;
@property (nonatomic,strong) CBCharacteristic *sendCharacteristic;
@property (nonatomic,strong) CBCharacteristic *receiveCharacteristic;

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
    
    //默认选中电疗设备
    UIButton *btn = (UIButton *)[self.contentView viewWithTag:electrotherapyTag];
    [self changeDevice:btn];
    //非本地设备
    isLocalDeviceList = NO;
    
    self.tableView.tableFooterView = [[UIView alloc]init];

    datas = [[NSMutableArray alloc]initWithCapacity:20];

    [self initTableHeaderAndFooter];
    
}
#pragma mark - refresh

-(void)initTableHeaderAndFooter{
    
    //下拉刷新

    MJRefreshNormalHeader *header = [MJRefreshNormalHeader headerWithRefreshingTarget:self refreshingAction:@selector(refresh)];
    [header setTitle:@"下拉刷新" forState:MJRefreshStateIdle];
    [header setTitle:@"松开更新" forState:MJRefreshStatePulling];
    [header setTitle:@"加载中..." forState:MJRefreshStateRefreshing];
    
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
    
    if (!isLocalDeviceList) {
        datas = [[NSMutableArray alloc]initWithCapacity:20];
        NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:20];
        
        switch (self.selectedDeviceTag) {
            case electrotherapyTag:
                
                [params setObject:[NSNumber numberWithInt:56832] forKey:@"machinetype"];
                
                break;
            case airProTag:
                
                [params setObject:[NSNumber numberWithInt:7681] forKey:@"machinetype"];
                break;
            case LightTag:
                [params setObject:@61184 forKey:@"machinetype"];
                break;
            default:
                break;
        }
        [params setObject:[NSNumber numberWithInt:0] forKey:@"isregistered"];
        
        [[NetWorkTool sharedNetWorkTool]POST:[HTTPServerURLString stringByAppendingString:@"Api/OnlineDevice/ListOnlineCount"]
                                      params:params
                                    hasToken:YES
                                     success:^(HttpResponse *responseObject) {

                                         if ([responseObject.result intValue] == 1) {
                                             NSString *count = responseObject.content[@"count"];
                                             NSLog(@"count = %@",count);
                                             
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

                                             }else{
                                                 [datas removeAllObjects];
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
    
    switch (self.selectedDeviceTag) {
        case electrotherapyTag:
            
            [mutableParam setObject:[NSNumber numberWithInt:56832] forKey:@"machinetype"];
            
            break;
        case airProTag:
            
            [mutableParam setObject:[NSNumber numberWithInt:7681] forKey:@"machinetype"];
            
        default:
            break;
    }
    
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

#pragma mark - changeDevice

- (IBAction)changeDevice:(UIButton *)sender {
    
    self.selectedDeviceTag = [sender tag];

    for (int i = electrotherapyTag; i<electrotherapyTag +4; i++) {
        UIButton *btn = (UIButton *)[self.contentView viewWithTag:i];
        //配置选中按钮
        if ([btn tag] == [(UIButton *)sender tag]) {
            btn.backgroundColor = UIColorFromHex(0x37bd9c);
            [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        }else{
            btn.backgroundColor = [UIColor whiteColor];
            [btn setTitleColor:UIColorFromHex(0x212121) forState:UIControlStateNormal];
        }
    }
    
    //选中蓝牙设备
    if (self.selectedDeviceTag == aladdinTag) {
        
        isLocalDeviceList = YES;
        
        datas = [[NSMutableArray alloc]initWithCapacity:20];
        
        baby = [BabyBluetooth shareBabyBluetooth];
        [self babyDelegate];
        baby.scanForPeripherals().begin();
        
        self.tableView.mj_header = nil;
        self.tableView.mj_footer = nil;

    }else {

        [baby cancelScan];
        [baby cancelAllPeripheralsConnection];
        
        isLocalDeviceList = NO;
        [self initTableHeaderAndFooter];
        
    }
    [self.tableView reloadData];
}




#pragma mark - BLE
-(void)babyDelegate {
    __weak typeof(self) weakSelf = self;
    __weak typeof(BabyBluetooth*) weakBaby = baby;
    [baby setBlockOnCentralManagerDidUpdateState:^(CBCentralManager *central) {
        if (central.state == CBManagerStatePoweredOff) {
            if (weakSelf.view) {
                weakSelf.HUD = [MBProgressHUD showHUDAddedTo:weakSelf.view animated:YES];
                weakSelf.HUD.mode = MBProgressHUDModeText;
                weakSelf.HUD.label.text = @"该设备尚未打开蓝牙,请在设置中打开";
                [weakSelf.HUD showAnimated:YES];
            }
        }else if(central.state == CBManagerStatePoweredOn) {
            if(weakSelf.HUD){
                [MBProgressHUD hideHUDForView:weakSelf.view animated:YES];
                weakBaby.scanForPeripherals().begin();
            }
            
        }
    }];
    
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
                    [weakSelf BleBeep];
                }
                
            }
        }
        
    }];
    
    [baby setBlockOnDiscoverToPeripherals:^(CBCentralManager *central, CBPeripheral *peripheral, NSDictionary *advertisementData, NSNumber *RSSI) {
        [weakSelf insertTableView:peripheral advertisementData:advertisementData RSSI:RSSI];
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
//                NSDictionary  *param = (NSDictionary *)dic;
//
//                [[NetWorkTool sharedNetWorkTool]POST:[HTTPServerURLString stringByAppendingString:api]
//                                              params:param
//                                            hasToken:YES
//                                             success:^(HttpResponse *responseObject) {
//                                                 if ([responseObject.result intValue] == 1) {
//                                                     [SVProgressHUD setMaximumDismissTimeInterval:0.5];
//                                                     [SVProgressHUD setSuccessImage:[UIImage imageNamed:@""]];
//                                                     [SVProgressHUD showSuccessWithStatus:@"录入成功"];
//                                                     [self refresh];
//                                                 }else{
//                                                     [SVProgressHUD showErrorWithStatus:responseObject.errorString];
//                                                 }
//                                             }
//                                             failure:nil];
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
