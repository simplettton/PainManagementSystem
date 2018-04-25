//
//  PatientModel.m
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/4/12.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import "PatientModel.h"

@implementation PatientModel

-(instancetype)initWithDic:(NSDictionary *)dict{
    if (self = [super init]) {
        
        self.name = dict[@"name"];
        self.birthdayString = dict[@"birthday"];

        self.gender = dict[@"gender"];
        
        NSNumber *ageNumber = dict[@"age"];

        //0岁显示<1岁
        if ([ageNumber integerValue]==0) {
            self.age = [NSString stringWithFormat:@"<1岁"];
        }else{
            self.age = [NSString stringWithFormat:@"%d岁",[ageNumber intValue]];
        }

        
        self.medicalRecordNum = dict[@"medicalrecordnum"];
        self.contact = dict[@"contact"];
        
        if ([dict[@"bednum"]isEqual:[NSNull null]]) {
            self.bednum = @"";
        }else{
            self.bednum = dict[@"bednum"];
        }

        
        self.registeredTimeString = dict[@"registeredtime"];
        
        self.birthday = (NSData *)[NSDate dateWithTimeIntervalSince1970:[self.birthdayString doubleValue]];
        self.registeredTime = (NSData *)[NSDate dateWithTimeIntervalSince1970:[self.registeredTimeString doubleValue]];
        
    }
    return self;
}
+(instancetype)modelWithDic:(NSDictionary* )dict{
    
    return [[self alloc] initWithDic:dict];
    
}
@end
