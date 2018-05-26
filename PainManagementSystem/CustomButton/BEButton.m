//
//  BEButton.m
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/3/27.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import "BEButton.h"
#import "BaseHeader.h"
@implementation BEButton

-(void)awakeFromNib{
    [super awakeFromNib];
    
    if ([self.backgroundColor isEqual:[UIColor clearColor]]) {
        [self.layer setBorderColor:UIColorFromHex(0xbbbbbb).CGColor];
    }
    [self.layer setCornerRadius:5.0f];
    [self.layer setMasksToBounds:YES];
}
-(instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {

        [self.layer setBorderColor:UIColorFromHex(0xf8f8f8).CGColor];
        [self.layer setCornerRadius:5.0f];
        [self.layer setMasksToBounds:YES];
        [self.layer setBorderWidth:0.5f];
    };

    return self;
}
@end
