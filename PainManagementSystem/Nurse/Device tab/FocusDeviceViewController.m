//
//  FocusDeviceViewController.m
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/4/4.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import "FocusDeviceViewController.h"
#import <MQTTClient/MQTTClient.h>
#import <MQTTClient/MQTTSessionManager.h>

NSString *const HOST = @"192.168.2.127";
NSString *const PORT = @"18826";
NSString *const MQTTUserName = @"admin";
NSString *const MQTTPassWord = @"lifotronic.com";

@interface FocusDeviceViewController ()<MQTTSessionManagerDelegate,MQTTSessionDelegate>{
    int page;
    int totalPage;  //总页数
    BOOL isRefreshing; //是否正在下拉刷新或者上拉加载
}

@property (weak, nonatomic) IBOutlet UIButton *allTabButton;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) IBOutlet UIView *deviceBackgroundView;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

//下拉框
@property (strong,nonatomic)HHDropDownList *dropList;
@property (strong, nonatomic) NSArray *dropListArray;
//区分 治疗中设备 未开始设备 和治疗结束设备
@property (nonatomic,strong)NSNumber* selectedTaskState;
//长按view抖动
@property (strong, nonatomic)UILongPressGestureRecognizer *longPress;

//在线tag还是本地tag
@property (nonatomic,assign)int tag;

//蓝牙设备
@property (strong ,nonatomic) CBPeripheral *peripheral;
@property (nonatomic,strong) CBCharacteristic *sendCharacteristic;
@property (nonatomic,strong) CBCharacteristic *receiveCharacteristic;
@property (nonatomic,strong) NSString *BLEDeviceName;
@property (nonatomic,assign)NSInteger selectedDeviceIndex;

//MQTT
@property (strong, nonatomic) MQTTSessionManager *manager;
@property (strong,nonatomic) NSMutableDictionary *subscriptions;
@end

@implementation FocusDeviceViewController
{
    BabyBluetooth *baby;
    NSMutableArray *datas;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initUI];


}
-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:YES];
    [self connectMQTT];
    if (datas != nil) {
        for (MachineModel *machine in datas) {
            [self subcribe:machine.cpuid];
        }
    }
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:YES];

    [baby cancelScan];
    [baby cancelAllPeripheralsConnection];
    [self.dropList pullBack];
    [self.HUD hideAnimated:YES];
    if (self.manager) {
        [self.manager removeObserver:self forKeyPath:@"state" context:nil];
    }
    [self disconnectMQTT];
    [self endRefresh];
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
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    
    //数据源
    datas = [NSMutableArray arrayWithCapacity:20];
    NSArray *dataArray = [[NSArray alloc]init];
    if (self.isInAllTab) {
//        dataArray = @[@{@"taskstate":@1,@"machinestate":@2,@"cpuid":@"33ffd9054b583033206510431e01",@"serialnum":@"pode",@"medicalrecordnum":@"12455",@"name":@"天天",@"bednum":@27,@"machinetype":@7681,@"nick":@"骨科一号"},
//                      @{@"taskstate":@3,@"machinestate":@1,@"cpuid":@"33ffd9054b5830332065104601",@"serialnum":@"p23e",@"medicalrecordnum":@"34675",@"name":@"李陌",@"bednum":@90,@"machinetype":@7681,@"nick":@"骨科二号"},
//                      @{@"taskstate":@7,@"machinestate":@2,@"cpuid":@"33ffd9054b583033206544621",@"serialnum":@"p235",@"medicalrecordnum":@"34633",@"name":@"靴靴",@"bednum":@90,@"machinetype":@7681,@"nick":@"骨科三号"}];

    }else{
//        dataArray= @[
//                     @{@"taskstate":@3,@"machinestate":@2,@"cpuid":@"33ffd9054b583033206510431e01",@"serialnum":@"pode",@"medicalrecordnum":@"124523456511",@"name":@"天天",@"bednum":@27,@"machinetype":@7681,@"nick":@"骨科一号"},
//                     @{@"taskstate":@3,@"machinestate":@1,@"cpuid":@"33ffd9054b5830332065104601",@"serialnum":@"p23e",@"medicalrecordnum":@"124523126511",@"name":@"李陌",@"bednum":@90,@"machinetype":@7681,@"nick":@"骨科二号"}];


    }
    for (NSDictionary *dic in dataArray) {
        MachineModel *machine = [MachineModel modelWithDic:dic];
        [datas addObject:machine];
    }

    self.subscriptions = [[NSMutableDictionary alloc]init];
    
    //seguement 在线或者本地
    self.segmentedControl.frame = CGRectMake(28, 75, 200, 35);
    
    [self.segmentedControl setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}forState:UIControlStateSelected];
    
    [self.segmentedControl setTitleTextAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:15.0f]}forState:UIControlStateNormal];
    
    [self.segmentedControl addTarget:self action:@selector(didClicksegmentedControlAction:) forControlEvents:UIControlEventValueChanged];
    
    //默认是在线设备
    self.tag = DeviceTypeOnline;
    
    //下拉框
    [self.deviceBackgroundView addSubview:self.dropList];
    NSArray *array_1 = @[@"治疗中设备", @"未开始设备", @"治疗结束设备"];
    self.dropListArray = array_1;
    
    [self.dropList reloadListData];
    
    //关注中设备添加 longpress 添加手势 可以取消设备
    if (!self.isInAllTab) {
        _longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(lonePressMoving:)];
        [self.collectionView addGestureRecognizer:_longPress];
    }
    
    //默认是治疗中的设备
    self.selectedTaskState = @3;
    //第一次加载的时候才自动刷新 以后都要手动刷新
    [self initTableHeaderAndFooter];

    
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

