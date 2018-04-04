//
//  SendTreatmentSuccessView.h
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/4/2.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
typedef void (^returnBlock)(void);
@interface SendTreatmentSuccessView : UIView

@property (nonatomic,strong)returnBlock returnEvent;
@property (weak, nonatomic) IBOutlet UIButton *setFocusButton;
@property (weak, nonatomic) IBOutlet UIView *backgroundView;
+(void)alertControllerAboveIn:(UIViewController *)controller returnBlock:(returnBlock)returnEvent;

@end
