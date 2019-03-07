//  SYZBackIntercepterProtocol.h
//  SYZNavigationControllerKit
//
//  Created by sun on 2019/3/5.

#ifndef SYZBackIntercepterProtocol_h
#define SYZBackIntercepterProtocol_h

@protocol SYZBackIntercepterProtocol<NSObject>

/** 是否对返回事件进行拦截*/
- (BOOL)shouldIntercepteBackEvent:(UINavigationController*)navigationController;

/** 已经拦截了，这时可以做弹框或者其他事情*/
- (void)didIntercepteBackEvent:(UINavigationController*)navigationController;

@end

#endif /* SYZBackIntercepterProtocol_h */