#pragma mark - refresh
-(void)initTableHeaderAndFooter{
    
    //下拉刷新
    self.collectionView.mj_header = [MJChiBaoZiHeader headerWithRefreshingTarget:self refreshingAction:@selector(refresh)];
    [self.collectionView.mj_header beginRefreshing];
    
    
    //上拉加载
    MJRefreshAutoNormalFooter *footer = [MJRefreshAutoNormalFooter footerWithRefreshingTarget:self refreshingAction:@selector(loadMore)];
    [footer setTitle:@"" forState:MJRefreshStateIdle];
    [footer setTitle:@"" forState:MJRefreshStateRefreshing];
    [footer setTitle:@"No more data" forState:MJRefreshStateNoMoreData];
    self.collectionView.mj_footer = footer;
    
}
-(void)refresh{
    if(self.tag == DeviceTypeOnline){
        [self askForData:YES];
    }

    
    if ([self.searchBar.text length]>0) {
        self.searchBar.text = @"";
    }

    [self.searchBar resignFirstResponder];
}
-(void)loadMore{
    if(self.tag == DeviceTypeOnline){
        [self askForData:NO];
    }

    [self.searchBar resignFirstResponder];
}
-(void)endRefresh{
    if (page == 0) {
        [self.collectionView.mj_header endRefreshing];
    }
    [self.collectionView.mj_footer endRefreshing];
}
-(void)askForData:(BOOL)isRefresh{
    NSMutableDictionary *params = [[NSMutableDictionary alloc]init];
    
    if (self.isInAllTab) {
        [params setObject:[NSNumber numberWithInteger:0] forKey:@"isfocus"];
    }else{
        [params setObject:[NSNumber numberWithInteger:1] forKey:@"isfocus"];
    }
    [params setObject:self.selectedTaskState forKey:@"taskstate"];
    
    
    [[NetWorkTool sharedNetWorkTool]POST:[HTTPServerURLString stringByAppendingString:@"Api/TaskList/QueryTaskCount"]
                                  params:(NSDictionary *)params
                                hasToken:YES
                                 success:^(HttpResponse *responseObject) {
                                     if ([responseObject.result intValue] == 1) {

                                         NSString *count = responseObject.content[@"count"];
                                         
                                         totalPage = ([count intValue]+9-1)/9;
                                         
                                         NSLog(@"totalPage = %d",totalPage);
                                         
                                         if ([count intValue]>0) {
                                             [self getNetworkData:isRefresh withParam:params];
                                         }else{
                                             [datas removeAllObjects];
                                             [self endRefresh];
//                                             [SVProgressHUD showErrorWithStatus:@"当前无设备连接上服务器"];
                                         }
                                         dispatch_async(dispatch_get_main_queue(), ^{
                                             [self.collectionView reloadData];
                                         });
                                         
                                     }else{
                                         [SVProgressHUD showErrorWithStatus:responseObject.errorString];
                                     }
                                 }
                                 failure:nil];
}
-(void)getNetworkData:(BOOL)isRefresh withParam:(NSMutableDictionary *)param{
    if (isRefresh) {
        page = 0;
    }else{
        page ++;
    }
    [param setObject:[NSNumber numberWithInt:page] forKey:@"page"];
    [[NetWorkTool sharedNetWorkTool]POST:[HTTPServerURLString stringByAppendingString:@"Api/TaskList/QueryTask"]
                                  params:param
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
                                     
                                     if (page >= totalPage) {
                                         [self endRefresh];
                                         [self.collectionView.mj_footer endRefreshingWithNoMoreData];
                                         return;
                                     }
                                     if ([responseObject.result intValue]==1) {
                                         NSArray *content = responseObject.content;
                                         if (content) {
                                             for (NSDictionary *dic in content) {
                                                 MachineModel *machine = [MachineModel modelWithDic:dic];
                                                [datas addObject:machine];
                                                 //订阅治疗中设备和未开始设备 taskstate = 1 ,taskstate = 3
                                                 if ([machine.taskStateNumber integerValue] == 1 || [machine.taskStateNumber integerValue] == 3) {
                                                     [self subcribe:machine.cpuid];
                                                 }
                                                 
                                             }
                                             dispatch_async(dispatch_get_main_queue(), ^{
                                                 [self.collectionView reloadData];
                                             });
                                        }
                                     }
                                 }
                                 failure:nil];
    
}
#pragma mark - initMQTT

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    
    switch (self.manager.state) {
            
        case MQTTSessionManagerStateClosed:
            NSLog(@"----------------------------------------closed");
            break;
        case MQTTSessionManagerStateClosing:
            NSLog(@"----------------------------------------closing");
            break;
        case MQTTSessionManagerStateConnecting:
            NSLog(@"--------------------------------------connecting");
            break;
        case MQTTSessionManagerStateConnected:
            NSLog(@"-------------------------------------connected");
            
            break;
        case MQTTSessionManagerStateStarting:
            NSLog(@"------------------------------------startConnecting");
            break;
        case MQTTSessionManagerStateError:
            NSLog(@"--------------------------------------------error");
        default:
            break;
    }
}
-(void)connectMQTT{
    if (!self.manager) {
        self.manager = [[MQTTSessionManager alloc] init];
        self.manager.delegate = self;

        
        //连接服务器
        [self.manager connectTo:HOST
                           port:18826
                            tls:false
                      keepalive:3600
                          clean:true
                           auth:true
                           user:@"admin"
                           pass:@"lifotronic.com"
                           will:nil
                      willTopic:nil
                        willMsg:nil
                        willQos:MQTTQosLevelExactlyOnce
                 willRetainFlag:false
                   withClientId:nil
                 securityPolicy:nil
                   certificates:nil
                  protocolLevel:MQTTProtocolVersion31
                 connectHandler:^(NSError *error) {
                     
                 }];
        
    }else{
        [self.manager connectToLast:^(NSError *error) {
            NSLog(@"connectToLast error:%@",error);
        }];
    }
    //订阅主题 controller即将出现的时候订阅
    
//    [self.subscriptions setObject:[NSNumber numberWithInt:MQTTQosLevelExactlyOnce] forKey:@"toapp/33ffd9054b583033206510431e01"];
    [self.subscriptions setObject:[NSNumber numberWithInt:MQTTQosLevelExactlyOnce] forKey:@"warning/#"];
    self.manager.subscriptions = [self.subscriptions copy];
    [self.manager addObserver:self
                   forKeyPath:@"state"
                      options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                      context:nil];
}

