//
//  YGAppRouter.m
//  Yaga
//

#import "YGAppRouter.h"
#import "SceneDelegate.h"
#import "YGBaseNavigationController.h"
#import "YGDirectLoginViewController.h"
#import "YGLoginViewController.h"
#import "YGTabBarController.h"
#import "YGWebContainerViewController.h"

static YGWebContainerViewController *YGAppRouterPendingWebContainerViewController = nil;

@implementation YGAppRouter

+ (void)switchToLoginInterface {
    UIViewController *loginViewController = [[YGLoginViewController alloc] init];
    UIViewController *rootViewController = [[YGBaseNavigationController alloc] initWithRootViewController:loginViewController];
    [self setRootViewController:rootViewController];
}

+ (void)switchToDirectLoginInterface {
    UIViewController *loginViewController = [[YGDirectLoginViewController alloc] init];
    UIViewController *rootViewController = [[YGBaseNavigationController alloc] initWithRootViewController:loginViewController];
    [self setRootViewController:rootViewController];
}

+ (void)switchToWebContainerInterface {
    [self switchToWebContainerInterfaceWithInitialLoadHandler:nil];
}

+ (void)switchToWebContainerInterfaceWithInitialLoadHandler:(void (^)(BOOL success))initialLoadHandler {
    YGWebContainerViewController *webContainerViewController = [[YGWebContainerViewController alloc] initWithH5Url:nil];
    webContainerViewController.modalPresentationStyle = UIModalPresentationFullScreen;

    UIWindow *window = [self activeWindow];
    UIViewController *presentingViewController = [self topViewControllerFromViewController:window.rootViewController];
    if (presentingViewController == nil) {
        if (initialLoadHandler) {
            initialLoadHandler(NO);
        }
        return;
    }

    YGAppRouterPendingWebContainerViewController = webContainerViewController;
    __weak YGWebContainerViewController *weakWebContainerViewController = webContainerViewController;
    __weak UIViewController *weakPresentingViewController = presentingViewController;
    webContainerViewController.onInitialLoadFinished = ^(BOOL success) {
        if (!success) {
            YGAppRouterPendingWebContainerViewController = nil;
            if (initialLoadHandler) {
                initialLoadHandler(NO);
            }
            return;
        }

        YGWebContainerViewController *strongWebContainerViewController = weakWebContainerViewController;
        UIViewController *strongPresentingViewController = weakPresentingViewController;
        if (strongWebContainerViewController == nil || strongPresentingViewController == nil || strongWebContainerViewController.presentingViewController != nil) {
            YGAppRouterPendingWebContainerViewController = nil;
            if (initialLoadHandler) {
                initialLoadHandler(NO);
            }
            return;
        }

        [strongPresentingViewController presentViewController:strongWebContainerViewController animated:YES completion:^{
            YGAppRouterPendingWebContainerViewController = nil;
            if (initialLoadHandler) {
                initialLoadHandler(YES);
            }
        }];
    };
    [webContainerViewController loadViewIfNeeded];
}

+ (void)switchToMainInterface {
    UIViewController *rootViewController = [[YGTabBarController alloc] init];
    [self setRootViewController:rootViewController];
}

+ (void)setRootViewController:(UIViewController *)rootViewController {
    UIWindow *window = [self activeWindow];
    if (window == nil) {
        return;
    }

    [UIView transitionWithView:window
                      duration:0.25
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{
        window.rootViewController = rootViewController;
    }
                    completion:nil];
    [window makeKeyAndVisible];
}

+ (nullable UIWindow *)activeWindow {
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if (![scene isKindOfClass:UIWindowScene.class]) {
            continue;
        }
        UIWindowScene *windowScene = (UIWindowScene *)scene;
        for (UIWindow *window in windowScene.windows) {
            if (window.isKeyWindow) {
                return window;
            }
        }
        if (windowScene.windows.count > 0) {
            return windowScene.windows.firstObject;
        }
    }
    return UIApplication.sharedApplication.windows.firstObject;
}

+ (nullable UIViewController *)topViewControllerFromViewController:(nullable UIViewController *)viewController {
    UIViewController *currentViewController = viewController;
    while (currentViewController.presentedViewController != nil) {
        currentViewController = currentViewController.presentedViewController;
    }

    if ([currentViewController isKindOfClass:UINavigationController.class]) {
        UINavigationController *navigationController = (UINavigationController *)currentViewController;
        return [self topViewControllerFromViewController:navigationController.visibleViewController];
    }

    if ([currentViewController isKindOfClass:UITabBarController.class]) {
        UITabBarController *tabBarController = (UITabBarController *)currentViewController;
        return [self topViewControllerFromViewController:tabBarController.selectedViewController];
    }

    return currentViewController;
}

@end
