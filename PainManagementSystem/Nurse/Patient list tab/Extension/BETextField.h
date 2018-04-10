//
//  BETextField.h
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/3/26.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
typedef void(^BETapActionBlock)(void);
typedef void(^BEEndEditBlock)(NSString *text);
@interface BETextField : UITextField
/** textField 的点击回调 */
@property (nonatomic, copy) BETapActionBlock tapAcitonBlock;
/** textField 结束编辑的回调 */
@property (nonatomic, copy) BEEndEditBlock endEditBlock;

-(void)addTapAciton:(BETapActionBlock)tapAcitonBlock;

@end
