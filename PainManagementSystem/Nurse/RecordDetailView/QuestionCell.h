//
//  QuestionCell.h
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/3/29.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface QuestionCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIView *questionBorderView;
@property (weak, nonatomic) IBOutlet UILabel *questionNameLabel;

@property (weak, nonatomic) IBOutlet UILabel *selectionsLabel;

@end
