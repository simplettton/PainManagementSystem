//
//  FocusDeviceViewController.m
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/4/4.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import "FocusDeviceViewController.h"

@interface FocusDeviceViewController ()

@property (weak, nonatomic) IBOutlet UIButton *allTabButton;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) IBOutlet UIView *deviceBackgroundView;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

//下拉框
@property (strong,nonatomic)HHDropDownList *dropList;
@property (strong, nonatomic) NSArray *dropListArray;
//长按view抖动
@property (strong, nonatomic)UILongPressGestureRecognizer *longPress;

//蓝牙设备
@property (strong ,nonatomic) CBPeripheral *peripheral;
@property (nonatomic,strong) CBCharacteristic *sendCharacteristic;
@property (nonatomic,strong) CBCharacteristic *receiveCharacteristic;
@property (nonatomic,strong) NSString *BLEDeviceName;
@property (nonatomic,assign)NSInteger selectedDeviceIndex;

@end

@implementation FocusDeviceViewController
{
    BabyBluetooth *baby;
    NSMutableArray *datas;
    BOOL isLocalDeviceList;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initUI];

}
-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:YES];
    
}
-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:YES];
    [baby cancelScan];
    [baby cancelAllPeripheralsConnection];
    [self.HUD hideAnimated:YES];
}

-(void)initUI{
    
    if (self.isInAllTab) {
        //隐藏本地设备
        self.allTabButton.hidden = NO;
        self.segmentedControl.hidden = YES;
    }else{
        self.allTabButton.hidden = YES;
        self.segmentedControl.hidden = NO;
    }
    
    //配置searchbar样式
    self.searchBar.delegate = self;
    self.searchBar.backgroundImage = [[UIImage alloc]init];//去除边框线
    
    self.searchBar.tintColor = UIColorFromHex(0x5E97FE);//出现光标
    //通过KVC获得到UISearchBar的私有变量
    //searchField
    UITextField *searchField = [self.searchBar valueForKey:@"searchField"];
    if (searchField) {
        [searchField setBackgroundColor:[UIColor whiteColor]];
        searchField.font = [UIFont systemFontOfSize:14.0f];
        searchField.layer.cornerRadius = 5.0f;
        searchField.layer.borderColor = UIColorFromHex(0xBBBBBB).CGColor;
        searchField.layer.borderWidth = 1;
        searchField.layer.masksToBounds = YES;
    }
    
    //设备外框边框设置
    self.deviceBackgroundView.layer.borderColor = UIColorFromHex(0xbbbbbb).CGColor;
    self.deviceBackgroundView.layer.borderWidth = 0.5f;
    [self.deviceBackgroundView.layer setMasksToBounds:YES];
    
    //UICollectionView 配置
//    [self.collectionView registerClass:[DeviceCollectionViewCell class] forCellWithReuseIdentifier:@"Cell"];
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    
    //数据源
    NSArray *dataArray = [[NSArray alloc]init];
    if (self.isInAllTab) {
        dataArray = @[@{@"state":@"running"},
                      @{@"state":@"stop"},
                      @{@"state":@"pause"},
                      @{@"state":@"alert"},
                      @{@"state":@"running"},
                      @{@"state":@"stop"},
                      @{@"state":@"pause"},
                      @{@"state":@"running"},
                      @{@"state":@"alert"}];
    }else{
        dataArray = @[@{@"state":@"running",@"serialnum":@"1234567"},
                      @{@"state":@"stop",@"serialnum":@"1234256"},
                      @{@"state":@"pause",@"serialnum":@"4334567"},
                      @{@"state":@"alert",@"serialnum":@"2222267"},
                      @{@"state":@"running",@"serialnum":@"16844567"},
                      @{@"state":@"running",@"serialnum":@"12345600"},
                      @{@"state":@"stop",@"serialnum":@"1234200"},
                      @{@"state":@"pause",@"serialnum":@"43300567"},
                      @{@"state":@"alert",@"serialnum":@"22200267"},
                      @{@"state":@"running",@"serialnum":@"1684007"},
                      @{@"state":@"running",@"serialnum":@"1134567"},
                      @{@"state":@"stop",@"serialnum":@"1134256"},
                      @{@"state":@"pause",@"serialnum":@"1134567"},
                      @{@"state":@"alert",@"serialnum":@"1122267"},
                      @{@"state":@"running",@"serialnum":@"11844567"}];
    }
    datas = [dataArray mutableCopy];
    
    
    //seguement 在线或者本地
    self.segmentedControl.frame = CGRectMake(28, 75, 200, 35);
    
    [self.segmentedControl setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}forState:UIControlStateSelected];
    
    [self.segmentedControl setTitleTextAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:15.0f]}forState:UIControlStateNormal];
    
    [self.segmentedControl addTarget:self action:@selector(didClicksegmentedControlAction:) forControlEvents:UIControlEventValueChanged];
    
    //默认是在线设备
    isLocalDeviceList = NO;
    
    //下拉框
    [self.deviceBackgroundView addSubview:self.dropList];
    NSArray *array_1 = @[@"所有设备", @"治疗中设备", @"异常设备", @"其他设备"];
    self.dropListArray = array_1;

    [self.dropList reloadListData];
    
    //关注中设备添加 longpress 添加手势 可以取消设备
    if (!self.isInAllTab) {
        _longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(lonePressMoving:)];
        [self.collectionView addGestureRecognizer:_longPress];
    }
    
    
}

