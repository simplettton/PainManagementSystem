//
//  FocusDeviceViewController.m
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/4/4.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import "FocusDeviceViewController.h"
#import "LocalMachineModel.h"
#import <MQTTClient/MQTTClient.h>
#import <MQTTClient/MQTTSessionManager.h>
#import <QuartzCore/QuartzCore.h>
#import "AppDelegate.h"
#import "MachineInfomationViewController.h"
#import "DeviceDetailController.h"
#define C_Button_Selected_Color 0x4F95D5
#define C_Button_UnSelected_Color 0xf8f8f8
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
@property (weak, nonatomic) IBOutlet UIView *noDataView;

//区分  治疗中设备 未开始设备 和治疗结束设备 按钮
@property (weak, nonatomic) IBOutlet UIView *taskStateView;

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

@property(nonatomic,strong)NSTimer *timer;

//MQTT
@property (strong, nonatomic) MQTTSessionManager *manager;
@property (strong,nonatomic) NSMutableDictionary *subscriptions;

//防止push多个相同的弹窗
@property (assign,nonatomic)BOOL pushOnce;
@end

@implementation FocusDeviceViewController
{
    BabyBluetooth *baby;
    NSMutableArray *datas;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.pushOnce = 1;
    [self initUI];

}
-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:YES];

    [self connectMQTT];
    [self refresh];
    self.collectionView.mj_header.hidden = NO;
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(didChangeDeviceSegmentBar:) name:@"ChangeDeviceSegmentBar" object:nil];
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(reloadDataWithNotification:) name:@"ClickTabbarItem" object:nil];
    self.pushOnce = 1;
}

-(void)reloadDataWithNotification:(NSNotification *)notification{
    if ([notification.object integerValue] == 2) {
        [self.collectionView.mj_header beginRefreshing];
    }
}
-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:YES];

    [baby cancelScan];
    [baby cancelAllPeripheralsConnection];
    [self.HUD hideAnimated:YES];
    if (self.manager) {
        [self.manager removeObserver:self forKeyPath:@"state" context:nil];
    }
    
    [self disconnectMQTT];
    [self endRefresh];
    self.collectionView.mj_header.hidden = YES;
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}
//关闭键盘
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
    [self hideKeyBoard];
}
-(void)hideKeyBoard{
    [self.view endEditing:YES];
    [self.collectionView endEditing:YES];


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
    //设置任务状态切换按钮边框
    for (UIView *view in self.taskStateView.subviews) {
        if ([view isKindOfClass:[UIButton class]]) {
            UIButton *button = (UIButton *)view;

            [button.layer setBorderWidth:1.0f];
            button.layer.borderColor = UIColorFromHex(C_Button_Selected_Color).CGColor;
        }
    }

    //配置searchbar样式
    self.searchBar.delegate = self;
    self.searchBar.backgroundImage = [[UIImage alloc]init];//去除边框线
    
    self.searchBar.tintColor = UIColorFromHex(0x5E97FE);//出现光标
    UITextField * searchField = [_searchBar valueForKey:@"_searchField"];
    
    [searchField setValue:[UIFont systemFontOfSize:15 weight:UIFontWeightLight] forKeyPath:@"_placeholderLabel.font"];

    
    //UICollectionView 配置
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    
    //隐藏键盘手势
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyBoard)];
    tapGestureRecognizer.cancelsTouchesInView = NO;
    
    [self.collectionView addGestureRecognizer:tapGestureRecognizer];
    
    //数据源
    datas = [NSMutableArray arrayWithCapacity:20];


    self.subscriptions = [[NSMutableDictionary alloc]init];
    
    //seguement 在线或者本地
    self.segmentedControl.frame = CGRectMake(28, 75, 200, 35);
    
    [self.segmentedControl setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}forState:UIControlStateSelected];
    
    [self.segmentedControl setTitleTextAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:15.0f]}forState:UIControlStateNormal];
    
    [self.segmentedControl addTarget:self action:@selector(didClicksegmentedControlAction:) forControlEvents:UIControlEventValueChanged];
    
    //默认是在线设备
    self.tag = DeviceTypeOnline;
    
    
    //设备添加 longpress 添加手势 可以取消关注/关注设备

    _longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(lonePressMoving:)];
    [self.collectionView addGestureRecognizer:_longPress];
    
    //默认是治疗中的设备
    self.selectedTaskState = @3;
    //第一次加载的时候才自动刷新 以后都要手动刷新
    [self initTableHeaderAndFooter];

    
}
#pragma mark - 长按手势取消关注和关注
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
                cell.btnDelete.tag = selectIndexPath.item;
                NSLog(@"selectIndexPath .item = %ld",(long)cell.btnDelete.tag);

                if(_isInAllTab){
                    [self performSelector:@selector(followDevice) withObject:nil afterDelay:0.5];
                }else{
                    [self performSelector:@selector(unfollowDevice:) withObject:cell.btnDelete afterDelay:0.5];
                }


                [self starShake:cell];
            }
            break;
        }
        case UIGestureRecognizerStateChanged: {
//            [self.collectionView updateInteractiveMovementTargetPosition:[longPress locationInView:_longPress.view]];
            break;
        }
        case UIGestureRecognizerStateEnded: {
            [self.collectionView endInteractiveMovement];

            break;
        }
        default: [self.collectionView cancelInteractiveMovement];
            break;
    }
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

