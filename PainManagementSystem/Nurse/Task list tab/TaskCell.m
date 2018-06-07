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
    [self.treatmentButton setBackgroundColor:UIColorFromHex(0xf0f0f0)];
    [self.treatmentButton.layer setMasksToBounds:YES];
    
    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:self.treatmentButton.bounds byRoundingCorners:UIRectCornerBottomLeft | UIRectCornerTopRight cornerRadii:CGSizeMake(15, 15)];

    CAShapeLayer *maskLayer = [[CAShapeLayer alloc]init];

    maskLayer.frame = self.treatmentButton.bounds;
    maskLayer.path = maskPath.CGPath;
    self.treatmentButton.layer.mask = maskLayer;

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
//            self.statusImage.image = [UIImage imageNamed:@""];
            self.statusImage.alpha = 0;

            break;
            
        case CellStyleGrey_DownLoadedUnRunning:
            [self.scanButton setImage:[UIImage imageNamed:@"scancode"] forState:UIControlStateNormal];
            self.statusImage.image = [UIImage imageNamed:@"notstarted"];
            self.statusImage.alpha = 1;

            break;
        
        case CellStyleGreen_DownLoadedRunning:

            self.statusImage.animationImages = [self animationImages];
            self.statusImage.animationDuration = 1;
            [self.statusImage startAnimating];
            self.statusImage.alpha = 1;

            break;
            
        case CellStyleBlue_DownLoadedFinishRunning:
            [self.scanButton setImage:[UIImage imageNamed:@"remark"] forState:UIControlStateNormal];
            self.statusImage.image = [UIImage imageNamed:@"finished"];
            self.statusImage.alpha = 1;

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
- (void)setBorderWithView:(UIView *)view top:(BOOL)top left:(BOOL)left bottom:(BOOL)bottom right:(BOOL)right borderColor:(UIColor *)color borderWidth:(CGFloat)width
{
    
    if (top) {
        CALayer *layer = [CALayer layer];
        layer.frame = CGRectMake(0, 0, view.frame.size.width, width);
        layer.backgroundColor = color.CGColor;
        [view.layer addSublayer:layer];
    }
    if (left) {
        CALayer *layer = [CALayer layer];
        layer.frame = CGRectMake(0, 0, width, view.frame.size.height);
        layer.backgroundColor = color.CGColor;
        [view.layer addSublayer:layer];
    }
    if (bottom) {
        CALayer *layer = [CALayer layer];
        layer.frame = CGRectMake(0, view.frame.size.height - width, view.frame.size.width, width);
        layer.backgroundColor = color.CGColor;
        [view.layer addSublayer:layer];
    }
    if (right) {
        CALayer *layer = [CALayer layer];
        layer.frame = CGRectMake(view.frame.size.width - width, 0, width, view.frame.size.height);
        layer.backgroundColor = color.CGColor;
        [view.layer addSublayer:layer];
    }
}

@end