- (void)lonePressMoving:(UILongPressGestureRecognizer *)longPress
{
    switch (_longPress.state) {
        case UIGestureRecognizerStateBegan: {
            {
                NSIndexPath *selectIndexPath = [self.collectionView indexPathForItemAtPoint:[_longPress locationInView:self.collectionView]];
                
                if (selectIndexPath == nil) {
                    break;
                }
                
                // 找到当前的cell
                DeviceCollectionViewCell *cell = (DeviceCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:selectIndexPath];
                // 定义cell的时候btn是隐藏的, 在这里设置为NO
                [cell.btnDelete setHidden:NO];

                cell.btnDelete.tag = selectIndexPath.item;
                NSLog(@"selectIndexPath .item = %ld",(long)cell.btnDelete.tag);
                
                //添加删除的点击事件
                [cell.btnDelete addTarget:self action:@selector(unfollowDevice:) forControlEvents:UIControlEventTouchUpInside];

                [_collectionView beginInteractiveMovementForItemAtIndexPath:selectIndexPath];
                
                
                //cell.layer添加抖动手势
                for (DeviceCollectionViewCell *cell in [self.collectionView visibleCells]) {
                    [self starShake:cell];
                }
                
            }
            break;
        }
        case UIGestureRecognizerStateChanged: {
            [self.collectionView updateInteractiveMovementTargetPosition:[longPress locationInView:_longPress.view]];
            break;
        }
        case UIGestureRecognizerStateEnded: {
            [self.collectionView endInteractiveMovement];
            //cell.layer移除抖动手势
//            for (DeviceCollectionViewCell *cell in [self.collectionView visibleCells]) {
//                [self stopShake:cell];
//            }

            break;
        }
        default: [self.collectionView cancelInteractiveMovement];
            break;
    }
}

