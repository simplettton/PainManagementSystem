//
//  DeviceListViewController.h
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/3/19.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DeviceListViewController : UIViewController<UITableViewDelegate,UITableViewDataSource>

/**
 *  获取网络数据
 *  @param isRefresh 是否是下拉刷新
 */
-(void)getNetworkData:(BOOL)isRefresh isFiltered:(BOOL)isFiltered;


@end
