//
//  UINavigationController+SYZFullscreenPopGesture.m
//  SYZNavigationControllerKit
//
//  Created by sun on 2019/3/5.
//

#import "UINavigationController+SYZFullscreenPopGesture.h"
#import <objc/runtime.h>

@interface _SYZFullscreenPopGestureRecognizerDelegate : NSObject <UIGestureRecognizerDelegate>
@property (nonatomic, weak) UINavigationController *navigationController;
@end

@implementation _SYZFullscreenPopGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIPanGestureRecognizer *)gestureRecognizer
{
    // Ignore when no view controller is pushed into the navigation stack.
    if (self.navigationController.viewControllers.count <= 1) {
        return NO;
    }
    
    UIViewController* topVC = self.navigationController.topViewController;
    id<SYZBackIntercepterProtocol> intercepter = nil;
    if ([topVC conformsToProtocol:@protocol(SYZBackIntercepterProtocol)]) {
        if ([topVC respondsToSelector:@selector(shouldIntercepteBackEvent:)]) {
            intercepter = (id<SYZBackIntercepterProtocol>)topVC;
            if ([intercepter shouldIntercepteBackEvent:self.navigationController]) {
                return NO;
            }
        }
    }
    
    // Ignore when the active view controller doesn't allow interactive pop.
    UIViewController *topViewController = self.navigationController.viewControllers.lastObject;
    if (topViewController.syz_interactivePopDisabled) {
        return NO;
    }
    
    // Ignore when the beginning location is beyond max allowed initial distance to left edge.
    CGPoint beginningLocation = [gestureRecognizer locationInView:gestureRecognizer.view];
    CGFloat maxAllowedInitialDistance = topViewController.syz_interactivePopMaxAllowedInitialDistanceToLeftEdge;
    if (maxAllowedInitialDistance > 0 && beginningLocation.x > maxAllowedInitialDistance) {
        return NO;
    }
    
    // Ignore pan gesture when the navigation controller is currently in transition.
    if ([[self.navigationController valueForKey:@"_isTransitioning"] boolValue]) {
        return NO;
    }
    
    // Prevent calling the handler when the gesture begins in an opposite direction.
    CGPoint translation = [gestureRecognizer translationInView:gestureRecognizer.view];
    BOOL isLeftToRight = [UIApplication sharedApplication].userInterfaceLayoutDirection == UIUserInterfaceLayoutDirectionLeftToRight;
    CGFloat multiplier = isLeftToRight ? 1 : - 1;
    if ((translation.x * multiplier) <= 0) {
        return NO;
    }
    
    return YES;
}

@end

typedef void (^_SNHViewControllerWillAppearInjectBlock)(UIViewController *viewController, BOOL animated);

@interface UIViewController (SNHFullscreenPopGesturePrivate)
@property (nonatomic, copy) _SNHViewControllerWillAppearInjectBlock snh_willAppearInjectBlock;
@end

@implementation UIViewController (SNHFullscreenPopGesturePrivate)

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Method viewWillAppear_originalMethod = class_getInstanceMethod(self, @selector(viewWillAppear:));
        Method viewWillAppear_swizzledMethod = class_getInstanceMethod(self, @selector(snh_viewWillAppear:));
        method_exchangeImplementations(viewWillAppear_originalMethod, viewWillAppear_swizzledMethod);
        
        Method viewWillDisappear_originalMethod = class_getInstanceMethod(self, @selector(viewWillDisappear:));
        Method viewWillDisappear_swizzledMethod = class_getInstanceMethod(self, @selector(snh_viewWillDisappear:));
        method_exchangeImplementations(viewWillDisappear_originalMethod, viewWillDisappear_swizzledMethod);
    });
}

- (void)snh_viewWillAppear:(BOOL)animated
{
    // Forward to primary implementation.
    [self snh_viewWillAppear:animated];
    
    if (self.snh_willAppearInjectBlock) {
        self.snh_willAppearInjectBlock(self, animated);
    }
}

- (void)snh_viewWillDisappear:(BOOL)animated
{
    // Forward to primary implementation.
    [self snh_viewWillDisappear:animated];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIViewController *viewController = self.navigationController.viewControllers.lastObject;
        if (viewController && !viewController.syz_prefersNavigationBarHidden) {
            [self.navigationController setNavigationBarHidden:NO animated:NO];
        }
    });
}

- (_SNHViewControllerWillAppearInjectBlock)snh_willAppearInjectBlock {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setSnh_willAppearInjectBlock:(_SNHViewControllerWillAppearInjectBlock)block {
    objc_setAssociatedObject(self, @selector(snh_willAppearInjectBlock), block, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

@end

@implementation UINavigationController (SNHFullscreenPopGesture)

+ (void)load {
    // Inject "-pushViewController:animated:"
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [self class];
        
        SEL originalSelector = @selector(pushViewController:animated:);
        SEL swizzledSelector = @selector(snh_pushViewController:animated:);
        
        Method originalMethod = class_getInstanceMethod(class, originalSelector);
        Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
        
        BOOL success = class_addMethod(class, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod));
        if (success) {
            class_replaceMethod(class, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod);
        }
    });
}

