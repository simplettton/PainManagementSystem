//
//  TreatRecordCell.h
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/3/27.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TreatRecordCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *medicalRecodNumLB;
@property (weak, nonatomic) IBOutlet UILabel *treatTimeLB;
@property (weak, nonatomic) IBOutlet UILabel *physicalTreatLB;
@property (weak, nonatomic) IBOutlet UILabel *vasBeforeLB;
@property (weak, nonatomic) IBOutlet UILabel *vasAfterLB;
@property (weak, nonatomic) IBOutlet UILabel *vasLabel;

@property (weak, nonatomic) IBOutlet UIButton *markButton;


@end
