//
//  ZFScanViewController.m
//  ZFScan
//
//  Created by apple on 16/3/8.
//  Copyright © 2016年 apple. All rights reserved.
//

#import "XFScanViewController.h"
#import "XFMaskView.h"
#import "XFCameraPemission.h"
#import <AVFoundation/AVFoundation.h>
#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height
#define adjustingFocus @"adjustingFocus"
#define Constant 40
#define XFMinZoom 1.0
#define XFMaxZoom 5.0

@interface XFScanViewController ()<AVCaptureMetadataOutputObjectsDelegate, AVCaptureVideoDataOutputSampleBufferDelegate>

/** 输入输出的中间桥梁 */
@property (nonatomic, strong) AVCaptureSession * session;
/** 取景器 */
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;
/** 扫描支持的编码格式的数组 */
@property (nonatomic, strong) NSMutableArray * metadataObjectTypes;
/** device */
@property (nonatomic, strong) AVCaptureDevice *device;
/** lightOutput */
@property (nonatomic, strong) AVCaptureVideoDataOutput *lightOutput;
/** flashButton */
@property (nonatomic, strong) UIButton *flashButton;
/** 遮罩层 */
@property (nonatomic, strong) XFMaskView * maskView;
/** pinchZoom */
@property (nonatomic, assign) CGFloat pinchZoom;
@end

@implementation XFScanViewController

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [self stopScan];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // 添加遮罩层
    [self addUI];
    // 扫描初始化
    [self capture];
    
    [XFCameraPemission requestCameraPemissionWithResult:^(BOOL granted) {
        if (granted) {
            //不延时，可能会导致界面黑屏并卡住一会
            [self performSelector:@selector(startScan) withObject:nil afterDelay:0.1];
        }else{
            [self.maskView stopDeviceReadying];
            NSLog(@"尚未开启相机权限,您可以去设置->隐私->相机开启");
        }
    }];
}

- (void)startScan {
    [self.session startRunning];
    [self.maskView startAnimayion];
}

- (void)stopScan {
    if ([self.session isRunning]) {
        [self.session stopRunning];
        self.session = nil;
        [self.maskView removeAnimation];
    }
}

/**
 *  添加遮罩层
 */
