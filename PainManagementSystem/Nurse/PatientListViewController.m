//
//  PatientListViewController.m
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/3/23.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import "PatientListViewController.h"
#import "AddPatientViewController.h"
#import "TreatmentCourseRecordViewController.h"
#import "PatientTableViewCell.h"
#import "BaseHeader.h"

@interface PatientListViewController ()<UITableViewDelegate,UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation PatientListViewController{
    NSMutableArray *datas;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"疼痛管理系统";
    
    [self initAll];
}

-(void)initAll{
    
    //navigation 返回导航栏的样式
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc]init];
    backButton.title = @"";
    self.navigationItem.backBarButtonItem = backButton;

    
    self.searchBar.backgroundImage = [[UIImage alloc]init];//去除边框线
    
    self.searchBar.tintColor = UIColorFromHex(0x5E97FE);//出现光标
    //通过KVC获得到UISearchBar的私有变量
    //searchField
    UITextField *searchField = [self.searchBar valueForKey:@"searchField"];
    if (searchField) {
        [searchField setBackgroundColor:[UIColor whiteColor]];
        searchField.layer.cornerRadius = 5.0f;
        searchField.layer.borderColor = UIColorFromHex(0xBBBBBB).CGColor;
        searchField.layer.borderWidth = 1;
        searchField.layer.masksToBounds = YES;
    }
    
    
    self.searchBar.delegate = self;
    

    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.tableFooterView = [[UIView alloc]init];
    
    datas = [[NSMutableArray alloc]initWithCapacity:20];
    datas = [NSMutableArray arrayWithObjects:
             @{@"medicalRecordNum":@"12345896",@"name":@"小明",@"gender":@"男",@"age":@"20",@"phone":@"13782965445"},
             @{@"medicalRecordNum":@"12345893",@"name":@"王力",@"gender":@"男",@"age":@"19",@"phone":@"15521064545"},
             @{@"medicalRecordNum":@"12345898",@"name":@"东东",@"gender":@"女",@"age":@"36",@"phone":@"18821654545"},
             nil];
    
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:YES];
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.navigationController.navigationBar.barTintColor = UIColorFromHex(0x2EA3E6);
    
}

#pragma mark - table view delegate
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [datas count];
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *CellIdentifier = @"Cell";
    
    PatientTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    if (cell == nil) {
        cell = [[PatientTableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    cell.medicalRecordNumLabel.text = [datas[indexPath.row]objectForKey:@"medicalRecordNum"];
    cell.nameLabel.text = [datas[indexPath.row]objectForKey:@"name"];
    cell.genderLabel.text = [datas[indexPath.row]objectForKey:@"gender"];
    cell.ageLabel.text = [datas[indexPath.row]objectForKey:@"age"];
    
    
    cell.editButton.tag = indexPath.row;
    [cell.editButton addTarget:self action:@selector(editPatientInfomation:) forControlEvents:UIControlEventTouchUpInside];
    
    [cell.inquireButton addTarget:self action:@selector(showRecord:) forControlEvents:UIControlEventTouchUpInside];
    
    
    return cell;
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}
-(void)editPatientInfomation:(UIButton *)sender{

    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:sender.tag inSection:0];
    
//    PatientTableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
//    [self performSegueWithIdentifier:@"EditPatientInfomation" sender:cell];
    
    NSDictionary *dataDic = datas[indexPath.row];
    [self performSegueWithIdentifier:@"EditPatientInfomation" sender:dataDic];


}
-(void)showRecord:(UIButton *)sender{
    
    UIView* contentView = [sender superview];
    PatientTableViewCell *cell = (PatientTableViewCell *)[contentView superview];
    
    NSInteger interger = [self.tableView.visibleCells indexOfObject:cell];
    NSDictionary *dataDic = datas[interger];
    
    [self performSegueWithIdentifier:@"ShowTreatmentCourseRecord" sender:dataDic];
    
    
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([segue.identifier isEqualToString:@"EditPatientInfomation"]) {
        AddPatientViewController *controller = (AddPatientViewController *)segue.destinationViewController;
        
        //传数据,segue手动
        controller.dataDic = sender;
    }else if ([segue.identifier isEqualToString:@"ShowTreatmentCourseRecord"]){
        TreatmentCourseRecordViewController *controller = (TreatmentCourseRecordViewController *)segue.destinationViewController;
        controller.dataDic = sender;
    }
}
@end
