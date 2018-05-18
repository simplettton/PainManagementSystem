//
//  RecordItemCell.h
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/3/28.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RecordItemCell : UITableViewCell

//几种cell共同部分
@property (weak, nonatomic) IBOutlet UIView *backGroundView;
@property (weak, nonatomic) IBOutlet UIView *titleView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

//中医病历采集 西医病历采集 设备治疗处方 cell 有的内置tableview
@property (weak, nonatomic) IBOutlet UITableView *insertTableView;

//内容label
@property (weak, nonatomic) IBOutlet UILabel *medicalNumLabel;
@property (weak, nonatomic) IBOutlet UILabel *patientLabel;
@property (weak, nonatomic) IBOutlet UILabel *vasLabel;
@property (weak, nonatomic) IBOutlet UILabel *contentLabel;
@property (weak, nonatomic) IBOutlet UIImageView *resultImageView;

@end
