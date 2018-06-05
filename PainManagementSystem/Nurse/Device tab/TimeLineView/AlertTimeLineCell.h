//
//  AlertTimeLineCell.h
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/6/5.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TimeLineModel.h"
@interface AlertTimeLineCell : UITableViewCell

+ (instancetype) timeLineCell:(UITableView *) tableView;

@property (nonatomic,strong)TimeLineModel *model;
@property (weak, nonatomic) IBOutlet UIView *lineView;
@property (weak, nonatomic) IBOutlet UIView *pointView;

@end
