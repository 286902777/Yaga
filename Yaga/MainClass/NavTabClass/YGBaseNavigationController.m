//
//  YGBaseNavigationController.m
//  Yaga
//

#import "YGBaseNavigationController.h"
#import "YGBaseViewController.h"

@interface YGBaseNavigationController () <UINavigationControllerDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, strong) UIImageView *backgroundImageView;

@end

@implementation YGBaseNavigationController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.delegate = self;
    self.interactivePopGestureRecognizer.delegate = self;
    [self setupBackgroundImageView];
    
    UINavigationBarAppearance *appearance = [[UINavigationBarAppearance alloc] init];
    [appearance configureWithTransparentBackground];
    appearance.backgroundEffect = nil;
    appearance.backgroundColor = UIColor.clearColor;
    appearance.shadowColor = UIColor.clearColor;
    appearance.titleTextAttributes = @{
        NSForegroundColorAttributeName: UIColor.blackColor,
        NSFontAttributeName: [UIFont boldSystemFontOfSize:18.0]
    };
    
    self.navigationBar.standardAppearance = appearance;
    self.navigationBar.scrollEdgeAppearance = appearance;
    self.navigationBar.compactAppearance = appearance;
    self.navigationBar.translucent = YES;
    self.navigationBar.tintColor = UIColor.blackColor;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    self.backgroundImageView.frame = self.view.bounds;
}

- (void)setupBackgroundImageView {
    self.view.backgroundColor = UIColor.clearColor;
    
    self.backgroundImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"backimage"]];
    self.backgroundImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.backgroundImageView.frame = self.view.bounds;
    self.backgroundImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view insertSubview:self.backgroundImageView atIndex:0];
}

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    if (self.viewControllers.count > 0) {
        viewController.hidesBottomBarWhenPushed = YES;
        if (![viewController isKindOfClass:YGBaseViewController.class]) {
            viewController.navigationItem.leftBarButtonItem = [self backBarButtonItem];
        }
    }
    
    [super pushViewController:viewController animated:animated];
}

- (UIBarButtonItem *)backBarButtonItem {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *backImage = [[UIImage imageNamed:@"navback"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    [button setImage:backImage forState:UIControlStateNormal];
    [button setImage:backImage forState:UIControlStateHighlighted];
    button.adjustsImageWhenHighlighted = NO;
    button.backgroundColor = UIColor.clearColor;
    button.tintColor = UIColor.clearColor;
    button.layer.borderWidth = 0.0;
    [button addTarget:self action:@selector(backButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    button.frame = CGRectMake(0.0, 0.0, 44.0, 44.0);
    button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    button.imageEdgeInsets = UIEdgeInsetsMake(0.0, 0.0, 0.0, 0.0);
    
    return [[UIBarButtonItem alloc] initWithCustomView:button];
}

- (void)backButtonTapped {
    [self popViewControllerAnimated:YES];
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer == self.interactivePopGestureRecognizer) {
        return self.viewControllers.count > 1;
    }
    
    return YES;
}

@end
