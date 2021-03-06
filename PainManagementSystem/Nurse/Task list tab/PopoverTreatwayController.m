//
//  PopoverTreatwayController.m
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/4/3.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import "PopoverTreatwayController.h"
//借用questioncell边框
#import "QuestionCell.h"
#import "BaseHeader.h"
#define KeyTag 10000
#define ValueTag 20000
#define CellBorderViewTag 1111

#define AladdinType 57119
#define AirProType 7681
#define maxHeight 575

#define RowHeight 44
@interface PopoverTreatwayController ()<UITableViewDelegate,UITableViewDataSource>
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *topView;
@property (weak, nonatomic) IBOutlet UITextView *infomationView;

@property (strong, nonatomic) NSString *type;
@end

@implementation PopoverTreatwayController{
    NSMutableArray *datas;
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:YES];
}
- (void)viewDidLoad {
    [super viewDidLoad];
    [self initAll];

}
-(void)initAll{
    
    self.tableView.tableFooterView = [[UIView alloc]init];
    //获取数据源
    NSArray *dataArray = self.treatParamDic[@"paramlist"];
    datas = [dataArray mutableCopy];
    NSMutableDictionary *noteDic = [[NSMutableDictionary alloc]initWithCapacity:20];

    self.type = self.treatParamDic[@"machinetype"];
    
    if ([self.type integerValue]!=0) {
//        [noteDic setObject:@"备注" forKey:@"showname"];
        
        if (![self.treatParamDic[@"note"]isEqual:[NSNull null]]){
            if(![self.treatParamDic[@"note"]isEqualToString:@""]){
                if( ![self.treatParamDic[@"note"]isEqualToString:@"无"]) {
                    //tableview footer增加noteview
                    [self addNote:self.treatParamDic[@"note"]];
//                    [noteDic setObject:self.treatParamDic[@"note"] forKey:@"value"];
//                    [datas addObject:noteDic];
                }
            }
        }
    }
    
    UIImageView *middleView = [self.topView viewWithTag:20000];
    
    UIImageView *leftView = [self.topView viewWithTag:10000];
    
    leftView.hidden = ([self.type integerValue] == AladdinType);
    self.infomationView.hidden = ([self.type integerValue] == AladdinType);

    middleView.hidden = ([self.type integerValue] != AladdinType);
    
    NSMutableDictionary *modeDic;
    NSString *modeValue = self.treatParamDic[@"modeshowname"];
    switch ([self.type integerValue]) {
        case AirProType:
        {

            NSString *aport;
            NSString *bport;
            //提取AB气囊
            for (NSDictionary *dic in datas) {
                NSString *key = dic[@"showname"];
                NSString *value = dic[@"value"];
                if ([key isEqualToString:@"A气囊类型"]) {

                    aport = [NSString stringWithFormat:@"A气囊类型 %@",value];
                }
                if ([key isEqualToString:@"B气囊类型"]) {

                    bport  = [NSString stringWithFormat:@"B气囊类型 %@",value];
                }
                if (aport !=nil && bport!=nil) {
                    break;
                }

            }

            self.infomationView.text = [NSString stringWithFormat:@"%@\n\n%@",aport,bport];
            
            leftView.image = [UIImage imageNamed:@"airIcon"];
            //提取模式
            modeDic = [[NSMutableDictionary alloc]initWithCapacity:20];
            [modeDic setObject:@"治疗模式" forKey:@"showname"];
            [modeDic setObject:modeValue forKey:@"value"];
        }
            break;
            
        case 56833:
        case 56834:
        case 56836:
        {

            //提取模式
            modeDic = [[NSMutableDictionary alloc]initWithCapacity:20];
            [modeDic setObject:@"电流波形" forKey:@"showname"];
            [modeDic setObject:modeValue forKey:@"value"];

            //提取电疗参数通道数
            NSString *channelNum = [[NSString alloc]init];
            for (NSDictionary *dic in datas) {
                NSString *key = dic[@"showname"];
                NSString *value = dic[@"value"];
                if ([key isEqualToString:@"通道数"]) {
                    channelNum = value;
                    self.infomationView.text = [NSString stringWithFormat:@"\n通道数: %@",value];
                    self.infomationView.textColor = UIColorFromHex(0x0dbaa5);
                    break;
                }
            }
            NSDictionary *channelImageNameInfo = @{@"单通道":@"singlechannel",@"双通道":@"doublechannel",@"三通道":@"thirdchannel"};
            leftView.image = [UIImage imageNamed:[channelImageNameInfo objectForKey:channelNum]];
            
        }
            break;
        //光子治疗仪
        case 61200:
        case 61201:
        case 61202:
            
            //提取模式
            modeDic = [[NSMutableDictionary alloc]initWithCapacity:20];
            [modeDic setObject:@"主模式" forKey:@"showname"];
            [modeDic setObject:modeValue forKey:@"value"];
            self.infomationView.text = [NSString stringWithFormat:@"\n主模式: %@",modeValue];
            leftView.image = [UIImage imageNamed:@"airIcon"];
            
            break;

        case 0:
        {
            //未知设备显示方案备注
            leftView.hidden = YES;
            [self.infomationView removeFromSuperview];
            NSString *showString = [NSString stringWithFormat:@"方案：%@\n\n处方：%@",self.treatmentScheduleName,self.treatParamDic[@"note"]];
            NSRange scheduleRange = [showString rangeOfString:@"方案："];
            NSRange noteRange = [showString rangeOfString:@"处方："];

            //突出方案和备注关键字
            NSMutableAttributedString *str = [[NSMutableAttributedString alloc]initWithString:showString];
            [str addAttribute:NSForegroundColorAttributeName value:UIColorFromHex(0x5e97fe) range:scheduleRange];
            [str addAttribute:NSForegroundColorAttributeName value:UIColorFromHex(0x5e97fe) range:noteRange];
            
            middleView.hidden = NO;
            UITextView *textView = [[UITextView alloc]initWithFrame:CGRectMake(20, middleView.frame.origin.y + middleView.frame.size.height +25, 300, 100)];
            [self.topView addSubview:textView];
            textView.attributedText = str;
            textView.textAlignment = NSTextAlignmentLeft;
            textView.font = [UIFont systemFontOfSize:16 weight:UIFontWeightLight];
            [self refreshTextViewSize:textView];
            
            CGRect frame = self.topView.frame;
            frame.size.height = textView.frame.size.height + textView.frame.origin.y;
            self.topView.frame = frame;

        }
            break;
        default:
            middleView.hidden = NO;
            leftView.hidden = YES;
            [self.infomationView removeFromSuperview];
            break;
            
    }

    //插入显示治疗模式
    if (modeDic) {
        [datas insertObject:modeDic atIndex:0];
    }
    
    //popover显示高度调整
    if (self.tableView.tableHeaderView.bounds.size.height + self.tableView.tableFooterView.bounds.size.height + [datas count]*RowHeight + 30 >maxHeight) {
        self.preferredContentSize = CGSizeMake(360, maxHeight);
    }else{
        self.preferredContentSize = CGSizeMake(360, self.tableView.tableHeaderView.bounds.size.height + self.tableView.tableFooterView.bounds.size.height + [datas count]*RowHeight + 30);
    }
}
-(void)addNote:(NSString *)note{
    NSString *showString = [NSString stringWithFormat:@"备注：%@",note];
    NSRange noteRange = [showString rangeOfString:@"备注："];
    
    //突出方案和备注关键字
    NSMutableAttributedString *str = [[NSMutableAttributedString alloc]initWithString:showString];
    [str addAttribute:NSForegroundColorAttributeName value:UIColorFromHex(0x5e97fe) range:noteRange];

    UITextView *textView = [[UITextView alloc]initWithFrame:CGRectMake(10, 10, 300, 100)];
    [self.tableView.tableFooterView addSubview:textView];
    textView.attributedText = str;
    textView.textAlignment = NSTextAlignmentLeft;
    textView.font = [UIFont systemFontOfSize:16 weight:UIFontWeightLight];
    [self refreshTextViewSize:textView];
    
    CGRect frame = self.tableView.tableFooterView.frame;
    frame.size.height = textView.frame.size.height + textView.frame.origin.y;
    self.tableView.tableFooterView.frame = frame;
}

