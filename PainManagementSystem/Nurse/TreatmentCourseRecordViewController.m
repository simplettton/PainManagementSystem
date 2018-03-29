//
//  TreatmentCourseRecordViewController.m
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/3/27.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import "TreatmentCourseRecordViewController.h"
#import "VASMarkView.h"
#import "TreatRecordCell.h"
#import "RecordDetailViewController.h"
@interface TreatmentCourseRecordViewController ()<UITableViewDelegate,UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *ageLabel;
@property (weak, nonatomic) IBOutlet UILabel *phoneLabel;

@end

@implementation TreatmentCourseRecordViewController{
    NSMutableArray *datas;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initAll];
    // Do any additional setup after loading the view.
}

-(void)initAll{
    

    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.tableFooterView = [[UIView alloc]init];
    
    if (self.dataDic) {
        self.title = @"治疗疗程记录";
        self.nameLabel.text = [NSString stringWithFormat:@"姓名:%@",self.dataDic[@"name"]];
        self.ageLabel.text = [NSString stringWithFormat:@"年龄:%@",self.dataDic[@"age"]];
        self.phoneLabel.text = [NSString stringWithFormat:@"电话:%@",self.dataDic[@"phone"]];
    }
    
    
    datas = [[NSMutableArray alloc]initWithCapacity:20];
    datas = [NSMutableArray arrayWithObjects:
             @{@"medicalRecordNum":@"12345896",@"name":@"小明",@"gender":@"男",@"age":@"20",@"phone":@"13782965445"},
             @{@"medicalRecordNum":@"12345893",@"name":@"王力",@"gender":@"男",@"age":@"19",@"phone":@"15521064545"},
             @{@"medicalRecordNum":@"12345898",@"name":@"东东",@"gender":@"女",@"age":@"36",@"phone":@"18821654545"},
             nil];
}

#pragma mark - tableview delegate
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [datas count];
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *CellIdentifier = @"Cell";
    TreatRecordCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    if (cell == nil) {
        cell = [[TreatRecordCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
//    [cell.markButton setTag:indexPath.row];
    [cell.markButton addTarget:self action:@selector(showVASMarkView:) forControlEvents:UIControlEventTouchUpInside];
    
    
    return cell;
}
-(void)showVASMarkView:(UIButton *)sender{
    [VASMarkView alertControllerAboveIn:self return:^(NSString *markString) {
        UIView *contentView = [sender superview];
        TreatRecordCell *cell = (TreatRecordCell *)[contentView superview];
        cell.vasAfterLB.text = markString;
    }];
    
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self performSegueWithIdentifier:@"ShowRecordDetail" sender:nil];
}
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([segue.identifier isEqualToString:@"ShowRecordDetail"]) {
        RecordDetailViewController *controller = (RecordDetailViewController *)segue.destinationViewController;
        controller.dataDic = self.dataDic;
    }
}

@end
