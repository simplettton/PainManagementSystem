//
//  SendTreatmentSuccessView.m
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/4/2.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import "SendTreatmentSuccessView.h"
#import "BaseHeader.h"
@interface SendTreatmentSuccessView()
@property (weak, nonatomic) IBOutlet UIView *confirmView;
@property (weak, nonatomic) IBOutlet UIView *setFocusView;

@end
@implementation SendTreatmentSuccessView
- (IBAction)tapOkButton:(id)sender {
    [self removeFromSuperview];
}
- (IBAction)tapSetFocusButton:(id)sender {
    self.returnEvent();
    [self removeFromSuperview];
}

-(void)awakeFromNib{
    [super awakeFromNib];
    self.backgroundColor = [[UIColor blackColor]colorWithAlphaComponent:0.5];
    self.backgroundView.layer.cornerRadius = 5.0f;
    
    //圆角一个角
    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:self.confirmView.bounds byRoundingCorners:UIRectCornerBottomLeft cornerRadii:CGSizeMake(10, 10)];
    CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
    maskLayer.frame = self.confirmView.bounds;
    maskLayer.path = maskPath.CGPath;
    self.confirmView.layer.mask = maskLayer;
    
    CALayer *layer = [CALayer layer];
    layer.frame = CGRectMake(self.confirmView.frame.size.width - 1, 0, 1, self.confirmView.frame.size.height);
    layer.backgroundColor = [UIColor whiteColor].CGColor;
    [self.confirmView.layer addSublayer:layer];
    
//    self.confirmView.layer.cornerRadius = 5.0f;
//    self.setFocusView.layer.cornerRadius = 5.0f;
    
    //右边线
    UIBezierPath *maskPath1 = [UIBezierPath bezierPathWithRoundedRect:self.setFocusView.bounds byRoundingCorners: UIRectCornerBottomRight cornerRadii:CGSizeMake(10, 10)];
    CAShapeLayer *maskLayer1 = [[CAShapeLayer alloc] init];
    maskLayer1.frame = self.setFocusView.bounds;
    maskLayer1.path = maskPath1.CGPath;
    self.setFocusView.layer.mask = maskLayer1;
    
}
+(void)alertControllerAboveIn:(UIViewController *)controller returnBlock:(returnBlock)returnEvent{
    SendTreatmentSuccessView *view = [[NSBundle mainBundle]loadNibNamed:@"SendTreatmentSuccessView" owner:nil options:nil][0];
    
    view.frame = CGRectMake(0, 0, KScreenWidth, KScreenHeight);
    
    view.returnEvent = returnEvent;
    
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
