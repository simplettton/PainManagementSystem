//
//  ContactServiceView.m
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/3/26.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import "ContactServiceView.h"
#import "BaseHeader.h"
#define KVIEW_H [UIScreen mainScreen].bounds.size.height
#define KVIEW_W [UIScreen mainScreen].bounds.size.width
@interface ContactServiceView()
@property (weak, nonatomic) IBOutlet UIView *backgroundView;
@property (weak, nonatomic) IBOutlet UIView *emailView;

@end
@implementation ContactServiceView
- (IBAction)cancel:(id)sender {
    [self removeFromSuperview];
}

-(void)awakeFromNib {
    [super awakeFromNib];
    self.backgroundColor = [[UIColor blackColor]colorWithAlphaComponent:0.5];
    self.backgroundView.layer.cornerRadius = 5;
    
    CALayer *layer = [CALayer layer];
    layer.frame = CGRectMake(0, self.emailView.frame.size.height - 0.5, _emailView.frame.size.width, 0.5);
    layer.backgroundColor = UIColorFromHex(0XBBBBBB).CGColor;
    [self.emailView.layer addSublayer:layer];
}

+(void)alertControllerAboveIn:(UIViewController *)controller{
    
    ContactServiceView *view = [[NSBundle mainBundle]loadNibNamed:@"ContactServiceView" owner:nil options:nil][0];
    
    view.frame = CGRectMake(0, 0, KVIEW_W, KVIEW_H);
    
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
