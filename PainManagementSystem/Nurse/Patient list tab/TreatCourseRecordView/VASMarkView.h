//
//  VASMarkView.h
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/3/27.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
typedef void (^returnMark) (NSString *);
@interface VASMarkView : UIView
@property (nonatomic,strong)returnMark returnEvent;
@property (nonatomic,strong)NSString *mark;
@property (nonatomic,strong)NSString *idString;
@property (nonatomic,strong)NSNumber *isForcedToStop;
+(void)alertControllerAboveIn:(UIViewController *)controller withData:(NSDictionary *)data describe:(NSString *)describe return:(returnMark)returnEvent;
@end