-(void)disconnectMQTT{
    [self.subscriptions removeAllObjects];
    self.manager.subscriptions = nil;
    [self.manager disconnectWithDisconnectHandler:nil];
}
-(void)subcribe:(NSString *)cpuid{
    
    [self.subscriptions setObject:[NSNumber numberWithInt:MQTTQosLevelExactlyOnce] forKey:[NSString stringWithFormat:@"toapp/%@",cpuid]];
    self.manager.subscriptions = [self.subscriptions copy];

}
-(void)unsubcibe:(NSString *)cpuid{
    [self.manager.session unsubscribeTopic:[NSString stringWithFormat:@"toapp/%@",cpuid]];
}
//receiveData
-(void)handleMessage:(NSData *)data onTopic:(NSString *)topic retained:(BOOL)retained{

    NSString *receiveStr = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
    
    NSData * receiveData = [receiveStr dataUsingEncoding:NSUTF8StringEncoding];

    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:receiveData options:NSJSONReadingMutableLeaves error:nil];
    
    __block NSDictionary *content = jsonDict[@"content"];
    DeviceCollectionViewCell *cell;
    MachineModel *currentMachine;

    
    if ([topic hasPrefix:@"warning"]) {
        NSLog(@"----------------------------------");
        NSLog(@"receivedata = %@,topic = %@",content[@"msg"],topic);
        NSString *cpuid = [topic substringFromIndex:8];
        for (MachineModel *machine in datas) {
            if ([machine.cpuid isEqualToString:cpuid]) {
                for (MachineModel *machine in datas) {
                    if ([machine.cpuid isEqualToString:cpuid]) {
                        machine.alertMessage = content[@"msg"];
                        currentMachine = machine;
                        break;
                    }
                }
                break;
            }
        }
    }else if ([topic hasPrefix:@"toapp"]){
        NSString *cpuid = [topic substringFromIndex:6];
        NSLog(@"cpuid = %@",cpuid);
        NSLog(@"content = %@",content);
        
        //遍历去取出cell
        for (MachineModel *machine in datas) {
            if ([machine.cpuid isEqualToString:cpuid]) {
                NSIndexPath *indexpath = [NSIndexPath indexPathForRow:[datas indexOfObject:machine] inSection:0];
                cell = (DeviceCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:indexpath];
                currentMachine = machine;
                if (cell) {
                    
                    NSNumber *code = content[@"code"];
                    switch ([currentMachine.taskStateNumber integerValue]) {
                        case 1:
                            if ([code integerValue] == 0x90){
                                //未开始变成治疗中刷新列表
                                NSNumber *machineState = content[@"state"];
                                if ([machineState isEqual:@0]) {
                                    [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"%@已开始治疗",machine.name]];
                                    [self performSelector:@selector(refresh) withObject:nil afterDelay:0.5];
                                }
                            }
                            break;
                        case 3:
                            switch ([code integerValue]){
                                //机器状态变化 刷新cell样式
                                case 0x90:
                                {

                                    NSNumber *machineState = content[@"state"];
                                    if ([machineState isEqualToNumber:@2] || [machineState isEqualToNumber:@1]) {
                                        if (![machine.alertMessage isEqualToString:@"过压"]) {
                                            dispatch_time_t timer = dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC);
                                            dispatch_after(timer, dispatch_get_main_queue(), ^{

                                                machine.alertMessage = nil;
                                                [machine changeState:machineState];
                                                dispatch_async(dispatch_get_main_queue(), ^{
                                                    [self.collectionView reloadData];
                                                });
                                            });
                                        }
                                    }
                                        [machine changeState:machineState];
                                        currentMachine = machine;
                                }
                                    break;
                                    //运行中的实时包 刷新倒计时
                                case 0x91:
                                {
                                    //等4秒才去除报警信息
                                    if (machine.alertMessage !=nil) {
                                        dispatch_time_t timer = dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC);
                                        dispatch_after(timer, dispatch_get_main_queue(), ^{
                                                machine.alertMessage = nil;
                                        });
                                    }
                                    else{
                                          //运行状态才刷新倒计时
                                        if([currentMachine.stateNumber isEqualToNumber:@0]){
                                            NSNumber *second= content[@"lefttime"];
                                            machine.leftTimeNumber = second;
                                            currentMachine = machine;
                                        }
                                    }
                                }
                                    break;
                                case 0x98:
                                {
                                    [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"%@已结束治疗",machine.name]];
                                    [self unsubcibe:machine.cpuid];
                                    [self performSelector:@selector(refresh) withObject:nil afterDelay:0.5];

                                    NSLog(@"收到0x98");
                                }
                                    break;
                                    
                                default:
                                    break;
                            }
                            break;
                        default:
                            break;
                    }
                    
                }
                //cpu匹配退出循环
                break;
            }
        }
 
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.collectionView reloadData];
    });
}