-(HHDropDownList *)dropList{
    if (!_dropList) {
        //配置dropList
        _dropList = [[HHDropDownList alloc]initWithFrame:CGRectMake(8, 14, List_Width, 35)];
        
        [_dropList setBackgroundColor:[UIColor colorWithRed:249/255.0 green:249/255.0 blue:249/255.0 alpha:1.0]];
        [_dropList setHighlightColor:[UIColor colorWithRed:46/255.0 green:163/255.0 blue:230/255.0 alpha:0.5]];
        [_dropList setDelegate:self];
        [_dropList setDataSource:self];
        
        [_dropList setIsExclusive:YES];
        [_dropList setHaveBorderLine:YES];

    }
    return _dropList;
}
-(void)didClicksegmentedControlAction:(UISegmentedControl *)segmentedControl{
    
    NSInteger Index = segmentedControl.selectedSegmentIndex;
    NSArray *dataArray = [[NSArray alloc]init];
    switch (Index) {
        case DeviceTypeOnline:
        {
            NSLog(@"切换在线设备");
            isLocalDeviceList = NO;
            
            dataArray = @[@{@"state":@"running",@"serialnum":@"1234567"},
                          @{@"state":@"stop",@"serialnum":@"1234256"},
                          @{@"state":@"pause",@"serialnum":@"4334567"},
                          @{@"state":@"alert",@"serialnum":@"2222267"},
                          @{@"state":@"running",@"serialnum":@"16844567"},
                          @{@"state":@"running",@"serialnum":@"12345600"},
                          @{@"state":@"stop",@"serialnum":@"1234200"},
                          @{@"state":@"pause",@"serialnum":@"43300567"},
                          @{@"state":@"alert",@"serialnum":@"22200267"},
                          @{@"state":@"running",@"serialnum":@"1684007"},
                          @{@"state":@"running",@"serialnum":@"1134567"},
                          @{@"state":@"stop",@"serialnum":@"1134256"},
                          @{@"state":@"pause",@"serialnum":@"1134567"},
                          @{@"state":@"alert",@"serialnum":@"1122267"},
                          @{@"state":@"running",@"serialnum":@"11844567"}];
            
            self.dropList.hidden = NO;
            
            [baby cancelScan];
            [baby cancelAllPeripheralsConnection];
            [self.HUD hideAnimated:YES];
        
        }
            
            break;
        case DeviceTypeLocal:
        {
            NSLog(@"切换本地设备");
            isLocalDeviceList = YES;
            
//            dataArray = @[@{@"state":@"connect",@"serialnum":@"1234567"},
//                          @{@"state":@"unconnect",@"serialnum":@"1234256"},
//                          @{@"state":@"unconnect",@"serialnum":@"223567"},
//                          @{@"state":@"unconnect",@"serialnum":@"2232267"}];
            
            dataArray = @[@{@"state":@"unconnect",@"serialnum":@"ALX420"}];

            [self.dropList pullBack];
            self.dropList.hidden = YES;
        }
            break;
            
        default:
            break;
    }

    datas = [dataArray mutableCopy];
    [self.collectionView reloadData];
}



#pragma mark - CollectionViewDelegate
-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return [datas count];
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{

    static NSString *CellIdentifier;
    
    DeviceCollectionViewCell *cell;
    
    if (!isLocalDeviceList) {
        CellIdentifier = @"Cell";
        
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
        
        NSDictionary *dic = [datas objectAtIndex:indexPath.row];
        
        NSString *state = [dic objectForKey:@"state"];
        
        NSDictionary *stateDic = @
        {@"running":[NSNumber numberWithInteger:CellStyleGreen_MachineRunning],
            @"stop":[NSNumber numberWithInteger:CellStyleGrey_MachineStop],
            @"pause":[NSNumber numberWithInteger:CellStyleGrey_MachinePause],
            @"alert":[NSNumber numberWithInteger:CellStyleOrange_MachineException],
            @"connect":[NSNumber numberWithInteger:CellStyle_LocalConnect],
            @"running":[NSNumber numberWithInteger:CellStyle_LocalRunning],
            @"unrunning":[NSNumber numberWithInteger:CellStyle_LocalUnrunning],
            @"unconnect":[NSNumber numberWithInteger:CellStyle_LocalUnconnect]
        };
        
        NSNumber *stateNumber = [stateDic objectForKey:state];
        [cell configureWithStyle:[stateNumber intValue]];
        
        //按钮操作
        switch (cell.style) {
            case CellStyleGrey_MachineStop:
                [cell.remarkButton addTarget:self action:@selector(goToRemarkVAS:) forControlEvents:UIControlEventTouchUpInside];
                break;
            case CellStyleGrey_MachinePause:
                [cell.playButton addTarget:self action:@selector(playAction:) forControlEvents:UIControlEventTouchUpInside];
                break;
            case CellStyleGreen_MachineRunning:
                [cell.leftButton addTarget:self action:@selector(pauseAction:) forControlEvents:UIControlEventTouchUpInside];
                [cell.rightButton addTarget:self action:@selector(stopAction:) forControlEvents:UIControlEventTouchUpInside];
                break;
                
            default:
                break;
        }
    }else{
    
        CellIdentifier = @"LocalDeviceCell";
        
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
        
        NSDictionary *dic = [datas objectAtIndex:indexPath.row];
        
        NSString *state = [dic objectForKey:@"state"];
        
        NSDictionary *stateDic = @
        {
            @"connected":[NSNumber numberWithInteger:CellStyle_LocalConnect],
            @"unconnect":[NSNumber numberWithInteger:CellStyle_LocalUnconnect],
            @"running":[NSNumber numberWithInteger:CellStyle_LocalRunning],
            @"unrunning":[NSNumber numberWithInteger:CellStyle_LocalUnrunning],
        };
        
        NSNumber *stateNumber = [stateDic objectForKey:state];
        
        [cell configureWithStyle:[stateNumber intValue]];

        [cell.remarkButton addTarget:self action:@selector(goToRemarkVAS:) forControlEvents:UIControlEventTouchUpInside];
        [cell.connectButton addTarget:self action:@selector(BLEConnectDevice:) forControlEvents:UIControlEventTouchUpInside];
        [cell.BLEPlayButton addTarget:self action:@selector(play:) forControlEvents:UIControlEventTouchUpInside];
        [cell.BLEPauseButton addTarget:self action:@selector(pause:) forControlEvents:UIControlEventTouchUpInside];
        [cell.BLEStopButton addTarget:self action:@selector(stop:) forControlEvents:UIControlEventTouchUpInside];
        
}
 
    if (cell == nil) {
        cell = [[DeviceCollectionViewCell alloc]init];
    }
    cell.btnDelete.hidden = YES;
    
    return cell;
}

