//
//  RecordDetailViewController.m
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/3/28.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import "RecordDetailViewController.h"
#import "RecordItemCell.h"
#import "QuestionCell.h"
#import "BaseHeader.h"

#import "RecordModel.h"

#define KTitleViewHeight 48
#define KRowHeight 21
#define KRowInterval 18
#define KPartInterval 11

#define KWestTableViewTag 1111
#define KEastTableViewTag 2222
#define KTreatParamViewTag 3333

@interface RecordDetailViewController ()<UITableViewDataSource,UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UITableView *rootTableView;
@property (strong,nonatomic)RecordModel *recordModel;

@end

@implementation RecordDetailViewController{
    NSMutableArray *titles;
}
-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:YES];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"诊疗记录详情";
    titles = [NSMutableArray arrayWithObjects:@"基本情况",@"西医病历采集",@"中医病历采集",@"诊断结果",@"物理治疗方法",@"设备治疗处方",nil];
    self.rootTableView.tableFooterView = [[UIView alloc]init];
    
    NSDictionary *dataDic = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Record" ofType:@"plist"]];
    
    //得到数据模型
    if (self.record) {
        self.recordModel = self.record;
    }else{
        self.recordModel = [RecordModel modelWithDic:dataDic];
    }

}

#pragma mark - tableViewDataSource

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    if (tableView == self.rootTableView) {
        return [titles count];;
    }else if(tableView.tag == KWestTableViewTag){

        return [self.recordModel.questionW count];

    }else if(tableView.tag == KEastTableViewTag){

        return [self.recordModel.questionE count];
    }else {
        return 1;
    }
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if (tableView == self.rootTableView) {
        return 1;
    }
    else if (tableView.tag == KWestTableViewTag){

        return [self.recordModel.questionW[section].questionArray count];
        
    }else if(tableView.tag == KEastTableViewTag){
        
        return [self.recordModel.questionE[section].questionArray count];
    }else if(tableView.tag == KTreatParamViewTag){
        return [self.recordModel.treatParam count];
    }else{
        return 1;
    }

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
        //西医病历采集
        if (indexPath.section == [titles indexOfObject:@"西医病历采集"]) {
            return [self rowHeightWithQuestionArray:self.recordModel.questionW];
        }
        if (indexPath.section == [titles indexOfObject:@"中医病历采集"]) {
            return [self rowHeightWithQuestionArray:self.recordModel.questionE];
        }
        if (indexPath.section == [titles indexOfObject:@"设备治疗处方"]) {
            return 44*([self.recordModel.treatParam count])+KTitleViewHeight +KPartInterval+KRowInterval*2;
        }
    }
    return 44;
}
-(NSInteger)rowHeightWithQuestionArray:(NSMutableArray *)array{
    
    NSInteger sectionNumber = [array count];
    NSMutableArray <QuestionItem*> *quetionItemArray = array;
    NSInteger rowNumber = 0;
    for (QuestionItem *item in quetionItemArray) {
        rowNumber += [item.questionArray count];
    }
    return 44*(sectionNumber + rowNumber)+KTitleViewHeight+KPartInterval+KRowInterval;
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
            case 0:
            {
                cell.basicInfoLabel.text = [NSString stringWithFormat:@"姓名：%@          年龄：%@          电话：%@",self.patient.name,self.patient.age,self.patient.contact];
                cell.vasLabel.text = [NSString stringWithFormat:@"治疗前vas：%@          治疗后vas：%@",self.recordModel.vasBefore,self.recordModel.vasAfter];
                cell.doctorLabel.text = [NSString stringWithFormat:@"医生：%@",self.recordModel.operator];
            }
                break;
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
            {
                cell.contentLabel.text = [NSString stringWithFormat:@"病理因素：%@          发病部位：%@         中医辨证：%@",self.recordModel.painfactorW,self.recordModel.painArea,self.recordModel.painfactorE];
            }
                break;
            case 4:
            {
                
                cell.contentLabel.text = [NSString stringWithFormat:@"%@",self.recordModel.physicalTreat];
            }
                break;
            case 5:
            {
                cell.insertTableView.tag = KTreatParamViewTag;
            }
            default: {      CellIdentifier = @"Cell";       }       break;
        }
           return cell;
    }else {
        
        CellIdentifier = @"QuestionCell";
        QuestionCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        if (cell == nil) {
            cell = [[QuestionCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        }
        
        NSMutableArray *dataArray = [[NSMutableArray alloc]init];
        //西医病历采集
        if (tableView.tag == KWestTableViewTag) {
            dataArray = self.recordModel.questionW;
            
        }else if (tableView.tag == KEastTableViewTag){  //中医病历采集
            dataArray = self.recordModel.questionE;
            
        }
        if([dataArray count]>0){
            
            QuestionItem *questionItem = dataArray[indexPath.section];
            
            Question *question = questionItem.questionArray[indexPath.row];
            
            cell.questionNameLabel.text = question.name;
            
            cell.selectionsLabel.text = question.selectionString;
        }else{
            //物理治疗方法
            Question *param = self.recordModel.treatParam[indexPath.row];
            cell.questionNameLabel.text = param.name;
            cell.selectionsLabel.text = param.selectionString;
        }

        return cell;
        
    }


}

#pragma mark -sectionStyle
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    if (tableView != self.rootTableView) {
        if (tableView.tag == KTreatParamViewTag) {
            return KRowInterval;
        }
        return 44;
    }
    return 0;
}
//返回每组头部view
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    
    UIView *headerView = [[UIView alloc]init];
    
    if ((tableView != self.rootTableView) && (tableView.tag != KTreatParamViewTag)) {
        
        UILabel *label = [[UILabel alloc]init];
        
        label.textColor = [UIColor grayColor];
        
        label.font = [UIFont systemFontOfSize:13 weight:UIFontWeightLight];
        
        label.frame = CGRectMake(30, 0, 100, 44);
        
        [headerView addSubview:label];
        
        NSMutableArray *dataArray = [[NSMutableArray alloc]init];
        
        if (tableView.tag == KWestTableViewTag) {

            dataArray = self.recordModel.questionW;
            
        }else if (tableView.tag == KEastTableViewTag){

            dataArray = self.recordModel.questionE;
            
        }
        
            NSMutableArray *typeNames = [[NSMutableArray alloc]initWithCapacity:20];;
        
        
        for (QuestionItem *questionItem  in dataArray) {
            
            NSString *typeName = questionItem.diagnosisType;
            
            [typeNames addObject:typeName];
        }
        
        if ([typeNames count ]>section) {
            label.text = typeNames[section];
        }
    }
    
    return headerView;
    
}



@end
