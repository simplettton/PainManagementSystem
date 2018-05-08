//
//  TapBarController.m
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/5/8.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import "TapBarController.h"

@interface TapBarController ()

@end

@implementation TapBarController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.tabBar.delegate = self;
}

- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController {
    // 确保当前显示的是首页界面,本例中首页是第一个 tabBar
    if ([tabBarController.selectedViewController isEqual:[tabBarController.viewControllers firstObject]]) {
        // 再次选中的 tab 页面是之前上一次选中的控制器页面
        if ([viewController isEqual:tabBarController.selectedViewController]) {
            // 发送通知,让首页刷新数据
            [[NSNotificationCenter defaultCenter] postNotificationName:
             @"DoubleClickTabbarItemNotification" object:@(tabBarBtn.tag)];
            return NO;
        }
        
    }
    return YES;
}

@end