#pragma mark - tableViewDelegate

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [datas count];
}
-(CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 44;
}
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return UITableViewAutomaticDimension;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *CellIdentifier = @"Cell";
    QuestionCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    if (cell == nil) {
        cell = [[QuestionCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    cell.selectionsLabel.numberOfLines = 0;
    cell.selectionsLabel.lineBreakMode = NSLineBreakByWordWrapping;
    NSDictionary *dic = [datas objectAtIndex:indexPath.row];
    NSString *key = dic[@"showname"];
    cell.questionNameLabel.text = key;
    if([dic[@"value"] isEqual:[NSNull null]]){
        cell.selectionsLabel.text = @"无";
    }else{
        cell.selectionsLabel.text = dic[@"value"];
    }
    return cell;

}

- (CGSize)getStringRectInTextView:(NSString *)string InTextView:(UITextView *)textView;
{
    //
    //    NSLog(@"行高  ＝ %f container = %@,xxx = %f",self.textview.font.lineHeight,self.textview.textContainer,self.textview.textContainer.lineFragmentPadding);
    //
    //实际textView显示时我们设定的宽
    CGFloat contentWidth = CGRectGetWidth(textView.frame);
    //但事实上内容需要除去显示的边框值
    CGFloat broadWith    = (textView.contentInset.left + textView.contentInset.right
                            + textView.textContainerInset.left
                            + textView.textContainerInset.right
                            + textView.textContainer.lineFragmentPadding/*左边距*/
                            + textView.textContainer.lineFragmentPadding/*右边距*/);
    
    CGFloat broadHeight  = (textView.contentInset.top
                            + textView.contentInset.bottom
                            + textView.textContainerInset.top
                            + textView.textContainerInset.bottom);//+self.textview.textContainer.lineFragmentPadding/*top*//*+theTextView.textContainer.lineFragmentPadding*//*there is no bottom padding*/);
    
    //由于求的是普通字符串产生的Rect来适应textView的宽
    contentWidth -= broadWith;
    
    CGSize InSize = CGSizeMake(contentWidth, MAXFLOAT);
    
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc]init];
    paragraphStyle.lineBreakMode = textView.textContainer.lineBreakMode;
    NSDictionary *dic = @{NSFontAttributeName:textView.font, NSParagraphStyleAttributeName:[paragraphStyle copy]};
    
    CGSize calculatedSize =  [string boundingRectWithSize:InSize options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading attributes:dic context:nil].size;
    
    CGSize adjustedSize = CGSizeMake(ceilf(calculatedSize.width),calculatedSize.height + broadHeight);//ceilf(calculatedSize.height)
    return adjustedSize;
}
- (void)refreshTextViewSize:(UITextView *)textView
{
    CGSize size = [textView sizeThatFits:CGSizeMake(CGRectGetWidth(textView.frame), MAXFLOAT)];
    CGRect frame = textView.frame;
    frame.size.height = size.height;
    textView.frame = frame;
}
@end