- (void)addUI{
    self.maskView = [[XFMaskView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:self.maskView];
    [self.maskView startDeviceReadyingWithTipString:@"设备启动中"];
    self.maskView.userInteractionEnabled = false;
    
    // 添加按钮
    UIButton *backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    backButton.frame = CGRectMake(Constant / 2, Constant / 2, Constant, Constant);
    [backButton setImage:[UIImage imageNamed:@"camera_goback"] forState:UIControlStateNormal];
    [backButton setImage:[UIImage imageNamed:@"camera_goback_highlighted"] forState:UIControlStateHighlighted];
    [backButton addTarget:self action:@selector(goBack) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:backButton];
    
    UIButton *flashButton = [UIButton buttonWithType:UIButtonTypeCustom];
    flashButton.frame = CGRectMake(self.view.frame.size.width - Constant / 2 - Constant, Constant / 2, Constant, Constant);
    [flashButton setImage:[UIImage imageNamed:@"camera_torch_off"] forState:UIControlStateNormal];
    [flashButton setImage:[UIImage imageNamed:@"camera_torch_on"] forState:UIControlStateSelected];
    [flashButton addTarget:self action:@selector(adjustFlashLight:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:flashButton];
    self.flashButton = flashButton;
}

/**
 *  扫描初始化
 */
- (void)capture{
    //获取摄像设备
    AVCaptureDevice * device = self.device;
    //创建输入流
    AVCaptureDeviceInput * input = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
    //创建输出流
    AVCaptureMetadataOutput * output = [[AVCaptureMetadataOutput alloc] init];
    //设置代理 在主线程里刷新
    [output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    //检测光线强度
    _lightOutput = [[AVCaptureVideoDataOutput alloc] init];
    [_lightOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
    
    //初始化链接对象
    self.session = [[AVCaptureSession alloc] init];
    //高质量采集率
    self.session.sessionPreset = AVCaptureSessionPresetHigh;
    
    [self.session addInput:input];
    [self.session addOutput:output];
    [self.session addOutput:_lightOutput];
    
    AVCaptureVideoPreviewLayer * previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.session];
    previewLayer.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
    previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    previewLayer.backgroundColor = [UIColor blackColor].CGColor;
    [self.view.layer insertSublayer:previewLayer below:self.maskView.layer];
    self.previewLayer = previewLayer;
    
    //设置扫描支持的编码格式(如下设置条形码和二维码兼容)
    output.metadataObjectTypes = self.metadataObjectTypes;
    
    // 设置二维码可识别区域
    CGFloat scanViewX = Constant;
    CGFloat scanViewW = SCREEN_WIDTH - scanViewX * 2;
    CGFloat scanViewH = scanViewW;
    CGFloat scanViewY = (SCREEN_HEIGHT - scanViewH) / 2;
    CGRect rect = CGRectMake(scanViewX, scanViewY, scanViewW, scanViewH);
    CGRect intertRect = [previewLayer metadataOutputRectOfInterestForRect:rect];
    output.rectOfInterest = intertRect;
    
    [self.view addGestureRecognizer:[[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchDetected:)]];
}

/** 返回 */
- (void)goBack {
    [self dismissViewControllerAnimated:YES completion:nil];
}

/** 开/关闪光灯 */
- (void)adjustFlashLight:(UIButton *)sender {
    sender.selected = !sender.isSelected;
    if ([self.device hasTorch]) {
        [self.device lockForConfiguration:nil];
        if (sender.isSelected) {
            [self.device setTorchMode:AVCaptureTorchModeOn];
        } else {
            [self.device setTorchMode:AVCaptureTorchModeOff];
        }
        [self.device unlockForConfiguration];
    }
}

/** 手势调整焦距 */
- (void)pinchDetected:(UIPinchGestureRecognizer*)recogniser {
    AVCaptureDevice * device = self.device;
    if (!device) {
        return;
    }
    if (recogniser.state == UIGestureRecognizerStateBegan) {
        _pinchZoom = device.videoZoomFactor;
    }
    NSError *error = nil;
    [device lockForConfiguration:&error];
    if (!error) {
        CGFloat zoomFactor;
        CGFloat scale = recogniser.scale;
        if (scale < XFMinZoom) {
            zoomFactor = _pinchZoom - (XFMinZoom - recogniser.scale) * 3;
        } else {
            zoomFactor = _pinchZoom + (recogniser.scale - XFMinZoom) * 1.5;
        }
        zoomFactor = MIN(XFMaxZoom, zoomFactor);
        zoomFactor = MAX(XFMinZoom, zoomFactor);
        device.videoZoomFactor = zoomFactor;
        [device unlockForConfiguration];
    }
}

#pragma mark - 对焦
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    CGPoint point = [[touches anyObject] locationInView:self.view];
    [self focusInPoint:point];
}

/** 点击对焦 */
- (void)focusInPoint:(CGPoint)devicePoint {
    if (CGRectContainsPoint(_previewLayer.bounds, devicePoint) == NO) {
        return;
    }
    devicePoint = [self convertToPointOfInterestFromViewCoordinates:devicePoint];
    [self focusWithMode:AVCaptureFocusModeAutoFocus exposeWithMode:AVCaptureExposureModeContinuousAutoExposure atDevicePoint:devicePoint monitorSubjectAreaChange:YES];
}

- (void)focusWithMode:(AVCaptureFocusMode)focusMode exposeWithMode:(AVCaptureExposureMode)exposureMode atDevicePoint:(CGPoint)point monitorSubjectAreaChange:(BOOL)monitorSubjectAreaChange {
    dispatch_queue_t sessionQueue = dispatch_queue_create("session queue", DISPATCH_QUEUE_SERIAL);
    dispatch_async(sessionQueue, ^{
        AVCaptureDevice * device = self.device;
        NSError *error = nil;
        if ([device lockForConfiguration:&error]) {
            if ([device isFocusPointOfInterestSupported] && [device isFocusModeSupported:focusMode]) {
                [device setFocusPointOfInterest:point];
                [device setFocusMode:focusMode];
            }
            if ([device isExposurePointOfInterestSupported] && [device isExposureModeSupported:exposureMode]) {
                [device setExposurePointOfInterest:point];
                [device setExposureMode:exposureMode];
            }
            [device setSubjectAreaChangeMonitoringEnabled:monitorSubjectAreaChange];
            [device unlockForConfiguration];
        }
    });
}

/**
 *  外部的point转换为camera需要的point(外部point/相机页面的frame)
 *
 *  @param viewCoordinates 外部的point
 *
 *  @return 相对位置的point
 */
- (CGPoint)convertToPointOfInterestFromViewCoordinates:(CGPoint)viewCoordinates {
    CGPoint pointOfInterest = CGPointMake(.5f, .5f);
    AVCaptureVideoPreviewLayer *videoPreviewLayer = self.previewLayer;
    CGSize frameSize = videoPreviewLayer.bounds.size;
    if([[videoPreviewLayer videoGravity] isEqualToString:AVLayerVideoGravityResize]) {
        pointOfInterest = CGPointMake(viewCoordinates.y / frameSize.height, 1.f - (viewCoordinates.x / frameSize.width));
    } else {
        CGRect cleanAperture;
        for(AVCaptureInputPort *port in [[self.session.inputs lastObject]ports]) {
            if([port mediaType] == AVMediaTypeVideo) {
                cleanAperture = CMVideoFormatDescriptionGetCleanAperture([port formatDescription], YES);
                CGSize apertureSize = cleanAperture.size;
                CGPoint point = viewCoordinates;
                
                CGFloat apertureRatio = apertureSize.height / apertureSize.width;
                CGFloat viewRatio = frameSize.width / frameSize.height;
                CGFloat xc = .5f;
                CGFloat yc = .5f;
                
                if([[videoPreviewLayer videoGravity]isEqualToString:AVLayerVideoGravityResizeAspect]) {
                    if(viewRatio > apertureRatio) {
                        CGFloat y2 = frameSize.height;
                        CGFloat x2 = frameSize.height * apertureRatio;
                        CGFloat x1 = frameSize.width;
                        CGFloat blackBar = (x1 - x2) / 2;
                        if(point.x >= blackBar && point.x <= blackBar + x2) {
                            xc = point.y / y2;
                            yc = 1.f - ((point.x - blackBar) / x2);
                        }
                    } else {
                        CGFloat y2 = frameSize.width / apertureRatio;
                        CGFloat y1 = frameSize.height;
                        CGFloat x2 = frameSize.width;
                        CGFloat blackBar = (y1 - y2) / 2;
                        if(point.y >= blackBar && point.y <= blackBar + y2) {
                            xc = ((point.y - blackBar) / y2);
                            yc = 1.f - (point.x / x2);
                        }
                    }
                } else if([[videoPreviewLayer videoGravity]isEqualToString:AVLayerVideoGravityResizeAspectFill]) {
                    if(viewRatio > apertureRatio) {
                        CGFloat y2 = apertureSize.width * (frameSize.width / apertureSize.height);
                        xc = (point.y + ((y2 - frameSize.height) / 2.f)) / y2;
                        yc = (frameSize.width - point.x) / frameSize.width;
                    } else {
                        CGFloat x2 = apertureSize.height * (frameSize.height / apertureSize.width);
                        yc = 1.f - ((point.x + ((x2 - frameSize.width) / 2)) / x2);
                        xc = point.y / frameSize.height;
                    }
                }
                pointOfInterest = CGPointMake(xc, yc);
                break;
            }
        }
    }
    return pointOfInterest;
}

#pragma mark - AVCaptureMetadataOutputObjectsDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection{
    if (metadataObjects.count > 0) {
        [self.session stopRunning];
        AVMetadataMachineReadableCodeObject * metadataObject = metadataObjects.firstObject;
        NSString *result = metadataObject.stringValue;//返回的扫描结果
        result = [self holderMessyCode:result];
        self.returnScanBarCodeValue(result);
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        NSLog(@"无法识别此二维码");
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

#pragma mark- AVCaptureVideoDataOutputSampleBufferDelegate的方法
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    Class captureDeviceClass = NSClassFromString(@"AVCaptureDevice");
    if (captureDeviceClass != nil) {
        CFDictionaryRef metadataDict = CMCopyDictionaryOfAttachments(NULL,sampleBuffer, kCMAttachmentMode_ShouldPropagate);
        NSDictionary *metadata = [[NSMutableDictionary alloc] initWithDictionary:(__bridge NSDictionary*)metadataDict];
        CFRelease(metadataDict);
        NSDictionary *exifMetadata = [[metadata objectForKey:(NSString *)kCGImagePropertyExifDictionary] mutableCopy];
        float brightnessValue = [[exifMetadata objectForKey:(NSString *)kCGImagePropertyExifBrightnessValue] floatValue];
        // 根据brightnessValue的值来打开和关闭闪光灯
        AVCaptureDevice * myLightDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        BOOL result = [myLightDevice hasTorch];// 判断设备是否有闪光灯
        if ((brightnessValue < 0) && result && myLightDevice.flashMode == AVCaptureFlashModeOff) {// 打开闪光灯
            [self adjustFlashLight:self.flashButton];
            // 只更改一次
            [self.lightOutput setSampleBufferDelegate:nil queue:dispatch_get_main_queue()];
        }
    }
}

/** 扫描乱码处理 */
- (NSString *)holderMessyCode:(NSString *)codeString {
    NSLog(@"处理前:%@", codeString);
    NSString *tempStr;
    // 修正扫描出来二维码里有中文时为乱码问题
    if ([codeString canBeConvertedToEncoding:NSShiftJISStringEncoding]) {
        tempStr = [NSString stringWithCString:[codeString cStringUsingEncoding:NSShiftJISStringEncoding] encoding:NSUTF8StringEncoding];
        // 如果转化成utf-8失败，再尝试转化为gbk
        if (tempStr == nil) {
            tempStr = [NSString stringWithCString:[codeString cStringUsingEncoding:NSShiftJISStringEncoding] encoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)];
        }
    } else if ([codeString canBeConvertedToEncoding:NSISOLatin1StringEncoding]) {
        tempStr = [NSString stringWithCString:[codeString cStringUsingEncoding:NSISOLatin1StringEncoding] encoding:NSUTF8StringEncoding];
        // 如果转化成utf-8失败，再尝试转化为gbk
        if (tempStr == nil) {
            tempStr = [NSString stringWithCString:[codeString cStringUsingEncoding:NSISOLatin1StringEncoding] encoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)];
        }
    }
    // 如果转化都失败，就显示原始扫描出来的字符串
    if (tempStr == nil) {
        tempStr = codeString;
    }
    return tempStr;
}


#pragma mark - lazy
- (NSMutableArray *)metadataObjectTypes{
    if (!_metadataObjectTypes) {
        _metadataObjectTypes = [NSMutableArray arrayWithObjects:AVMetadataObjectTypeAztecCode, AVMetadataObjectTypeCode128Code, AVMetadataObjectTypeCode39Code, AVMetadataObjectTypeCode39Mod43Code, AVMetadataObjectTypeCode93Code, AVMetadataObjectTypeEAN13Code, AVMetadataObjectTypeEAN8Code, AVMetadataObjectTypePDF417Code, AVMetadataObjectTypeQRCode, AVMetadataObjectTypeUPCECode, nil];
        
        // >= iOS 8
        if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_7_1) {
            [_metadataObjectTypes addObjectsFromArray:@[AVMetadataObjectTypeInterleaved2of5Code, AVMetadataObjectTypeITF14Code, AVMetadataObjectTypeDataMatrixCode]];
        }
    }
    
    return _metadataObjectTypes;
}

- (AVCaptureDevice *)device {
    if (!_device) {
        _device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    }
    return _device;
}

@end
