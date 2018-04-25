//
//  MachineModel.h
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/4/13.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
@interface MachineModel : NSObject
//设备基本信息
@property(nonatomic,copy)NSString *name;

@property(nonatomic,copy)NSString *cpuid;

@property(nonatomic,copy)NSString *serialNum;

@property(nonatomic,copy)NSString *type;

//设备运行状态（包括设备绑定病人的处方状态）
@property(nonatomic,copy)NSNumber *stateNumber;

@property(nonatomic,copy)NSString *state;

@property(nonatomic,copy)NSNumber *taskStateNumber;

////这两个待定 去除特定的cell刷新还是刷新整个列表
@property(nonatomic,copy)NSNumber *leftTimeNumber;

//@property(nonatomic,copy)NSString *leftTime;
//
@property(nonatomic,copy)NSString *alertMessage;

@property(nonatomic,assign)BOOL isWarning;

//绑定患者信息
@property(nonatomic,copy)NSString *userName;

@property(nonatomic,copy)NSString *userBedNum;

@property(nonatomic,copy)NSString *userMedicalNum;

//显示cellstyle

@property(nonatomic,assign)UInt8 cellStyle;

-(void)changeState:(NSNumber *)machineState;

-(instancetype)initWithDic:(NSDictionary* )dict;

+(instancetype)modelWithDic:(NSDictionary* )dict;
@end
