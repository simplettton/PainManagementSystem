//
//  RecordItemCell.h
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/3/28.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RecordItemCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIView *backGroundView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *titleView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@end
