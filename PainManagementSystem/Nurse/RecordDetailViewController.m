//
//  RecordDetailViewController.m
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/3/28.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import "RecordDetailViewController.h"
#import "RecordItemCell.h"
#define KTitleViewHeight 48
#define KRowHeight 21
#define KRowInterval 18
#define KPartInterval 11
#define KContentTag 5555
#define KWestTableViewTag 1111
#define KEastTableViewTag 2222

@interface RecordDetailViewController ()<UITableViewDataSource,UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UITableView *rootTableView;
@end

@implementation RecordDetailViewController{
    NSMutableArray *titles;
    NSArray *westArray;
    NSArray *eastArray;
}
-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:YES];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"诊疗记录详情";
    // Do any additional setup after loading the view.
    titles = [NSMutableArray arrayWithObjects:@"基本情况",@"西医病历采集",@"中医病历采集",@"诊断结果",@"物理治疗方法",@"设备治疗处方",nil];
    self.rootTableView.tableFooterView = [[UIView alloc]init];
    
    NSDictionary *dataDict = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Record" ofType:@"plist"]];
    
    //西方诊断类别
    westArray = [NSArray arrayWithArray:dataDict[@"questionw"]];
    
    NSMutableArray *westTypeNames = [[NSMutableArray alloc]initWithCapacity:20];;
    
    for (NSDictionary *dic in westArray) {
        
        NSString *typeName = dic[@"diagnosistype"];
        
        //诊断类别数组
        [westTypeNames addObject:typeName];
        
        //问题数组
        NSArray *questions = dic[@"question"];
        
        
        NSMutableArray *questionNames = [[NSMutableArray alloc]initWithCapacity:20];
        
        for (NSDictionary *question in questions) {
            
            //问题名字数组
            [questionNames addObject:question[@"name"]];
        }
        

    }

    
    
    //东方诊断类别
    eastArray = [NSArray arrayWithArray:dataDict[@"questione"]];
    NSInteger eastTypeNum = [eastArray count];
    
    
    
    NSMutableArray *mArray = [NSMutableArray array];
}

#pragma mark - tableViewDataSource

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    if (tableView == self.rootTableView) {
        return [titles count];;
    }else if(tableView.tag == KWestTableViewTag){
        NSLog(@"weatArray count= %lu",(unsigned long)[westArray count]);
        return [westArray count];

    }else{
        return [eastArray count];
    }

}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 1;
}
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (tableView == self.rootTableView) {
        //基本情况
        if (indexPath.section == [titles indexOfObject:@"基本情况"]) {
            return 4*KRowInterval+3*KRowHeight+KTitleViewHeight+KPartInterval;
        }
        //诊断结果
        if ((indexPath.section == [titles indexOfObject:@"诊断结果"]) || (indexPath.section == [titles indexOfObject:@"物理治疗方法"])) {
            return 2*KRowInterval+1*KRowHeight+KTitleViewHeight+KPartInterval;
        }
        return 350;
    }else{
        return 44;
    }

}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *CellIdentifier;
    if (tableView == self.rootTableView) {
        switch (indexPath.section) {
                
            case 0: {   CellIdentifier = @"BasicInfomationCell";    }       break;
            case 3: {   CellIdentifier = @"ResultCell";     }
            case 4: {   CellIdentifier = @"ResultCell";     }       break;
            default: {      CellIdentifier = @"Cell";       }       break;
        }
        
        RecordItemCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        if (cell == nil) {
            cell = [[RecordItemCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        }
        cell.titleLabel.text = titles[indexPath.section];
        
        switch (indexPath.section) {
            case 1:
            {
                cell.insertTableView.tag = KWestTableViewTag;
            }
                break;
            case 2:
            {
                cell.insertTableView.tag = KEastTableViewTag;
            }
                break;
            case 3:
            {   UILabel *content = [cell viewWithTag:KContentTag];
                content.text = [NSString stringWithFormat:@"病理因素：痉挛性疼痛          发病部位：肌肉          中医辨证：寒"];
            }
                break;
            case 4:
            {
                UILabel *content = [cell viewWithTag:KContentTag];
                content.text = [NSString stringWithFormat:@"超声治疗法"];
            }
                break;
            default: {      CellIdentifier = @"Cell";       }       break;
        }
           return cell;
    }else {
        
        CellIdentifier = @"QuestionCell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        if (cell == nil) {
            cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        }
        if(tableView.tag == KWestTableViewTag){
            
        }else{
            
        }
        return cell;
        
    }


}


@end
