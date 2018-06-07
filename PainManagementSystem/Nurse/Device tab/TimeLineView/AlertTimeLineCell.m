//
//  AlertTimeLineCell.m
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/6/5.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import "AlertTimeLineCell.h"
#import "SDAutoLayout.h"
@interface AlertTimeLineCell()
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UIView *titleView;


@end
@implementation AlertTimeLineCell
+ (instancetype) timeLineCell:(UITableView *) tableView{
    AlertTimeLineCell *cell = [tableView dequeueReusableCellWithIdentifier:@"AlertTimeLineCell"];
    if (cell == nil) {
        cell = [[[NSBundle mainBundle] loadNibNamed:@"AlertTimeLineCell" owner:nil options:nil] firstObject];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return cell;
}
- (void)awakeFromNib {
    [super awakeFromNib];
    
//    这里对titleLB的布局做高度自适应，及设置autoHeightRatio为0即可，然后我们直接在设置模型中调用 [self setupAutoHeightWithBottomView:self.titleLB bottomMargin:0]就自动完成了高度自适应，是不是很方便
//    。
    self.titleLabel.sd_layout.autoHeightRatio(0);
    [self setRadius];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}
-(void)setModel:(TimeLineModel *)model{
    _model = model;
    self.titleLabel.text = model.title;
    self.dateLabel.text = [self stringFromTimeIntervalString:model.timeStamp dateFormat:@"yyyy-MM-dd"];
    self.timeLabel.text = [self stringFromTimeIntervalString:model.timeStamp dateFormat:@"HH:mm"];
//    [self setupAutoHeightWithBottomView:self.titleLB bottomMargin:0];
}
-(void)setRadius{
    self.pointView.layer.cornerRadius = self.pointView.frame.size.width/2;
    [self.pointView.layer setMasksToBounds:YES];
    
    self.titleView.layer.cornerRadius = 5.0f;
    [self.titleView.layer setMasksToBounds:YES];
}
//时间戳字符串转化为日期或时间
- (NSString *)stringFromTimeIntervalString:(NSString *)timeString dateFormat:(NSString*)dateFormat
{
    // 格式化时间
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    [formatter setTimeZone: [NSTimeZone timeZoneWithName:@"Asia/Beijing"]];
    [formatter setDateStyle:NSDateFormatterMediumStyle];
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    [formatter setDateFormat:dateFormat];
    
    // 毫秒值转化为秒
    NSDate* date = [NSDate dateWithTimeIntervalSince1970:[timeString doubleValue]];
    NSString* dateString = [formatter stringFromDate:date];
    
    return dateString;
}
@end
