//
//  RecordItemCell.m
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/3/28.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import "RecordItemCell.h"
#import "BaseHeader.h"
@implementation RecordItemCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.backGroundView.layer.borderWidth = 0.5f;
    self.backGroundView.layer.borderColor = UIColorFromHex(0xbbbbbb).CGColor;

}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
