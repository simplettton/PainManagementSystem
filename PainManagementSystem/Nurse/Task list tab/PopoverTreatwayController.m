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

#define AladdinViewTag 57119
#define ElectrotherapyViewTag 56833
#define AirProViewTag 7681
#define ElectrotherapyLabelTag 2222

#define RowHeight 44
@interface PopoverTreatwayController ()<UITableViewDelegate,UITableViewDataSource>
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *topView;
@property (weak, nonatomic) IBOutlet UILabel *airProALabel;
@property (weak, nonatomic) IBOutlet UILabel *airProBLabel;

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
    
    NSArray *dataArray = self.treatWayDic[@"list"];
    datas = [dataArray mutableCopy];
    self.type = self.treatWayDic[@"type"];
    
    UIImageView *aladdinView = [self.topView viewWithTag:AladdinViewTag];
    
    UIImageView *leftView = [self.topView viewWithTag:ElectrotherapyViewTag];
    
    UILabel *electrotherapyLabel = [self.topView viewWithTag:ElectrotherapyLabelTag];
    
    self.preferredContentSize = CGSizeMake(360, self.topView.bounds.size.height + [datas count]*RowHeight + 15);
    
    self.airProALabel.hidden = ([self.type integerValue] != AirProViewTag);
    self.airProBLabel.hidden = ([self.type integerValue] != AirProViewTag);
    leftView.hidden = ([self.type integerValue] == AladdinViewTag);
    electrotherapyLabel.hidden = ([self.type integerValue] != ElectrotherapyViewTag);
    aladdinView.hidden = ([self.type integerValue] != AladdinViewTag);
    
    switch ([self.type integerValue]) {
        case AladdinViewTag:

            aladdinView.image = [UIImage imageNamed:@"aladdin"];
            break;
            
        case AirProViewTag:

//            aladdinView.image = [UIImage imageNamed:@"airpro"];
            leftView.image = [UIImage imageNamed:@"airIcon"];

            break;
            
        case ElectrotherapyViewTag:
        {

            //电疗第一个参数就是通道数
            NSDictionary *channelDic = [datas objectAtIndex:0];
            NSString *channelNum = channelDic[@"value"];
            
            electrotherapyLabel.text = [NSString stringWithFormat:@"通道数:%@",channelNum];

            NSDictionary *channelImageNameInfo = @{@"1":@"singlechannel",@"2":@"doublechannel",@"3":@"thirdchannel"};
            
            leftView.image = [UIImage imageNamed:[channelImageNameInfo objectForKey:channelNum]];
            
        }

            break;
            
            
        default:
            break;
    }
    
}

#pragma mark - tableViewDelegate

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [datas count];
}
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 44;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *CellIdentifier = @"Cell";
    QuestionCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    if (cell == nil) {
        cell = [[QuestionCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    
    NSDictionary *dic = [datas objectAtIndex:indexPath.row];
    NSString *key = dic[@"name"];
    cell.questionNameLabel.text = key;
    cell.selectionsLabel.text = dic[@"value"];
    
    if ([key isEqualToString:@"调制波形"]) {
        cell.selectionsLabel.text = nil;
        
        cell.waveFormImageView.image = [UIImage imageNamed:dic[@"value"]];
        
    }
    
    
    return cell;
    
    
}


@end