-(NSString *)changeSecondToTimeString:(NSNumber *)second{
    NSLog(@"second = %@",second);
    NSInteger hour = [second intValue]/3600;
    NSInteger minute = [second integerValue]/60%60;
    
    
    if (second != 0) {
        minute = minute +1;
        if (minute == 60) {
            hour = hour +1;
            minute = 0;
        }
    }
    
    NSString *hourString = [NSString stringWithFormat:hour>9?@"%ld":@"0%ld",(long)hour];
    NSString *minString = [NSString stringWithFormat:minute>9?@"%ld":@"0%ld",(long)minute];
    NSString *timeString = [NSString stringWithFormat:@"  %@:%@",hourString,minString];
    return timeString;
}


#pragma mark - HHDropDownList
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
- (NSArray *)listDataForDropDownList:(HHDropDownList *)dropDownList {
    
    return _dropListArray;
}
- (void)dropDownList:(HHDropDownList *)dropDownList didSelectItemName:(NSString *)itemName atIndex:(NSInteger)index {
    NSDictionary *taskStateInfo = @{@"治疗中设备":@3,@"未开始设备":@1,@"治疗结束设备":@7};
    self.selectedTaskState = taskStateInfo[itemName];

    [self.collectionView.mj_header beginRefreshing];
    
}

