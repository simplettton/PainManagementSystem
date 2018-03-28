//
//  RecordDetailViewController.m
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/3/28.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import "RecordDetailViewController.h"
#import "RecordItemCell.h"
@interface RecordDetailViewController ()<UITableViewDataSource,UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@end

@implementation RecordDetailViewController{
    NSMutableArray *titles;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"诊疗记录详情";
    // Do any additional setup after loading the view.
    titles = [NSMutableArray arrayWithObjects:@"基本情况",@"西医病历采集",@"中医病历采集",@"诊断结果",@"物理治疗方法",@"设备治疗处方",nil];
    self.tableView.tableFooterView = [[UIView alloc]init];
}

#pragma mark - tableViewDataSource

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [titles count];
}
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 350;
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *CellIdentifier = @"Cell";
    RecordItemCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    if (cell == nil) {
        cell = [[RecordItemCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
//        cell = [[NSBundle mainBundle]loadNibNamed:@"RecordItem" owner:nil options:nil][0];
    }
    cell.titleLabel.text = titles[indexPath.row];
    
    return cell;
}


@end
