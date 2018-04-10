//
//  AddDeviceViewController.m
//  PainManagementSystem
//
//  Created by Binger Zeng on 2018/3/19.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import "AddDeviceViewController.h"
#import "AddDeviceCell.h"
#import "BaseHeader.h"
#import "QRCodeReaderViewController.h"

#import <MBProgressHUD.h>
#import <AVFoundation/AVFoundation.h>
typedef NS_ENUM(NSUInteger,typeTags)
{
    electrotherapyTag = 1000,airProTag = 1001,aladdinTag = 1002
};
@interface AddDeviceViewController ()<QRCodeReaderDelegate,UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *contentView;

//条形码扫描
@property (strong,nonatomic) QRCodeReaderViewController *reader;
@property (assign,nonatomic) NSInteger selectedDeviceTag;
@property (assign,nonatomic) NSInteger selectedRow;

@property (strong, nonatomic)MBProgressHUD * HUD;

@end

@implementation AddDeviceViewController{
    
    NSMutableArray *datas;
    NSMutableArray *peripheralDataArray;
    BabyBluetooth *baby;
}

- (IBAction)changeDevice:(UIButton *)sender {
    self.selectedDeviceTag = [sender tag];
    
    
    for (int i = electrotherapyTag; i<electrotherapyTag +3; i++) {
        UIButton *btn = (UIButton *)[self.contentView viewWithTag:i];
        //配置选中按钮
        if ([btn tag] == [(UIButton *)sender tag]) {
            btn.backgroundColor = UIColorFromHex(0x37bd9c);
            [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        }else{
            btn.backgroundColor = [UIColor whiteColor];
            [btn setTitleColor:UIColorFromHex(0x212121) forState:UIControlStateNormal];
        }
    }
    
    //选中蓝牙设备
    if (self.selectedDeviceTag == aladdinTag) {
        
        datas = [[NSMutableArray alloc]initWithCapacity:20];
        baby.scanForPeripherals().begin();
        

    }else {
        [baby cancelScan];
        [baby cancelAllPeripheralsConnection];
        
        datas = [NSMutableArray arrayWithObjects:
                 @{@"type":@"空气波",@"macString":@"dgahqaa",@"name":@"骨科一号",@"serialNum":@"13654979946"},
                 @{@"type":@"空气波",@"macString":@"fjfjfds",@"name":@"骨科一号",@"serialNum":@"45645615764"},
                 @{@"type":@"电疗",@"macString":@"fstjkst",@"name":@"骨科一号",@"serialNum":@"12367874456"},
                 nil];
    }
    [self.tableView reloadData];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    [self initAll];
    
    // Do any additional setup after loading the view.
}


-(void)viewWillAppear:(BOOL)animated{
    
    [super viewWillAppear:YES];
    self.title = @"设备管理系统";
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:46.0f/255.0f green:163.0f/255.0f blue:230.0f/255.0f alpha:1];
}


-(void)initAll{
    
    //默认选中电疗设备
    UIButton *btn = (UIButton *)[self.contentView viewWithTag:electrotherapyTag];
    [self changeDevice:btn];
    
    self.tableView.tableFooterView = [[UIView alloc]init];
    
    datas = [[NSMutableArray alloc]initWithCapacity:20];
    datas = [NSMutableArray arrayWithObjects:
             @{@"type":@"空气波",@"macString":@"dgahqaa",@"name":@"骨科一号",@"serialNum":@"13654979946"},
             @{@"type":@"空气波",@"macString":@"fjfjfds",@"name":@"骨科一号",@"serialNum":@"45645615764"},
             @{@"type":@"电疗",@"macString":@"fstjkst",@"name":@"骨科一号",@"serialNum":@"12367874456"},
             nil];
    
    peripheralDataArray = [[NSMutableArray alloc]init];
    baby = [BabyBluetooth shareBabyBluetooth];
    [self babyDelegate];
}


