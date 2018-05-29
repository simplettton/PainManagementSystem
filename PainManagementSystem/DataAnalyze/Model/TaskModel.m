//
//  TaskModel.m
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/4/18.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//
#define ElectrotherapyTypeValue 56833
#define AirProTypeValue 7681
#define AladdinTypeValue 57119
#import "TaskModel.h"
#import "AppDelegate.h"
#import "MachineSeriesModel.h"

@implementation TaskModel
-(instancetype)initWithDic:(NSDictionary *)dict{
    if (self = [super init]) {
        

        
        self.patientName = dict[@"name"];
        self.medicalRecordNum = dict[@"medicalrecordnum"];
        if (![dict[@"creator"]isKindOfClass:[NSNull class]]) {
            self.doctorName = dict[@"creator"];
        }


        NSDictionary *treatParam = dict[@"treatparam"];
        self.treatParam = treatParam;
        self.machineTypeNumber = treatParam[@"machinetype"];
        
        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        NSDictionary *typeDic = appDelegate.typeDic;
        MachineSeriesModel *machineSeries = typeDic[treatParam[@"machinetype"]];
        self.machineType = machineSeries.name;

        self.treatTime = treatParam[@"time"];
        //治疗模式
        self.treatMode = treatParam[@"modeshowname"];
        self.paramlist = treatParam[@"paramlist"];
        
        //治疗方案
        self.treatmentScheduleName = dict[@"selecttreatargstext"];
        
        //任务类型
        self.taskStateNumber = dict[@"taskstate"];
        self.state = [self.taskStateNumber intValue];

        //任务id
        self.ID = dict[@"id"];
        
        //是否关注设备
        self.isFocus = ([dict[@"isfocus"]intValue] == 1)? YES:NO;
        
        //治疗完成时间
        
        NSString *finishTimeString = dict[@"finishtime"];
        self.finishTime = (NSDate *)[NSDate dateWithTimeIntervalSince1970:[finishTimeString doubleValue]];
        self.finishTimeString = dict[@"finishtime"];
        
        //实际下发序列号
        self.serialNum = dict[@"serialnum"];
        
    }
    return self;
}
+(instancetype)modelWithDic:(NSDictionary *)dict{
    
    return [[self alloc] initWithDic:dict];
}
@end
