//
//  ViewController.m
//  XFScanDemo
//
//  Created by zhanglong on 16/10/14.
//  Copyright © 2016年 ZKXC. All rights reserved.
//

#import "ViewController.h"
#import "XFScanViewController.h"
#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height
@interface ViewController ()

@property (nonatomic, strong) UIButton * scanButton;//扫描按钮
@property (nonatomic, strong) UILabel * resultLabel;//显示扫描结果

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //扫描按钮
    self.scanButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.scanButton.frame = CGRectMake((SCREEN_WIDTH - 100) / 2, SCREEN_HEIGHT - 100, 100, 30);
    [self.scanButton setTitle:@"扫描" forState:UIControlStateNormal];
    [self.scanButton addTarget:self action:@selector(scanAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.scanButton];
    
    //显示扫描结果
    self.resultLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 200, SCREEN_WIDTH, 100)];
    self.resultLabel.textAlignment = NSTextAlignmentCenter;
    self.resultLabel.numberOfLines = 0;
    [self.view addSubview:self.resultLabel];
}

/**
 *  扫描事件
 */
- (void)scanAction:(UIButton *)sender{
    XFScanViewController * vc = [[XFScanViewController alloc] init];
    vc.returnScanBarCodeValue = ^(NSString * barCodeString){
        self.resultLabel.text = [NSString stringWithFormat:@"扫描结果:\n%@",barCodeString];
        NSLog(@"扫描结果的字符串======%@",barCodeString);
    };
    
    [self.navigationController pushViewController:vc animated:YES];
}


@end
