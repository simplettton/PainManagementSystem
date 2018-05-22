//
//  SetNetWorkView.h
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/3/22.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GCDAsyncUdpSocket.h"

typedef void (^returnIP) (NSString *);
@interface SetNetWorkView : UIView<GCDAsyncUdpSocketDelegate>

@property (nonatomic,copy)returnIP returnEvent;
+(void)alertControllerAboveIn:(UIViewController *)controller return:(returnIP)returnEvent;
@end