-(BOOL)collectionView:(UICollectionView *)collectionView canMoveItemAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

//4.移动完成后的方法  －－ 交换数据
-(void)collectionView:(UICollectionView *)collectionView moveItemAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
    //    [datas exchangeObjectAtIndex:sourceIndexPath.row withObjectAtIndex:destinationIndexPath.row];
    //    NSLog(@"data = %@",datas);
    NSIndexPath *selectIndexPath = [self.collectionView indexPathForItemAtPoint:[_longPress locationInView:self.collectionView]];
    // 找到当前的cell
    DeviceCollectionViewCell *cell = (DeviceCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:selectIndexPath];
    
    //取出源item数据
    id objc = [datas objectAtIndex:sourceIndexPath.item];
    //从资源数组中移除该数据
    [datas removeObject:objc];
    //将数据插入到资源数组中的目标位置上
    [datas insertObject:objc atIndex:destinationIndexPath.item];
    [self.collectionView reloadData];
    
}
// 允许选中时，高亮
-(BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath{
    return YES;
}
// 设置是否允许选中
- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"%s", __FUNCTION__);
    //cell.layer移除抖动手势
    for (DeviceCollectionViewCell *cell in [self.collectionView visibleCells]) {
        [self stopShake:cell];
    }
    [collectionView reloadData];
    
    return YES;
}

//选中后回调
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    DeviceCollectionViewCell *cell = (DeviceCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
    
}
//设置每个item的尺寸
-(CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
    return CGSizeMake(220, 186);
}

////设置每个item的UIEdgeInsets
//- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
//{
//    return UIEdgeInsetsMake(10, 10, 10, 10);
//}

//设置每个item水平间距
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    return 5;
}


//设置每个item垂直间距
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    return 40;
}


- (void)starShake:(DeviceCollectionViewCell*)cell{
    
    CAKeyframeAnimation * keyAnimaion = [CAKeyframeAnimation animation];
    keyAnimaion.keyPath = @"transform.rotation";
    keyAnimaion.values = @[@(-3 / 180.0 * M_PI),@(3 /180.0 * M_PI),@(-3/ 180.0 * M_PI)];//度数转弧度
    keyAnimaion.removedOnCompletion = NO;
    keyAnimaion.fillMode = kCAFillModeForwards;
    keyAnimaion.duration = 0.3;
    keyAnimaion.repeatCount = MAXFLOAT;
    [cell.layer addAnimation:keyAnimaion forKey:@"cellShake"];
}

