//
//  AddDeviceCell.h
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/3/21.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AddDeviceCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIButton *ringButton;
@property (weak, nonatomic) IBOutlet UIButton *scanButton;
@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
@property (weak, nonatomic) IBOutlet UITextField *serialNumTextField;

@end
