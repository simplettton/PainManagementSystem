//
//  FocusMachineAlertView.m
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/4/4.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import "FocusMachineAlertView.h"
#import "BaseHeader.h"
@interface FocusMachineAlertView()
@property (weak, nonatomic) IBOutlet UIView *backGroundView;

@end
@implementation FocusMachineAlertView
-(void)awakeFromNib{
    [super awakeFromNib];
    self.backgroundColor = [[UIColor blackColor]colorWithAlphaComponent:0.5];
    self.backGroundView.layer.cornerRadius = 5.0f;
}

+(void)alertControllerAboveIn:(UIViewController *)controller returnBlock:(returnBlock)returnEvent{
    
    FocusMachineAlertView *view = [[NSBundle mainBundle]loadNibNamed:@"FocusMachineAlertView" owner:nil options:nil][0];
    
    view.frame = CGRectMake(0, 0, KScreenWidth, KScreenHeight);
    
    view.returnEvent = returnEvent;
    
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
    [self removeFromSuperview];
}


@end
