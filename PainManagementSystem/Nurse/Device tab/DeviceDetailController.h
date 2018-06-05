//
//  DeviceDetailController.h
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/6/5.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MachineModel.h"
@interface DeviceDetailController : UITableViewController
//在线设备传machine
@property (nonatomic,strong)MachineModel *machine;
//本地设备传medicalnum再请求设备和患者数据
@property (nonatomic,strong)NSString *medicalNum;
@end
