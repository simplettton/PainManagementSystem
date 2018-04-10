//
//  BETextField.m
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/3/26.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import "BETextField.h"

@interface BETextField ()
@property (nonatomic, strong) UIView *tapView;

@end

@implementation BETextField

-(void)addTapAciton:(BETapActionBlock)tapAcitonBlock{
    self.tapAcitonBlock = tapAcitonBlock;
    self.tapView.hidden = NO;
}

-(void)setEndEditBlock:(BEEndEditBlock)endEditBlock{
    self.endEditBlock = endEditBlock;
    [self addTarget:self action:@selector(didEndEditTextField:) forControlEvents:UIControlEventEditingDidEnd];
}

- (UIView *)tapView {
    if (!_tapView) {
        _tapView = [[UIView alloc]initWithFrame:self.bounds];
        _tapView.backgroundColor = [UIColor clearColor];
        [self addSubview:_tapView];
        _tapView.userInteractionEnabled = YES;
        UITapGestureRecognizer *myTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(didTapTextField)];
        [_tapView addGestureRecognizer:myTap];
    }
    return _tapView;
}

- (void)didTapTextField {
    // 响应点击事件时，隐藏键盘
    UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
    [keyWindow endEditing:YES];
    NSLog(@"点击了textField，执行点击回调");
    if (self.tapAcitonBlock) {
        self.tapAcitonBlock();
    }
}


- (void)didEndEditTextField:(UITextField *)textField {
    NSLog(@"textField编辑结束，回调编辑框输入的文本内容:%@", textField.text);
    if (self.endEditBlock) {
        self.endEditBlock(textField.text);
    }
}


@end
