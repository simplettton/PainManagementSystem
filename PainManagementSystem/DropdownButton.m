//
//  DropdownButton.m
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/4/13.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import "DropdownButton.h"
static NSString *CellIdentifier = @"DropDownCell";

@interface DropdownButton () <UITableViewDataSource, UITableViewDelegate> {
    UITableView *listView;
}
@end
@implementation DropdownButton

- (instancetype)initWithFrame:(CGRect)frame Title:(NSString*)title List:(NSArray *)list {
    self = [super initWithFrame:frame];
    if (self) {
        self.title = [NSString stringWithString:title];
        self.list = [NSArray arrayWithArray:list];
        
        [self setup];
    }
    
    return self;
}
- (void)awakeFromNib {
    [super awakeFromNib];
    self.title = self.titleLabel.text;
    [self setup];
    [self.superview addSubview:listView];
    [self.superview bringSubviewToFront:self];
}
- (void)didMoveToSuperview {
    [self.superview addSubview:listView];
}
//设置表视图listView的布局、数据源和代理
- (void)setupDefaultTable {
    //将listView放在当前按钮下方位置，保持宽度相同，初始高度设置为0
    listView = [[UITableView alloc] initWithFrame:CGRectMake(self.frame.origin.x, self.frame.origin.y+self.frame.size.height+10, self.frame.size.width*5, 0) style:UITableViewStylePlain];

    listView.layer.cornerRadius = 5.0f;
//    [listView setSeparatorColor:UIColorFromHex(0x5e97fe)];
    listView.dataSource = self;
    listView.delegate = self;
    listView.layer.borderWidth = 0.5f;
    listView.layer.borderColor = UIColorFromHex(0x3CBD9E).CGColor;
    
    listView.separatorStyle= UITableViewCellSeparatorStyleNone;
}
- (void)setup {
    [self setTitle:self.title forState:UIControlStateNormal];
    [self setupDefaultTable];
    [self setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
    [self addTarget:self action:@selector(clickedToDropDown) forControlEvents:UIControlEventTouchUpInside];
}

//添加listView的下拉动画、收起动画方法
- (void)startDropDownAnimation {
    CGRect frame = listView.frame;
    //使listView高度在0.3秒内从0过渡到最大高度以显示全部列表项
    frame.size.height = self.frame.size.height*1.5 *self.list.count;
    [UIView animateWithDuration:0.3 animations:^{
        listView.frame = frame;
    } completion:^(BOOL finished) {
        
    }];
}

- (void)startPackUpAnimation {
    CGRect frame = listView.frame;
    //使listView高度在0.3秒内从最大高度过渡到0以隐藏全部列表项
    frame.size.height = 0;
    [UIView animateWithDuration:0.3 animations:^{
        listView.frame = frame;
    } completion:^(BOOL finished) {
        
    }];
}
//添加按钮点击事件，每点击一次按钮，tag值自加1，然后根据tag值执行下拉或收起列表动画，最后重新加载一次listView的数据，防止串改列表项后不能及时更新到listView中
- (void)clickedToDropDown {
    self.tag++;
    self.tag%2 ? [self startDropDownAnimation] : [self startPackUpAnimation];
    
//    [listView reloadData];
}

#pragma mark - table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    //根据成员list数组中的元素数返回列表的行数，必须保证self.list不为nil，才会调用cellForRowAtIndexPath方法
    return self.list.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (nil == cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    //设置列表中的每一项文本、字体、颜色等
    cell.textLabel.text = self.list[indexPath.row];
    cell.textLabel.font = self.titleLabel.font;
    [cell.textLabel setTextColor:UIColorFromHex(0x3CBD9E)];
    
    cell.selectedBackgroundView = [[UIView alloc] initWithFrame:cell.frame];
    
    cell.selectedBackgroundView.backgroundColor = [UIColor clearColor];

    return cell;
}

#pragma mark - table view delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    //选择某项后，使按钮标题内容变为当前选项
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self setTitle:self.list[indexPath.row] forState:UIControlStateNormal];
    //执行列表收起动画
    [self clickedToDropDown];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    //设置表单元高度为按钮高度
    return self.frame.size.height*1.5;
}

@end
