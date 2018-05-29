//
//  DropdownButton.h
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/4/13.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DropdownButton : UIButton
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSArray *list;
@property (nonatomic, assign)BOOL isShow;
/**
 *  初始化DropDownButton
 *
 *  @param frame 结构
 *  @param title 标题
 *  @param list  下拉列表
 *
 *  @return DropDownButton实例
 */
- (instancetype)initWithFrame:(CGRect)frame Title:(NSString*)title List:(NSArray *)list;
- (void)clickedToDropDown;
@end
