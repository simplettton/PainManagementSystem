//
//  TaskCell.h
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/4/2.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TaskCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIButton *treatmentButton;
@property (weak, nonatomic) IBOutlet UIButton *scanButton;
@property (weak, nonatomic) IBOutlet UILabel *medicalRecordNumLable;
@property (weak, nonatomic) IBOutlet UILabel *patientNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *typeLabel;
@property (weak, nonatomic) IBOutlet UILabel *doctorNameLable;
-(void)setTypeLableColor:(UIColor *)color;

@end