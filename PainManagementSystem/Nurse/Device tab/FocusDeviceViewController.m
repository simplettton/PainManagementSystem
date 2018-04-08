//
//  FocusDeviceViewController.m
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/4/4.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import "FocusDeviceViewController.h"
#import "TreatmentCourseRecordViewController.h"
#import "DeviceCollectionViewCell.h"
#import "FocusMachineAlertView.h"
#import "BaseHeader.h"
#import "HHDropDownList.h"

#define kOrangeColor 0xf8b273

#define kGreenColor 0x7ede98

#define kGreyColor 0xc1c1c1

#define kCellWidth 220

#define kCellHeight 186

#define List_Width (KScreenWidth + 1.4 )/4.0

@interface FocusDeviceViewController ()<UISearchBarDelegate,UICollectionViewDelegate,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout,HHDropDownListDelegate, HHDropDownListDataSource>

@property (weak, nonatomic) IBOutlet UIButton *allTabButton;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;

@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) IBOutlet UIView *deviceBackgroundView;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;



//@property (weak, nonatomic) IBOutlet HHDropDownList *dropList;
@property (strong,nonatomic)HHDropDownList *dropList;

@property (strong, nonatomic) NSArray *dropListArray;

@end

@implementation FocusDeviceViewController
{
    NSMutableArray *datas;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initUI];
    
    // Do any additional setup after loading the view.
}
-(void)initUI{
    
    if (self.isInAllTab) {
        
        //隐藏本地设备
        self.allTabButton.hidden = NO;
        self.segmentedControl.hidden = YES;
    }else{
        self.allTabButton.hidden = YES;
        self.segmentedControl.hidden = NO;
    }
    
    //配置searchbar样式
    self.searchBar.delegate = self;
    self.searchBar.backgroundImage = [[UIImage alloc]init];//去除边框线
    
    self.searchBar.tintColor = UIColorFromHex(0x5E97FE);//出现光标
    //通过KVC获得到UISearchBar的私有变量
    //searchField
    UITextField *searchField = [self.searchBar valueForKey:@"searchField"];
    if (searchField) {
        [searchField setBackgroundColor:[UIColor whiteColor]];
        searchField.font = [UIFont systemFontOfSize:14.0f];
        searchField.layer.cornerRadius = 5.0f;
        searchField.layer.borderColor = UIColorFromHex(0xBBBBBB).CGColor;
        searchField.layer.borderWidth = 1;
        searchField.layer.masksToBounds = YES;
    }
    
    //设备外框边框设置
    self.deviceBackgroundView.layer.borderColor = UIColorFromHex(0xbbbbbb).CGColor;
    self.deviceBackgroundView.layer.borderWidth = 0.5f;
    [self.deviceBackgroundView.layer setMasksToBounds:YES];
    
    //UICollectionView 配置
//    [self.collectionView registerClass:[DeviceCollectionViewCell class] forCellWithReuseIdentifier:@"Cell"];
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    
    //数据源
    NSArray *dataArray = [[NSArray alloc]init];
    if (self.isInAllTab) {
        dataArray = @[@{},@{},@{},@{},@{},@{},@{},@{},@{}];
    }else{
        dataArray = @[@{},@{},@{},@{},@{}];
    }
    datas = [dataArray copy];
    
    
    //seguement 在线或者本地
    self.segmentedControl.frame = CGRectMake(28, 75, 200, 35);
    
    [self.segmentedControl setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}forState:UIControlStateSelected];
    
    [self.segmentedControl setTitleTextAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:15.0f]}forState:UIControlStateNormal];
    
    [self.segmentedControl addTarget:self action:@selector(didClicksegmentedControlAction:) forControlEvents:UIControlEventValueChanged];
    
    
    
    //下拉框
    [self.deviceBackgroundView addSubview:self.dropList];
    NSArray *array_1 = @[@"所有设备", @"治疗中设备", @"异常设备", @"其他设备"];
    self.dropListArray = array_1;

    [self.dropList reloadListData];
    
}

-(HHDropDownList *)dropList{
    if (!_dropList) {
        //配置dropList
        _dropList = [[HHDropDownList alloc]initWithFrame:CGRectMake(8, 14, List_Width, 35)];
        
        [_dropList setBackgroundColor:[UIColor colorWithRed:249/255.0 green:249/255.0 blue:249/255.0 alpha:1.0]];
        [_dropList setHighlightColor:[UIColor colorWithRed:46/255.0 green:163/255.0 blue:230/255.0 alpha:0.5]];
        [_dropList setDelegate:self];
        [_dropList setDataSource:self];
        
        [_dropList setIsExclusive:YES];
        [_dropList setHaveBorderLine:YES];

    }
    return _dropList;
}
-(void)didClicksegmentedControlAction:(UISegmentedControl *)segmentedControl{
    
    NSInteger Index = segmentedControl.selectedSegmentIndex;
    NSArray *dataArray = [[NSArray alloc]init];
    switch (Index) {
        case DeviceTypeOnline:
        {
            
            dataArray = @[@{},@{},@{},@{},@{}];
            self.dropList.hidden = NO;
        
        }
            
            break;
        case DeviceTypeLocal:
        {
            
            dataArray = @[@{},@{},@{},@{}];
            self.dropList.hidden = YES;
        }
            break;
            
        default:
            break;
    }

    datas = [dataArray copy];
    [self.collectionView reloadData];
}



