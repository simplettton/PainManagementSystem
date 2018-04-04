//
//  DeviceCollectionViewCell.m
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/4/4.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import "DeviceCollectionViewCell.h"
#import "BaseHeader.h"
#define kBlueColor 0x5e97fe

#define kOrangeColor 0xf8b273

#define kGreenColor 0x7ede98

#define kGreyColor 0xc1c1c1
@interface DeviceCollectionViewCell()
@property (weak, nonatomic) IBOutlet UIImageView *middleImageView;

@property (weak, nonatomic) IBOutlet UIButton *leftButton;
@property (weak, nonatomic) IBOutlet UIButton *rightButton;

@end
@implementation DeviceCollectionViewCell
-(void)awakeFromNib{
    [super awakeFromNib];
    
    self.contentView.layer.borderWidth = 0.5f;
    self.contentView.layer.borderColor = UIColorFromHex(0xbbbbbb).CGColor;
    [self.contentView.layer setMasksToBounds:YES];
    
    CALayer *layer = [CALayer layer];
    layer.frame = CGRectMake(0, self.topView.frame.size.height - 0.5, self.topView.frame.size.width, 0.5f);
    layer.backgroundColor = UIColorFromHex(0xbbbbbb).CGColor;
    [self.topView.layer addSublayer:layer];
    
    
    
}

-(void)configureWithStyle:(CellStyle)style{
    switch (style) {
            
        case CellStyleGrey_MachineStop:
            
            self.topView.backgroundColor =UIColorFromHex(0xf9f9f9);
//            self.topView.backgroundColor = UIColorFromHex(kGreyColor);
            self.middleImageView.hidden = NO;
            self.leftButton.hidden = YES;
            self.rightButton.hidden = YES;
            
            self.middleImageView.image = [UIImage imageNamed:@"remark"];
            self.machineStateLabel.text = @"本次治疗结束";
            [self.machineStateLabel setTextColor:UIColorFromHex(kBlueColor)];
            [self.machineNameLabel setTextColor:UIColorFromHex(kBlueColor)];
            
            break;
            
        case CellStyleGrey_MachinePause:
            
            self.topView.backgroundColor = UIColorFromHex(0xf9f9f9);
            self.middleImageView.hidden = NO;
            self.leftButton.hidden = YES;
            self.rightButton.hidden = YES;
            
            self.middleImageView.image = [UIImage imageNamed:@"play"];
            self.machineStateLabel.text = @"本次治疗未开始/暂停中";
            [self.machineStateLabel setTextColor:UIColorFromHex(kBlueColor)];
            [self.machineNameLabel setTextColor:UIColorFromHex(kBlueColor)];
            
            break;
            
        case CellStyleGreen_MachineRunning:
            
            self.topView.backgroundColor = UIColorFromHex(kGreenColor);
//            self.contentView.layer.borderColor = UIColorFromHex(kGreenColor).CGColor;
            self.middleImageView.hidden = YES;
            self.leftButton.hidden = NO;
            self.rightButton.hidden = NO;
            
            self.machineStateLabel.text = @"治疗中";
            [self.machineStateLabel setTextColor:UIColorFromHex(kGreenColor)];
            [self.machineNameLabel setTextColor:[UIColor whiteColor]];
            
            break;
            
        case CellStyleOrange_MachineException:
            
            self.topView.backgroundColor = UIColorFromHex(kOrangeColor);
//            self.contentView.layer.borderColor = UIColorFromHex(kOrangeColor).CGColor;
            self.middleImageView.hidden = NO;
            self.leftButton.hidden = YES;
            self.rightButton.hidden = YES;
            
            self.middleImageView.image = [UIImage imageNamed:@"alert"];
            self.machineStateLabel.text = @"气囊类型不合适";
            [self.machineStateLabel setTextColor:UIColorFromHex(kOrangeColor)];
            [self.machineNameLabel setTextColor:[UIColor whiteColor]];
            
            break;
            
        default:
            break;
    }
}

@end
