//
//  MachineModel.m
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/4/13.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import "MachineModel.h"
#import "AppDelegate.h"
#import "MachineSeriesModel.h"
typedef enum _CellStyle {
    
    CellStyleNotStarted_MachineStop = 0,
    CellStyleOngoing_MachineRunning,
    CellStyleOngoing_MachinePause,
    CellStyleOngoing_MachineStop,
    CellStyleFinished_MachineStop,
    CellStyle_MachineException,
    CellStyle_MachineOffline,
    
    CellStyleGrey_Unfinished,//通用

    CellStyle_LocalUnconnect,
    CellStyle_LocalConnect,
    CellStyle_LocalUnrunning,
    CellStyle_LocalRunning
} CellStyle;
@implementation MachineModel
-(instancetype)initWithDic:(NSDictionary *)dict{
    if (self = [super init]) {
        id nickName = dict[@"nick"];
        if (nickName != [NSNull null]) {
            self.name = dict[@"nick"];
        }else{
            self.name = @"";
        }
        self.serialNum = dict[@"serialnum"];
        self.cpuid = dict[@"cpuid"];
        NSNumber *typeNumber = dict[@"machinetype"];

        //设备类型
        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        NSDictionary *typeDic = appDelegate.typeDic;
        MachineSeriesModel *machineSeries = typeDic[typeNumber];
        self.machineInfo = machineSeries;
        
        if (typeDic[typeNumber]) {
            
            self.type = machineSeries.name;

        }else{
            self.type = @"未知";
        }
        
        self.isLocal = machineSeries.isLocal;
        self.isFocus = ([dict[@"isfocus"]intValue] == 1)? YES:NO;
        self.stateNumber = dict[@"machinestate"];
        self.treatTimeNumber = dict[@"treattime"];
        self.treatTime = [NSString stringWithFormat:@"%@min",self.treatTimeNumber];
    
        
        NSDictionary *machineStateDic = @{
                                          @0:@"设备运行中",
                                          @1:@"设备暂停中",
                                          @2:@"设备未运行",
                                          @3:@"设备运行中",
                                          @4:@"设备不在线"
                                          };
        
        
        self.state = machineStateDic[self.stateNumber];
        
        //配置显示cellstyle

        self.taskStateNumber = dict[@"taskstate"];
        
        switch ([self.taskStateNumber intValue]) {
            case 0:
                self.taskStateString = @"处方尚未下发";
                break;
            case 1:
                self.taskStateString = @"处方已下发，治疗尚未开始";
                break;
            case 3:
                self.taskStateString = @"诊疗进行中";
                break;
            case 7:
                self.taskStateString = @"治疗结束，尚未VAS评分";
                break;
            case 15:
                self.taskStateString = @"疗程结束";
                
                break;
            default:
                self.taskStateString = @"未知";
                break;
        }
        
        switch ([self.taskStateNumber integerValue]) {
            case 1:
                self.cellStyle = CellStyleNotStarted_MachineStop;
                break;
            case 3:
            {
                switch ([self.stateNumber integerValue]) {
                    case 0:
                        self.cellStyle = CellStyleOngoing_MachineRunning;
                        break;
                    case 1:
                        self.cellStyle = CellStyleOngoing_MachinePause;
                        break;
                    case 2:
                        self.cellStyle = CellStyleOngoing_MachineStop;
                        break;
                    default:
                        break;
                }
            }
                break;
            case 7:
                self.cellStyle = CellStyleFinished_MachineStop;
                break;
            default:
                break;
        }
        
        if ([self.state isEqualToString:@"设备不在线"]) {
            if ([dict[@"taskstate"] integerValue] != 7) {
                self.cellStyle = CellStyle_MachineOffline;
            }
        }
        //绑定患者信息
        self.userName = dict[@"name"];
        if ([dict[@"bednum"]isEqual:[NSNull null]]) {
            self.userBedNum = @"";
        }else{
            self.userBedNum = dict[@"bednum"];
        }
        self.userAge = dict[@"age"];
        self.userContact = dict[@"contact"];
        self.userMedicalNum = dict[@"medicalrecordnum"];
        
        self.taskId = dict[@"id"];
        
    }
    return self;
}
-(void)changeState:(NSNumber *)machineState{
    NSArray *stateArray = @[@0,@1,@2];
    if ([stateArray containsObject:machineState]) {
        self.stateNumber = machineState;
        
        switch ([self.stateNumber integerValue]) {
            case 0:
                self.cellStyle = CellStyleOngoing_MachineRunning;
                break;
            case 1:
                self.cellStyle = CellStyleOngoing_MachinePause;
                break;
            case 2:
                self.cellStyle = CellStyleOngoing_MachineStop;
                break;
            default:
                break;
        }
        
    }else{
        return;
    }
}
+(instancetype)modelWithDic:(NSDictionary* )dict{
    
    return [[self alloc] initWithDic:dict];
    
}
@end
