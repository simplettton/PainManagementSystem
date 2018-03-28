//
//  QuestionnaireTableView.m
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/3/28.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import "QuestionnaireTableView.h"
#import "BaseHeader.h"
@implementation QuestionnaireTableView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/
-(void)awakeFromNib{
    [super awakeFromNib];
    self.allowsSelection = NO;
    self.separatorStyle = UITableViewCellSeparatorStyleNone;
    for (UITableViewCell *cell in self.visibleCells) {
        
        UIView *view = (UIView *)cell.contentView;
        view.layer.borderColor = UIColorFromHex(0xBBBBBB).CGColor;
        view.layer.borderWidth = 0.5f;
        
    }
}
@end