-(void)didClicksegmentedControlAction:(UISegmentedControl *)segmentedControl{
    
    NSInteger Index = segmentedControl.selectedSegmentIndex;
    NSArray *dataArray = [[NSArray alloc]init];
    switch (Index) {
        case DeviceTypeOnline:
        {
            self.collectionView.mj_header.hidden = NO;
            self.collectionView.mj_footer.hidden = NO;
            NSLog(@"切换在线设备");
            [datas removeAllObjects];
            self.tag = DeviceTypeOnline;
            
//
//            dataArray= @[
//                         @{@"taskstate":@3,@"machinestate":@2,@"cpuid":@"33ffd9054b583033206510431e01",@"serialnum":@"pode",@"medicalrecordnum":@"124523456511",@"name":@"天天",@"bednum":@27,@"machinetype":@7681,@"nick":@"骨科一号"},
//                         @{@"taskstate":@3,@"machinestate":@1,@"cpuid":@"33ffd9054b5830332065104601",@"serialnum":@"p23e",@"medicalrecordnum":@"124523126511",@"name":@"李陌",@"bednum":@90,@"machinetype":@7681,@"nick":@"骨科二号"}];
            
            for (NSDictionary *dic in dataArray) {
                MachineModel *machine = [MachineModel modelWithDic:dic];
                [datas addObject:machine];
            }
            
            self.dropList.hidden = NO;
            
            [baby cancelScan];
            [baby cancelAllPeripheralsConnection];
            [self.HUD hideAnimated:YES];
            [self connectMQTT];
        
        }
            
            break;
        case DeviceTypeLocal:
        {
            self.collectionView.mj_header.hidden = YES;
            self.collectionView.mj_footer.hidden = YES;
            NSLog(@"切换本地设备");
            self.tag = DeviceTypeLocal;
            
            
            dataArray = @[@{@"state":@"unconnect",@"serialnum":@"ALX420"}];
            
            [self.dropList pullBack];
            self.dropList.hidden = YES;
            datas = [dataArray mutableCopy];
            [self disconnectMQTT];

            //位置布局
//            UIEdgeInsets padding = UIEdgeInsetsMake(10, 10, 10, 10);
//            [self.collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
//                make.left.bottom.right.top.equalTo(self.deviceBackgroundView).with.offset(padding.left);
//
//            }];
        }
            break;
            
        default:
            break;
    }

    [self.collectionView reloadData];
}



