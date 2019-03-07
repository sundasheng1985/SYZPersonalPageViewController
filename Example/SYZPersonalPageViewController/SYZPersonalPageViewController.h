//
//  SYZPersonalPageViewController.h
//  SYZPersonalPageViewController_Example
//
//  Created by sun on 2019/3/6.
//  Copyright © 2019年 sun. All rights reserved.
//

#import <SYZPersonalPageViewController/SYZStickyPageController.h>
#import "WRCustomNavigationBar.h"
#import "WRNavigationBar.h"
#import "SNHPersonalPageHeaderView.h"
NS_ASSUME_NONNULL_BEGIN

@interface SYZPersonalPageViewController : SYZStickyPageController

@property (nonatomic, strong) WRCustomNavigationBar *customeNav;
/** header高度 */
@property (nonatomic, assign) CGFloat headerHeight;
/** 状态栏加导航栏 */
@property (nonatomic, assign) CGFloat KNavHeight;
/** 组 */
@property (nonatomic, strong) NSArray *musicCategories;
/** header */
@property (nonatomic, strong) SNHPersonalPageHeaderView *headerView;
@end

NS_ASSUME_NONNULL_END
