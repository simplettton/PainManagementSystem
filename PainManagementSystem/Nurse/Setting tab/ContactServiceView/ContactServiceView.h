//
//  ContactServiceView.h
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/3/26.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
typedef void(^returnBlock) (void);
@interface ContactServiceView : UIView
@property (nonatomic,strong)returnBlock returnEvent;
+(void)alertControllerAboveIn:(UIViewController *)controller returnBlock:(returnBlock)returnEvent;
@end
