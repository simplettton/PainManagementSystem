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
    CellStyleOrange_MachineException
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
@property (weak, nonatomic) IBOutlet UIButton *middleButton;

-(void)configureWithStyle:(CellStyle) style;
@end
