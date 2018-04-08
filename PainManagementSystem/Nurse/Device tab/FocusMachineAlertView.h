//
//  FocusMachineAlertView.h
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/4/4.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
typedef void (^returnBlock)(void);
@interface FocusMachineAlertView : UIView
@property (nonatomic,strong)returnBlock returnEvent;
+(void)alertControllerAboveIn:(UIViewController *)controller withDataDic:(NSDictionary *)dic returnBlock:(returnBlock)returnEvent;
@end
