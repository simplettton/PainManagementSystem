//
//  BETimeLine.m
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/6/5.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import "BETimeLine.h"
#import "AlertTimeLineCell.h"
#import "SDAutoLayout.h"

@interface BETimeLine()<UITableViewDelegate,UITableViewDataSource>
@property(nonatomic, strong)NSMutableArray *dataArray;

@end
@implementation BETimeLine
-(void)setSuperView:(UIView *)superView DataArray:(NSMutableArray *)dataArray{
    self.frame = superView.bounds;
    [superView addSubview:self];
    
    [self setUp];
    self.dataArray = dataArray;
}
-(void)setUp{
    self.tableView = [[UITableView alloc]init];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.separatorStyle = UITableViewCellSelectionStyleNone;
    
    [self addSubview:self.tableView];
    
 self.tableView.sd_layout.topEqualToView(self).leftEqualToView(self).bottomEqualToView(self).rightEqualToView(self);
}
#pragma mark - tableview delegate
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.dataArray.count;
}
-(CGFloat)cellHeightForIndexPath:(NSIndexPath *)indexPath cellContentViewWidth:(CGFloat)width tableView:(UITableView *)tableView{
    TimeLineModel *model = self.dataArray[indexPath.row];
    
    //用到了SDAutoLayout这个库用来自动计算cell高度的
    return [self.tableView cellHeightForIndexPath:indexPath model:model keyPath:@"model" cellClass:[AlertTimeLineCell class] contentViewWidth:self.frame.size.width];
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    AlertTimeLineCell *cell = [AlertTimeLineCell timeLineCell:tableView];
    if (indexPath.row == 0) {
        cell.lineView.sd_layout.topSpaceToView(cell.pointView, 0);
    }else if(indexPath.row == [self.dataArray count] - 1){
        cell.lineView.sd_layout.bottomSpaceToView(cell.pointView, 0);
    }else{
        cell.lineView.sd_layout.topSpaceToView(cell.contentView, 0);
    }
    cell.model = self.dataArray[indexPath.row];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}
//-(void) tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    if([indexPath row] == ((NSIndexPath*)[[tableView indexPathsForVisibleRows] lastObject]).row){
//        //end of loading
////        dispatch_async(dispatch_get_main_queue(),^{
////            //for example [activityIndicator stopAnimating];
////        });
//        [[NSNotificationCenter defaultCenter]postNotificationName:@"111" object:nil];
//        CGRect frame = self.frame;
//        frame.size.height = self.tableView.contentSize.height;
//        NSLog(@"height = %f",self.tableView.contentSize.height);
//        self.frame = frame;
//    }
//}

@end
