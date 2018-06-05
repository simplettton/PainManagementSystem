//
//  TimeLineModel.m
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/6/5.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import "TimeLineModel.h"

@implementation TimeLineModel
-(instancetype)initWithDic:(NSDictionary *)dic{
    if (self = [super init]) {
        self.title = dic[@"info"];
        self.timeStamp = dic[@"time"];
    }
    return self;
}
+(instancetype)modelWithDic:(NSDictionary *)dic{
    return [[self alloc]initWithDic:dic];
}
@end
