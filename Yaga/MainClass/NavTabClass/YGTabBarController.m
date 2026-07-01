//
//  YGTabBarController.m
//  Yaga
//

#import "YGTabBarController.h"
#import "YGBaseNavigationController.h"
#import "YGHomeViewController.h"
#import "YGChatViewController.h"
#import "YGCircleViewController.h"
#import "YGMineViewController.h"
#import "YGAppRouter.h"
#import "YGUserStore.h"

@interface YGTabBarController () <UITabBarControllerDelegate>

@end

@implementation YGTabBarController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.delegate = self;
    [self setupAppearance];
    [self setupViewControllers];
}

- (void)setupAppearance {
    UITabBarAppearance *appearance = [[UITabBarAppearance alloc] init];
    [appearance configureWithOpaqueBackground];
    appearance.backgroundColor = UIColor.whiteColor;
    appearance.shadowColor = [UIColor colorWithWhite:0.90 alpha:1.0];
    
    NSDictionary *normalAttributes = @{
        NSForegroundColorAttributeName: [UIColor colorWithWhite:0.55 alpha:1.0],
        NSFontAttributeName: [UIFont systemFontOfSize:11.0]
    };
    NSDictionary *selectedAttributes = @{
        NSForegroundColorAttributeName: [UIColor colorWithRed:0.13 green:0.53 blue:0.95 alpha:1.0],
        NSFontAttributeName: [UIFont systemFontOfSize:11.0 weight:UIFontWeightMedium]
    };
    
    appearance.stackedLayoutAppearance.normal.titleTextAttributes = normalAttributes;
    appearance.stackedLayoutAppearance.selected.titleTextAttributes = selectedAttributes;
    
    self.tabBar.standardAppearance = appearance;
    if (@available(iOS 15.0, *)) {
        self.tabBar.scrollEdgeAppearance = appearance;
    }
}

- (void)setupViewControllers {
    UIViewController *home = [[YGHomeViewController alloc] init];
    UIViewController *chat = [[YGChatViewController alloc] init];
    UIViewController *circle = [[YGCircleViewController alloc] init];
    UIViewController *mine = [[YGMineViewController alloc] init];
    
    self.viewControllers = @[
        [self navigationControllerWithRoot:home title:@"" imageName:@"unhomepage" selectedImageName:@"homepage"],
        [self navigationControllerWithRoot:circle title:@"" imageName:@"uncirclepage" selectedImageName:@"circlepage"],
        [self navigationControllerWithRoot:chat title:@"" imageName:@"unchatpage" selectedImageName:@"chatpage"],
        [self navigationControllerWithRoot:mine title:@"" imageName:@"unminepage" selectedImageName:@"minepage"]
    ];
}

- (YGBaseNavigationController *)navigationControllerWithRoot:(UIViewController *)rootViewController
                                                       title:(NSString *)title
                                                   imageName:(NSString *)imageName
                                           selectedImageName:(NSString *)selectedImageName {
    rootViewController.title = title;
    UIImage *image = [[UIImage imageNamed:imageName] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    UIImage *selectedImage = [[UIImage imageNamed:selectedImageName] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    rootViewController.tabBarItem = [[UITabBarItem alloc] initWithTitle:title image:image selectedImage:selectedImage];
    
    return [[YGBaseNavigationController alloc] initWithRootViewController:rootViewController];
}

#pragma mark - UITabBarControllerDelegate

- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController {
    NSUInteger index = [tabBarController.viewControllers indexOfObject:viewController];
    if (index != NSNotFound && index >= 2 && [[YGUserStore sharedStore] isGuestMode]) {
        [YGAppRouter switchToLoginInterface];
        return NO;
    }
    return YES;
}

@end
