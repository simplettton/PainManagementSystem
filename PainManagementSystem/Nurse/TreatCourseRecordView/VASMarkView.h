//
//  VASMarkView.h
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/3/27.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
typedef void (^returnMark) (NSString *);
@interface VASMarkView : UIView
@property (nonatomic,strong)returnMark returnEvent;
+(void)alertControllerAboveIn:(UIViewController *)controller return:(returnMark)returnEvent;
@end
