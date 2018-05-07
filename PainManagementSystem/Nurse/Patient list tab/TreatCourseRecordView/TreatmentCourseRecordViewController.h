//
//  TreatmentCourseRecordViewController.h
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/3/27.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PatientModel.h"
@interface TreatmentCourseRecordViewController : UIViewController
@property (nonatomic,strong)PatientModel *patient;
//判断是否从处方列表里进入
@property (nonatomic,strong)NSString *medicalRecordNum;
//判断是否强制评分
@property (nonatomic,assign)BOOL isFocusToStop;
@end
