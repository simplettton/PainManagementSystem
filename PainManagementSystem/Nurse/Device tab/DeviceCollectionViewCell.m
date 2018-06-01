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
@property (strong, nonatomic) IBOutletCollection(MultiParamButton) NSArray *controlButtons;


@end
@implementation DeviceCollectionViewCell
-(void)awakeFromNib{
    [super awakeFromNib];
    
    //按钮自带控制参数
    self.playButton.multiParamDic = @{@"cmdcode":@0};
    self.pauseButton.multiParamDic = @{@"cmdcode":@1};
    self.stopButton.multiParamDic = @{@"cmdcode":@2};

    self.contentView.layer.borderWidth = 1.f;
    self.contentView.layer.borderColor = UIColorFromHex(0xe9e7ef).CGColor;
    [self.contentView.layer setMasksToBounds:YES];
    
    CALayer *layer = [CALayer layer];
    layer.frame = CGRectMake(0, self.topView.frame.size.height - 1, self.topView.frame.size.width, 1.f);
    layer.backgroundColor = UIColorFromHex(0xe9e7ef).CGColor;
    [self.topView.layer addSublayer:layer];
    
}

-(void)configureWithStyle:(CellStyle)style message:(NSString *)message{
    
    if(style != CellStyleGrey_Unfinished)
    {
        self.style =style;
    }

    switch (style) {
            
        //三种灰色未治疗结束的模板
        case CellStyleGrey_Unfinished:
            
            self.topView.backgroundColor = UIColorFromHex(0xf0f0f4);
            [self.machineStateLabel setTextColor:UIColorFromHex(kBlueColor)];
            [self.machineNameLabel setTextColor:UIColorFromHex(kBlueColor)];
            break;
        //不在线
        case CellStyle_MachineOffline:
            [self configureWithStyle:CellStyleGrey_Unfinished message:nil];
            self.machineStateLabel.text = @"设备不在线";
            self.middleImageView.image = [UIImage imageNamed:@"offline"];
            break;

        //灰色未治疗结束
        case CellStyleNotStarted_MachineStop:
            [self configureWithStyle:CellStyleGrey_Unfinished message:nil];
            self.machineStateLabel.text = @"治疗尚未开始";
            break;
        case CellStyleOngoing_MachineStop:
            [self configureWithStyle:CellStyleGrey_Unfinished message:nil];
            self.machineStateLabel.text = @"设备未运行";
            [self.playButton setImage:[UIImage imageNamed:@"play_green"] forState:UIControlStateNormal];
            break;
        case CellStyleOngoing_MachinePause:
            [self configureWithStyle:CellStyleGrey_Unfinished message:nil];
            self.machineStateLabel.text = @"设备暂停中";
            [self.playButton setImage:[UIImage imageNamed:@"pause"] forState:UIControlStateNormal];
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
            //601加上1分钟就是持续治疗
            if ([message isEqualToString:@"  10:01"]) {
                message = @"     持续治疗";
            }
            self.machineStateLabel.text = (message == nil)?@"  00:00":message;
            [self.machineStateLabel setTextColor:UIColorFromHex(kGreenColor)];
            [self.machineNameLabel setTextColor:[UIColor whiteColor]];
            
            break;
        
        case CellStyle_MachineException:
            
            self.topView.backgroundColor = UIColorFromHex(kOrangeColor);
            self.machineStateLabel.text = (message == nil)?@"气囊类型不合适":message;
            [self.machineStateLabel setTextColor:UIColorFromHex(kOrangeColor)];
            [self.machineNameLabel setTextColor:[UIColor whiteColor]];
            self.middleImageView.image = [UIImage imageNamed:@"alert"];
            
            break;
            
        //local machine        case CellStyle_LocalConnect:
            
            self.topView.backgroundColor = UIColorFromHex(kGreenColor);
            [self.machineNameLabel setTextColor:[UIColor whiteColor]];
            

            break;
        case CellStyle_LocalUnconnect:
            
            self.topView.backgroundColor = UIColorFromHex(0xefeff4);
            [self.machineNameLabel setTextColor:UIColorFromHex(kBlueColor)];
            

            break;
        case CellStyle_LocalRunning:
            
            self.topView.backgroundColor = UIColorFromHex(kGreenColor);
            [self.machineNameLabel setTextColor:[UIColor whiteColor]];

            
            break;
        case CellStyle_LocalUnrunning:
            
            self.topView.backgroundColor = UIColorFromHex(kGreenColor);
            [self.machineNameLabel setTextColor:[UIColor whiteColor]];
            [self.BLEPlayButton setImage:[UIImage imageNamed:@"play_green"] forState:UIControlStateNormal];
            break;
            
        case CellStyle_LocalPause:
            self.topView.backgroundColor = UIColorFromHex(kGreenColor);
            [self.machineNameLabel setTextColor:[UIColor whiteColor]];
            [self.BLEPlayButton setImage:[UIImage imageNamed:@"pause"] forState:UIControlStateNormal];
            break;
        default:
            break;
    }

    //online
    self.clockImageView.hidden = (style != CellStyleOngoing_MachineRunning);
    self.pauseButton.hidden  = (style != CellStyleOngoing_MachineRunning);
    self.stopButton.hidden  = (style != CellStyleOngoing_MachineRunning);
    self.middleImageView.hidden = !((style == CellStyle_MachineException)||(style == CellStyle_MachineOffline));
    self.playButton.hidden = (style == CellStyleOngoing_MachineRunning ||style == CellStyle_MachineException ||style == CellStyleFinished_MachineStop ||style == CellStyle_MachineOffline);
    self.remarkButton.hidden = (style !=CellStyleFinished_MachineStop);
    
    
    //Local
    self.connectButton.hidden = (style == CellStyle_LocalUnconnect)? NO:YES;
    
    self.BLEPlayButton.hidden = ((style == CellStyle_LocalUnconnect)||(style == CellStyle_LocalRunning))?YES:NO;
    self.BLEPauseButton.hidden = ((style == CellStyle_LocalUnconnect)||(style == CellStyle_LocalUnrunning)||(style == CellStyle_LocalPause))?YES:NO;
    self.BLEStopButton.hidden = ((style == CellStyle_LocalUnconnect)||(style == CellStyle_LocalUnrunning)||(style == CellStyle_LocalPause))?YES:NO;
    self.BLERemarkButton.hidden = (style == CellStyle_LocalRunning);
}
- (IBAction)controlButttons:(id)sender {
}
@end
