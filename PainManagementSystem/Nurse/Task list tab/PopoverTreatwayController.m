//
//  PopoverTreatwayController.m
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/4/3.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import "PopoverTreatwayController.h"

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
//
//    NSArray *dataArray = [NSArray arrayWithContentsOfFile:[[NSBundle mainBundle]pathForResource:@"TreatmentParam" ofType:@"plist"]];
//
//    datas = [dataArray mutableCopy];
    
    NSArray *dataArray = self.treatWayDic[@"list"];
    datas = [dataArray mutableCopy];
    self.type = self.treatWayDic[@"type"];
    
    UIImageView *aladdinView = [self.topView viewWithTag:AladdinViewTag];
    
    UIImageView *electrotherapyView = [self.topView viewWithTag:ElectrotherapyViewTag];
    
    UILabel *electrotherapyLabel = [self.topView viewWithTag:ElectrotherapyLabelTag];
    
    self.preferredContentSize = CGSizeMake(360, self.topView.bounds.size.height + [datas count]*RowHeight + 15);
    
    switch ([self.type integerValue]) {
        case AladdinViewTag:
            electrotherapyView.hidden = YES;
            electrotherapyLabel.hidden = YES;
            aladdinView.hidden = NO;
            aladdinView.image = [UIImage imageNamed:@"aladdin"];
            break;
            
        case AirProViewTag:
            electrotherapyView.hidden = YES;
            electrotherapyLabel.hidden = YES;
            aladdinView.hidden = NO;
            aladdinView.image = [UIImage imageNamed:@"airpro"];
            break;
            
        case ElectrotherapyViewTag:
        {
            electrotherapyView.hidden = NO;
            electrotherapyLabel.hidden = NO;
            aladdinView.hidden = YES;
            //电疗第一个参数就是通道数
            NSDictionary *channelDic = [datas objectAtIndex:0];
            NSString *channelNum = channelDic[@"value"];
            
            electrotherapyLabel.text = [NSString stringWithFormat:@"通道数:%@",channelNum];

            NSDictionary *channelImageNameInfo = @{@"1":@"singlechannel",@"2":@"doublechannel",@"3":@"thirdchannel"};
            
            electrotherapyView.image = [UIImage imageNamed:[channelImageNameInfo objectForKey:channelNum]];
            
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

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    
    NSDictionary *dic = [datas objectAtIndex:indexPath.row];
    NSString *key = dic[@"name"];
    cell.textLabel.text = key;
    cell.detailTextLabel.text = dic[@"value"];
    
    
    return cell;
    
    
}


@end

