//
//  XFMaskView.m
//  XFScanDemo
//
//  Created by zhanglong on 16/10/14.
//  Copyright © 2016年 ZKXC. All rights reserved.
//

#import "XFMaskView.h"
#define StartX 40
@interface XFMaskView ()

@property (nonatomic, strong) UIImageView * scanLineImg;

/** scanView */
@property (nonatomic, strong) UIView *scanView;

@end

@implementation XFMaskView

- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        [self addUI];
    }
    
    return self;
}

/**
 *  添加UI
 */
- (void)addUI{
    //遮罩层
    UIView * maskView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
    maskView.backgroundColor = [UIColor blackColor];
    maskView.alpha = 0.5;
    maskView.layer.mask = [self maskLayer];
    [self addSubview:maskView];
    
    // 扫描区
    CGFloat scanViewX = StartX;
    CGFloat scanViewW = self.frame.size.width - scanViewX * 2;
    CGFloat scanViewH = scanViewW;
    CGFloat scanViewY = (self.frame.size.height - scanViewH) / 2;
    UIView *scanView = [[UIView alloc] initWithFrame:CGRectMake(scanViewX, scanViewY, scanViewW, scanViewH)];
    scanView.backgroundColor = [UIColor clearColor];
    [self addSubview:scanView];
    _scanView = scanView;
    
    //提示框
    UILabel * hintLabel = [[UILabel alloc] initWithFrame:CGRectMake(scanViewX, CGRectGetMaxY(scanView.frame) + 10, scanViewW, 50)];
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
    [scanView addSubview:topLeftImg];
    
    //右上
    UIImageView * topRightImg = [[UIImageView alloc] initWithFrame:CGRectMake(scanViewW - topRight.size.width, 0, topRight.size.width, topRight.size.height)];
    topRightImg.image = topRight;
    [scanView addSubview:topRightImg];
    
    //左下
    UIImageView * bottomLeftImg = [[UIImageView alloc] initWithFrame:CGRectMake(0, scanViewH - bottomLeft.size.height, bottomLeft.size.width, bottomLeft.size.height)];
    bottomLeftImg.image = bottomLeft;
    [scanView addSubview:bottomLeftImg];
    
    //右下
    UIImageView * bottomRightImg = [[UIImageView alloc] initWithFrame:CGRectMake(scanViewW - bottomRight.size.width, scanViewH - bottomRight.size.height, bottomRight.size.width, bottomRight.size.height)];
    bottomRightImg.image = bottomRight;
    [scanView addSubview:bottomRightImg];
    
    //扫描线
    UIImage * scanLine = [UIImage imageNamed:@"scan_5"];
    self.scanLineImg = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, scanViewW, scanLine.size.height)];
    self.scanLineImg.image = scanLine;
    self.scanLineImg.contentMode = UIViewContentModeScaleAspectFit;
    [scanView addSubview:self.scanLineImg];
    [self.scanLineImg.layer addAnimation:[self animation] forKey:nil];
}

- (CABasicAnimation *)animation{
    CABasicAnimation * animation = [CABasicAnimation animationWithKeyPath:@"position"];
    animation.duration = 3;
    animation.fillMode = kCAFillModeForwards;
    animation.removedOnCompletion = NO;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    animation.repeatCount = MAXFLOAT;
    animation.fromValue = [NSValue valueWithCGPoint:CGPointMake(self.scanView.frame.size.width / 2, 0)];
    animation.toValue = [NSValue valueWithCGPoint:CGPointMake(self.scanView.frame.size.width / 2, self.frame.size.width - 2 * StartX)];
    
    return animation;
}

/**
 *  遮罩层bezierPath
 *
 *  @return UIBezierPath
 */
- (UIBezierPath *)maskPath{
    UIBezierPath * bezier = [UIBezierPath bezierPathWithRect:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
    CGFloat pathX = StartX;
    CGFloat pathWidth = self.frame.size.width - StartX * 2;
    CGFloat pathY = (self.frame.size.height - pathWidth) / 2;
    [bezier appendPath:[[UIBezierPath bezierPathWithRect:CGRectMake(pathX, pathY, pathWidth, pathWidth)] bezierPathByReversingPath]];
    return bezier;
}

/**
 *  遮罩层ShapeLayer
 *
 *  @return CAShapeLayer
 */
- (CAShapeLayer *)maskLayer{
    CAShapeLayer * layer = [CAShapeLayer layer];
    layer.path = [self maskPath].CGPath;
    return layer;
}

/**
 *  移除动画
 */
- (void)removeAnimation{
    [self.scanLineImg.layer removeAllAnimations];
}

@end

