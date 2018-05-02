//
//  XFMaskView.h
//  XFScanDemo
//
//  Created by zhanglong on 16/10/14.
//  Copyright © 2016年 ZKXC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface XFMaskView : UIView

/** 设备启动提示 */
- (void)startDeviceReadyingWithTipString:(NSString *)tipString;

/** 设备停止启动 */
- (void)stopDeviceReadying;

/** 开启扫描动画 */
- (void)startAnimayion;

/** 移除扫描动画 */
- (void)removeAnimation;


@end