-(void)followDevice{
    NSIndexPath *selectIndexPath = [self.collectionView indexPathForItemAtPoint:[_longPress locationInView:self.collectionView]];
     MachineModel *machine = [datas objectAtIndex:selectIndexPath.row];
    // 找到当前的cell
    for (DeviceCollectionViewCell *cell in [self.collectionView visibleCells]) {
        [self stopShake:cell];
    }
    if(machine.isFocus){
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@""
                                                                       message:@"已关注该设备"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* okAction = [UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault
                                                             handler:^(UIAlertAction * action) {
                                                                 [self.collectionView reloadData];
                                                                 
                                                                 for (DeviceCollectionViewCell *cell in [self.collectionView visibleCells]) {
                                                                     [self stopShake:cell];
                                                                 }
                                                             }];
        [alert addAction:okAction];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }else{
        
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"要关注设备吗？"
                                                                       message:@"关注之后可以在关注设备中查看"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleDefault
                                                             handler:^(UIAlertAction * action) {
                                                                 [self.collectionView reloadData];
                                                                 
                                                                 for (DeviceCollectionViewCell *cell in [self.collectionView visibleCells]) {
                                                                     [self stopShake:cell];
                                                                 }
                                                             }];
        UIAlertAction *focusAction = [UIAlertAction actionWithTitle:@"关注" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            if ([datas count]>0) {
                MachineModel *machine = [datas objectAtIndex:selectIndexPath.row];
                [self focusMachine:machine.serialNum];
            }
        }];
        
        [alert addAction:cancelAction];
        [alert addAction:focusAction];
        [self presentViewController:alert animated:YES completion:nil];
    }
 
}
//删除代码
- (void)unfollowDevice:(UIButton *)btn{
    //cell的隐藏删除设置
    NSIndexPath *selectIndexPath = [self.collectionView indexPathForItemAtPoint:[_longPress locationInView:self.collectionView]];
    // 找到当前的cell
    for (DeviceCollectionViewCell *cell in [self.collectionView visibleCells]) {
        [self stopShake:cell];
    }
    
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
                                                                  
                                                                  if ([datas count]>0) {
                                                                      id objc = [datas objectAtIndex:selectIndexPath.row];
                                                                      
                                                                      //sendToserver
                                                                      NSString *serialNum = [[NSString alloc]init];
                                                                      if(self.tag == DeviceTypeOnline){
                                                                          MachineModel *machine = (MachineModel *)objc;
                                                                          serialNum = machine.serialNum;
                                                                          [[NetWorkTool sharedNetWorkTool]POST:[HTTPServerURLString stringByAppendingString:@"Api/Myfocus/Delete"]
                                                                                                        params:@{@"serialnum":serialNum}
                                                                                                      hasToken:YES
                                                                                                       success:^(HttpResponse *responseObject) {
                                                                                                           if([responseObject.result intValue] == 1){
                                                                                                               [SVProgressHUD showErrorWithStatus:@"已取消关注"];
                                                                                                               
                                                                                                               
                                                                                                               [datas removeObject:objc];
                                                                                                               [self.collectionView reloadData];
                                                                                                           }else{
                                                                                                               [SVProgressHUD showErrorWithStatus:responseObject.errorString];                                NSLog(@"取消关注错误:%@",responseObject.errorString);
                                                                                                           }
                                                                                                           
                                                                                                       }
                                                                                                       failure:nil];
                                                                          
                                                                      }else{
                                                                          LocalMachineModel *machine = (LocalMachineModel *)objc;
                                                                          serialNum = machine.serialNum;
                                                                          [self unfollowLocalDevice:machine];
                                                                          
                                                                      }
                                                                      
                                                                      for (DeviceCollectionViewCell *cell in [self.collectionView visibleCells]) {
                                                                          [self stopShake:cell];
                                                                      }
                                                                  }
                                                                  
                                                              }];
    
    [alert addAction:defaultAction];
    
    [alert addAction:cancelFocusAction];
    
    [self presentViewController:alert animated:YES completion:nil];
    
}

-(void)unfollowLocalDevice:(LocalMachineModel *)machine{
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
            if ([savedMachine.userMedicalNum isEqualToString:machine.userMedicalNum]) {
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
            [SVProgressHUD showErrorWithStatus:@"无法取消关注设备"];
            
        }else{
            [SVProgressHUD showSuccessWithStatus:@"已取消关注"];
            if(self.tag == DeviceTypeLocal){
                [self refresh];
            }
        }
        
    }
}

