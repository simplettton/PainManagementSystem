//
//  PatientModel.h
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/4/12.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PatientModel : NSObject
@property(nonatomic,copy)NSString *name;

@property(nonatomic,strong)NSData *birthday;
//实际使用的是这个时间戳
@property(nonatomic,copy)NSString *birthdayString;

@property(nonatomic,copy)NSString *gender;

@property(nonatomic,copy)NSString *age;

@property(nonatomic,copy)NSString *medicalRecordNum;

@property(nonatomic,copy)NSString *contact;

@property(nonatomic,copy)NSString *bednum;

@property(nonatomic,assign)BOOL isInTheTask;

@property(nonatomic,strong)NSData *registeredTime;

@property(nonatomic,copy)NSString *registeredTimeString;

-(instancetype)initWithDic:(NSDictionary* )dict;

+(instancetype)modelWithDic:(NSDictionary* )dict;

@end
