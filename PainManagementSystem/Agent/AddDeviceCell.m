//
//  AddDeviceCell.m
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/3/21.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import "AddDeviceCell.h"

@implementation AddDeviceCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.ringButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
