//
//  SYZPersonalPageViewController.m
//  SYZPersonalPageViewController_Example
//
//  Created by sun on 2019/3/6.
//  Copyright © 2019年 sun. All rights reserved.
//

#import "SYZPersonalPageViewController.h"
#import <ReactiveObjC/ReactiveObjC.h>
#import "SYZDetailViewController.h"
#import <YYWebImage/YYWebImage.h>
#import <SYZNavigationControllerKit/SYZNavigationControllerKit.h>

static CGFloat const kWMMenuViewHeight = 44.0;

#define SCREEN_WIDTH   [UIScreen mainScreen].bounds.size.width

#define SCREENH_HEIGHT [UIScreen mainScreen].bounds.size.height

@interface SYZPersonalPageViewController ()

@end

@implementation SYZPersonalPageViewController

- (instancetype)init{
    self = [super init];
    if (self) {
        self.showOnNavigationBar = NO;
        self.menuViewLayoutMode = WMMenuViewLayoutModeScatter;
        self.titleSizeSelected = 17.;
        self.titleSizeNormal = 17.;
        self.titleColorNormal = [UIColor grayColor];
        self.titleColorSelected = [UIColor redColor];
        self.menuViewStyle = WMMenuViewStyleLine;
        self.automaticallyCalculatesItemWidths = YES;
        self.progressViewIsNaughty = YES;
        self.progressWidth = 20;
        self.menuView.backgroundColor = [UIColor whiteColor];
        //要比头部view高度大
        self.headerHeight = SCREEN_WIDTH*0.63;
        self.KNavHeight = CGRectGetHeight(self.navigationController.navigationBar.frame) + [[UIApplication sharedApplication] statusBarFrame].size.height;
        self.menuViewHeight = kWMMenuViewHeight;
        /** 设置允许滑动的最大和最小高度 */
        self.maximumHeaderViewHeight = self.headerHeight;
        self.minimumHeaderViewHeight = self.KNavHeight + kWMMenuViewHeight;
        self.musicCategories = @[@"动态",@"相册",@"视频"];
        self.menuItemWidth = SCREEN_WIDTH / self.musicCategories.count;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.syz_prefersNavigationBarHidden = YES;
    [self.view addSubview:self.headerView];
    [self.view addSubview:self.customeNav];
    [self _refreshHeaderView];
     [_headerView yy_setImageWithURL:[NSURL URLWithString:@"https://goss.veer.com/creative/vcg/veer/800water/veer-146885451.jpg"] placeholder:[UIImage imageNamed:@""]];
    [self reloadData];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
//    [self.navigationController setNavigationBarHidden:YES animated:YES];
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
//    [self.navigationController setNavigationBarHidden:NO animated:YES];
}

- (void)_refreshHeaderView{
    CGFloat headerViewHeight = self.headerHeight;
    CGFloat headerViewX = 0;
    UIScrollView *scrollView = (UIScrollView *)self.view;
    if (scrollView.contentOffset.y < 0) {
        headerViewX = scrollView.contentOffset.y;
        headerViewHeight -= headerViewX;
    }
    self.headerView.frame = CGRectMake(0, headerViewX, CGRectGetWidth(self.view.bounds), headerViewHeight);
}

#pragma mark - ScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [super scrollViewDidScroll:scrollView];
    CGFloat offsetY = scrollView.contentOffset.y;
    if (offsetY != 0) {
        //此处更加滑动改变nav状态，可以自定义距离
        if (offsetY > [WRNavigationBar navBarBottom]) {
            CGFloat alpha = (offsetY - SCREEN_WIDTH*0.60*0.7 + [WRNavigationBar navBarBottom]) / [WRNavigationBar navBarBottom];
            [self.customeNav wr_setBackgroundAlpha:alpha];
            [self.customeNav wr_setBottomLineHidden:NO];
            [self.customeNav wr_setLeftButtonWithImage:[UIImage imageNamed:@"nva_return"]];
            [self.customeNav wr_setRightButtonWithImage:[UIImage imageNamed:@"dynamic_share_bottom"]];
        } else {
            [self.customeNav wr_setBackgroundAlpha:0];
            [self.customeNav wr_setBottomLineHidden:YES];
            [self.customeNav wr_setLeftButtonWithImage:[UIImage imageNamed:@"nva_return"]];
            [self.customeNav wr_setRightButtonWithImage:[UIImage imageNamed:@"dynamic_share_bottom"]];
        }
        //如果有分类可以直接赋值
        //        self.customeNav.y = offsetY;
        self.customeNav.frame = CGRectMake(CGRectGetMinX(self.customeNav.frame), offsetY, CGRectGetWidth(self.customeNav.frame), CGRectGetHeight(self.customeNav.frame));
        
        CGFloat headerViewHeight = self.headerHeight;
        CGFloat headerViewX = 0;
        if (scrollView.contentOffset.y < 0) {
            headerViewX = offsetY;
            headerViewHeight -= offsetY;
        }
        self.headerView.frame = CGRectMake(0, headerViewX, CGRectGetWidth(self.view.bounds), headerViewHeight);
        if (offsetY > [WRNavigationBar navBarBottom]) {
            self.customeNav.title = @"我的个人主页";
        } else {
            self.customeNav.title = @"";
        }

    }
}

#pragma mark - Datasource & Delegate
- (NSInteger)numbersOfChildControllersInPageController:(WMPageController *)pageController {
    return self.musicCategories.count;
}

- (UIViewController *)pageController:(WMPageController *)pageController viewControllerAtIndex:(NSInteger)index {
    switch (index) {
        case 0:
            return [SYZDetailViewController new];
        case 1:
            return [SYZDetailViewController new];
        case 2:
            return [SYZDetailViewController new];
       
        default:
            return [UIViewController new];
    }
}

- (NSString *)pageController:(WMPageController *)pageController titleAtIndex:(NSInteger)index {
    return self.musicCategories[index];
}


- (WRCustomNavigationBar *)customeNav {
    if (!_customeNav) {
        _customeNav = [WRCustomNavigationBar CustomNavigationBar];
        [_customeNav wr_setBackgroundAlpha:0];
        [_customeNav wr_setBottomLineHidden:YES];
        [_customeNav wr_setLeftButtonWithImage:[UIImage imageNamed:@"nva_return"]];
        @weakify(self);
        _customeNav.onClickLeftButton = ^{
            @strongify(self);
            [self.navigationController popViewControllerAnimated:YES];
        };
        _customeNav.onClickRightButton = ^{
//            @strongify(self);
           //分享事件
        };
    }
    return _customeNav;
}

- (SNHPersonalPageHeaderView *)headerView{
    if (!_headerView) {
        _headerView = [[SNHPersonalPageHeaderView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_WIDTH*0.6)];
       
    }
    return _headerView;
}

@end