#pragma mark - babyDelegate
-(void)babyDelegate {
    __weak typeof(self) weakSelf = self;
    [baby setBlockOnCentralManagerDidUpdateState:^(CBCentralManager *central) {
        if (central.state == CBManagerStatePoweredOff) {
            if (weakSelf.view) {
                weakSelf.HUD = [MBProgressHUD showHUDAddedTo:weakSelf.view animated:YES];
                weakSelf.HUD.mode = MBProgressHUDModeText;
                weakSelf.HUD.label.text = @"该设备尚未打开蓝牙,请在设置中打开";
                [weakSelf.HUD showAnimated:YES];
            }
        }else if(central.state == CBManagerStatePoweredOn) {
            if(weakSelf.HUD){
                [MBProgressHUD hideHUDForView:weakSelf.view animated:YES];
            }
            
        }
    }];
    
    [baby setBlockOnDiscoverToPeripherals:^(CBCentralManager *central, CBPeripheral *peripheral, NSDictionary *advertisementData, NSNumber *RSSI) {
        [weakSelf insertTableView:peripheral advertisementData:advertisementData RSSI:RSSI];
    }];
    
    [baby setFilterOnDiscoverPeripherals:^BOOL(NSString *peripheralName, NSDictionary *advertisementData, NSNumber *RSSI) {
        if (peripheralName.length > 0) {
            return YES;
        }
        return NO;
    }];
    
    NSDictionary *scanForPeripheralsWithOptions = @{CBCentralManagerScanOptionAllowDuplicatesKey:@YES};
    [baby setBabyOptionsWithScanForPeripheralsWithOptions:scanForPeripheralsWithOptions connectPeripheralWithOptions:nil scanForPeripheralsWithServices:nil discoverWithServices:nil discoverWithCharacteristics:nil];
}
#pragma mark UIViewController 方法
//插入table数据
-(void)insertTableView:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI{
    
    NSArray *peripherals = [datas valueForKey:@"peripheral"];
    if(![peripherals containsObject:peripheral]) {
        NSMutableArray *indexPaths = [[NSMutableArray alloc] init];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:peripherals.count inSection:0];
        [indexPaths addObject:indexPath];
        
        NSMutableDictionary *item = [[NSMutableDictionary alloc] init];
        [item setValue:peripheral forKey:@"peripheral"];
        [item setValue:RSSI forKey:@"RSSI"];
        [item setValue:advertisementData forKey:@"advertisementData"];
        NSLog(@"peripheral = %@",peripheral.name);
        NSLog(@"advertisementData = %@",advertisementData);
//        [peripheralDataArray addObject:item];
        [datas addObject:item];
        [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

#pragma mark - scan
- (void)scanAction:(id)sender {

    self.selectedRow = [sender tag];
    
    NSArray *types = @[AVMetadataObjectTypeQRCode,
                       AVMetadataObjectTypeEAN13Code,
                       AVMetadataObjectTypeEAN8Code,
                       AVMetadataObjectTypeUPCECode,
                       AVMetadataObjectTypeCode39Code,
                       AVMetadataObjectTypeCode39Mod43Code,
                       AVMetadataObjectTypeCode93Code,
                       AVMetadataObjectTypeCode128Code,
                       AVMetadataObjectTypePDF417Code];
    
    _reader        = [QRCodeReaderViewController readerWithMetadataObjectTypes:types];
    
    // Using delegate methods
    _reader.delegate = self;
    
    
    [self presentViewController:_reader animated:YES completion:NULL];

}

#pragma mark - QRCodeReader Delegate Methods
- (void)reader:(QRCodeReaderViewController *)reader didScanResult:(NSString *)result
{
    [self dismissViewControllerAnimated:YES completion:^{
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.selectedRow inSection:0];
        AddDeviceCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
        cell.serialNumTextField.text = result;
        NSLog(@"QRretult == %@", result);
    }];
}

- (void)readerDidCancel:(QRCodeReaderViewController *)reader
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (IBAction)backToDeviceList:(id)sender {
    [self.navigationController popViewControllerAnimated:NO];
    [self dismissViewControllerAnimated:NO completion:nil];
}

#pragma mark - tableview dataSource
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [datas count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *CellIdentifier = @"Cell";
    AddDeviceCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    if (cell == nil) {
        cell = [[AddDeviceCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    //wifi设备
    NSDictionary *dataDic = [datas objectAtIndex:indexPath.row];
    [cell.ringButton setTitle:[dataDic objectForKey:@"macString"] forState:UIControlStateNormal];
    [cell.ringButton addTarget:self action:@selector(ring:) forControlEvents:UIControlEventTouchUpInside];
    cell.nameTextField.text = [dataDic objectForKey:@"name"];
    
    [cell.scanButton addTarget:self action:@selector(scanAction:) forControlEvents:UIControlEventTouchUpInside];
    cell.scanButton.tag = indexPath.row;
    
    //蓝牙设备
    NSDictionary *item = [datas objectAtIndex:indexPath.row];
    CBPeripheral *peripheral = [item objectForKey:@"peripheral"];
    if (peripheral) {
        NSDictionary *advertisementData = [item objectForKey:@"advertisementData"];
        cell.nameTextField.text = peripheral.name;
        
        //BLE的mac地址
        NSData *data = (NSData *)[advertisementData objectForKey:@"kCBAdvDataManufacturerData"];
        NSMutableArray *array = [NSMutableArray arrayWithCapacity:20];
        if (data) {
            Byte *dataByte = (Byte *)[data bytes];
            for (int i =0 ; i < 6; i++) {
                [array addObject:[NSString stringWithFormat:@"%x",dataByte[i]]];
            }
        }
        NSString *mac = [array componentsJoinedByString:@""];
        if(!data) {
            [cell.ringButton setTitle:peripheral.identifier.UUIDString forState:UIControlStateNormal];
        }else {
            [cell.ringButton setTitle:mac forState:UIControlStateNormal];
        }
        
    }
 
    return cell;
}

-(NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [self.tableView endEditing:YES];
    return indexPath;
}

-(void)ring:(UIButton *)button{
    AddDeviceCell *cell = (AddDeviceCell *)[[button superview]superview];
    NSString *cpuid = cell.ringButton.titleLabel.text;
    NSLog(@"send to server--------cupid：%@ --------------bibibi",cpuid);
}

- (IBAction)saveAll:(id)sender {
    NSArray *cells = self.tableView.visibleCells;
    NSMutableArray *saveArray = [NSMutableArray array];
    
    for (AddDeviceCell *cell in cells) {
        NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithCapacity:20];
        [dic setObject:cell.ringButton.titleLabel.text forKey:@"macString"];
        [dic setObject:cell.nameTextField.text forKey:@"name"];
        [dic setObject:cell.serialNumTextField.text forKey:@"seraialNum"];
        if (cell.serialNumTextField.text.length>0 && cell.nameTextField.text.length>0) {
            [saveArray addObject:dic];
        }
    }
    
    NSLog(@"send to server -----------add device array :%@",saveArray);
    
}

//关闭键盘
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}

@end
