//
//  FocusMachineAlertView.m
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/4/4.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//


#import "FocusMachineAlertView.h"
#import "LocalMachineModel.h"
#import "BaseHeader.h"
#import "BEButton.h"
#import "Pack.h"
#define SERVICE_UUID           @"1b7e8251-2877-41c3-b46e-cf057c562023"
#define TX_CHARACTERISTIC_UUID @"5e9bf2a8-f93f-4481-a67e-3b2f4a07891a"
#define RX_CHARACTERISTIC_UUID @"8ac32d3f-5cb9-4d44-bec2-ee689169f626"
@interface FocusMachineAlertView()
@property (weak, nonatomic) IBOutlet UIView *backGroundView;
@property (weak, nonatomic) IBOutlet UILabel *medicalNumLabel;
@property (weak, nonatomic) IBOutlet UILabel *patientNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *bedNumLabel;
@property (weak, nonatomic) IBOutlet UILabel *machineTypeLabel;
@property (weak, nonatomic) IBOutlet UILabel *machineNickLabel;
@property (weak, nonatomic) IBOutlet UILabel *taskStateLabel;
@property (weak, nonatomic) IBOutlet UILabel *machineStateLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;

@property (weak, nonatomic) IBOutlet BEButton *focusButton;
@property (weak, nonatomic) IBOutlet BEButton *findButton;

//蓝牙设备
@property (nonatomic,strong) NSString *BLEDeviceName;
@property (strong ,nonatomic) CBPeripheral *peripheral;
@property (nonatomic,strong) CBCharacteristic *sendCharacteristic;
@property (nonatomic,strong) CBCharacteristic *receiveCharacteristic;
@end
@implementation FocusMachineAlertView{
    BabyBluetooth *baby;
}
-(void)awakeFromNib{
    [super awakeFromNib];
    self.backgroundColor = [[UIColor blackColor]colorWithAlphaComponent:0.5];

}

+(void)alertControllerAboveIn:(UIViewController *)controller withDataModel:(MachineModel *)machine returnBlock:(returnBlock)returnEvent{
    
    FocusMachineAlertView *view = [[NSBundle mainBundle]loadNibNamed:@"FocusMachineAlertView" owner:nil options:nil][0];
    
    view.frame = CGRectMake(0, 0, KScreenWidth, KScreenHeight);
    
    view.returnEvent = returnEvent;
    
    //传入字典更新ui
    if (machine) {
        [view configureUIWithDataModel:machine];
        view.dataModel = machine;
        if ([machine.type isEqualToString:@"血瘘"]) {
            view.isLocalMachine = YES;

        }else{
            view.isLocalMachine = NO;
        }
    }
    
    [controller.view addSubview:view];
    
    CGAffineTransform transform = CGAffineTransformScale(CGAffineTransformIdentity, 1.0, 1.0);
    
    view.backGroundView.transform = CGAffineTransformScale(CGAffineTransformIdentity,0.2,0.2);
    
    view.backGroundView.alpha = 0;
    
    [UIView animateWithDuration:0.3 delay:0.1 usingSpringWithDamping:0.5 initialSpringVelocity:10 options:UIViewAnimationOptionCurveLinear animations:^{
        view.backGroundView.transform = transform;
        view.backGroundView.alpha = 1;
    } completion:^(BOOL finished) {
        
    }];
}
- (IBAction)close:(id)sender {
    self.returnEvent(@"我按了取消按钮");
    [self removeFromSuperview];
    [baby cancelScan];
    [baby cancelAllPeripheralsConnection];
}
- (IBAction)tapFocusButton:(id)sender {
    self.returnEvent(@"");
    [baby cancelScan];
    [baby cancelAllPeripheralsConnection];
    [self removeFromSuperview];
}
- (IBAction)tapFindMechineButton:(id)sender {
    if (!_isLocalMachine) {
        [[NetWorkTool sharedNetWorkTool]POST:[HTTPServerURLString stringByAppendingString:@"Api/OnlineDevice/Beep"] params:@{@"cpuid":self.dataModel.cpuid}
                                    hasToken:YES success:^(HttpResponse *responseObject) {
                                        if ([responseObject.result intValue] == 0) {
                                            [SVProgressHUD showErrorWithStatus:responseObject.errorString];
                                        }
                                    } failure:nil];
    }else{
        //本地设备
        baby = [BabyBluetooth shareBabyBluetooth];
        [self babyDelegate];
        self.BLEDeviceName = [[NSString alloc]init];
        if ([self.dataModel.serialNum isEqualToString:@"P06A17A00001"]) {
            self.BLEDeviceName = @"ALX420";
        }
        baby.scanForPeripherals().begin();
    }

}

