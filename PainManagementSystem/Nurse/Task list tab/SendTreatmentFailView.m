//
//  SendTreatmentFailView.m
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/4/2.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import "SendTreatmentFailView.h"
#import "BaseHeader.h"
@implementation SendTreatmentFailView
- (IBAction)tapConfirmButton:(id)sender {
    [self removeFromSuperview];
}
-(void)awakeFromNib{
    [super awakeFromNib];
    self.backgroundColor = [[UIColor blackColor]colorWithAlphaComponent:0.5];
    self.backgroundView.layer.cornerRadius = 5.0f;
    
    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:self.confirmView.bounds byRoundingCorners:UIRectCornerBottomLeft |UIRectCornerBottomRight cornerRadii:CGSizeMake(10, 10)];
    CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
    maskLayer.frame = self.confirmView.bounds;
    maskLayer.path = maskPath.CGPath;
    self.confirmView.layer.mask = maskLayer;
}
+(void)alertControllerAboveIn:(UIViewController *)controller{
    
    SendTreatmentFailView *view = [[NSBundle mainBundle]loadNibNamed:@"SendTreatmentFailView" owner:nil options:nil][0];
    
    view.frame = CGRectMake(0, 0, KScreenWidth, KScreenHeight);
    
    [controller.view addSubview:view];
    
    CGAffineTransform transform = CGAffineTransformScale(CGAffineTransformIdentity, 1.0, 1.0);
    
    view.backgroundView.transform = CGAffineTransformScale(CGAffineTransformIdentity,0.2,0.2);
    
    view.backgroundView.alpha = 0;
    
    
    
    [UIView animateWithDuration:0.3 delay:0.1 usingSpringWithDamping:0.5 initialSpringVelocity:10 options:UIViewAnimationOptionCurveLinear animations:^{
        view.backgroundView.transform = transform;
        view.backgroundView.alpha = 1;
    } completion:^(BOOL finished) {
        
    }];
}

@end
