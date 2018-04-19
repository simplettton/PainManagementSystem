//
//  OnlineDeviceViewController.m
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/3/23.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import "DeviceViewController.h"
#import "BaseHeader.h"

#import "FocusDeviceViewController.h"
#import "AllDeviceViewController.h"
#import "MJRefresh.h"
@interface DeviceViewController ()

@end

 
@implementation DeviceViewController
#pragma mark - segmentVC
- (LLSegmentBarVC *)segmentVC{
    if (!_segmentVC) {
        
        //segmentVC是follow view和 all view的容器
        LLSegmentBarVC *vc = [[LLSegmentBarVC alloc]init];
        // 添加到到控制器
        [self addChildViewController:vc];
        _segmentVC = vc;
    }
    return _segmentVC;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"治疗设备";
    [self customNavItem];
    // Do any additional setup after loading the view.
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:YES];
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.navigationController.navigationBar.barTintColor = UIColorFromHex(0x2EA3E6);
}

#pragma mark - 定制导航条内容
- (void) customNavItem {
    // 1 设置segmentBar的frame
    self.segmentVC.segmentBar.frame = CGRectMake(280,0, KScreenWidth-560, 40);
    self.navigationItem.titleView = self.segmentVC.segmentBar;
    
    // 2 添加控制器的View
    self.segmentVC.view.frame = self.view.bounds;
    [self.view addSubview:self.segmentVC.view];
    
    NSArray *items = @[@"关注", @"全部"];
    FocusDeviceViewController *follow = [[UIStoryboard storyboardWithName:@"Main" bundle:nil]instantiateViewControllerWithIdentifier:@"FocusDeviceViewController"];
//    UIViewController *follow = [[UIViewController alloc] init];
    follow.view.backgroundColor = [UIColor whiteColor];
    follow.isInAllTab = NO;
    
    FocusDeviceViewController *all = [[UIStoryboard storyboardWithName:@"Main" bundle:nil]instantiateViewControllerWithIdentifier:@"FocusDeviceViewController"];
    all.isInAllTab = YES;

    
    // 3 添加标题数组和控住器数组
    [self.segmentVC setUpWithItems:items childVCs:@[follow,all]];
    
    // 4  配置基本设置  可采用链式编程模式进行设置
    [self.segmentVC.segmentBar updateWithConfig:^(LLSegmentBarConfig *config) {
        config.itemNormalColor([UIColor whiteColor]).itemSelectColor([UIColor whiteColor]).indicatorColor([UIColor whiteColor]);
        config.itemFont([UIFont boldSystemFontOfSize:17.0f]);
    }];
}

- (void)segmentBar:(LLSegmentBar *)segmentBar didSelectIndex: (NSInteger)toIndex fromIndex: (NSInteger)fromIndex{
    NSString *title;
    if (toIndex == 0) {
        title = @"关注";
    }else{
        title = @"全部";
    }
    NSLog(@"select %@",title);
}

@end
