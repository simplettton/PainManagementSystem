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
typedef enum _DeviceType
{
    DeviceTypeOnline = 0,
    DeviceTypeLocal = 1
}DeviceType;
@interface FocusDeviceViewController : UIViewController<UISearchBarDelegate,UICollectionViewDelegate,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout,HHDropDownListDelegate, HHDropDownListDataSource>

@property (assign,nonatomic) BOOL isInAllTab;

@end
