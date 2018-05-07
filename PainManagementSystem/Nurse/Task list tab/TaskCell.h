//
//  TaskCell.h
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/4/2.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
typedef enum _CellStyle {
    CellStyle_UnDownLoad  = 0,
    CellStyleGrey_DownLoadedUnRunning,
    CellStyleGreen_DownLoadedRunning,
    CellStyleBlue_DownLoadedFinishRunning,
    CellStyle_DownLoadedRemarked,

} CellStyle;
@interface TaskCell : UITableViewCell
@property (nonatomic,assign) CellStyle style;
@property (weak, nonatomic) IBOutlet UIButton *treatmentButton;
@property (weak, nonatomic) IBOutlet UIButton *scanButton;
@property (weak, nonatomic) IBOutlet UILabel *medicalRecordNumLable;
@property (weak, nonatomic) IBOutlet UILabel *patientNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *typeLabel;
@property (weak, nonatomic) IBOutlet UILabel *doctorNameLable;
@property (weak, nonatomic) IBOutlet UIImageView *statusImage;
//@property (weak, nonatomic) IBOutlet UIImageView *finishImageView;
@property (weak, nonatomic) IBOutlet UILabel *finishTimeLabel;

@property (strong, nonatomic) IBOutletCollection(UILabel) NSArray *labels;


-(void)setAllLableColor:(UIColor *)color;
-(void)setTypeLableColor:(UIColor *)color;
-(void)configureWithStyle:(CellStyle) style;

@end