//切换关注或者和全部
-(void)didChangeDeviceSegmentBar:(NSNotification *)notification{
    NSString *selected = notification.object;
    NSLog(@"收到通知:切换%@tab",selected);
    [self.searchBar resignFirstResponder];
    [self refresh];
}
#pragma mark - refresh
-(void)initTableHeaderAndFooter{
    
    //下拉刷新

    MJRefreshNormalHeader *header = [MJRefreshNormalHeader headerWithRefreshingTarget:self refreshingAction:@selector(refresh)];
    [header setTitle:@"加载中..." forState:MJRefreshStateRefreshing];
    header.stateLabel.textColor =UIColorFromHex(0xdbdbdb);
    header.lastUpdatedTimeLabel.hidden = YES;
    header.stateLabel.hidden = YES;
    self.collectionView.mj_header = header;
//    [self.collectionView.mj_header beginRefreshing];
    [self refresh];
    
    
    //上拉加载
    MJRefreshAutoNormalFooter *footer = [MJRefreshAutoNormalFooter footerWithRefreshingTarget:self refreshingAction:@selector(loadMore)];
    [footer setTitle:@"" forState:MJRefreshStateIdle];
    [footer setTitle:@"" forState:MJRefreshStateRefreshing];
    [footer setTitle:@"没有数据了~" forState:MJRefreshStateNoMoreData];
    self.collectionView.mj_footer = footer;
    
}
-(void)refresh{
    
    [baby cancelAllPeripheralsConnection];
    
    if(self.tag == DeviceTypeOnline){
        [self askForData:YES];
    }else if(self.tag == DeviceTypeLocal){
        [self loadLocalMachineData];
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
    
    if (!self.isInAllTab) {
        [params setObject:[NSNumber numberWithInteger:1] forKey:@"isfocus"];
    }
    [params setObject:self.selectedTaskState forKey:@"taskstate"];
    [params setObject:@0 forKey:@"needlocal"];
    
    NSDictionary *taskStateInfo = @{@3:@"治疗中设备",@1:@"未开始治疗设备",@7:@"治疗结束设备"};
    
    [[NetWorkTool sharedNetWorkTool]POST:[HTTPServerURLString stringByAppendingString:@"Api/TaskList/QueryTask"]
                                  params:(NSDictionary *)params
                                hasToken:YES
                                 success:^(HttpResponse *responseObject) {
                                     if ([responseObject.result intValue] == 1) {

                                         NSNumber *count = responseObject.count;

                                         totalPage = ([count intValue]+9-1)/9;

                                         if (totalPage <= 1) {
                                             self.collectionView.mj_footer.hidden = YES;
                                         }else{
                                             self.collectionView.mj_footer.hidden = NO;
                                         }
                                         if ([count intValue]>0) {
                                             [self getNetworkData:isRefresh withParam:params];

                                             [self hideNodataView];
                                         }else{
                                             [datas removeAllObjects];

                                             [self endRefresh];
                                             [self showNodataViewWithTitle:[NSString stringWithFormat:@"暂无%@",taskStateInfo[self.selectedTaskState]]];
                                         }
                                         dispatch_async(dispatch_get_main_queue(), ^{
                                             [self.collectionView reloadData];
                                         });

                                     }else{
                                         [SVProgressHUD showErrorWithStatus:responseObject.errorString];
                                     }
                                 }
                                 failure:^(NSError *error) {
                                     dispatch_async(dispatch_get_main_queue(), ^{
                                         [self.collectionView reloadData];
                                     });
                                 }];
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
                                             if (self.tag == DeviceTypeOnline) {
                                                 for (NSDictionary *dic in content) {
                                                     MachineModel *machine = [MachineModel modelWithDic:dic];
                                                     [datas addObject:machine];
                                                     //订阅治疗中设备和未开始设备 taskstate = 1 ,taskstate = 3
                                                     if ([self.selectedTaskState isEqual: @1] ||[self.selectedTaskState isEqual: @3]) {

                                                         [self subcribe:machine.cpuid];
                                                     }
                                                 }
                                                 dispatch_async(dispatch_get_main_queue(), ^{
                                                     [self.collectionView reloadData];

                                                 });
                                             }
                                        }
                                     }
                                 }
                                 failure:nil];
    
}
#pragma mark - mark NoDataView
-(void)showNodataViewWithTitle:(NSString *)title{
    self.noDataView.hidden = NO;
    UILabel *titleLabel = [self.noDataView viewWithTag:20000];
    titleLabel.text = title;

}
-(void)hideNodataView{
    self.noDataView.hidden = YES;
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
        //clientid
        NSString *clientId = [UserDefault objectForKey:@"UserName"];
        if (self.isInAllTab) {
            clientId = [clientId stringByAppendingString:@"1"];
        }
        //连接服务器
        NSString *host = [UserDefault objectForKey:@"HTTPServerIP"];
        NSString *port = [UserDefault objectForKey:@"MQTTPort"];
        
        [self.manager connectTo:host
                           port:[port intValue]
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
                   withClientId:clientId 
                 securityPolicy:nil
                   certificates:nil
                  protocolLevel:MQTTProtocolVersion31
                 connectHandler:^(NSError *error) {
                     
                 }];
        
    }else{
        [self.manager connectToLast:^(NSError *error) {
            NSLog(@"connectToLast error:%@",error);
        }];
        self.manager.delegate = self;
    }
    //订阅主题 controller即将出现的时候订阅
    [self.subscriptions setObject:[NSNumber numberWithInt:MQTTQosLevelExactlyOnce] forKey:@"warning/#"];
    self.manager.subscriptions = [self.subscriptions copy];
    
    //若没有订阅设备则订阅设备
    if (self.tag == DeviceTypeOnline) {
        if (datas != nil) {
            for (MachineModel *machine in datas) {
                [self subcribe:machine.cpuid];
            }
        }
    }

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
    NSString *newTopic = [NSString stringWithFormat:@"toapp/%@",cpuid];
    if (![self.manager.subscriptions.allKeys containsObject:newTopic]){
        [self.subscriptions setObject:[NSNumber numberWithInt:MQTTQosLevelExactlyOnce] forKey:newTopic];
        self.manager.subscriptions = [self.subscriptions copy];
    }
}
-(void)unsubcibe:(NSString *)cpuid{
    [self.manager.session unsubscribeTopic:[NSString stringWithFormat:@"toapp/%@",cpuid]];
}
//receiveData
-(void)reloadItemAtIndex:(NSInteger)index{
    if ([datas count]>0) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
        NSMutableArray *indexPaths = [[NSMutableArray alloc] init];
        [indexPaths addObject:indexPath];
        if (index < [datas count]) {
            [self.collectionView reloadItemsAtIndexPaths:indexPaths];
        }
    }

}
-(void)handleMessage:(NSData *)data onTopic:(NSString *)topic retained:(BOOL)retained{

    NSString *receiveStr = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
    
    NSData * receiveData = [receiveStr dataUsingEncoding:NSUTF8StringEncoding];

    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:receiveData options:NSJSONReadingMutableLeaves error:nil];
    
    __block NSDictionary *content = jsonDict[@"content"];
    DeviceCollectionViewCell *cell;
    __block MachineModel *currentMachine;

    if ([topic hasPrefix:@"warning"]) {
        NSLog(@"--------------------------------------------------");
        NSLog(@"warnning = %@,topic = %@",content[@"msg"],topic);
        NSString *cpuid = [topic substringFromIndex:8];
        for (MachineModel *machine in datas) {
            if ([machine.cpuid isEqualToString:cpuid]) {
                machine.alertMessage = content[@"msg"];
                currentMachine = machine;
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSInteger index = [datas indexOfObject:machine];
                    [self reloadItemAtIndex:index];
                });
                break;
            }
        }
    }else if ([topic hasPrefix:@"toapp"]){
        NSString *cpuid = [topic substringFromIndex:6];
        NSLog(@"=================================================");
        NSLog(@"topic = %@\ncontent = %@",topic,content);
        
        //遍历去取出cell
        for (MachineModel *machine in datas) {
            if ([machine.cpuid isEqualToString:cpuid]) {
                NSIndexPath *indexpath = [NSIndexPath indexPathForRow:[datas indexOfObject:machine] inSection:0];
                cell = (DeviceCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:indexpath];
                currentMachine = machine;
                if (cell) {
                    if (![content isEqual:[NSNull null]]) {
                        NSNumber *code = content[@"code"];
                        
                        //上下线信息
                        if ([code integerValue] == 0x97) {
                            NSString *message = [[NSString alloc]init];
                            if ([content[@"state"] isEqual:@2]) {
                                message = @"上线";
                            }else if( [content[@"state"] isEqual:@4]){
                                message = @"下线";
                            }
                            [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"%@已%@",machine.name,message]];
                            [self performSelector:@selector(refresh) withObject:nil afterDelay:0.5];
                        }
                        //其他信息
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
                                            if(machine.alertMessage){
                                                if (![machine.alertMessage isEqualToString:@"过压"]) {
                                                    dispatch_time_t timer = dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC);
                                                    dispatch_after(timer, dispatch_get_main_queue(), ^{
                                                        
                                                        machine.alertMessage = nil;
                                                        [machine changeState:machineState];
                                                        dispatch_async(dispatch_get_main_queue(), ^{
                                                            NSInteger index = [datas indexOfObject:machine];
                                                            [self reloadItemAtIndex:index];
                                                        });
                                                    });
                                                }
                                            }
                                            
                                        }
                                        [machine changeState:machineState];
                                        currentMachine = machine;
                                        NSInteger index = [datas indexOfObject:machine];
                                        [self reloadItemAtIndex:index];
                                    }
                                        break;
                                        //运行中的实时包 刷新倒计时
                                    case 0x91:
                                    {
                                        //等3秒才去除报警信息
                                        if (machine.alertMessage !=nil) {
                                            dispatch_time_t timer = dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC);
                                            dispatch_after(timer, dispatch_get_main_queue(), ^{
                                                machine.alertMessage = nil;
                                                NSInteger index = [datas indexOfObject:currentMachine];
                                                [self reloadItemAtIndex:index];
                                            });
                                        }
                                        else{
                                            //运行状态分钟有变化才刷新倒计时
                                            if([currentMachine.stateNumber isEqualToNumber:@0]){
                                                NSNumber *second= content[@"lefttime"];
                                                if(![[self changeSecondToTimeString:second]isEqualToString:[self changeSecondToTimeString:machine.leftTimeNumber]]){
                                                    machine.leftTimeNumber = second;
                                                    currentMachine = machine;
                                                    NSInteger index = [datas indexOfObject:currentMachine];
                                                    [self reloadItemAtIndex:index];
                                                }
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
                }
                break;
            }
        }

    }

}

