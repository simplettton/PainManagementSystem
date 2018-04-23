//
//  FocusDeviceViewController.h
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/4/4.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TreatmentCourseRecordViewController.h"
#import "DeviceCollectionViewCell.h"
#import "FocusMachineAlertView.h"
#import "BaseHeader.h"
#import "HHDropDownList.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import "BabyBluetooth.h"
#import <MBProgressHUD.h>

#import "LLSegmentBarVC.h"
#import "DeviceViewController.h"

#import "PatientModel.h"
#import "MultiParamButton.h"

//refresh
#import "MJRefresh.h"
#import "MJChiBaoZiHeader.h"

//布局
#import "Masonry.h"

#import "Pack.h"
#import "Unpack.h"
#define kOrangeColor 0xf8b273
#define kGreenColor 0x7ede98
#define kGreyColor 0xc1c1c1
#define kCellWidth 220
#define kCellHeight 186
#define List_Width (KScreenWidth + 1.4 )/4.0
#define SERVICE_UUID           @"1b7e8251-2877-41c3-b46e-cf057c562023"
#define TX_CHARACTERISTIC_UUID @"5e9bf2a8-f93f-4481-a67e-3b2f4a07891a"
#define RX_CHARACTERISTIC_UUID @"8ac32d3f-5cb9-4d44-bec2-ee689169f626"

typedef enum _DeviceType
{
    DeviceTypeOnline = 0,
    DeviceTypeLocal = 1
}DeviceType;

typedef NS_ENUM(NSInteger,KCmdids)
{
    CMDID_DEVICE_TYPE = 0XFA,
    CMDID_SEND_PARAMETER = 0X9A,
    CMDID_CHANGE_STATE = 0X90,
    CMDID_UPDATE_DATA_REQUEST = 0X97
};
@interface FocusDeviceViewController : UIViewController<UISearchBarDelegate,UICollectionViewDelegate,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout,HHDropDownListDelegate, HHDropDownListDataSource>

@property (assign,nonatomic) BOOL isInAllTab;
@property (strong, nonatomic)MBProgressHUD * HUD;

@end
