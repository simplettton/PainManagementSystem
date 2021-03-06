//
//  TaskModel.h
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/4/18.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MachineSeriesModel.h"

@interface TaskModel : NSObject

@property(nonatomic,copy)NSString *ID;

@property(nonatomic,copy)NSNumber *taskStateNumber;

@property(nonatomic,copy)NSString *medicalRecordNum;

@property(nonatomic,copy)NSString *patientName;

@property (nonatomic, assign) NSUInteger state;

@property(nonatomic,copy)NSString *treatMode;

@property(nonatomic,copy)NSString *treatTime;

@property(nonatomic,copy)NSString *treatmentScheduleName;

@property(nonatomic,copy)NSDictionary *treatParam;

@property(nonatomic,copy)NSArray *paramlist;

@property(nonatomic,copy)NSString *machineType;

@property(nonatomic,strong) MachineSeriesModel *machine;

@property(nonatomic,copy)NSNumber *machineTypeNumber;

@property(nonatomic,copy)NSString *doctorName;

@property(nonatomic,assign)BOOL isFocus;

@property(nonatomic,strong)NSDate *finishTime;

@property(nonatomic,copy)NSString *finishTimeString;

//下发处方实际设备
@property(nonatomic,copy)NSString *serialNum;

-(instancetype)initWithDic:(NSDictionary* )dict;

+(instancetype)modelWithDic:(NSDictionary* )dict;

@end
