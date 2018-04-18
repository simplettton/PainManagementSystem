//
//  RecordDetailViewController.h
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/3/28.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PatientModel.h"
@interface RecordDetailViewController : UIViewController
@property (nonatomic,strong)NSDictionary *dataDic;
@property (nonatomic,strong)PatientModel *patient;
@end
