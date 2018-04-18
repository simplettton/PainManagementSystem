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
-(void)configureWithStyle:(CellStyle)style{
    
    self.style = style;
    switch (style) {
        case CellStyle_UnDownLoad:
            [self.scanButton setImage:[UIImage imageNamed:@"scancode"] forState:UIControlStateNormal];
        
            break;
            
        case CellStyleGrey_DownLoadedUnRunning:
            [self.scanButton setImage:[UIImage imageNamed:@"scancode"] forState:UIControlStateNormal];
            break;
        
        case CellStyleGreen_DownLoadedRunning:
            [self.scanButton setImage:[UIImage imageNamed:@"remark"] forState:UIControlStateNormal];
            break;
            
        case CellStyleBlue_DownLoadedFinishRunning:
            [self.scanButton setImage:[UIImage imageNamed:@"remark"] forState:UIControlStateNormal];
            break;
        
        case CellStyle_DownLoadedRemarked:
            [self.scanButton setImage:[UIImage imageNamed:@""] forState:UIControlStateNormal];
            
        default:
            break;
    }
}

@end
