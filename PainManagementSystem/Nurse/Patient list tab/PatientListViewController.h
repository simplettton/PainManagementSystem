//
//  PatientListViewController.h
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/3/23.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import  "PatientModel.h"
@interface PatientListViewController : UIViewController<UISearchBarDelegate>
@property (nonatomic,strong)PatientModel *patient;
@end
