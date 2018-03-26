//
//  MedicalRecordListViewController.m
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/3/23.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import "MedicalRecordListViewController.h"
#import "BaseHeader.h"
@interface MedicalRecordListViewController ()<UITableViewDelegate,UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation MedicalRecordListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"疼痛管理系统";
    
    [self initAll];
}

-(void)initAll{
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
    
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:YES];
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.navigationController.navigationBar.barTintColor = UIColorFromHex(0x2EA3E6);
}

#pragma mark - delegate
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 1;
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        
    }
    return cell;
}
@end
