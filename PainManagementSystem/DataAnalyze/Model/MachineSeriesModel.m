//
//  MachineSeriesModel.m
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/5/24.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import "MachineSeriesModel.h"
#define MIN_BUTTONWIDTH 75
@implementation MachineSeriesModel
-(instancetype)initWithDic:(NSDictionary *)dic{
    if (self = [super init]) {
        self.name = dic[@"name"];
        self.code = dic[@"code"];
        
        NSNumber *islocalNumber = dic[@"islocal"];
        
        if ([islocalNumber integerValue] == 1) {
            self.isLocal = YES;
            self.serviceUUID = dic[@"serviceuuid"];
            self.txCharacteristicUUID = dic[@"txcharacteristicuuid"];
            self.rxCharacteristicUUID = dic[@"rxcharacteristicuuid"];
            self.broadcastName = dic[@"broadcastname"];
        }else{
            self.isLocal = NO;
        }
        
        NSDictionary *attributes = @{NSFontAttributeName:[UIFont systemFontOfSize:15]};
        
        CGFloat length = [self.name boundingRectWithSize:CGSizeMake(552, 74) options:NSStringDrawingUsesLineFragmentOrigin attributes:attributes context:nil].size.width;
        self.buttonWidth = MAX(length + 20, MIN_BUTTONWIDTH);
        

    }
    return self;
}
+(instancetype)modelWithDic:(NSDictionary *)dic{
    return [[self alloc]initWithDic:dic];
}
@end
