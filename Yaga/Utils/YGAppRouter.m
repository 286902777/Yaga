//
//  YGAppRouter.m
//  Yaga
//

#import "YGAppRouter.h"
#import "SceneDelegate.h"
#import "YGBaseNavigationController.h"
#import "YGLoginViewController.h"
#import "YGTabBarController.h"

@implementation YGAppRouter

+ (void)switchToLoginInterface {
    UIViewController *loginViewController = [[YGLoginViewController alloc] init];
    UIViewController *rootViewController = [[YGBaseNavigationController alloc] initWithRootViewController:loginViewController];
    [self setRootViewController:rootViewController];
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

@end
