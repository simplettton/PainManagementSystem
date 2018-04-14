//
//  MachineModel.h
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/4/13.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MachineModel : NSObject

@property(nonatomic,copy)NSString *name;

@property(nonatomic,copy)NSString *cpuid;

@property(nonatomic,copy)NSString *serialNum;

@property(nonatomic,copy)NSNumber *typeNumber;

@property(nonatomic,copy)NSString *type;

@property(nonatomic,copy)NSNumber *stateNumber;

@property(nonatomic,copy)NSString *state;

-(instancetype)initWithDic:(NSDictionary* )dict;

+(instancetype)modelWithDic:(NSDictionary* )dict;
@end
