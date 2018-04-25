//
//  VASMarkView.m
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/3/27.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import "VASMarkView.h"
#import "BaseHeader.h"

#import "NetWorkTool.h"
@interface VASMarkView()
@property (weak, nonatomic) IBOutlet UIView *backgroundView;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIButton *saveButton;
@property (weak, nonatomic) IBOutlet UITextView *scoreStandardsTV;
@property (weak, nonatomic) IBOutlet UISlider *slider;
@property (weak, nonatomic) IBOutlet UILabel *valueLabel;

@end
@implementation VASMarkView

-(void)awakeFromNib{
    [super awakeFromNib];
    self.backgroundColor = [[UIColor blackColor]colorWithAlphaComponent:0.5];
    self.backgroundView.layer.cornerRadius = 5.0f;
    self.slider.continuous = YES;
    [self.slider addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    self.valueLabel.text = [NSString stringWithFormat:@"%.0f", self.slider.value];
}

+(void)alertControllerAboveIn:(UIViewController *)controller withMark:(NSString *)mark describe:(NSString *)describe return:(returnMark)returnEvent{
    
    VASMarkView *view = [[NSBundle mainBundle]loadNibNamed:@"VASMarkView" owner:nil options:nil][0];
    
    view.frame = CGRectMake(0, 0, KScreenWidth, KScreenHeight);
    
    view.returnEvent = returnEvent;
    
    [controller.view addSubview:view];
    
    CGAffineTransform transform = CGAffineTransformScale(CGAffineTransformIdentity, 1.0, 1.0);
    
    view.backgroundView.transform = CGAffineTransformScale(CGAffineTransformIdentity,0.2,0.2);
    
    view.backgroundView.alpha = 0;
    
    view.mark = mark;
    
    view.slider.value = [mark intValue];
    
    view.valueLabel.text = mark;
    
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineSpacing = 10;// 字体的行间距
    
    NSDictionary *attributes = @{
                                 NSFontAttributeName:[UIFont systemFontOfSize:16 weight:UIFontWeightLight],
                                 NSParagraphStyleAttributeName:paragraphStyle
                                 };
    if (describe) {
        
        view.scoreStandardsTV.attributedText = [[NSAttributedString alloc]initWithString:[NSString stringWithFormat:@"VAS评分说明(0分-100分):\n%@",describe] attributes:attributes];
    }else{
        NSString *defaultDescribe = @"0分:无痛； 30分以内:有轻微的疼痛，能忍受； 40分-60分:患者疼痛并影响睡眠，尚能忍受； 70分-100分:患者有渐强烈的疼痛，疼痛难忍，影响食欲，影响睡眠。";
        view.scoreStandardsTV.attributedText = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"VAS评分说明(0分-100分):\n%@",defaultDescribe] attributes:attributes];

    }
    

    
    [UIView animateWithDuration:0.3 delay:0.1 usingSpringWithDamping:0.5 initialSpringVelocity:10 options:UIViewAnimationOptionCurveLinear animations:^{
        view.backgroundView.transform = transform;
        view.backgroundView.alpha = 1;
    } completion:^(BOOL finished) {
        
    }];
    
}
#pragma mark - action
- (IBAction)cancel:(id)sender {
    [self removeFromSuperview];
}
- (IBAction)save:(id)sender {
    
    NSString *string = self.valueLabel.text;
    self.returnEvent(string);
    [self removeFromSuperview];


}
-(void)sliderValueChanged:(UISlider *)sender{
    
    UISlider *slider = (UISlider *)sender;
    self.valueLabel.text = [NSString stringWithFormat:@"%.0f", slider.value];
}

@end
