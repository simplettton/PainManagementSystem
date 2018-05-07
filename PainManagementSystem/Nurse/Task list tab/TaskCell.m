//
//  TaskCell.m
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/4/2.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import "TaskCell.h"
#import "BaseHeader.h"
#import <QuartzCore/QuartzCore.h>

@implementation TaskCell

- (void)awakeFromNib {
    [super awakeFromNib];
    //设置按钮的边框
    [self.treatmentButton.layer setBorderWidth:0.5f];
    [self.treatmentButton.layer setBorderColor:UIColorFromHex(0xbbbbbb).CGColor];
    [self.treatmentButton.layer setCornerRadius:5.0f];
    [self.treatmentButton.layer setMasksToBounds:YES];
    
    self.patientNameLabel.numberOfLines = 0;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}
-(void)setTypeLableColor:(UIColor *)color{
    [self.typeLabel setTextColor:color];
}
-(void)setAllLableColor:(UIColor *)color{
    for (UILabel *label in self.labels) {
        [label setTextColor:color];
    }
    
}
-(void)configureWithStyle:(CellStyle)style{
    
    self.style = style;
    switch (style) {
        case CellStyle_UnDownLoad:
            [self.scanButton setImage:[UIImage imageNamed:@"scancode"] forState:UIControlStateNormal];
            self.statusImage.image = [UIImage imageNamed:@""];

            break;
            
        case CellStyleGrey_DownLoadedUnRunning:
            [self.scanButton setImage:[UIImage imageNamed:@"scancode"] forState:UIControlStateNormal];
            self.statusImage.image = [UIImage imageNamed:@"notstarted"];

            break;
        
        case CellStyleGreen_DownLoadedRunning:

            self.statusImage.animationImages = [self animationImages];
            self.statusImage.animationDuration = 1;
            [self.statusImage startAnimating];

            break;
            
        case CellStyleBlue_DownLoadedFinishRunning:
            [self.scanButton setImage:[UIImage imageNamed:@"remark"] forState:UIControlStateNormal];
            self.statusImage.image = [UIImage imageNamed:@"finished"];

            break;
        
        case CellStyle_DownLoadedRemarked:
//            self.statusImage.image = [UIImage imageNamed:@""];

            break;
            
        default:
            break;
    }
    
    //完成的任务不显示按钮
    self.scanButton.hidden = (style == CellStyle_DownLoadedRemarked);
//    self.finishImageView.hidden = (style != CellStyle_DownLoadedRemarked);
    self.finishTimeLabel.hidden = (style != CellStyle_DownLoadedRemarked);
    
}

- (NSArray *)animationImages
{
    
    NSMutableArray *imagesArr = [NSMutableArray array];
    
    for (NSUInteger i = 0; i<= 29; i++) {
        UIImage *image = [UIImage imageNamed:[NSString stringWithFormat:@"processing_anim_000%zd",i]];
        if (image) {
            [imagesArr addObject:image];
        }
    }
    return imagesArr;
}


@end
