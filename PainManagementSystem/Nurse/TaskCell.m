//
//  TaskCell.m
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/4/2.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import "TaskCell.h"
#import "BaseHeader.h"
@implementation TaskCell

- (void)awakeFromNib {
    [super awakeFromNib];
    //设置按钮的边框
    [self.treatmentButton.layer setBorderWidth:0.5f];
    [self.treatmentButton.layer setBorderColor:UIColorFromHex(0xbbbbbb).CGColor];
    [self.treatmentButton.layer setCornerRadius:5.0f];
    [self.treatmentButton.layer setMasksToBounds:YES];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}
-(void)setTypeLableColor:(UIColor *)color{
    [self.typeLabel setTextColor:color];
}

@end
