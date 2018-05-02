//
//  XFMaskView.m
//  XFScanDemo
//
//  Created by zhanglong on 16/10/14.
//  Copyright © 2016年 ZKXC. All rights reserved.
//

#import "XFMaskView.h"
#import <AVFoundation/AVFoundation.h>

#define Constant 40

@interface XFMaskView ()
/** 扫描线 */
@property (nonatomic, strong) UIImageView * scanLineImageView;
/** 扫描区域View */
@property (nonatomic, strong) UIView *scanView;
/** indicatorView */
@property (nonatomic, strong) UIActivityIndicatorView *indicatorView;
/** labelReadying */
@property (nonatomic, strong) UILabel *labelReadying;
@end

@implementation XFMaskView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self addUI];
    }
    return self;
}

/** 添加UI */
- (void)addUI {
    //遮罩层
    UIView *maskView = [[UIView alloc] initWithFrame:self.bounds];
    maskView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.5];
    maskView.layer.mask = [self maskLayer];
    [self addSubview:maskView];
    
    // 扫描区
    CGFloat scanViewX = Constant;
    CGFloat scanViewW = self.frame.size.width - scanViewX * 2;
    CGFloat scanViewH = scanViewW;
    CGFloat scanViewY = (self.frame.size.height - scanViewH) / 2;
    _scanView = [[UIView alloc] initWithFrame:CGRectMake(scanViewX, scanViewY, scanViewW, scanViewH)];
    _scanView.backgroundColor = [UIColor clearColor];
    [self addSubview:_scanView];
    
    //提示框
    UILabel * hintLabel = [[UILabel alloc] initWithFrame:CGRectMake(scanViewX, CGRectGetMaxY(_scanView.frame) + 20, scanViewW, 50)];
    hintLabel.text = @"将二维码放入框内中央,即可自动扫描";
    hintLabel.textColor = [UIColor whiteColor];
    hintLabel.numberOfLines = 0;
    hintLabel.textAlignment = NSTextAlignmentCenter;
    [self addSubview:hintLabel];
    
    //边框
    UIImage * topLeft = [UIImage imageNamed:@"scan_1"];
    UIImage * topRight = [UIImage imageNamed:@"scan_2"];
    UIImage * bottomLeft = [UIImage imageNamed:@"scan_3"];
    UIImage * bottomRight = [UIImage imageNamed:@"scan_4"];
    
    //左上
    UIImageView * topLeftImg = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, topLeft.size.width, topLeft.size.height)];
    topLeftImg.image = topLeft;
    [_scanView addSubview:topLeftImg];
    
    //右上
    UIImageView * topRightImg = [[UIImageView alloc] initWithFrame:CGRectMake(scanViewW - topRight.size.width, 0, topRight.size.width, topRight.size.height)];
    topRightImg.image = topRight;
    [_scanView addSubview:topRightImg];
    
    //左下
    UIImageView * bottomLeftImg = [[UIImageView alloc] initWithFrame:CGRectMake(0, scanViewH - bottomLeft.size.height, bottomLeft.size.width, bottomLeft.size.height)];
    bottomLeftImg.image = bottomLeft;
    [_scanView addSubview:bottomLeftImg];
    
    //右下
    UIImageView * bottomRightImg = [[UIImageView alloc] initWithFrame:CGRectMake(scanViewW - bottomRight.size.width, scanViewH - bottomRight.size.height, bottomRight.size.width, bottomRight.size.height)];
    bottomRightImg.image = bottomRight;
    [_scanView addSubview:bottomRightImg];
    
    //扫描线
    UIImage * scanLine = [UIImage imageNamed:@"scan_5"];
    self.scanLineImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, scanViewW, scanLine.size.height)];
    self.scanLineImageView.image = scanLine;
    self.scanLineImageView.hidden = true;
    self.scanLineImageView.contentMode = UIViewContentModeScaleAspectFit;
    [_scanView addSubview:self.scanLineImageView];
}

- (CABasicAnimation *)animation {
    CABasicAnimation * animation = [CABasicAnimation animationWithKeyPath:@"position"];
    animation.duration = 3;
    animation.fillMode = kCAFillModeForwards;
    animation.removedOnCompletion = NO;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    animation.repeatCount = MAXFLOAT;
    animation.fromValue = [NSValue valueWithCGPoint:CGPointMake(self.scanLineImageView.center.x, 0)];
    animation.toValue = [NSValue valueWithCGPoint:CGPointMake(self.scanLineImageView.center.x, self.frame.size.width - 2 * Constant)];
    return animation;
}

/**
 *  遮罩层bezierPath
 *
 *  @return UIBezierPath
 */
- (UIBezierPath *)maskPath {
    UIBezierPath * bezier = [UIBezierPath bezierPathWithRect:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
    CGFloat pathX = Constant;
    CGFloat pathWidth = self.frame.size.width - Constant * 2;
    CGFloat pathY = (self.frame.size.height - pathWidth) / 2;
    [bezier appendPath:[[UIBezierPath bezierPathWithRect:CGRectMake(pathX, pathY, pathWidth, pathWidth)] bezierPathByReversingPath]];
    return bezier;
}

/**
 *  遮罩层ShapeLayer
 *
 *  @return CAShapeLayer
 */
- (CAShapeLayer *)maskLayer {
    CAShapeLayer * layer = [CAShapeLayer layer];
    layer.path = [self maskPath].CGPath;
    return layer;
}

/**
 *  移除动画
 */
- (void)removeAnimation {
    [self.scanLineImageView.layer removeAllAnimations];
}

- (void)startDeviceReadyingWithTipString:(NSString *)tipString {
    //启动提示
    _indicatorView = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
    [_indicatorView setHidesWhenStopped:true];
    [_indicatorView startAnimating];
    [_scanView addSubview:self.indicatorView];
    if (tipString) {
        CGRect rect = [tipString boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:18]} context:nil];
        CGFloat width = rect.size.width + 16;
        _indicatorView.center = CGPointMake(CGRectGetWidth(_scanView.frame) / 2 - width / 2, CGRectGetHeight(_scanView.frame) / 2);
        [_indicatorView setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleWhite];
        CGRect labelReadyRect = CGRectMake(CGRectGetMaxX(self.indicatorView.frame), self.indicatorView.frame.origin.y, width, 30);
        UILabel *labelReadying = [[UILabel alloc]initWithFrame:labelReadyRect];
        labelReadying.backgroundColor = [UIColor clearColor];
        labelReadying.textColor  = [UIColor whiteColor];
        labelReadying.font = [UIFont systemFontOfSize:18];
        labelReadying.text = tipString;
        [_scanView addSubview:labelReadying];
        _labelReadying = labelReadying;
    } else {
        _indicatorView.center = CGPointMake(CGRectGetWidth(_scanView.frame) / 2, CGRectGetHeight(_scanView.frame) / 2);
        [_indicatorView setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleWhiteLarge];
    }
}

- (void)stopDeviceReadying {
    if (_indicatorView) {
        [_indicatorView stopAnimating];
        [_indicatorView removeFromSuperview];
        [_labelReadying removeFromSuperview];
        self.indicatorView = nil;
        self.labelReadying = nil;
    }
}

- (void)startAnimayion {
    self.labelReadying.hidden = true;
    self.indicatorView.hidden = true;
    self.scanLineImageView.hidden = false;
    [self.scanLineImageView.layer addAnimation:[self animation] forKey:nil];
}

@end