#pragma mark - CollectionViewDelegate
-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return [datas count];
}
-(void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath{
    if (self.tag == DeviceTypeOnline) {

        MachineModel *machine = [datas objectAtIndex:indexPath.row];
        if (machine.alertMessage) {
            
            DeviceCollectionViewCell *currentCell = (DeviceCollectionViewCell *)cell;

            currentCell.middleImageView.alpha = 0.0;
            currentCell.machineStateLabel.alpha = 0.0;
            [UIView animateWithDuration:0.5 animations:^{
                cell.transform = CGAffineTransformIdentity;
                currentCell.middleImageView.alpha = 1.0;
                currentCell.machineStateLabel.alpha = 1.0;
            } completion:^(BOOL finished) {
                
            }];
        }else{
            [cell.layer removeAllAnimations];
        }
    }
}
-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{

    static NSString *CellIdentifier;
    
    DeviceCollectionViewCell *cell;
    
    if (self.tag == DeviceTypeOnline) {
        CellIdentifier = @"Cell";
        
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
        [cell.playButton addTarget:self action:@selector(controllAction:) forControlEvents:UIControlEventTouchUpInside];
        [cell.pauseButton addTarget:self action:@selector(controllAction:) forControlEvents:UIControlEventTouchUpInside];
        [cell.stopButton addTarget:self action:@selector(controllAction:) forControlEvents:UIControlEventTouchUpInside];
        
        MachineModel *machine = [datas objectAtIndex:indexPath.row];
        
        [cell configureWithStyle:machine.cellStyle message:nil];
        cell.machineNameLabel.text = [NSString stringWithFormat:@"%@-%@",machine.type,machine.name];
        cell.patientLabel.text = [NSString stringWithFormat:@"%@   %@",machine.userMedicalNum,machine.userName];
        cell.bedNumLabel.text = [NSString stringWithFormat:@"病床号: %@",machine.userBedNum];

        //警告
        if (machine.alertMessage) {
            [cell configureWithStyle:CellStyle_MachineException message:machine.alertMessage];

        }else if (machine.leftTimeNumber) {
            //进行中才更新倒计时
            if (cell.style == CellStyleOngoing_MachineRunning) {
                [cell configureWithStyle:CellStyleOngoing_MachineRunning message:[self changeSecondToTimeString:machine.leftTimeNumber]];
            }
        }else{

        }
        //按钮操作
        switch (cell.style) {
            case CellStyleFinished_MachineStop:
                [cell.remarkButton addTarget:self action:@selector(goToRemarkVAS:) forControlEvents:UIControlEventTouchUpInside];
                break;
            case CellStyleOngoing_MachinePause:
            case CellStyleOngoing_MachineStop:
                break;
            case CellStyleOngoing_MachineRunning:

                break;
                
            default:
                break;
        }
    }else if(self.tag == DeviceTypeLocal){
    
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
        
        [cell configureWithStyle:[stateNumber intValue] message:nil];

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
    [self.searchBar resignFirstResponder];
    
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

-(void)controllAction:(MultiParamButton *)button{
    UIView* contentView = [button superview];
    DeviceCollectionViewCell *deviceCell = (DeviceCollectionViewCell *)[contentView superview];
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:deviceCell];
    MachineModel *machine = [datas objectAtIndex:indexPath.row];
    NSString *cpuid = machine.cpuid;
    NSNumber *cmdcode = button.multiParamDic[@"cmdcode"];
    NSDictionary *param = @{@"cpuid":cpuid,@"cmdcode":cmdcode};
    [[NetWorkTool sharedNetWorkTool]POST:[HTTPServerURLString stringByAppendingString:@"Api/OnlineDevice/Control"]
                                  params:param
                                hasToken:YES
                                 success:^(HttpResponse *responseObject) {
                                     
                                 }
                                 failure:nil];
}
-(void)playAction:(UIButton *)button{
    
    UIView* contentView = [button superview];
    DeviceCollectionViewCell *deviceCell = (DeviceCollectionViewCell *)[contentView superview];
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:deviceCell];
    MachineModel *machine = [datas objectAtIndex:indexPath.row];
    NSString *cpuid = machine.cpuid;
    NSDictionary *param = @{@"cpuid":cpuid,@"cmdcode":@0};
    
    [[NetWorkTool sharedNetWorkTool]POST:[HTTPServerURLString stringByAppendingString:@"Api/OnlineDevice/Control"]
                                  params:param
                                hasToken:YES
                                 success:^(HttpResponse *responseObject) {
                                     
                                 }
                                 failure:nil];

}
-(void)stopAction:(UIButton *)button{
    NSLog(@"停止治疗");
    DeviceCollectionViewCell *deviceCell = (DeviceCollectionViewCell *)[button superview];
    
    NSInteger interger = [self.collectionView.visibleCells indexOfObject:deviceCell];
    
    MachineModel *machine = [datas objectAtIndex:interger];
    
    NSString *cpuid = machine.cpuid;
    
    NSDictionary *param = @{@"cpuid":cpuid,@"cmdcode":@2};
    
    
    [[NetWorkTool sharedNetWorkTool]POST:[HTTPServerURLString stringByAppendingString:@"Api/OnlineDevice/Control"]
                                  params:param
                                hasToken:YES
                                 success:^(HttpResponse *responseObject) {
                                     
                                 }
                                 failure:nil];
    
}
-(void)pauseAction:(UIButton *)button{
    
    DeviceCollectionViewCell *deviceCell = (DeviceCollectionViewCell *)[button superview];
    
    NSInteger interger = [self.collectionView.visibleCells indexOfObject:deviceCell];
    
    MachineModel *machine = [datas objectAtIndex:interger];
    
    NSString *cpuid = machine.cpuid;
    
    NSDictionary *param = @{@"cpuid":cpuid,@"cmdcode":@1};
    
    
    [[NetWorkTool sharedNetWorkTool]POST:[HTTPServerURLString stringByAppendingString:@"Api/OnlineDevice/Control"]
                                  params:param
                                hasToken:YES
                                 success:^(HttpResponse *responseObject) {
                                     
                                 }
                                 failure:nil];
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
        [[NetWorkTool sharedNetWorkTool]POST:[HTTPServerURLString stringByAppendingString:@"Api/TaskList/QueryTask"]
                                      params:@{@"medicalrecordnum":self.searchBar.text}
                                    hasToken:YES success:^(HttpResponse *responseObject) {
                                        if ([responseObject.result intValue] == 1) {
                                            [self.searchBar resignFirstResponder];
                                            NSArray *content = responseObject.content;
                                            if (content) {
                                                for (NSDictionary *dic in content) {
                                                    MachineModel *machine = [MachineModel modelWithDic:dic];
                                                    [FocusMachineAlertView alertControllerAboveIn:self withDataModel:machine returnBlock:^{
                                                        
                                                    }];
                                                }
                                            }else{
                                                [SVProgressHUD showErrorWithStatus:@"查找不到该病人的记录"];
                                            }
                                        }
                                    } failure:nil];
        

    }else{
        [SVProgressHUD showErrorWithStatus:@"请输入病历号查找设备~"];
    }

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
        
    }];
    
    [baby setBlockOnDisconnect:^(CBCentralManager *central, CBPeripheral *peripheral, NSError *error) {
        NSLog(@"断开连接");
        
        [weakSelf.HUD hideAnimated:YES];
        
        if (weakSelf                                                                                                                                                                                                                                                                                                                                                                                                                                                                .tag == DeviceTypeLocal) {
            
            NSMutableDictionary *machineDic = [[weakDatas objectAtIndex:weakSelf.selectedDeviceIndex]mutableCopy];
            [weakDatas removeObject:machineDic];
            
            [machineDic setValue:@"unconnect" forKey:@"state"];
            
            [weakDatas insertObject:machineDic atIndex:weakSelf.selectedDeviceIndex];
            
            [weakSelf.collectionView reloadData];
        }

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



#pragma mark - segue+
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([segue.identifier isEqualToString:@"GoToRemarkVAS"]) {
        UIView* contentView = [sender superview];
        DeviceCollectionViewCell *deviceCell = (DeviceCollectionViewCell *)[contentView superview];
        NSIndexPath *indexPath = [self.collectionView indexPathForCell:deviceCell];
        MachineModel *machine = [datas objectAtIndex:indexPath.row];
        TreatmentCourseRecordViewController *controller = segue.destinationViewController;
        controller.medicalRecordNum = machine.userMedicalNum;

    }
}

#pragma mark - animation
-(CABasicAnimation *)opacityForever_Animation:(float)time
{
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"opacity"];//必须写opacity才行。
    animation.fromValue = [NSNumber numberWithFloat:1.0f];
    animation.toValue = [NSNumber numberWithFloat:0.0f];//这是透明度。
    animation.autoreverses = YES;
    animation.duration = time;
    animation.repeatCount = MAXFLOAT;
    animation.removedOnCompletion = NO;
    animation.fillMode = kCAFillModeForwards;
    animation.timingFunction=[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];///没有的话是均匀的动画。
    return animation;
}

@end