- (void)snh_pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    if (viewController == nil || [viewController isKindOfClass:[UIViewController class]] == NO) return;
    
    if (![self.interactivePopGestureRecognizer.view.gestureRecognizers containsObject:self.snh_fullscreenPopGestureRecognizer]) {
        
        // Add our own gesture recognizer to where the onboard screen edge pan gesture recognizer is attached to.
        [self.interactivePopGestureRecognizer.view addGestureRecognizer:self.snh_fullscreenPopGestureRecognizer];
        
        // Forward the gesture events to the private handler of the onboard gesture recognizer.
        NSArray *internalTargets = [self.interactivePopGestureRecognizer valueForKey:@"targets"];
        id internalTarget = [internalTargets.firstObject valueForKey:@"target"];
        SEL internalAction = NSSelectorFromString(@"handleNavigationTransition:");
        self.snh_fullscreenPopGestureRecognizer.delegate = self.snh_popGestureRecognizerDelegate;
        [self.snh_fullscreenPopGestureRecognizer addTarget:internalTarget action:internalAction];
        
        // Disable the onboard gesture recognizer.
        self.interactivePopGestureRecognizer.enabled = NO;
    }
    
    // Handle perferred navigation bar appearance.
    [self snh_setupViewControllerBasedNavigationBarAppearanceIfNeeded:viewController];
    
    // Forward to primary implementation.
    if (![self.viewControllers containsObject:viewController]) {
        [self snh_pushViewController:viewController animated:animated];
    }
}

- (void)snh_setupViewControllerBasedNavigationBarAppearanceIfNeeded:(UIViewController *)appearingViewController {
    if (!self.snh_viewControllerBasedNavigationBarAppearanceEnabled) {
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    _SNHViewControllerWillAppearInjectBlock block = ^(UIViewController *viewController, BOOL animated) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf) {
            [strongSelf setNavigationBarHidden:viewController.syz_prefersNavigationBarHidden animated:animated];
        }
    };
    
    // Setup will appear inject block to appearing view controller.
    // Setup disappearing view controller as well, because not every view controller is added into
    // stack by pushing, maybe by "-setViewControllers:".
    appearingViewController.snh_willAppearInjectBlock = block;
    UIViewController *disappearingViewController = self.viewControllers.lastObject;
    if (disappearingViewController && !disappearingViewController.snh_willAppearInjectBlock) {
        disappearingViewController.snh_willAppearInjectBlock = block;
    }
}

- (_SYZFullscreenPopGestureRecognizerDelegate *)snh_popGestureRecognizerDelegate {
    _SYZFullscreenPopGestureRecognizerDelegate *delegate = objc_getAssociatedObject(self, _cmd);
    
    if (!delegate) {
        delegate = [[_SYZFullscreenPopGestureRecognizerDelegate alloc] init];
        delegate.navigationController = self;
        
        objc_setAssociatedObject(self, _cmd, delegate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return delegate;
}

- (UIPanGestureRecognizer *)snh_fullscreenPopGestureRecognizer {
    UIPanGestureRecognizer *panGestureRecognizer = objc_getAssociatedObject(self, _cmd);
    
    if (!panGestureRecognizer) {
        panGestureRecognizer = [[UIPanGestureRecognizer alloc] init];
        panGestureRecognizer.maximumNumberOfTouches = 1;
        
        objc_setAssociatedObject(self, _cmd, panGestureRecognizer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return panGestureRecognizer;
}

- (BOOL)snh_viewControllerBasedNavigationBarAppearanceEnabled {
    NSNumber *number = objc_getAssociatedObject(self, _cmd);
    if (number) {
        return number.boolValue;
    }
    self.snh_viewControllerBasedNavigationBarAppearanceEnabled = YES;
    return YES;
}

- (void)setSnh_viewControllerBasedNavigationBarAppearanceEnabled:(BOOL)enabled {
    SEL key = @selector(snh_viewControllerBasedNavigationBarAppearanceEnabled);
    objc_setAssociatedObject(self, key, @(enabled), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark - Intercepter
- (BOOL)navigationBar:(UINavigationBar*)navigationBar shouldPopItem:(nonnull UINavigationItem *)item {
    if (self.viewControllers.count < navigationBar.items.count)  return YES;
    BOOL shouldPop = YES;
    UIViewController* topVC = self.topViewController;
    id<SYZBackIntercepterProtocol> intercepter = nil;
    if ([topVC conformsToProtocol:@protocol(SYZBackIntercepterProtocol)]) {
        if ([topVC respondsToSelector:@selector(shouldIntercepteBackEvent:)]) {
            intercepter = (id<SYZBackIntercepterProtocol>)topVC;
            shouldPop = ![intercepter shouldIntercepteBackEvent:self];
        }
    }
    
    if (shouldPop) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self popViewControllerAnimated:YES];
        });
    } else {
        for (UIView* subView in navigationBar.subviews) {
            if (0.f < subView.alpha && subView.alpha < 1.0f) {
                [UIView animateWithDuration:0.25f animations:^{
                    subView.alpha = 1.0f;
                }];
            }
        }
        
        if ([intercepter respondsToSelector:@selector(didIntercepteBackEvent:)]) {
            [intercepter didIntercepteBackEvent:self];
        }
    }
    return shouldPop;
}

@end

@implementation UIViewController (SNHFullscreenPopGesture)

- (BOOL)syz_interactivePopDisabled {
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)setSyz_interactivePopDisabled:(BOOL)disabled {
    objc_setAssociatedObject(self, @selector(syz_interactivePopDisabled), @(disabled), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)syz_prefersNavigationBarHidden {
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)setSyz_prefersNavigationBarHidden:(BOOL)hidden {
    objc_setAssociatedObject(self, @selector(syz_prefersNavigationBarHidden), @(hidden), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}


- (CGFloat)syz_interactivePopMaxAllowedInitialDistanceToLeftEdge {
#if CGFLOAT_IS_DOUBLE
    return [objc_getAssociatedObject(self, _cmd) doubleValue];
#else
    return [objc_getAssociatedObject(self, _cmd) floatValue];
#endif
}

- (void)setSyz_interactivePopMaxAllowedInitialDistanceToLeftEdge:(CGFloat)distance {
    SEL key = @selector(syz_interactivePopMaxAllowedInitialDistanceToLeftEdge);
    objc_setAssociatedObject(self, key, @(MAX(0, distance)), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
