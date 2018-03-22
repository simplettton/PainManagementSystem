//
//  SetNetWorkView.m
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/3/22.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//
#define KVIEW_H [UIScreen mainScreen].bounds.size.height
#define KVIEW_W [UIScreen mainScreen].bounds.size.width

#import "SetNetWorkView.h"
#import "BaseHeader.h"
@interface SetNetWorkView()
@property (weak, nonatomic) IBOutlet UIView *backgroundView;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIButton *setButton;
@property (weak, nonatomic) IBOutlet UITextField *IPTextFileld;
@property (weak, nonatomic) IBOutlet UIView *contentView;

@end
@implementation SetNetWorkView

-(void)awakeFromNib {
    [super awakeFromNib];
    self.backgroundColor = [[UIColor blackColor]colorWithAlphaComponent:0.5];
    self.backgroundView.layer.cornerRadius = 5;
    
    CALayer *layer = [CALayer layer];
    layer.frame = CGRectMake(0, self.contentView.frame.size.height - 1.0, _contentView.frame.size.width, 1.0);
    layer.backgroundColor = UIColorFromHex(0XBBBBBB).CGColor;
    [self.contentView.layer addSublayer:layer];
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/
+(void)alertControllerAboveIn:(UIViewController *)controller return:(returnIP)returnEvent{
    
    SetNetWorkView *view = [[NSBundle mainBundle]loadNibNamed:@"SetNetWorkView" owner:nil options:nil][0];
    
    view.frame = CGRectMake(0, 0, KVIEW_W, KVIEW_H);
    
    view.returnEvent = returnEvent;
    
    [view configureUI];
    
    
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
- (IBAction)cancel:(id)sender {
    [self removeFromSuperview];
}
- (IBAction)setIP:(id)sender {
    NSString *IPString = self.IPTextFileld.text;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:IPString forKey:@"IPString"];
    [defaults synchronize];
    self.returnEvent(IPString);
    [self removeFromSuperview];
}

-(void)configureUI{
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *IPString = [defaults objectForKey:@"IPString"];
    self.IPTextFileld.text = IPString == nil? @"http://192.128.127" :IPString;
    
//    [self.IPTextFileld becomeFirstResponder];
}


@end
