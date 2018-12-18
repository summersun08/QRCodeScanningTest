//
//  ViewController.m
//  QRCodeScanning
//
//  Created by 孙宛宛 on 2018/12/17.
//  Copyright © 2018年 wanwan. All rights reserved.
//

#import "ViewController.h"
#import "QRCodeScanningVC.h"

@interface ViewController ()

@property (nonatomic, strong) UIButton *qrCodeBtn;
@property (nonatomic, strong) UILabel *desclab;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationItem.title = @"二维码扫描";
    
    [self setUI];
    
//    CABasicAnimation *scanNetAnimation = [CABasicAnimation animation];
//    scanNetAnimation.keyPath = @"transform.translation.y";
//    scanNetAnimation.byValue = @(300);
//    scanNetAnimation.duration = 1.0;
//    scanNetAnimation.repeatCount = MAXFLOAT;
//    [self.qrCodeBtn.layer addAnimation:scanNetAnimation forKey:@"move"];
}

#pragma mark - privateMethod

- (void)qrCodeBtnClick
{
    QRCodeScanningVC *vc = [[QRCodeScanningVC alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - setUI

- (void)setUI
{
    [self.view addSubview:self.qrCodeBtn];
    [self.view addSubview:self.desclab];
    
    [self.qrCodeBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(self.view.mas_centerX);
        make.top.mas_offset(200);
    }];
    
    [self.desclab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.qrCodeBtn.mas_bottom).mas_offset(15);
        make.centerX.mas_equalTo(self.qrCodeBtn.mas_centerX);
    }];
    
    [self.view layoutIfNeeded];
}

#pragma mark - getter

- (UIButton *)qrCodeBtn
{
    if(!_qrCodeBtn)
    {
        _qrCodeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_qrCodeBtn setImage:GetImage(@"plus-code") forState:UIControlStateNormal];
        [_qrCodeBtn addTarget:self action:@selector(qrCodeBtnClick) forControlEvents:UIControlEventTouchUpInside];
        _qrCodeBtn.layer.borderColor = UIColorFromHEXA(0xbfbfbf, 1.0).CGColor;
        _qrCodeBtn.layer.borderWidth = 0.5;
        _qrCodeBtn.layer.cornerRadius = 5;
        _qrCodeBtn.layer.masksToBounds = YES;
    }
    return _qrCodeBtn;
}

- (UILabel *)desclab
{
    if(!_desclab)
    {
        _desclab = [[UILabel alloc] init];
        _desclab.text = @"快去扫描二维码吧~";
        _desclab.textAlignment = NSTextAlignmentCenter;
        _desclab.textColor = [UIColor blackColor];
        _desclab.font = SystemFontSize(18);
    }
    return _desclab;
}

@end
