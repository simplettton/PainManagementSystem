//
//  TimeLineModel.h
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/6/5.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TimeLineModel : NSObject
@property (nonatomic,copy)NSString *title;
@property (nonatomic,copy)NSString *timeStamp;
+(instancetype)modelWithDic:(NSDictionary *)dic;
@end
