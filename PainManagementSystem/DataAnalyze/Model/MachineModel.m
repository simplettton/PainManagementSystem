//
//  MachineModel.m
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/4/13.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import "MachineModel.h"

@implementation MachineModel
-(instancetype)initWithDic:(NSDictionary *)dict{
    if (self = [super init]) {
        
        self.name = dict[@"nick"];
        self.serialNum = dict[@"serialnum"];
        self.cpuid = dict[@"cpuid"];
        self.typeNumber = dict[@"machinetype"];
        
        NSDictionary *typeDic = @{
                               @7681:@"空气波",
                               @57119:@"血瘘",
                               @56832:@"电疗",
                               @56833:@"电疗",
                               @56834:@"电疗",
                               @56836:@"电疗"
                               
                               };
        
        self.type = typeDic[self.typeNumber];
        
        self.stateNumber = dict[@"machinestate"];
        
        NSDictionary *machineStateDic = @{
                                          @"0":@"running",
                                          @"1":@"pause",
                                          @"2":@"stop"
                                          };
        
        self.state = machineStateDic[self.stateNumber];
        

        
    }
    return self;
}
+(instancetype)modelWithDic:(NSDictionary* )dict{
    
    return [[self alloc] initWithDic:dict];
    
}
@end
