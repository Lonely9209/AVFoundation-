//
//  ZFScanViewController.m
//  ZFScan
//
//  Created by apple on 16/3/8.
//  Copyright © 2016年 apple. All rights reserved.
//

#import "XFScanViewController.h"
#import "XFMaskView.h"
#import <AVFoundation/AVFoundation.h>
#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height
#define Constant 40

@interface XFScanViewController ()<AVCaptureMetadataOutputObjectsDelegate>

/** 输入输出的中间桥梁 */
@property (nonatomic, strong) AVCaptureSession * session;
/** 扫描支持的编码格式的数组 */
@property (nonatomic, strong) NSMutableArray * metadataObjectTypes;
/** 遮罩层 */
@property (nonatomic, strong) XFMaskView * maskView;

@end

@implementation XFScanViewController

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

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    
    [self.maskView removeAnimation];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // 扫描初始化
    [self capture];
    // 添加遮罩层
    [self addUI];
}

/**
 *  添加遮罩层
 */
- (void)addUI{
    self.maskView = [[XFMaskView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:self.maskView];
}

/**
 *  扫描初始化
 */
- (void)capture{
    //获取摄像设备
    AVCaptureDevice * device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    //创建输入流
    AVCaptureDeviceInput * input = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
    //创建输出流
    AVCaptureMetadataOutput * output = [[AVCaptureMetadataOutput alloc] init];
    //设置代理 在主线程里刷新
    [output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    
    //初始化链接对象
    self.session = [[AVCaptureSession alloc] init];
    //高质量采集率
    self.session.sessionPreset = AVCaptureSessionPresetHigh;
    
    [self.session addInput:input];
    [self.session addOutput:output];
    
    AVCaptureVideoPreviewLayer * previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.session];
    previewLayer.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
    previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    previewLayer.backgroundColor = [UIColor blackColor].CGColor;
    [self.view.layer addSublayer:previewLayer];
    
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
    
    //开始捕获
    [self.session startRunning];
}

#pragma mark - AVCaptureMetadataOutputObjectsDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection{
    NSLog(@"%@-----%@",metadataObjects,connection);
    if (metadataObjects.count > 0) {
        [self.session stopRunning];
        AVMetadataMachineReadableCodeObject * metadataObject = metadataObjects.firstObject;
        NSString *result = metadataObject.stringValue;//返回的扫描结果
        NSData *data=[metadataObject.stringValue dataUsingEncoding:NSUTF8StringEncoding];
        NSStringEncoding enc = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
        NSString *retStr = [[NSString alloc] initWithData:data encoding:enc];//如果中文是utf-8编码转gbk结果为空
        if (retStr)//如果扫描中文乱码则需要处理，否则不处理
        {
            NSInteger max = [metadataObject.stringValue length];
            char *nbytes = malloc(max + 1);
            for (int i = 0; i < max; i++)
            {
                unichar ch = [metadataObject.stringValue  characterAtIndex: i];
                nbytes[i] = (char) ch;
            }
            nbytes[max] = '\0';
            result=[NSString stringWithCString: nbytes
                                      encoding: enc];
        }
        self.returnScanBarCodeValue(result);
        [self.navigationController popViewControllerAnimated:YES];
    }
}

@end
