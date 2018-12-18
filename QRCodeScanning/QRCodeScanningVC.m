//
//  QRCodeScanningVC.m
//  QRCodeScanning
//
//  Created by 孙宛宛 on 2018/12/17.
//  Copyright © 2018年 wanwan. All rights reserved.
//

#import "QRCodeScanningVC.h"
#import <QuartzCore/QuartzCore.h>
#import <AVFoundation/AVFoundation.h>

#define kScreenW ([UIScreen mainScreen].bounds.size.width)
#define kScreenH ([UIScreen mainScreen].bounds.size.height)
#define ScanWindowWH kScreenW * 3 / 4

@interface QRCodeScanningVC ()<AVCaptureMetadataOutputObjectsDelegate>
{
    AVCaptureDeviceInput *input;       // 输入流
    AVCaptureMetadataOutput *output;   // 输出流
    AVCaptureVideoPreviewLayer *layer; // 预览对象
}

@property (nonatomic, strong) UIButton *quitBtn;
@property (nonatomic, strong) UIButton *flashBtn;   // 闪光灯

@property (nonatomic, strong) AVCaptureSession *session; // 连接数据流对象

@end

@implementation QRCodeScanningVC

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    
    // 扫描前先去除上一次扫描留下的扫描层，三个时候都要去掉：back，dismiss，模糊地时候
    [layer removeFromSuperlayer];
    
    // 查看相机权限
    [self checkCameraPermissions];
    
    [self beginScanning];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    
    [_session stopRunning];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = UIColorFromHEXA(0x000000, 0.7);
    
    [self setUI];
}

#pragma mark - privateMethod

- (void)quitBtnClick
{
    [self.navigationController popViewControllerAnimated:YES];
}

// 检查相机权限
- (void)checkCameraPermissions
{
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    
    if (authStatus ==AVAuthorizationStatusRestricted || authStatus ==AVAuthorizationStatusDenied)
    {
        // 无权限 引导去开启
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"您没有授权使用相机，请转到设置打开相机授权！" message:nil preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *action = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
            [alertController dismissViewControllerAnimated:YES completion:nil];
        }];
        
        [alertController addAction:action];
        
        [self presentViewController:alertController animated:YES completion:^{}];
    }
}

#pragma mark - 闪光灯

- (void)flashBtnClick:(UIButton *)btn
{
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if (![device hasTorch])
    {
        // 没有闪光灯
        [MBProgressHUD showError:@"抱歉，该设备没有闪光灯而无法使用手电筒功能！"];
        return;
    }
    
    [device lockForConfiguration:nil];
    
    btn.selected = !btn.selected;
    if (btn.selected)
    {
        // 打开闪光灯
        [device setTorchMode:AVCaptureTorchModeOn];
    }
    else
    {
        [device setTorchMode:AVCaptureTorchModeOff];
    }
    
    [device unlockForConfiguration];
}

#pragma mark - 初始化扫描对象

- (void)beginScanning
{
    /* 获取摄像头 */
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    /* 初始化输入流AVCaptureDeviceInput对象 */
    input = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
    if (!input)
    {
        return;
    }
    
    /* 初始化输出流AVCaptureMetadataOutput对象 */
    output = [[AVCaptureMetadataOutput alloc] init];
    
    // 扫描范围
    output.rectOfInterest = CGRectMake(0.1, 0, 0.9, 1);
    // 设置委托和调度队列
    [output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    
    /* 初始化连接对象 */
    _session = [[AVCaptureSession alloc] init];
    
    // 高质量采集率
    [_session setSessionPreset:AVCaptureSessionPresetHigh];
    [_session addInput:input];
    [_session addOutput:output];
    // 扫描类型
    output.metadataObjectTypes = @[AVMetadataObjectTypeQRCode,AVMetadataObjectTypeEAN13Code,AVMetadataObjectTypeEAN8Code];
    
    /* 初始化预览对象AVCaptureVideoPreviewLayer */
    layer = [AVCaptureVideoPreviewLayer layerWithSession:_session];
    layer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    layer.frame = self.view.bounds;
    [self.view.layer insertSublayer:layer atIndex:0];
    
    /* 开始捕获 */
    [_session startRunning];
}

#pragma mark - AVCaptureMetadataOutputObjectsDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    // 扫描到东西了
    if (metadataObjects.count > 0)
    {
        [_session stopRunning];
        
        AVMetadataMachineReadableCodeObject *metadataObject = [metadataObjects objectAtIndex:0];
        [MBProgressHUD showSuccess:metadataObject.stringValue];
        
        [self quitBtnClick];
    }
}

