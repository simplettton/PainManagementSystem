//
//  BETimeLine.h
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/6/5.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BETimeLine : UIView
@property(nonatomic,strong)NSArray *titleArray;
@property(nonatomic, strong)UITableView *tableView;
-(void)setSuperView:(UIView *)superView DataArray:(NSMutableArray *)dataArray;
@end