#pragma mark - CollectionViewDelegate
-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return [datas count];
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{

    static NSString *CellIdentifier;
    
    DeviceCollectionViewCell *cell;
    
    switch (self.segmentedControl.selectedSegmentIndex) {
        case DeviceTypeOnline:
        {
            CellIdentifier = @"Cell";
            
            cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
            
            if (indexPath.row == 1) {
                [cell configureWithStyle:CellStyleGrey_MachinePause];
            }else{
                switch (indexPath.row %3) {
                    case 0:
                        
                        [cell configureWithStyle:CellStyleOrange_MachineException];
                        break;
                    case 1:
                        
                        [cell configureWithStyle:CellStyleGreen_MachineRunning];
                        break;
                    case 2:
                        
                        [cell configureWithStyle:CellStyleGrey_MachineStop];
                        [cell.middleButton addTarget:self action:@selector(goToRemarkVAS:) forControlEvents:UIControlEventTouchUpInside];
                        break;
                    default:
                        break;
                }
            }
            
            
        }
            
            break;
            
        case DeviceTypeLocal:
        {
            CellIdentifier = @"LocalDeviceCell";
            
            cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
            
        }
            
            break;
            
        default:
            break;
    }
    
    
    if (cell == nil) {
        cell = [[DeviceCollectionViewCell alloc]init];
    }
    


    UILongPressGestureRecognizer* longgs=[[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(longpress:)];
    [cell addGestureRecognizer:longgs];//为cell添加手势
    longgs.minimumPressDuration=1.0;//定义长按识别时长
    longgs.view.tag=indexPath.row;//将手势和cell的序号绑定


    return cell;
}
-(void)goToRemarkVAS:(UIButton *)button{
    [self performSegueWithIdentifier:@"GoToRemarkVAS" sender:button];
}

-(void)longpress:(UILongPressGestureRecognizer*)ges{
    if(ges.state==UIGestureRecognizerStateBegan){
        //获取目标cell
        NSInteger row=ges.view.tag;
        //删除操作
        if(datas.count >1){
            NSIndexPath *index =[NSIndexPath indexPathForRow:row inSection:0];
            NSArray* deletearr=@[index];
            [self.collectionView deleteItemsAtIndexPaths:deletearr];
        }else{
            [self.collectionView reloadData];
            
        }
    }
}

// 允许选中时，高亮
-(BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath{
    return YES;
}
// 设置是否允许选中
- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"%s", __FUNCTION__);
    return YES;
}

//选中后回调
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    DeviceCollectionViewCell *cell = (DeviceCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];

}
//设置每个item的尺寸
-(CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
    return CGSizeMake(220, 186);
}

////设置每个item的UIEdgeInsets
//- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
//{
//    return UIEdgeInsetsMake(10, 10, 10, 10);
//}

//设置每个item水平间距
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    return 5;
}


//设置每个item垂直间距
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    return 25;
}


#pragma mark - UICollectionViewDelegateFlowLayout

//-(CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
//{
//    return (CGSize){kCellWidth,kCellHeight};
//}
- (IBAction)search:(id)sender {
    [FocusMachineAlertView alertControllerAboveIn:self withDataDic:nil returnBlock:^{
        
    }];
}

#pragma mark - HHDropDownListDataSource
- (NSArray *)listDataForDropDownList:(HHDropDownList *)dropDownList {
    
    return _dropListArray;
}

#pragma mark - HHDropDownListDelegate
- (void)dropDownList:(HHDropDownList *)dropDownList didSelectItemName:(NSString *)itemName atIndex:(NSInteger)index {
    
    NSLog(@"筛选设备%d:%@",index,itemName);
}

#pragma mark - segue
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([segue.identifier isEqualToString:@"GoToRemarkVAS"]) {
        TreatmentCourseRecordViewController *controller = segue.destinationViewController;
        controller.dataDic = @{@"medicalRecordNum":@"12345896",@"name":@"小明",@"gender":@"男",@"age":@"20",@"phone":@"13782965445"};
        
    }
}

@end
