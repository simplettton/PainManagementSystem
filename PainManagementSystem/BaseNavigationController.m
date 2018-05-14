//
//  BaseNavigationController.m
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/5/14.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import "BaseNavigationController.h"

@interface BaseNavigationController ()<UINavigationControllerDelegate>
// 记录push标志
@property (nonatomic, getter=isPushing) BOOL pushing;
@end

@implementation BaseNavigationController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.delegate = self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    if (self.pushing == YES) {
        NSLog(@"被拦截");
        return;
    } else {
        NSLog(@"push");
        self.pushing = YES;
    }
    
    [super pushViewController:viewController animated:animated];
}
#pragma mark - UINavigationControllerDelegate
-(void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    self.pushing = NO;
}

@end
