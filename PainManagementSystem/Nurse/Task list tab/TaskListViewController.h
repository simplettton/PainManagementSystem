//
//  TaskListViewController.h
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/4/2.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
typedef enum _TaskListType
{
    TaskListTypeNotStarted= 0,
    TaskListTypeProcessing = 1,
    TaskListTypeFinished = 2,
}TaskListType;
@interface TaskListViewController : UIViewController

@end
