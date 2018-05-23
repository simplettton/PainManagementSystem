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
    
    self.type = self.treatParamDic[@"machinetype"];

    UIImageView *middleView = [self.topView viewWithTag:20000];
    
    UIImageView *leftView = [self.topView viewWithTag:10000];
    
    leftView.hidden = ([self.type integerValue] == AladdinType);
    self.infomationView.hidden = ([self.type integerValue] == AladdinType);

    middleView.hidden = ([self.type integerValue] != AladdinType);
    
    NSMutableDictionary *modeDic;
    NSString *modeValue = self.treatParamDic[@"modeshowname"];
    switch ([self.type integerValue]) {
        case AladdinType:

            middleView.image = [UIImage imageNamed:@"aladdin"];
            break;
            
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

        default:
            //未知设备显示方案备注
            self.infomationView.text = [NSString stringWithFormat:@"%@",self.treatParamDic[@"note"]];

            self.infomationView.textAlignment = NSTextAlignmentLeft;
            break;
            
    }

    //插入显示治疗模式
    if (modeDic) {
        [datas insertObject:modeDic atIndex:0];
    }
    
    if (self.tableView.tableHeaderView.bounds.size.height + [datas count]*RowHeight + 30 >maxHeight) {
        self.preferredContentSize = CGSizeMake(360, maxHeight);
    }else{
        self.preferredContentSize = CGSizeMake(360, self.tableView.tableHeaderView.bounds.size.height + [datas count]*RowHeight + 30);
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
    NSString *key = dic[@"showname"];
    cell.questionNameLabel.text = key;
    cell.selectionsLabel.text = dic[@"value"];
    
//    if ([key isEqualToString:@"调制波形"]) {
//        cell.selectionsLabel.text = nil;
//
//        cell.waveFormImageView.image = [UIImage imageNamed:dic[@"value"]];
//
//    }

    return cell;

}


@end

