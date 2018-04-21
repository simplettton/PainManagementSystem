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



@property (weak, nonatomic) IBOutlet UIImageView *clockImageView;


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

-(void)configureWithStyle:(CellStyle)style message:(NSString *)message{
    
    self.style =style;

    
    switch (style) {
            
        //三种灰色未治疗结束的模板
        case CellStyleGrey_Unfinished:
            
            self.topView.backgroundColor = UIColorFromHex(0xf9f9f9);
            [self.machineStateLabel setTextColor:UIColorFromHex(kBlueColor)];
            [self.machineNameLabel setTextColor:UIColorFromHex(kBlueColor)];
            break;
        
        //灰色未治疗结束
        case CellStyleNotStarted_MachineStop:
            [self configureWithStyle:CellStyleGrey_Unfinished message:nil];
            self.machineStateLabel.text = @"本次治疗未开始";
            break;
        case CellStyleOngoing_MachineStop:
            [self configureWithStyle:CellStyleGrey_Unfinished message:nil];
            self.machineStateLabel.text = @"当前设备停止了";
            break;
        case CellStyleOngoing_MachinePause:
            [self configureWithStyle:CellStyleGrey_Unfinished message:nil];
            self.machineStateLabel.text = @"当前设备暂停中";
            break;

        //治疗结束
        case CellStyleFinished_MachineStop:
            
            self.topView.backgroundColor =UIColorFromHex(0xf9f9f9);
            self.machineStateLabel.text = @"本次治疗结束";
            [self.machineStateLabel setTextColor:UIColorFromHex(kBlueColor)];
            [self.machineNameLabel setTextColor:UIColorFromHex(kBlueColor)];
            break;
            

        //治疗中运行
        case CellStyleOngoing_MachineRunning:

            self.topView.backgroundColor = UIColorFromHex(kGreenColor);
            self.machineStateLabel.text = (message == nil)?@"  00:30":message;
            [self.machineStateLabel setTextColor:UIColorFromHex(kGreenColor)];
            [self.machineNameLabel setTextColor:[UIColor whiteColor]];
            
            break;
        
        case CellStyle_MachineException:
            
            self.topView.backgroundColor = UIColorFromHex(kOrangeColor);
            
            [self.middleImageView.layer addAnimation:[self opacityForever_Animation:0.5] forKey:nil];
            [self.machineStateLabel.layer addAnimation:[self opacityForever_Animation:0.5] forKey:nil];
        
            self.machineStateLabel.text = (message == nil)?@"气囊类型不合适":message;
            [self.machineStateLabel setTextColor:UIColorFromHex(kOrangeColor)];
            [self.machineNameLabel setTextColor:[UIColor whiteColor]];
            
            break;
            
        //local machine
        case CellStyle_LocalConnect:
            
            self.topView.backgroundColor = UIColorFromHex(kGreenColor);
            [self.machineNameLabel setTextColor:[UIColor whiteColor]];
            

            break;
        case CellStyle_LocalUnconnect:
            
            self.topView.backgroundColor =UIColorFromHex(0xf9f9f9);
            [self.machineNameLabel setTextColor:UIColorFromHex(kBlueColor)];
            

            break;
        case CellStyle_LocalRunning:
            
            self.topView.backgroundColor = UIColorFromHex(kGreenColor);
            [self.machineNameLabel setTextColor:[UIColor whiteColor]];

            
            break;
        case CellStyle_LocalUnrunning:
            
            self.topView.backgroundColor = UIColorFromHex(kGreenColor);
            [self.machineNameLabel setTextColor:[UIColor whiteColor]];
            
        default:
            break;
    }

    //online
    self.clockImageView.hidden = (style != CellStyleOngoing_MachineRunning);
    self.leftButton.hidden  = (style != CellStyleOngoing_MachineRunning);
    self.rightButton.hidden  = (style != CellStyleOngoing_MachineRunning);
    self.middleImageView.hidden = (style != CellStyle_MachineException);
    self.playButton.hidden = (style == CellStyleOngoing_MachineRunning ||style == CellStyle_MachineException ||style == CellStyleFinished_MachineStop);
    self.remarkButton.hidden = (style == CellStyleFinished_MachineStop || style == CellStyle_LocalUnconnect)?NO:YES;
    
    
    //Local
    self.connectButton.hidden = (style == CellStyle_LocalUnconnect)? NO:YES;
    
    
    self.BLEPlayButton.hidden = ((style == CellStyle_LocalUnconnect)||(style == CellStyle_LocalRunning))?YES:NO;
    self.BLEPauseButton.hidden = ((style == CellStyle_LocalUnconnect)||(style == CellStyle_LocalUnrunning))?YES:NO;
    self.BLEStopButton.hidden = ((style == CellStyle_LocalUnconnect)||(style == CellStyle_LocalUnrunning))?YES:NO;
    
    
}
#pragma mark - animation
-(CABasicAnimation *)opacityForever_Animation:(float)time
{
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"opacity"];//必须写opacity才行。
    animation.fromValue = [NSNumber numberWithFloat:1.0f];
    animation.toValue = [NSNumber numberWithFloat:0.0f];//这是透明度。
    animation.autoreverses = YES;
    animation.duration = time;
    animation.repeatCount = MAXFLOAT;
    animation.removedOnCompletion = NO;
    animation.fillMode = kCAFillModeForwards;
    animation.timingFunction=[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];///没有的话是均匀的动画。
    return animation;
}

@end
