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
    //获取数据源
    NSArray *dataArray = self.treatParamDic[@"paramlist"];
    datas = [dataArray mutableCopy];
    
    self.type = self.treatParamDic[@"machinetype"];

    UIImageView *aladdinView = [self.topView viewWithTag:AladdinViewTag];
    
    UIImageView *leftView = [self.topView viewWithTag:ElectrotherapyViewTag];
    
    UILabel *electrotherapyLabel = [self.topView viewWithTag:ElectrotherapyLabelTag];

    
    self.airProALabel.hidden = ([self.type integerValue] != AirProViewTag);
    self.airProBLabel.hidden = ([self.type integerValue] != AirProViewTag);
    leftView.hidden = ([self.type integerValue] == AladdinViewTag);
    electrotherapyLabel.hidden = ([self.type integerValue] != ElectrotherapyViewTag);
    aladdinView.hidden = ([self.type integerValue] != AladdinViewTag);
    
    NSMutableDictionary *modeDic;
    NSString *modeValue = self.treatParamDic[@"modeshowname"];
    switch ([self.type integerValue]) {
        case AladdinViewTag:

            aladdinView.image = [UIImage imageNamed:@"aladdin"];
            break;
            
        case AirProViewTag:
        {

//            aladdinView.image = [UIImage imageNamed:@"airpro"];
            //提取AB气囊
            for (NSDictionary *dic in datas) {
                NSString *key = dic[@"showname"];
                NSString *value = dic[@"value"];
                if ([key isEqualToString:@"A气囊类型"]) {
                    self.airProALabel.text = [NSString stringWithFormat:@"A气囊类型 %@",value];
                }
                if ([key isEqualToString:@"B气囊类型"]) {
                    self.airProBLabel.text = [NSString stringWithFormat:@"B气囊类型 %@",value];
                }
            }
            
            leftView.image = [UIImage imageNamed:@"airIcon"];
            //提取模式
            modeDic = [[NSMutableDictionary alloc]initWithCapacity:20];
            [modeDic setObject:@"治疗模式" forKey:@"showname"];
            [modeDic setObject:modeValue forKey:@"value"];
        }
            break;
            
        case ElectrotherapyViewTag:
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
                    electrotherapyLabel.text = [NSString stringWithFormat:@"通道数:%@",value];
                    channelNum = value;
                    break;
                }
            }
            NSDictionary *channelImageNameInfo = @{@"1":@"singlechannel",@"2":@"doublechannel",@"3":@"thirdchannel"};
            
            leftView.image = [UIImage imageNamed:[channelImageNameInfo objectForKey:channelNum]];
            
        }

            break;
            
            
        default:
            break;
            
    }

    //插入显示治疗模式
    if (modeDic) {
        [datas insertObject:modeDic atIndex:0];
    }
    
    self.preferredContentSize = CGSizeMake(360, self.topView.bounds.size.height + [datas count]*RowHeight + 15);
    
    
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
    NSString *key = dic[@"showname"];
    cell.questionNameLabel.text = key;
    cell.selectionsLabel.text = dic[@"value"];
    
    if ([key isEqualToString:@"调制波形"]) {
        cell.selectionsLabel.text = nil;
        
        cell.waveFormImageView.image = [UIImage imageNamed:dic[@"value"]];
        
    }
    
    
    return cell;
    
    
}


@end

