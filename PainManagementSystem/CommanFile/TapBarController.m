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
    self.delegate = self;
    // Do any additional setup after loading the view.
}

- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController {

    // 再次选中的 tab 页面是之前上一次选中的控制器页面
    if ([viewController isEqual:tabBarController.selectedViewController]) {
        
        [[NSNotificationCenter defaultCenter]postNotificationName:@"ClickTabbarItem" object:@(self.selectedIndex)];
    }

    return YES;
}
-(void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController{
    
    
    
}

-(void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item{
    NSLog(@"tabBarSelect %@",item.title);
}

@end
