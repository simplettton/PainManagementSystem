//
//  AddDeviceViewController.h
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/3/19.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "BabyBluetooth.h"

typedef NS_ENUM(NSInteger,KCmdids)
{
    CMDID_DEVICE_TYPE = 0XFA,
    CMDID_SEND_PARAMETER = 0X9A,
    CMDID_CHANGE_STATE = 0X90,
    CMDID_UPDATE_DATA_REQUEST = 0X97
};
@interface AddDeviceViewController : UIViewController

@end
