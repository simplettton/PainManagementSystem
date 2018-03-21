//
//  DeviceListViewController.m
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/3/19.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import "DeviceListViewController.h"
#import "DeviceTableViewCell.h"
#import "EditDeviceViewController.h"
@interface DeviceListViewController ()
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation DeviceListViewController{
        NSMutableArray *datas;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"设备管理系统";
    [self initAll];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:YES];

    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:46.0f/255.0f green:163.0f/255.0f blue:230.0f/255.0f alpha:1];
}


-(void)initAll{
    
    self.searchBar.backgroundImage = [[UIImage alloc]init];//去除边框线
    self.searchBar.tintColor = [UIColor blackColor];//出现光标
    self.tableView.tableFooterView = [[UIView alloc]init];
    
    datas = [[NSMutableArray alloc]initWithCapacity:20];
    datas = [NSMutableArray arrayWithObjects:
             @{@"type":@"空气波",@"macString":@"dgahqaa",@"name":@"骨科一号",@"serialNum":@"13654979946"},
             @{@"type":@"空气波",@"macString":@"fjfjfds",@"name":@"骨科一号",@"serialNum":@"45645615764"},
             @{@"type":@"电疗",@"macString":@"fstjkst",@"name":@"骨科一号",@"serialNum":@"12367874456"},
             nil];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
#pragma mark - tableview dataSource
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [datas count];
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *CellIdentifier = @"Cell";
    DeviceTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    if (cell == nil) {
        cell = [[DeviceTableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    NSDictionary *dataDic = [datas objectAtIndex:indexPath.row];
    cell.typeLabel.text = [dataDic objectForKey:@"type"];
    cell.serialNumLabel.text = [dataDic objectForKey:@"serialNum"];
    cell.nameLabel.text = [dataDic objectForKey:@"name"];
    cell.macString = [dataDic objectForKey:@"macString"];
    
    cell.editButton.tag = indexPath.row;
    [cell.editButton addTarget:self action:@selector(edit:) forControlEvents:UIControlEventTouchUpInside];
    
    
    return cell;
}

-(void)edit:(UIButton *)sender{
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:sender.tag inSection:0];
    DeviceTableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    [self performSegueWithIdentifier:@"EditDevice" sender:cell];
}

#pragma mark - segue

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if([segue.identifier isEqualToString:@"EditDevice"]){
        UINavigationController *navi = (UINavigationController  *)segue.destinationViewController;
        DeviceTableViewCell *cell= (DeviceTableViewCell *)sender;
        EditDeviceViewController *controller = [navi.viewControllers firstObject];
        controller.type = cell.typeLabel.text;
        controller.name = cell.nameLabel.text;
        controller.macString = cell.macString;
        controller.serialNum = cell.serialNumLabel.text;
        
        
    }
}
@end
