//
//  DeviceCollectionViewCell.h
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/4/4.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MultiParamButton.h"
typedef enum _CellStyle {
    
    CellStyleNotStarted_MachineStop = 0,
    CellStyleOngoing_MachineRunning,
    CellStyleOngoing_MachinePause,
    CellStyleOngoing_MachineStop,
    CellStyleFinished_MachineStop,
    CellStyle_MachineException,
    
    CellStyleGrey_Unfinished,//通用

    
    CellStyle_LocalUnconnect,
    CellStyle_LocalConnect,
    CellStyle_LocalUnrunning,
    CellStyle_LocalRunning
} CellStyle;
@interface DeviceCollectionViewCell : UICollectionViewCell
@property (nonatomic,assign) CellStyle style;
@property (weak, nonatomic) IBOutlet UIView *topView;
@property (weak, nonatomic) IBOutlet UILabel *machineStateLabel;
@property (weak, nonatomic) IBOutlet UILabel *patientLabel;
@property (weak, nonatomic) IBOutlet UILabel *bedNumLabel;
@property (weak, nonatomic) IBOutlet UILabel *machineNameLabel;

@property (weak, nonatomic) IBOutlet MultiParamButton *pauseButton;
@property (weak, nonatomic) IBOutlet MultiParamButton *stopButton;
@property (weak, nonatomic) IBOutlet MultiParamButton *playButton;
@property (weak, nonatomic) IBOutlet UIButton *remarkButton;
//警告
@property (weak, nonatomic) IBOutlet UIImageView *middleImageView;
//删除按钮
@property (weak, nonatomic) IBOutlet UIButton *btnDelete;

@property (weak, nonatomic) IBOutlet UIImageView *clockImageView;

//本地设备
@property (weak, nonatomic) IBOutlet UIButton *BLEPauseButton;

@property (weak, nonatomic) IBOutlet UIButton *BLEStopButton;

@property (weak, nonatomic) IBOutlet UIButton *connectButton;

@property (weak, nonatomic) IBOutlet UIButton *BLEPlayButton;


-(void)configureWithStyle:(CellStyle)style message:(NSString *)message;
@end
