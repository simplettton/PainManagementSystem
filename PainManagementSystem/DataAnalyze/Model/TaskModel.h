//
//  TaskModel.h
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/4/18.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TaskModel : NSObject

@property(nonatomic,copy)NSString *medicalRecordNum;

@property(nonatomic,copy)NSString *name;

//是否评分来判断任务是否完成
@property(nonatomic,assign)BOOL isFinish;

//是否下发
@property(nonatomic,assign)BOOL isDownload;

@property(nonatomic,copy)NSDictionary *treatwayDic;

@property(nonatomic,copy)NSString *machineType;

@property(nonatomic,copy)NSString *strong;

@property(nonatomic,copy)NSString *creator;

-(instancetype)initWithDic:(NSDictionary* )dict;

+(instancetype)modelWithDic:(NSDictionary* )dict;

@end
