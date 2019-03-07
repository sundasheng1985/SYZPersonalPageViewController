//
//  WMStickyPageViewController.h
//  StickyExample
//
//  Created by Tpphha on 2017/7/22.
//  Copyright © 2017年 Tpphha. All rights reserved.
//

#import <WMPageController/WMPageController.h>

@class SYZStickyPageController;

@protocol SYZStickyPageControllerDelegate;

/**
 The self.view is custom UIScrollView
 */
@interface SYZStickyPageController : WMPageController

/**
 It's determine the sticky locatio.
 */
@property (nonatomic, assign)  CGFloat  minimumHeaderViewHeight;

/**
 The custom headerView's height, default 0 means no effective.
 */
@property (nonatomic, assign) CGFloat maximumHeaderViewHeight;

/**
 The menuView's height, default 44
 */
@property (nonatomic, assign) CGFloat menuViewHeight;

@end

@protocol SYZStickyPageControllerDelegate <WMPageControllerDelegate>

@optional
- (BOOL)pageController:(SYZStickyPageController *)pageController shouldScrollWithSubview:(UIScrollView *)subview;

@end
