//
//  MachineSeriesModel.h
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/5/24.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MachineSeriesModel : NSObject

@property (nonatomic,copy)NSString *name;

@property (nonatomic,copy)NSNumber *code;

@property (nonatomic,assign)BOOL isLocal;

@property (nonatomic,copy)NSString *serviceUUID;

@property (nonatomic,copy)NSString *txCharacteristicUUID;

@property (nonatomic,copy)NSString *rxCharacteristicUUID;

@property (nonatomic,copy)NSString *broadcastName;

@property (nonatomic,assign)CGFloat buttonWidth;

+(instancetype)modelWithDic:(NSDictionary *)dic;

@end
