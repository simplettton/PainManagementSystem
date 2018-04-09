//
//  DeviceCollectionViewCell.h
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/4/4.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
typedef enum _CellStyle {
    CellStyleGreen_MachineRunning  = 0,
    CellStyleGrey_MachineStop,
    CellStyleGrey_MachinePause,
    CellStyleOrange_MachineException,
    CellStyle_LocalUnconnect,
    CellStyle_LocalConnect
} CellStyle;
@interface DeviceCollectionViewCell : UICollectionViewCell
@property (nonatomic,assign) CellStyle style;
@property (weak, nonatomic) IBOutlet UIView *topView;
@property (weak, nonatomic) IBOutlet UILabel *machineStateLabel;
@property (weak, nonatomic) IBOutlet UILabel *patientLabel;
@property (weak, nonatomic) IBOutlet UILabel *bedNumLabel;
@property (weak, nonatomic) IBOutlet UILabel *machineNameLabel;

@property (weak, nonatomic) IBOutlet UIButton *leftButton;
@property (weak, nonatomic) IBOutlet UIButton *rightButton;
@property (weak, nonatomic) IBOutlet UIImageView *middleImageView;
@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (weak, nonatomic) IBOutlet UIButton *remarkButton;

@property (weak, nonatomic) IBOutlet UIButton *btnDelete;


//本地设备
@property (weak, nonatomic) IBOutlet UIButton *BLEPauseButton;

@property (weak, nonatomic) IBOutlet UIButton *BLEStopButton;

@property (weak, nonatomic) IBOutlet UIButton *connectButton;

@property (weak, nonatomic) IBOutlet UIButton *BLEPlayButton;




-(void)configureWithStyle:(CellStyle) style;
@end
