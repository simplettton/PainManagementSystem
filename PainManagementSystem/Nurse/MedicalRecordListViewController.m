//
//  MedicalRecordListViewController.m
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/3/23.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import "MedicalRecordListViewController.h"
#import "BaseHeader.h"
@interface MedicalRecordListViewController ()
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;

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
    
//    UITextField *searchField = [self.searchBar valueForKey:@"searchField"];
//    if (searchField) {
//        [searchField setBackgroundColor:[UIColor whiteColor]];
//        searchField.layer.cornerRadius = 14.0f;
//        searchField.layer.borderColor = [UIColor colorWithRed:247/255.0 green:75/255.0 blue:31/255.0 alpha:1].CGColor;
//        searchField.layer.borderWidth = 1;
//        searchField.layer.masksToBounds = YES;
//    }
    
    self.searchBar.delegate = self;
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:YES];
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.navigationController.navigationBar.barTintColor = UIColorFromHex(0x2EA3E6);
}
@end
