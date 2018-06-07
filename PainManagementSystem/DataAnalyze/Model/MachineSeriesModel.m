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
-(void)encodeWithCoder:(NSCoder *)aCoder{
    [aCoder encodeObject:self.name forKey:@"name"];
    [aCoder encodeObject:self.code forKey:@"code"];
    [aCoder encodeBool:self.isLocal forKey:@"islocal"];
    [aCoder encodeObject:self.serviceUUID forKey:@"serviceUUID"];
    [aCoder encodeObject:self.txCharacteristicUUID forKey:@"txCharacteristicUUID"];
    [aCoder encodeObject:self.rxCharacteristicUUID forKey:@"rxCharacteristicUUID"];
    [aCoder encodeObject:self.broadcastName forKey:@"broadcastName"];
    [aCoder encodeFloat:self.buttonWidth forKey:@"buttonWidth"];
}
-(instancetype)initWithCoder:(NSCoder *)aDecoder{
    if (self = [super init]) {
        self.name = [aDecoder decodeObjectForKey:@"name"];
        self.code = [aDecoder decodeObjectForKey:@"code"];
        self.isLocal = [aDecoder decodeBoolForKey:@"islocal"];
        self.serviceUUID = [aDecoder decodeObjectForKey:@"serviceUUID"];
        self.txCharacteristicUUID = [aDecoder decodeObjectForKey:@"txCharacteristicUUID"];
        self.rxCharacteristicUUID = [aDecoder decodeObjectForKey:@"rxCharacteristicUUID"];
        self.broadcastName = [aDecoder decodeObjectForKey:@"broadcastName"];
        self.buttonWidth = [aDecoder decodeFloatForKey:@"buttonWidth"];
    }
    return self;
}
-(instancetype)initWithDic:(NSDictionary *)dic{
    if (self = [super init]) {
        self.name = dic[@"name"];
        self.code = dic[@"code"];
        
        NSNumber *islocalNumber = dic[@"islocal"];
        
        if ([islocalNumber integerValue] == 1) {
            self.isLocal = YES;
            NSDictionary *tagDic = dic[@"tag"];
            self.serviceUUID = tagDic[@"serviceuuid"];
            self.txCharacteristicUUID = tagDic[@"txcharacteristicuuid"];
            self.rxCharacteristicUUID = tagDic[@"rxcharacteristicuuid"];
            self.broadcastName = tagDic[@"broadcastname"];
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