-(NSString *)changeSecondToTimeString:(NSNumber *)second{
    
    NSInteger minute = [second integerValue]/60;
    
//    NSInteger hour = [second intValue]/3600;
//    NSInteger minute = [second integerValue]/60%60;

    if (second != 0) {
        if (minute < 1) {
            minute = 1;
        }
    }
//    NSString *hourString = [NSString stringWithFormat:hour>9?@"%ld":@"0%ld",(long)hour];
//    NSString *minString = [NSString stringWithFormat:minute>9?@"%ld":@"0%ld",(long)minute];
//    NSString *timeString = [NSString stringWithFormat:@"%@:%@",hourString,minString];
    NSString *timeString = [NSString stringWithFormat:@"%ldmin",minute];
    return timeString;
}

#pragma mark - changeTaskState

- (IBAction)changeTaskState:(UIButton *)sender {
    self.selectedTaskState = [NSNumber numberWithInteger:[sender tag]];
    
    NSArray *taskStateButtonTagArray = [NSArray arrayWithObjects:@1,@3,@7, nil];
    for (NSNumber *taskState in taskStateButtonTagArray) {
        UIButton *btn = [self.taskStateView viewWithTag:[taskState integerValue]];
        if ([btn tag] == [sender tag]) {
            btn.backgroundColor = UIColorFromHex(C_Button_Selected_Color);
            [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        }else{
            btn.backgroundColor = UIColorFromHex(C_Button_UnSelected_Color);
            [btn setTitleColor:UIColorFromHex(C_Button_Selected_Color) forState:UIControlStateNormal];
        }
    }
    

    [self refresh];
    
    
    
}
//在线或本地切换
-(void)didClicksegmentedControlAction:(UISegmentedControl *)segmentedControl{
    
    NSInteger Index = segmentedControl.selectedSegmentIndex;
    [self hideNodataView];
    switch (Index) {
        case DeviceTypeOnline:
        {

            self.collectionView.mj_header.hidden = NO;
            self.collectionView.mj_footer.hidden = NO;
            NSLog(@"切换在线设备");
            [datas removeAllObjects];
            [self.collectionView reloadData];
            self.tag = DeviceTypeOnline;
            
            self.taskStateView.hidden = NO;
            
            [baby cancelScan];
            [baby cancelAllPeripheralsConnection];
            [self.HUD hideAnimated:YES];
            [self connectMQTT];
            
            //uicollectionview下移
            UICollectionViewFlowLayout *collectionViewLayout = (UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout;
            collectionViewLayout.headerReferenceSize = CGSizeMake(50, 60);
        
        }
            
            break;
        case DeviceTypeLocal:
        {
            [datas removeAllObjects];
            
            [self endRefresh];
            self.collectionView.mj_footer.hidden = YES;
            NSLog(@"切换本地设备");
            self.tag = DeviceTypeLocal;
            self.taskStateView.hidden = YES;

            [self disconnectMQTT];
            baby = [BabyBluetooth shareBabyBluetooth];
            [self babyDelegate];
            //位置布局  //uicollectionview上移
            UICollectionViewFlowLayout *collectionViewLayout = (UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout;
            collectionViewLayout.headerReferenceSize = CGSizeMake(50, 20);
        }
            break;
            
        default:
            break;
    }
    [self refresh];
    [self.searchBar resignFirstResponder];

}



#pragma mark - CollectionViewDelegate
-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return [datas count];
}
-(void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath{
    if (self.tag == DeviceTypeOnline) {

        MachineModel *machine = [datas objectAtIndex:indexPath.row];
        DeviceCollectionViewCell *currentCell = (DeviceCollectionViewCell *)cell;
        if (machine.alertMessage) {
        [currentCell.middleImageView.layer addAnimation:[self opacityForever_Animation:0.25] forKey:nil];
        [currentCell.machineStateLabel.layer addAnimation:[self opacityForever_Animation:0.25] forKey:nil];
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
        
        if(datas){
            MachineModel *machine = [datas objectAtIndex:indexPath.row];

            [cell configureWithStyle:machine.cellStyle message:nil];
            cell.machineNameLabel.text = [NSString stringWithFormat:@"%@-%@",machine.type,machine.name];
            cell.patientLabel.text = [NSString stringWithFormat:@"%@   %@",machine.userMedicalNum,machine.userName];
            
            cell.bedNumLabel.hidden = [machine.userBedNum isEqualToString:@""];

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
        }

    }else if(self.tag == DeviceTypeLocal){
    
        CellIdentifier = @"LocalDeviceCell";
        
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
        
        if (datas!=nil && [datas count]>0) {
            
            LocalMachineModel *machine = [datas objectAtIndex:indexPath.row];
            cell.machineNameLabel.text = [NSString stringWithFormat:@"%@-%@",machine.type,machine.name];
            cell.patientLabel.text = [NSString stringWithFormat:@"%@   %@",machine.userMedicalNum,machine.userName];
            cell.bedNumLabel.hidden = [machine.userBedNum isEqualToString:@""];
            cell.bedNumLabel.text = [NSString stringWithFormat:@"病床号: %@",machine.userBedNum];
            
            NSDictionary *stateDic = @
            {
                @"connected":[NSNumber numberWithInteger:CellStyle_LocalConnect],
                @"unconnect":[NSNumber numberWithInteger:CellStyle_LocalUnconnect],
                @"running":[NSNumber numberWithInteger:CellStyle_LocalRunning],
                @"unrunning":[NSNumber numberWithInteger:CellStyle_LocalUnrunning],
                @"pause":[NSNumber numberWithInteger:CellStyle_LocalPause]
            };
            
            NSNumber *stateNumber = [stateDic objectForKey:machine.state];
            
            [cell configureWithStyle:[stateNumber intValue] message:nil];
            
            [cell.BLERemarkButton addTarget:self action:@selector(goToRemarkVAS:) forControlEvents:UIControlEventTouchUpInside];
            [cell.connectButton addTarget:self action:@selector(BLEConnectDevice:) forControlEvents:UIControlEventTouchUpInside];
            [cell.BLEPlayButton addTarget:self action:@selector(play:) forControlEvents:UIControlEventTouchUpInside];
            [cell.BLEPauseButton addTarget:self action:@selector(pause:) forControlEvents:UIControlEventTouchUpInside];
            [cell.BLEStopButton addTarget:self action:@selector(stop:) forControlEvents:UIControlEventTouchUpInside];
        }
        

        
}
 
    if (cell == nil) {
        cell = [[DeviceCollectionViewCell alloc]init];
    }
    cell.btnDelete.hidden = YES;
    
    return cell;
}

// 允许选中时，高亮
-(BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath{
    return YES;
}
// 设置是否允许选中
- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [self.searchBar resignFirstResponder];
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

    if (self.tag != DeviceTypeLocal) {
        if ([datas count]>0) {
            MachineModel *machine = [datas objectAtIndex:indexPath.row];
//            [self performSegueWithIdentifier:@"ShowAlertMessage" sender:machine];
            [self performSegueWithIdentifier:@"ShowDeviceDetail" sender:machine];
        }
    }else{
        if ([datas count]>0) {
            LocalMachineModel *machine = [datas objectAtIndex:indexPath.row];
//            [self performSegueWithIdentifier:@"ShowAlertMessage" sender:machine.userMedicalNum];
        [self performSegueWithIdentifier:@"ShowDeviceDetail" sender:machine.userMedicalNum];
        }
    }

}
//设置每个item的尺寸
-(CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
    return CGSizeMake(220, 186);
}

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


#pragma mark http control machine

-(void)controllAction:(MultiParamButton *)button{
    [SVProgressHUD showWithStatus:@"正在加载中..."];
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
                                     if ([responseObject.result integerValue] == 1) {
                                         [SVProgressHUD dismiss];
                                     }else{
                                         [SVProgressHUD showErrorWithStatus:responseObject.errorString];
                                     }
                                 }
                                 failure:nil];
}

-(void)controlMahine:(NSString *)serialnum cmdcode:(int)cmdcode
{
    [SVProgressHUD show];
    NSMutableDictionary *params = [[NSMutableDictionary alloc]init];
    
    [params setObject:serialnum forKey:@"cpuid"];
    
    [params setObject:[NSNumber numberWithInt:cmdcode] forKey:@"cmdcode"];
    
    [[NetWorkTool sharedNetWorkTool]POST:[HTTPServerURLString stringByAppendingString:@"Api/OnlineDevice/Control"]
                                 params:params
                               hasToken:YES
                                success:^(HttpResponse *responseObject) {
                                    if ([responseObject.result integerValue] == 1) {
                                        [SVProgressHUD dismiss];
                                    }
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
                                      params:@{
                                               @"medicalrecordnum":self.searchBar.text,
                                               @"needlocal":@1,
                                               @"taskstate":@135
                                               }
                                    hasToken:YES success:^(HttpResponse *responseObject) {
                                        if ([responseObject.result intValue] == 1) {
                                            [self.searchBar resignFirstResponder];
                                            __block NSArray *content = responseObject.content;
                                            if (content) {
                                                    __block MachineModel *machine = [MachineModel modelWithDic:content[0]];

                                                if (self.pushOnce == 1) {
                                                    [FocusMachineAlertView alertControllerAboveIn:self withDataModel:machine returnBlock:^(NSString * returnString){
                                                        
                                                        if (![returnString isEqualToString:@"我按了取消按钮"]) {
                                                            //补关注设备
                                                            if (machine.isLocal) {
                                                                LocalMachineModel *machine = [LocalMachineModel modelWithDic:content[0]];
                                                                [self saveLocalDevice:machine];
                                                            }
                                                            else if (machine.serialNum) {

                                                                [self focusMachine:machine.serialNum];
                                                            }
                                                        }

                                                        self.pushOnce = 1;

                                                    }];
                                                }
                                                self.pushOnce = 0;

                                            }else{
                                                [SVProgressHUD showErrorWithStatus:@"查找不到该病人的记录"];
                                            }
                                        }else{
                                            if ([self.searchBar.text length]>0) {
                                                self.searchBar.text = @"";
                                            }
                                            [SVProgressHUD showErrorWithStatus:responseObject.errorString];
                                        }
                                    } failure:nil];
    }else{
        [SVProgressHUD showErrorWithStatus:@"请输入病历号查找设备~"];
    }
}
-(void)focusMachine:(NSString *)serialNum{
    
    if (serialNum) {
        [[NetWorkTool sharedNetWorkTool]POST:[HTTPServerURLString stringByAppendingString:@"Api/Myfocus/Add"]
                                      params:@{@"serialnum":serialNum}
                                    hasToken:YES
                                     success:^(HttpResponse *responseObject) {
                                         if ([responseObject.result intValue]==1) {
                                             NSLog(@"关注设备成功");
                                             [SVProgressHUD showSuccessWithStatus:@"已关注设备"];
                                             [self refresh];
                                         }else{
                                             [SVProgressHUD showErrorWithStatus:responseObject.errorString];
                                         }
                                     }
                                     failure:nil];
    }
}

#pragma mark - BLEFileManage
-(void)saveLocalDevice:(LocalMachineModel *)machine{
    //文件名
    NSString *documents = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    if (!documents)
    {
        NSLog(@"目录未找到");
    }
    NSString *documentPath = [documents stringByAppendingPathComponent:@"focusLocalMachine.plist"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    //machine Array
    NSArray *machineArray = [[NSArray alloc]init];
    if (![fileManager fileExistsAtPath:documentPath])
    {
        //没有文件就新建文件
        [fileManager createFileAtPath:documentPath contents:nil attributes:nil];
    }else{
        //有文件就去取文件中的数据
        
        NSData * resultdata = [[NSData alloc] initWithContentsOfFile:documentPath];
        NSKeyedUnarchiver *unArchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:resultdata];
        machineArray = [unArchiver decodeObjectForKey:@"machineArray"];
    }
    
    NSMutableArray *array = [NSMutableArray arrayWithArray:machineArray];
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
    machineArray = [array copy];
    
    //写入文件
    NSMutableData *data = [[NSMutableData alloc] init] ;
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data] ;
    [archiver encodeObject:machineArray forKey:@"machineArray"];
    [archiver finishEncoding];
    
    BOOL success = [data writeToFile:documentPath atomically:YES];
    if (!success)
    {
        [SVProgressHUD showErrorWithStatus:@"无法关注设备"];
    }else{
        [SVProgressHUD showSuccessWithStatus:@"已关注设备"];
        if (self.tag == DeviceTypeLocal) {
            [self loadLocalMachineData];
        }
    }
    
}

-(void)loadLocalMachineData{
    
    NSString *documents = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)lastObject];
    NSString *documentPath = [documents stringByAppendingPathComponent:@"focusLocalMachine.plist"];
    NSFileManager *fileManager = [NSFileManager defaultManager];

    if (![fileManager fileExistsAtPath:documentPath])
    {
        //没有文件就新建文件
        [fileManager createFileAtPath:documentPath contents:nil attributes:nil];
        [self endRefresh];
    }else {
        NSData * resultdata = [[NSData alloc] initWithContentsOfFile:documentPath];
        NSKeyedUnarchiver *unArchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:resultdata];
        __block NSArray *savedArray = [unArchiver decodeObjectForKey:@"machineArray"];
        NSMutableArray *array = [NSMutableArray arrayWithArray:savedArray];
        
        if (array) {
            datas = array;
            [self.collectionView reloadData];
        }
        if ([array count] == 0) {
            [self showNodataViewWithTitle:@"暂无本地设备"];
        }else{
            [self hideNodataView];
        }
        
        __block NSArray *serverTaskListArray = [[NSArray alloc]init];
        [[NetWorkTool sharedNetWorkTool]POST:[HTTPServerURLString stringByAppendingString:@"Api/TaskList/RunningTaskList"]
                                      params:nil
                                    hasToken:YES success:^(HttpResponse *responseObject) {
                                        if ([responseObject.result intValue] ==1) {
                                            if (responseObject.content) {
                                                serverTaskListArray = (NSArray *)responseObject.content;

                                                //比对处理中的任务 没有则取消关注
                                                for (LocalMachineModel *machine in savedArray){
                                                    if (![serverTaskListArray containsObject:machine.taskId]) {

                                                        NSUInteger index = [array indexOfObject:machine];
                                                        [array removeObjectAtIndex:index];
                                                    }
                                                }
                                                //刷新列表
                                                datas = array;
                                                [self endRefresh];
                                                if(datas){
                                                    [self.collectionView reloadData];
                                                }
                                                
                                                //保存到文件中
                                                NSMutableData *fileData = [[NSMutableData alloc] init] ;
                                                NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:fileData] ;
                                                [archiver encodeObject:array forKey:@"machineArray"];
                                                [archiver finishEncoding];
                                                
                                                BOOL success = [fileData writeToFile:documentPath atomically:YES];
                                                if (!success)
                                                {
                                                
                                                }else{
                                                    NSLog(@"同步服务器数据");
                                                }

                                            }
                                        }else{
                                            [SVProgressHUD showErrorWithStatus:responseObject.errorString];
                                        }

                                    } failure:^(NSError *error) {

                                    }];
    }
}