#pragma mark - setUI

- (void)setUI
{
    [self setScanWindowView];
    
    [self.view addSubview:self.quitBtn];
    [self.view addSubview:self.flashBtn];

    [self.quitBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_offset(44);
        make.right.mas_offset(-15);
    }];
    
    [self.flashBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.mas_equalTo(self.quitBtn.mas_centerY);
        make.centerX.mas_equalTo(self.view.mas_centerX);
    }];

}

- (void)setScanWindowView
{
    UIView *scanWindow = [[UIView alloc] init];
    scanWindow.bounds = CGRectMake(0, 0, ScanWindowWH, ScanWindowWH);
    scanWindow.center = self.view.center;
    scanWindow.clipsToBounds = YES;
    [self.view addSubview:scanWindow];
    
    // 添加动画
    UIImageView *scanNetImageView = [[UIImageView alloc] initWithImage:GetImage(@"scan_net")];
    scanNetImageView.frame = CGRectMake(0, -241, ScanWindowWH, 241);
    [scanWindow addSubview:scanNetImageView];

    CABasicAnimation *scanNetAnimation = [CABasicAnimation animation];
    scanNetAnimation.keyPath = @"transform.translation.y";
    scanNetAnimation.byValue = @(ScanWindowWH);
    scanNetAnimation.duration = 1.0;
    scanNetAnimation.repeatCount = MAXFLOAT;
    [scanNetImageView.layer addAnimation:scanNetAnimation forKey:@"move"];
    
    // 添加四周标识图片
    CGFloat imageWH = 19;
    
    UIImageView *topLeft = [[UIImageView alloc] initWithImage:GetImage(@"scan_1")];
    topLeft.frame = CGRectMake(0, 0, imageWH, imageWH);
    [scanWindow addSubview:topLeft];
    
    UIImageView *topRight = [[UIImageView alloc] initWithImage:GetImage(@"scan_2")];
    topRight.frame = CGRectMake(ScanWindowWH - imageWH, 0, imageWH, imageWH);
    [scanWindow addSubview:topRight];
    
    UIImageView *bottomLeft = [[UIImageView alloc] initWithImage:GetImage(@"scan_3")];
    bottomLeft.frame = CGRectMake(0, ScanWindowWH - imageWH + 2, imageWH, imageWH);
    [scanWindow addSubview:bottomLeft];
    
    UIImageView *bottomRight = [[UIImageView alloc] initWithImage:GetImage(@"scan_4")];
    bottomRight.frame = CGRectMake(ScanWindowWH - imageWH, ScanWindowWH - imageWH + 2, imageWH, imageWH);
    [scanWindow addSubview:bottomRight];
}

#pragma mark - getter

- (UIButton *)quitBtn
{
    if(!_quitBtn)
    {
        _quitBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_quitBtn setImage:GetImage(@"guanbi") forState:UIControlStateNormal];
        [_quitBtn addTarget:self action:@selector(quitBtnClick) forControlEvents:UIControlEventTouchUpInside];
    }
    return _quitBtn;
}

- (UIButton *)flashBtn
{
    if(!_flashBtn)
    {
        _flashBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_flashBtn setImage:GetImage(@"ocr_flash-off") forState:UIControlStateNormal];
        [_flashBtn setImage:GetImage(@"ocr_flash-on") forState:UIControlStateSelected];
        [_flashBtn addTarget:self action:@selector(flashBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _flashBtn;
}

@end
