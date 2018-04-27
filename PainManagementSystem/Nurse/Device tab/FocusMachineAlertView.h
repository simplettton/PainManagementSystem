//
//  FocusMachineAlertView.h
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/4/4.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MachineModel.h"
typedef void (^returnBlock)(void);
@interface FocusMachineAlertView : UIView
@property (nonatomic,strong)returnBlock returnEvent;

@property (nonatomic,strong)MachineModel *dataModel;
+(void)alertControllerAboveIn:(UIViewController *)controller withDataModel:(MachineModel *)machine returnBlock:(returnBlock)returnEvent;
@end
