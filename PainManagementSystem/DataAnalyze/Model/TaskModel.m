//
//  TaskModel.m
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/4/18.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import "TaskModel.h"

@implementation TaskModel
-(instancetype)initWithDic:(NSDictionary *)dict{
    if (self = [super init]) {
        
    }
    return self;
}
+(instancetype)modelWithDic:(NSDictionary *)dict{
                                                                                                                                                                                                                                                                                                                                                                                                                                                
        return [[self alloc] initWithDic:dict];
}
@end
