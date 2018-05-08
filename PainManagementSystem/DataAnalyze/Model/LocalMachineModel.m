//
//  LocalMachineModel.m
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/4/28.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import "LocalMachineModel.h"
typedef enum _CellStyle {

    CellStyle_LocalUnconnect = 8,
    CellStyle_LocalConnect,
    CellStyle_LocalUnrunning,
    CellStyle_LocalRunning
} CellStyle;
@implementation LocalMachineModel
-(void)encodeWithCoder:(NSCoder *)aCoder{
    [aCoder encodeObject:self.taskId forKey:@"taskId"];
    [aCoder encodeObject:self.name forKey:@"name"];
    [aCoder encodeObject:self.cpuid forKey:@"cpuid"];
    [aCoder encodeObject:self.serialNum forKey:@"serialNum"];
    [aCoder encodeObject:self.type forKey:@"type"];
    [aCoder encodeObject:self.userBedNum forKey:@"userBedNum"];
    [aCoder encodeObject:self.userName forKey:@"userName"];
    [aCoder encodeObject:self.userMedicalNum forKey:@"userMedicalNum"];
    
    [aCoder encodeObject:self.state forKey:@"state"];
    [aCoder encodeInteger:self.cellStyle forKey:@"cellStyle"];
}
-(instancetype)initWithCoder:(NSCoder *)aDecoder{
    if (self = [super init]) {
        
        self.taskId = [aDecoder decodeObjectForKey:@"taskId"];
        self.name = [aDecoder decodeObjectForKey:@"name"];
        self.cpuid = [aDecoder decodeObjectForKey:@"cpuid"];
        self.serialNum = [aDecoder decodeObjectForKey:@"serialNum"];
        self.type = [aDecoder decodeObjectForKey:@"type"];
        self.userMedicalNum = [aDecoder decodeObjectForKey:@"userMedicalNum"];
        self.userName = [aDecoder decodeObjectForKey:@"userName"];
        self.userBedNum = [aDecoder decodeObjectForKey:@"userBedNum"];
        
        self.state = [aDecoder decodeObjectForKey:@"state"];
        self.cellStyle = [aDecoder decodeIntegerForKey:@"cellStyle"];
    }
    return self;
}

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
        
        
        NSDictionary *typeDic = @{
                                  @57119:@"血瘘",
                                  };
        if (typeDic[typeNumber]) {
            self.type = typeDic[typeNumber];
        }else{
            self.type = @"未知";
        }
        //绑定患者信息
        self.userName = dict[@"name"];
        if ([dict[@"bednum"]isEqual:[NSNull null]]) {
            self.userBedNum = @"";
        }else{
            self.userBedNum = dict[@"bednum"];
        }
        self.userMedicalNum = dict[@"medicalrecordnum"];
        
        self.state = @"unconnect";
        
        self.taskId = dict[@"id"];
    }
    return self;
}
+(instancetype)modelWithDic:(NSDictionary *)dict{
    return [[self alloc]initWithDic:dict];
}
-(void)changeState:(NSString *)machineState{
//    NSDictionary *stateDic = @
//    {
//        @"connected":[NSNumber numberWithInteger:CellStyle_LocalConnect],
//        @"unconnect":[NSNumber numberWithInteger:CellStyle_LocalUnconnect],
//        @"running":[NSNumber numberWithInteger:CellStyle_LocalRunning],
//        @"unrunning":[NSNumber numberWithInteger:CellStyle_LocalUnrunning],
//    };
//    NSNumber *stateNumber = [stateDic objectForKey:machineState];
    
    self.state = machineState;

}
@end