- (void)stopShake:(DeviceCollectionViewCell*)cell{
    [cell.layer removeAnimationForKey:@"cellShake"];
}

//删除代码
- (void)unfollowDevice:(UIButton *)btn{
    //cell的隐藏删除设置
    NSIndexPath *selectIndexPath = [self.collectionView indexPathForItemAtPoint:[_longPress locationInView:self.collectionView]];
    // 找到当前的cell
    __block DeviceCollectionViewCell *cell = (DeviceCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:selectIndexPath];
    cell.btnDelete.hidden = NO;
    
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"要取消关注设备吗？"
                                                                   message:@"取消关注操作将不可恢复。"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {
                                                              [self.collectionView reloadData];
                                                              
                                                              for (DeviceCollectionViewCell *cell in [self.collectionView visibleCells]) {
                                                                  [self stopShake:cell];
                                                              }
                                                          }];
    
    UIAlertAction* cancelFocusAction = [UIAlertAction actionWithTitle:@"取消关注" style:UIAlertActionStyleDestructive
                                                              handler:^(UIAlertAction * action) {
                                                                  //取出源item数据
                                                                  id objc = [datas objectAtIndex:btn.tag];
                                                                  //从资源数组中移除该数据
                                                                  [datas removeObject:objc];
                                                                  [self.collectionView reloadData];
                                                                  
                                                                  
                                                                  for (DeviceCollectionViewCell *cell in [self.collectionView visibleCells]) {
                                                                      [self stopShake:cell];
                                                                  }
                                                              }];
    
    [alert addAction:defaultAction];
    
    [alert addAction:cancelFocusAction];
    
    [self presentViewController:alert animated:YES completion:nil];
    
    
}


#pragma mark http control machine

-(void)playAction:(UIButton *)button{
    
    DeviceCollectionViewCell *deviceCell = (DeviceCollectionViewCell *)[button superview];
    
    NSInteger interger = [self.collectionView.visibleCells indexOfObject:deviceCell];

}
-(void)stopAction:(UIButton *)button{
    NSLog(@"停止治疗");
    
}
-(void)pauseAction:(UIButton *)button{
    NSLog(@"暂停治疗");
}

-(void)controlMahine:(NSString *)serialnum cmdcode:(int)cmdcode
{
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc]init];
    
    [params setObject:serialnum forKey:@"cpuid"];
    
    [params setObject:[NSNumber numberWithInt:cmdcode] forKey:@"cmdcode"];
    
    [[NetWorkTool sharedNetWorkTool]POST:[HTTPServerURLString stringByAppendingString:@"Api/OnlineDevice/Control"]
                                 params:params
                               hasToken:YES
                                success:^(HttpResponse *responseObject) {
                                    
                                }
                                failure:nil];
}

-(void)goToRemarkVAS:(UIButton *)button{
    [self performSegueWithIdentifier:@"GoToRemarkVAS" sender:button];
    NSLog(@"vas评分");
}


