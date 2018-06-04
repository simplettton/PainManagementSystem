//
//  LocalMachineModel.h
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/4/28.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MachineSeriesModel.h"
@interface LocalMachineModel : NSObject<NSCoding>

//taskId
@property(nonatomic,copy)NSString *taskId;
//设备基本信息
@property(nonatomic,strong) MachineSeriesModel *machineInfo;

@property(nonatomic,copy)NSString *name;

@property(nonatomic,copy)NSString *cpuid;

@property(nonatomic,copy)NSString *serialNum;

@property(nonatomic,copy)NSString *type;

//设备的运行状态
@property(nonatomic,copy)NSString *state;

//cell style
@property(nonatomic,assign)UInt8 cellStyle;

//绑定患者信息
@property(nonatomic,copy)NSString *userName;

@property(nonatomic,copy)NSString *userBedNum;

@property(nonatomic,copy)NSString *userMedicalNum;

@property(nonatomic,copy)NSString *userAge;

@property(nonatomic,copy)NSString *userContact;

-(instancetype)initWithDic:(NSDictionary* )dict;

+(instancetype)modelWithDic:(NSDictionary* )dict;

-(void)changeState:(NSString *)machineState;
@end