-(void)configureUIWithDataModel:(MachineModel *)machine
{
    //patient information
    self.medicalNumLabel.text = [NSString stringWithFormat:@"病历号： %@",machine.userMedicalNum];
    self.patientNameLabel.text = [NSString stringWithFormat:@"病人姓名： %@",machine.userName];
    
    if ([machine.userBedNum isEqualToString:@""]) {
        self.bedNumLabel.hidden = YES;
    }else{
        self.bedNumLabel.hidden = NO;
        self.bedNumLabel.text = [NSString stringWithFormat:@"病床号： %@",machine.userBedNum];
    }

    //machine information
    self.machineTypeLabel.text = [NSString stringWithFormat:@"治疗设备：    %@", machine.type];
    self.machineNickLabel.text = [NSString stringWithFormat:@"设备昵称：    %@",machine.name];
    
    NSString *treatmentState = [NSString string];
    switch ([machine.taskStateNumber intValue]) {
        case 0:
            treatmentState = @"处方尚未下发";
            break;
        case 1:
            treatmentState = @"处方已下发，治疗尚未开始";
            break;
        case 3:
            treatmentState = @"诊疗进行中";
            break;
        case 7:
            treatmentState = @"治疗结束，尚未VAS评分";
            break;
        case 15:
            treatmentState = @"疗程结束";
            
            break;
        default:
            treatmentState = @"未知";
            break;
    }
    if ([machine.type isEqualToString:@"血瘘"]) {
        
        self.focusButton.enabled = ![self checkLocalMachineFocus:machine.taskId];
        
    }else{
        if(machine.isFocus == NO){
            self.focusButton.enabled = YES;
        }else{
            self.focusButton.enabled = NO;
        }
    }
    if (self.focusButton.enabled) {
        [self.focusButton setTitle:@"设置关注" forState:UIControlStateNormal];
    }else{
        [self.focusButton setTitle:@"已关注" forState:UIControlStateNormal];
    }
    

    self.findButton.hidden = ([treatmentState isEqualToString:@"处方尚未下发"]||[treatmentState isEqualToString:@"疗程结束"]);

    self.taskStateLabel.text = [NSString stringWithFormat:@"治疗状态：    %@",treatmentState];

    if (machine.state) {
            self.machineStateLabel.text = [NSString stringWithFormat:@"设备状态：    %@",machine.state];
    }else{
        self.machineStateLabel.text = @"设备状态：    未知";
    }
    if ([machine.treatTimeNumber intValue] == 0) {
        self.timeLabel.hidden = YES;
    }else{
        self.timeLabel.hidden = NO;
        self.timeLabel.text = [NSString stringWithFormat:@"治疗时间：    %@",machine.treatTime];
    }
}
#pragma mark - BLE
-(void)babyDelegate{
    
    __weak typeof(self) weakSelf = self;
    __weak typeof(BabyBluetooth*) weakBaby = baby;
    [baby setBlockOnCentralManagerDidUpdateState:^(CBCentralManager *central) {
        if (@available(iOS 10.0, *)) {
            if (central.state == CBManagerStatePoweredOff) {
                if (weakSelf) {
                    [SVProgressHUD showErrorWithStatus:@"该设备尚未打开蓝牙,请在设置中打开"];
                }
            }else if(central.state == CBManagerStatePoweredOn) {
                weakBaby.scanForPeripherals().begin();
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
                    
                    [weakSelf performSelector:@selector(BleBeep) withObject:nil afterDelay:0.5];
                    
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
//                       [weakSelf handleCompleteData:data];
                   }
                   
               }];
    });
}
-(void)BleBeep{
    [self writeWithCmdid:0X90 data:nil];
}
-(void)writeWithCmdid:(Byte)cmdid data:(NSData*)data{
    
    [self.peripheral writeValue:[Pack packetWithCmdid:cmdid
                                          dataEnabled:YES
                                                 data:data]
              forCharacteristic:self.sendCharacteristic
                           type:CBCharacteristicWriteWithResponse];
}

#pragma - private method
-(BOOL)checkLocalMachineFocus:(NSString *)taskId{
    NSArray *localMachineTaskIds = [self returnLocalMachineTaskIdArray];
    if ([localMachineTaskIds containsObject:taskId]) {
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

@end
