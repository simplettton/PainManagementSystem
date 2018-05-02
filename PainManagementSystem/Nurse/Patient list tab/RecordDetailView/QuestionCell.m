//
//  QuestionCell.m
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/3/29.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import "QuestionCell.h"
#import "BaseHeader.h"
@implementation QuestionCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.questionBorderView.layer.borderWidth = 0.5f;
    self.questionBorderView.layer.borderColor = UIColorFromHex(0xbbbbbb).CGColor;
    self.selectionsLabel.preferredMaxLayoutWidth = self.selectionsLabel.frame.size.width;
    self.selectionsLabel.numberOfLines = 0;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

}

@end
