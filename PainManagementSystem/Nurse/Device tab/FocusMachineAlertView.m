//
//  FocusMachineAlertView.m
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/4/4.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import "FocusMachineAlertView.h"
#import "BaseHeader.h"
#import "BEButton.h"
@interface FocusMachineAlertView()
@property (weak, nonatomic) IBOutlet UIView *backGroundView;
@property (weak, nonatomic) IBOutlet UILabel *medicalNumLabel;
@property (weak, nonatomic) IBOutlet UILabel *patientNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *bedNumLabel;
@property (weak, nonatomic) IBOutlet UILabel *machineTypeLabel;
@property (weak, nonatomic) IBOutlet UILabel *machineNickLabel;
@property (weak, nonatomic) IBOutlet UILabel *taskStateLabel;
@property (weak, nonatomic) IBOutlet UILabel *machineStateLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;

@property (weak, nonatomic) IBOutlet BEButton *focusButton;
@property (weak, nonatomic) IBOutlet BEButton *findButton;

@end
@implementation FocusMachineAlertView
-(void)awakeFromNib{
    [super awakeFromNib];
    self.backgroundColor = [[UIColor blackColor]colorWithAlphaComponent:0.5];
//    self.backGroundView.layer.cornerRadius = 5.0f;
}

+(void)alertControllerAboveIn:(UIViewController *)controller withDataModel:(MachineModel *)machine returnBlock:(returnBlock)returnEvent{
    
    FocusMachineAlertView *view = [[NSBundle mainBundle]loadNibNamed:@"FocusMachineAlertView" owner:nil options:nil][0];
    
    view.frame = CGRectMake(0, 0, KScreenWidth, KScreenHeight);
    
    view.returnEvent = returnEvent;
    
    //传入字典更新ui
    if (machine) {
        [view configureUIWithDataModel:machine];
        view.dataModel = machine;
    }
    
    [controller.view addSubview:view];
    
    CGAffineTransform transform = CGAffineTransformScale(CGAffineTransformIdentity, 1.0, 1.0);
    
    view.backGroundView.transform = CGAffineTransformScale(CGAffineTransformIdentity,0.2,0.2);
    
    view.backGroundView.alpha = 0;
    
    [UIView animateWithDuration:0.3 delay:0.1 usingSpringWithDamping:0.5 initialSpringVelocity:10 options:UIViewAnimationOptionCurveLinear animations:^{
        view.backGroundView.transform = transform;
        view.backGroundView.alpha = 1;
    } completion:^(BOOL finished) {
        
    }];
}
- (IBAction)close:(id)sender {
    [self removeFromSuperview];
}
- (IBAction)tapFocusButton:(id)sender {
    self.returnEvent();

    [self removeFromSuperview];
}
- (IBAction)tapFindMechineButton:(id)sender {
    [[NetWorkTool sharedNetWorkTool]POST:[HTTPServerURLString stringByAppendingString:@"Api/OnlineDevice/Beep"] params:@{@"cpuid":self.dataModel.cpuid}
                                hasToken:YES success:^(HttpResponse *responseObject) {
                                    if ([responseObject.result intValue] == 0) {
                                        [SVProgressHUD showErrorWithStatus:responseObject.errorString];
                                    }
                                } failure:nil];
}

-(void)configureUIWithDataModel:(MachineModel *)machine
{
    //patient information
    self.medicalNumLabel.text = [NSString stringWithFormat:@"病历号： %@",machine.userMedicalNum];
    self.patientNameLabel.text = [NSString stringWithFormat:@"病人姓名： %@",machine.userName];
    self.bedNumLabel.text = [NSString stringWithFormat:@"病历号： %@",machine.userBedNum];
    
    //machine information
    self.machineTypeLabel.text = [NSString stringWithFormat:@"治疗设备：    %@", machine.type];
    self.machineNickLabel.text = [NSString stringWithFormat:@"设备昵称：    %@",machine.name];
    
    NSString *treatmentState = [NSString string];
    switch ([machine.taskStateNumber intValue]) {
        case 0:
            treatmentState = @"治疗处方未下发";
            break;
        case 1:
        case 3:
        case 7:
            treatmentState = @"治疗处方已下发";
            break;
        case 15:
            treatmentState = @"治疗疗程已结束";
            
            break;
        default:
            treatmentState = @"未知";
            break;
    }
    
    if([treatmentState isEqualToString:@"治疗处方已下发"]&&(machine.isFocus == NO)){
        self.focusButton.hidden = NO;
    }else{
        self.focusButton.hidden = YES;
    }
    self.findButton.hidden = !([treatmentState isEqualToString:@"治疗处方已下发"]||[treatmentState isEqualToString:@"治疗疗程已结束"]);
    
    
    self.taskStateLabel.text = [NSString stringWithFormat:@"治疗状态：    %@",treatmentState];

    if (machine.state) {
            self.machineStateLabel.text = [NSString stringWithFormat:@"设备状态：    %@",machine.state];
    }else{
        self.machineStateLabel.text = @"设备状态：    未知";
    }
    if ([machine.treatTimeNumber intValue] == 0) {
        self.timeLabel.hidden = YES;
    }else{
        self.timeLabel.hidden = NO;
        self.timeLabel.text = [NSString stringWithFormat:@"治疗时间：    %@",machine.treatTime];
    }

    
}

@end
