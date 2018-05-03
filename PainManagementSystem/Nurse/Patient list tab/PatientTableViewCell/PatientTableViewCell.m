//
//  PatientTableViewCell.m
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/3/26.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import "PatientTableViewCell.h"
#import "BaseHeader.h"
@interface PatientTableViewCell()
@property (strong, nonatomic) IBOutletCollection(UIButton) NSArray *buttons;

@end
@implementation PatientTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
//    
//    for (UIButton *button in _buttons) {
//        button.layer.borderWidth = 0.5f;
//        button.layer.borderColor = UIColorFromHex(0xbbbbbb).CGColor;
//        [button.layer setCornerRadius:5.0f];
//        [button.layer setMasksToBounds:YES];
//    }

}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}


@end
