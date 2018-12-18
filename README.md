# QRCodeScanningTest

之前写项目遇到二维码扫描的界面时， 解决方案一直是网上找第三方代码复制粘贴， 没有自己的思考。

那今天就来总结一下，如何利用AVFoundation实现自定义开发。

> AVFoundation
AVFoundation 是 Objective-C 中创建及编辑视听媒体文件的几个框架之一，其提供了检查、创建、编辑或重新编码媒体文件的接口，也使得从设备获取的视频实时数据可操纵。

AVFoundation的一个重点功能就是**媒体捕捉**。其核心类是**AVCaptureSession**，用于连接输入输出的资源。

我们先来看一下**媒体捕捉**时需要用的几个类：

![图片来自网络](https://upload-images.jianshu.io/upload_images/5670606-76ca2ed316d30375.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

>捕捉设备 AVCaptureDevice

AVCaptureDevice类为诸如摄像头或麦克风等物理设备定义了一个接口。针对物理设备定义了大量控制方法，包括对焦、白平衡、曝光等。

>捕捉设备的输入 AVCaptureInput

AVCaptureInput类用来输入数据源。在使用捕捉设备进行处理前， 要先添加一个输入设备，我们通常使用AVCaptureDeviceInput实例来进行添加。

>捕捉的输出 AVCaptureOutput

AVCaptureOutput类用于为从捕捉会话得到的数据输入到目的地。我们经常使用这个抽象基类的派生类如：AVCaptureStillImageOuptut、AVCaptureMovieFileOutput等。

>捕捉预览 AVCaptureVideoPreviewLayer

AVCaptureVideoPreviewLayer类满足在捕捉时的实时预览，类似于AVPlayerLayer的角色，支持重力概念，可控制视频内容渲染和缩放、拉伸效果。

###使用AVFounation捕获二维码数据的一般步骤如下：

```
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
    
    // 扫描类型
    output.metadataObjectTypes = @[AVMetadataObjectTypeQRCode,AVMetadataObjectTypeEAN13Code,AVMetadataObjectTypeEAN8Code,AVMetadataObjectTypeCode128Code];
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
    
    /* 初始化预览对象AVCaptureVideoPreviewLayer */
    layer = [AVCaptureVideoPreviewLayer layerWithSession:_session];
    layer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    layer.frame = self.view.layer.bounds;
    [self.view.layer insertSublayer:layer atIndex:0];
    
    /* 开始捕获 */
    [_session startRunning];
}
```
### 自定义二维码扫描框以及扫描动画

对于二维码扫描框，其实最主要的就是一个背景框+来回滚动的扫描线，这里扫描线我用了一个背景图，给图片的layer层添加一个CABasicAnimation的动画：

```
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
}
```

对于这个动画，这里有一个大坑！！

扫描这个VC最开始写是用模态弹出（presentViewControlle()）来进行页面跳转的，然后scanNetImageView的动画就一直显示不出来， 我以为是自己的代码写错了， 但是在上一个界面进行测试动画效果是正常的， 纠结了好久，然后将页面跳转方式改为push，动画效果就正常了！！！ 

至于为什么， 暂时没找出来，有明白原因的欢迎简信告诉我~~

###闪光灯操作

闪光灯的方法调用AVCaptureDevice类里有相关的设置方法， 我们只需要根据状态设置对应的开关。

```
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
```

以上， 就是一个简单的自定义二维码的主要流程了。

有喜欢的欢迎点亮小星星~ 