#pragma mark - BLE
-(void)BLEConnectDevice:(UIButton *)button{
    
    //判断蓝牙是否打开
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if (appDelegate.isBLEPoweredOff) {
        [SVProgressHUD showErrorWithStatus:@"没有打开蓝牙无法连接设备,请在设置中打开"];
        return;
    }
    
    //old connected device
    [baby cancelAllPeripheralsConnection];

    LocalMachineModel *oldMachine = [datas objectAtIndex:self.selectedDeviceIndex];
    
    [oldMachine changeState:@"unconnect"];


    //new device to connect
    
    [self startTimeOutTimer];
    
    DeviceCollectionViewCell *deviceCell = (DeviceCollectionViewCell *)[[button superview]superview];
    
    NSInteger interger = [self.collectionView.visibleCells indexOfObject:deviceCell];
    
    self.selectedDeviceIndex = interger;
    
    LocalMachineModel *machine = [datas objectAtIndex:interger];

    self.BLEDeviceName = machine.machineInfo.broadcastName;
    
    [self babyDelegate];
    
    baby.scanForPeripherals().begin();
    
    //连接中状态指示
    [self.collectionView reloadData];
    [SVProgressHUD showWithStatus:[NSString stringWithFormat:@"连接设备%@中...",machine.name]];

}
-(void)babyDelegate{
    __weak typeof(self) weakSelf = self;
    __weak typeof(BabyBluetooth*) weakBaby = baby;
    __weak typeof(NSMutableArray *)weakDatas = datas;
    
    [baby setBlockOnConnected:^(CBCentralManager *central, CBPeripheral *peripheral) {
        
        NSLog(@"连接成功");

    }];
    
    [baby setBlockOnDisconnect:^(CBCentralManager *central, CBPeripheral *peripheral, NSError *error) {
        NSLog(@"断开连接");
        
        if (weakSelf.timer) {
            [weakSelf closeTimer];
        }

        
        if (weakSelf                                                                                                                                                                                                                                                                                                                                                                                                                                                                .tag == DeviceTypeLocal) {
            
            LocalMachineModel *machine = [weakDatas objectAtIndex:weakSelf.selectedDeviceIndex];
            [machine changeState:@"unconnect"];
            
            [weakSelf.collectionView reloadData];
        }

    }];
    
    //发现service的Characteristics
    [baby setBlockOnDiscoverCharacteristics:^(CBPeripheral *peripheral, CBService *service, NSError *error) {
        LocalMachineModel *machine = [weakDatas objectAtIndex:weakSelf.selectedDeviceIndex];
        if ([service.UUID isEqual:[CBUUID UUIDWithString:machine.machineInfo.serviceUUID]]) {
            
            for (CBCharacteristic *characteristic in service.characteristics)
            {
                if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:machine.machineInfo.rxCharacteristicUUID]])
                {
                    weakSelf.receiveCharacteristic = characteristic;
                    if (![characteristic isNotifying]) {
                        [weakSelf setNotify:characteristic];
                    }
                }
                if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:machine.machineInfo.txCharacteristicUUID]])
                {
                    weakSelf.sendCharacteristic = characteristic;
                    [weakSelf performSelector:@selector(sendMachineStateRequest) withObject:nil afterDelay:0.1];

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
        if (peripheralName.length > 0 && [peripheralName isEqualToString:weakSelf.BLEDeviceName]) {
            
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
            
            //收到状态才判定为连接成功
            [SVProgressHUD dismiss];
            if (self.timer) {
                [self closeTimer];
            }

            
            NSString *stateKey = [NSString stringWithFormat:@"%d",dataByte];
            
            NSDictionary *typeDic = @{@"1":@"unrunning",
                                      @"2":@"running",
                                      @"3":@"pause"
                                      };
            LocalMachineModel *machine = [datas objectAtIndex:self.selectedDeviceIndex];
            [machine changeState:typeDic[stateKey]];

            
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

-(void)startTimeOutTimer{
    self.timer = [NSTimer scheduledTimerWithTimeInterval:12 target:self selector:@selector(showTimeOutView) userInfo:nil repeats:NO];
}
-(void)closeTimer{
    [self.timer invalidate];
    self.timer = nil;
}
-(void)showTimeOutView{
    [self.HUD hideAnimated:YES];
    LocalMachineModel *machine = [datas objectAtIndex:self.selectedDeviceIndex];
    [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"%@连接超时",machine.name]];
}
                      

#pragma mark - segue+
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([segue.identifier isEqualToString:@"GoToRemarkVAS"]) {
        UIView* contentView = [sender superview];
        DeviceCollectionViewCell *deviceCell = (DeviceCollectionViewCell *)[contentView superview];
        NSIndexPath *indexPath = [self.collectionView indexPathForCell:deviceCell];

        TreatmentCourseRecordViewController *controller = segue.destinationViewController;
        if(self.tag == DeviceTypeLocal){
            LocalMachineModel *machine = [datas objectAtIndex:indexPath.row];
            controller.medicalRecordNum = machine.userMedicalNum;
        }else if(self.tag == DeviceTypeOnline){
            MachineModel *machine = [datas objectAtIndex:indexPath.row];
            controller.medicalRecordNum = machine.userMedicalNum;
        }
    }
//    else if([segue.identifier isEqualToString:@"ShowAlertMessage"]){
//        MachineInfomationViewController *vc = (MachineInfomationViewController  *)segue.destinationViewController;
//        if (self.tag == DeviceTypeOnline) {
//            vc.machine = sender;
//        }else{
//            vc.medicalNum = sender;
//        }
//
//    }
    else if([segue.identifier isEqualToString:@"ShowDeviceDetail"]){
        DeviceDetailController *vc = (DeviceDetailController *)segue.destinationViewController;
        if (self.tag == DeviceTypeOnline) {
            vc.machine = sender;
        }else{
            vc.medicalNum = sender;
        }
    }
}
#pragma mark === 永久闪烁的动画 ======
-(CABasicAnimation *)opacityForever_Animation:(float)time
{
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"opacity"];//必须写opacity才行。
    animation.fromValue = [NSNumber numberWithFloat:1.0f];
    animation.toValue = [NSNumber numberWithFloat:0.0f];//这是透明度。
    animation.autoreverses = YES;
    animation.duration = time;
    animation.repeatCount = 6;
    animation.removedOnCompletion = NO;
    animation.fillMode = kCAFillModeForwards;
    animation.timingFunction=[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];///没有的话是均匀的动画。
    return animation;
}
- (void)setBorderWithView:(UIView *)view top:(BOOL)top left:(BOOL)left bottom:(BOOL)bottom right:(BOOL)right borderColor:(UIColor *)color borderWidth:(CGFloat)width
{
    
    if (top) {
        CALayer *layer = [CALayer layer];
        layer.frame = CGRectMake(0, 0, view.frame.size.width, width);
        layer.backgroundColor = color.CGColor;
        [view.layer addSublayer:layer];
    }
    if (left) {
        CALayer *layer = [CALayer layer];
        layer.frame = CGRectMake(0, 0, width, view.frame.size.height);
        layer.backgroundColor = color.CGColor;
        [view.layer addSublayer:layer];
    }
    if (bottom) {
        CALayer *layer = [CALayer layer];
        layer.frame = CGRectMake(0, view.frame.size.height - width, view.frame.size.width, width);
        layer.backgroundColor = color.CGColor;
        [view.layer addSublayer:layer];
    }
    if (right) {
        CALayer *layer = [CALayer layer];
        layer.frame = CGRectMake(view.frame.size.width - width, 0, width, view.frame.size.height);
        layer.backgroundColor = color.CGColor;
        [view.layer addSublayer:layer];
    }
}
@end
