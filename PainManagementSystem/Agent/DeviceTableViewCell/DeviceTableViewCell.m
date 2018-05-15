//
//  DeviceTableViewCell.m
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/3/20.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import "DeviceTableViewCell.h"
#import "BaseHeader.h"
@implementation DeviceTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    UIView *view = [[UIView alloc] init];
    view.backgroundColor = UIColorFromRGB(0xF6F6F6);
    self.selectedBackgroundView = view;
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}
-(void)setEditing:(BOOL)editing animated:(BOOL)animated{
    if (self.editing == editing) {
        return;
    }
    [super setEditing:editing animated:animated];
    CGFloat moveSpace = 38;
    if (editing) {


        [self.typeLabel setFrame:CGRectMake(self.typeLabel.frame.origin.x - moveSpace, self.typeLabel.frame.origin.y, self.typeLabel.frame.size.width, self.typeLabel.frame.size.height)];

        [self.serialNumLabel setFrame:CGRectMake(self.serialNumLabel.frame.origin.x - moveSpace, self.serialNumLabel.frame.origin.y, self.serialNumLabel.frame.size.width, self.serialNumLabel.frame.size.height)];

        [self.nameLabel setFrame:CGRectMake(self.nameLabel.frame.origin.x - moveSpace, self.nameLabel.frame.origin.y, self.nameLabel.frame.size.width, self.nameLabel.frame.size.height)];

        [self.editButton setFrame:CGRectMake(self.editButton.frame.origin.x - moveSpace, self.editButton.frame.origin.y, self.editButton.frame.size.width, self.editButton.frame.size.height)];

    }else{
        [self.typeLabel setFrame:CGRectMake(self.typeLabel.frame.origin.x + moveSpace , self.typeLabel.frame.origin.y, self.typeLabel.frame.size.width, self.typeLabel.frame.size.height)];

        [self.serialNumLabel setFrame:CGRectMake(self.serialNumLabel.frame.origin.x + moveSpace, self.serialNumLabel.frame.origin.y, self.serialNumLabel.frame.size.width, self.serialNumLabel.frame.size.height)];

        [self.nameLabel setFrame:CGRectMake(self.nameLabel.frame.origin.x + moveSpace, self.nameLabel.frame.origin.y, self.nameLabel.frame.size.width, self.nameLabel.frame.size.height)];

        [self.editButton setFrame:CGRectMake(self.editButton.frame.origin.x + moveSpace, self.editButton.frame.origin.y, self.editButton.frame.size.width, self.editButton.frame.size.height)];
    }
}

@end