- (IBAction)search:(id)sender {
    
    [self writeWithCmdid:CMDID_SEND_PARAMETER dataString:@"0f03"];
    
    [FocusMachineAlertView alertControllerAboveIn:self withDataDic:nil returnBlock:^{
        
    }];
}
#pragma mark - BLE
-(void)BLEConnectDevice:(UIButton *)button{
    
    DeviceCollectionViewCell *deviceCell = (DeviceCollectionViewCell *)[[button superview]superview];
    
    NSInteger interger = [self.collectionView.visibleCells indexOfObject:deviceCell];
    
    self.selectedDeviceIndex = interger;
    
    NSDictionary *machineDic = [datas objectAtIndex:interger];
    
    NSString *name = machineDic[@"serialnum"];
    
    self.BLEDeviceName = name;
    
    baby = [BabyBluetooth shareBabyBluetooth];
    [self babyDelegate];
    baby.scanForPeripherals().begin();
    
    //连接中状态指示
    _HUD = [MBProgressHUD showHUDAddedTo:deviceCell animated:YES];
    
    
    

}
-(void)babyDelegate{
    __weak typeof(self) weakSelf = self;
    __weak typeof(BabyBluetooth*) weakBaby = baby;
    __weak typeof(NSMutableArray *)weakDatas = datas;
    
    
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
        
        NSLog(@"连接成功");
        [weakSelf sendMachineStateRequest];
        
//        [weakSelf.HUD hideAnimated:YES];
//
//        NSMutableDictionary *machineDic = [[weakDatas objectAtIndex:weakSelf.selectedDeviceIndex]mutableCopy];
//        [weakDatas removeObject:machineDic];
//
//        [machineDic setValue:@"connected" forKey:@"state"];
//
//        [weakDatas insertObject:machineDic atIndex:weakSelf.selectedDeviceIndex];
//
//        [weakSelf.collectionView reloadData];
        
        
    }];
    
    [baby setBlockOnDisconnect:^(CBCentralManager *central, CBPeripheral *peripheral, NSError *error) {
        NSLog(@"断开连接");
        
        [weakSelf.HUD hideAnimated:YES];
        
        NSMutableDictionary *machineDic = [[weakDatas objectAtIndex:weakSelf.selectedDeviceIndex]mutableCopy];
        [weakDatas removeObject:machineDic];
        
        [machineDic setValue:@"unconnect" forKey:@"state"];
        
        [weakDatas insertObject:machineDic atIndex:weakSelf.selectedDeviceIndex];
        
        [weakSelf.collectionView reloadData];
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
                    [weakSelf sendMachineStateRequest];
                    
                    
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
        
        if (cmdid == CMDID_CHANGE_STATE) {
            
            [self.HUD hideAnimated:YES];
            
            NSString *stateKey = [NSString stringWithFormat:@"%d",dataByte];
            
            NSDictionary *typeDic = @{@"1":@"unrunning",
                                      @"2":@"running",
                                      @"3":@"unrunning"
                                      };
            
            NSMutableDictionary *machineDic = [[datas objectAtIndex:self.selectedDeviceIndex]mutableCopy];
            
            [datas removeObject:machineDic];
            
            [machineDic setValue:typeDic[stateKey] forKey:@"state"];
            
            [datas insertObject:machineDic atIndex:self.selectedDeviceIndex];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.collectionView reloadData];
            });

        }
        
    }
}

//发送数据

-(void)writeWithCmdid:(Byte)cmdid dataString:(NSString *)dataString{
    
    if (self.sendCharacteristic) {
        [self.peripheral writeValue:[Pack packetWithCmdid:cmdid
                                              dataEnabled:YES
                                                     data:[self convertHexStrToData:dataString]]
                  forCharacteristic:self.sendCharacteristic
                               type:CBCharacteristicWriteWithResponse];
    }

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

-(void)play:(UIButton *)button{
    [self writeWithCmdid:CMDID_CHANGE_STATE dataString:@"0002"];
}
-(void)pause:(UIButton *)button{
    [self writeWithCmdid:CMDID_CHANGE_STATE dataString:@"0003"];
}
-(void)stop:(UIButton *)button{
    [self writeWithCmdid:CMDID_CHANGE_STATE dataString:@"0001"];
}

-(void)sendMachineStateRequest{
    [self writeWithCmdid:CMDID_UPDATE_DATA_REQUEST dataString:nil];
}


#pragma mark - HHDropDownListDataSource-delegate
- (NSArray *)listDataForDropDownList:(HHDropDownList *)dropDownList {
    
    return _dropListArray;
}
- (void)dropDownList:(HHDropDownList *)dropDownList didSelectItemName:(NSString *)itemName atIndex:(NSInteger)index {
    NSLog(@"筛选设备%ld:%@",(long)index,itemName);
}

#pragma mark - segue
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([segue.identifier isEqualToString:@"GoToRemarkVAS"]) {
        TreatmentCourseRecordViewController *controller = segue.destinationViewController;
        controller.dataDic = @{@"medicalRecordNum":@"12345896",@"name":@"小明",@"gender":@"男",@"age":@"20",@"phone":@"13782965445"};
        
    }
}

@end
