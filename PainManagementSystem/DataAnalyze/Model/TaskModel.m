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

@implementation TaskModel
-(instancetype)initWithDic:(NSDictionary *)dict{
    if (self = [super init]) {
        
        NSDictionary *typeDic =  @{
                                   @7681:@"空气波",
                                   @57119:@"血瘘",
                                   @56832:@"电疗",
                                   @56833:@"电疗100",
                                   @56834:@"电疗200",
                                   @56836:@"电疗400"
                                   };
        self.patientName = dict[@"name"];
        self.medicalRecordNum = dict[@"medicalrecordnum"];
        self.doctorName = dict[@"creator"];

        NSDictionary *treatParam = dict[@"treatparam"];
        self.treatParam = treatParam;
        self.machineTypeNumber = treatParam[@"machinetype"];
        self.machineType = typeDic[treatParam[@"machinetype"]];
        self.treatTime = treatParam[@"time"];
        //治疗模式
        self.treatMode = treatParam[@"modeshowname"];
        self.paramlist = treatParam[@"paramlist"];
        
        //任务类型
        self.taskStateNumber = dict[@"taskstate"];
        self.state = [self.taskStateNumber intValue];

        //任务id
        self.ID = dict[@"id"];
        
    }
    return self;
}
+(instancetype)modelWithDic:(NSDictionary *)dict{
    
    return [[self alloc] initWithDic:dict];
}
@end
