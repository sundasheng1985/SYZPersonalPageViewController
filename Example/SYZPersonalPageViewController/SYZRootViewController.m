//
//  SYZRootViewController.m
//  SYZPersonalPageViewController_Example
//
//  Created by sun on 2019/3/6.
//  Copyright © 2019年 sun. All rights reserved.
//

#import "SYZRootViewController.h"
#import "SYZPersonalPageViewController.h"
@interface SYZRootViewController ()

@end

@implementation SYZRootViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor grayColor];
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.backgroundColor = [UIColor yellowColor];
    btn.frame = CGRectMake(100, 100, 100, 100);
    [btn addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
}

- (void)buttonAction:(UIButton *)sender{
    [self.navigationController pushViewController:[SYZPersonalPageViewController new] animated:YES];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
