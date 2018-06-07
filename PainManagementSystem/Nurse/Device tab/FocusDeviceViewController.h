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
#import <CoreBluetooth/CoreBluetooth.h>
#import "BabyBluetooth.h"
#import <MBProgressHUD.h>

#import "LLSegmentBarVC.h"
#import "DeviceViewController.h"

#import "PatientModel.h"
#import "MultiParamButton.h"

//refresh
#import "MJRefresh.h"

//布局
#import "Masonry.h"

#import "MachineModel.h"
#import "Pack.h"
#import "Unpack.h"
#define kOrangeColor 0xf8b273
#define kGreenColor 0x7ede98
#define kGreyColor 0xc1c1c1
#define kCellWidth 220
#define kCellHeight 186
#define List_Width (KScreenWidth + 1.4 )/4.0

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
@interface FocusDeviceViewController: UIViewController<UISearchBarDelegate,UICollectionViewDelegate,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout>

@property (assign,nonatomic) BOOL isInAllTab;
@property (strong, nonatomic)MBProgressHUD * HUD;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@end
