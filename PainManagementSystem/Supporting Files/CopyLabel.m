//
//  CopyLabel.m
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/5/21.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import "CopyLabel.h"

@implementation CopyLabel

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/
-(BOOL)canBecomeFirstResponder {
    
    return YES;
}

// 可以响应的方法
-(BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    
    return (action == @selector(copy:));
}

//针对于响应方法的实现
-(void)copy:(id)sender {
    
    UIPasteboard *pboard = [UIPasteboard generalPasteboard];
    pboard.string = self.text;
}

//UILabel默认是不接收事件的，我们需要自己添加touch事件
-(void)attachTapHandler {
    
    self.userInteractionEnabled = YES;
    UILongPressGestureRecognizer *touch = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    [self addGestureRecognizer:touch];
}

//绑定事件
- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        
        [self attachTapHandler];
        
        [[NSNotificationCenter defaultCenter] addObserverForName:UIMenuControllerWillHideMenuNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
            self.backgroundColor = [UIColor whiteColor];
        }];
        
    }
    return self;
}

-(void)awakeFromNib {
    
    [super awakeFromNib];
    [self attachTapHandler];
    //复制完通知改颜色
    [[NSNotificationCenter defaultCenter] addObserverForName:UIMenuControllerWillHideMenuNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        self.backgroundColor = [UIColor whiteColor];
    }];
}

-(void)handleTap:(UIGestureRecognizer*) recognizer {
    
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        
        return;
    }else if(recognizer.state == UIGestureRecognizerStateBegan){
        [self becomeFirstResponder];
        self.backgroundColor = UIColorFromHex(0xececec);
        UIMenuItem *copyLink = [[UIMenuItem alloc] initWithTitle:@"复制"
                                                          action:@selector(newFunc)];
        [[UIMenuController sharedMenuController] setMenuItems:[NSArray arrayWithObjects:copyLink, nil]];
        [[UIMenuController sharedMenuController] setTargetRect:self.frame inView:self.superview];
        [[UIMenuController sharedMenuController] setMenuVisible:YES animated: YES];
    }
}
-(void)newFunc{
    UIPasteboard *pboard = [UIPasteboard generalPasteboard];
    pboard.string = self.text;
}
@end
