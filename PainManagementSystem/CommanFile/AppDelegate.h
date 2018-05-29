//
//  AppDelegate.h
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/3/9.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (assign, nonatomic) BOOL isBLEPoweredOff;
@property (strong, nonatomic) NSDictionary *typeDic;
-(void)initRootViewController;

@end

