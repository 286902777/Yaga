//
//  YGBaseViewController.m
//  Yaga
//

#import "YGBaseViewController.h"

@interface YGBaseViewController () <UIGestureRecognizerDelegate>

@property (nonatomic, strong) UIView *yg_navigationBarView;
@property (nonatomic, strong) UIView *yg_leftContainerView;
@property (nonatomic, strong) UIButton *yg_backButton;
@property (nonatomic, strong) UILabel *yg_titleLabel;
@property (nonatomic, strong) UIView *yg_rightContainerView;
@property (nonatomic, strong) NSLayoutConstraint *navigationBarHeightConstraint;
@property (nonatomic, strong) NSLayoutConstraint *leftContainerWidthConstraint;
@property (nonatomic, strong) NSArray<NSLayoutConstraint *> *navigationBarHostConstraints;
@property (nonatomic, strong) NSArray<NSLayoutConstraint *> *leftViewConstraints;
@property (nonatomic, strong) NSArray<NSLayoutConstraint *> *rightViewConstraints;
@property (nonatomic, strong) UITapGestureRecognizer *keyboardDismissTapGesture;
@property (nonatomic, strong) UIImageView *yg_backgroundImageView;
@property (nonatomic, assign) BOOL usesCustomLeftView;

@end

@implementation YGBaseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupPageBackgroundIfNeeded];
    self.yg_tapToDismissKeyboardEnabled = YES;
    [self setupCustomNavigationBar];
    [self setupKeyboardDismissGesture];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self updateRootViewBackgroundIfNeeded];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    [self attachCustomNavigationBarToHostViewIfNeeded];
    [self updateCustomNavigationBarVisibility];
    [self updateBackButtonVisibility];
    [self updateAdditionalSafeAreaInsets];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.yg_navigationBarView.hidden = YES;
    UIViewController *nextViewController = self.navigationController.topViewController;
    BOOL shouldKeepCustomNavigationBar = [nextViewController isKindOfClass:YGBaseViewController.class];
    [self.navigationController setNavigationBarHidden:shouldKeepCustomNavigationBar animated:animated];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if (self.yg_backgroundImageView != nil) {
        [self.view sendSubviewToBack:self.yg_backgroundImageView];
    }
    [self attachCustomNavigationBarToHostViewIfNeeded];
    [self updateNavigationBarHeight];
    [self.yg_navigationBarView.superview bringSubviewToFront:self.yg_navigationBarView];
    [self updateAdditionalSafeAreaInsets];
    [self yg_updateScrollViewKeyboardDismissMode];
}

- (void)setupPageBackgroundIfNeeded {
    if (self.yg_backgroundImageView != nil) {
        return;
    }

    self.view.opaque = YES;
    self.view.backgroundColor = UIColor.whiteColor;

    UIImage *backgroundImage = [UIImage imageNamed:@"backimage"];
    if (backgroundImage == nil) {
        return;
    }

    self.yg_backgroundImageView = [[UIImageView alloc] initWithImage:backgroundImage];
    self.yg_backgroundImageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.yg_backgroundImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.yg_backgroundImageView.clipsToBounds = YES;
    self.yg_backgroundImageView.userInteractionEnabled = NO;
    [self.view insertSubview:self.yg_backgroundImageView atIndex:0];

    [NSLayoutConstraint activateConstraints:@[
        [self.yg_backgroundImageView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.yg_backgroundImageView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.yg_backgroundImageView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.yg_backgroundImageView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
    ]];
}

- (void)updateRootViewBackgroundIfNeeded {
    CGFloat alpha = 1.0;
    [self.view.backgroundColor getRed:NULL green:NULL blue:NULL alpha:&alpha];
    if (self.view.backgroundColor == nil || alpha < 1.0) {
        self.view.backgroundColor = UIColor.whiteColor;
    }
    self.view.opaque = YES;
}

- (void)setupCustomNavigationBar {
    self.yg_navigationBarView = [[UIView alloc] init];
    self.yg_navigationBarView.translatesAutoresizingMaskIntoConstraints = NO;
    self.yg_navigationBarView.backgroundColor = UIColor.clearColor;
    self.navigationBarHeightConstraint = [self.yg_navigationBarView.heightAnchor constraintEqualToConstant:88.0];

    self.yg_leftContainerView = [[UIView alloc] init];
    self.yg_leftContainerView.translatesAutoresizingMaskIntoConstraints = NO;
    self.yg_leftContainerView.backgroundColor = UIColor.clearColor;
    [self.yg_navigationBarView addSubview:self.yg_leftContainerView];

    self.yg_backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.yg_backButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.yg_backButton.backgroundColor = UIColor.clearColor;
    self.yg_backButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    UIImage *backImage = [[UIImage imageNamed:@"navback"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    [self.yg_backButton setImage:backImage forState:UIControlStateNormal];
    [self.yg_backButton setImage:backImage forState:UIControlStateHighlighted];
    self.yg_backButton.adjustsImageWhenHighlighted = NO;
    [self.yg_backButton addTarget:self action:@selector(yg_backButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.yg_leftContainerView addSubview:self.yg_backButton];

    self.yg_titleLabel = [[UILabel alloc] init];
    self.yg_titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.yg_titleLabel.textColor = UIColor.blackColor;
    self.yg_titleLabel.font = [UIFont boldSystemFontOfSize:18.0];
    self.yg_titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.yg_navigationBarView addSubview:self.yg_titleLabel];

    self.yg_rightContainerView = [[UIView alloc] init];
    self.yg_rightContainerView.translatesAutoresizingMaskIntoConstraints = NO;
    self.yg_rightContainerView.backgroundColor = UIColor.clearColor;
    [self.yg_navigationBarView addSubview:self.yg_rightContainerView];

    self.leftContainerWidthConstraint = [self.yg_leftContainerView.widthAnchor constraintEqualToConstant:44.0];
    [self attachCustomNavigationBarToHostViewIfNeeded];

    self.leftViewConstraints = @[
        [self.yg_backButton.topAnchor constraintEqualToAnchor:self.yg_leftContainerView.topAnchor],
        [self.yg_backButton.leadingAnchor constraintEqualToAnchor:self.yg_leftContainerView.leadingAnchor],
        [self.yg_backButton.trailingAnchor constraintEqualToAnchor:self.yg_leftContainerView.trailingAnchor],
        [self.yg_backButton.bottomAnchor constraintEqualToAnchor:self.yg_leftContainerView.bottomAnchor]
    ];

    NSMutableArray<NSLayoutConstraint *> *constraints = [NSMutableArray arrayWithArray:@[
        [self.yg_leftContainerView.leadingAnchor constraintEqualToAnchor:self.yg_navigationBarView.leadingAnchor constant:16.0],
        [self.yg_leftContainerView.bottomAnchor constraintEqualToAnchor:self.yg_navigationBarView.bottomAnchor],
        self.leftContainerWidthConstraint,
        [self.yg_leftContainerView.heightAnchor constraintEqualToConstant:44.0],

        [self.yg_titleLabel.centerXAnchor constraintEqualToAnchor:self.yg_navigationBarView.centerXAnchor],
        [self.yg_titleLabel.centerYAnchor constraintEqualToAnchor:self.yg_leftContainerView.centerYAnchor],
        [self.yg_titleLabel.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.yg_leftContainerView.trailingAnchor constant:12.0],
        [self.yg_titleLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.yg_rightContainerView.leadingAnchor constant:-12.0],

        [self.yg_rightContainerView.trailingAnchor constraintEqualToAnchor:self.yg_navigationBarView.trailingAnchor constant:-16.0],
        [self.yg_rightContainerView.centerYAnchor constraintEqualToAnchor:self.yg_leftContainerView.centerYAnchor],
        [self.yg_rightContainerView.heightAnchor constraintEqualToConstant:44.0]
    ]];
    [constraints addObjectsFromArray:self.leftViewConstraints];
    [NSLayoutConstraint activateConstraints:constraints];
}

- (void)setupKeyboardDismissGesture {
    self.keyboardDismissTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(keyboardDismissTapGestureRecognized:)];
    self.keyboardDismissTapGesture.cancelsTouchesInView = NO;
    self.keyboardDismissTapGesture.delegate = self;
    [self.view addGestureRecognizer:self.keyboardDismissTapGesture];
}

- (void)setYg_tapToDismissKeyboardEnabled:(BOOL)yg_tapToDismissKeyboardEnabled {
    _yg_tapToDismissKeyboardEnabled = yg_tapToDismissKeyboardEnabled;
    self.keyboardDismissTapGesture.enabled = yg_tapToDismissKeyboardEnabled;
}

- (void)keyboardDismissTapGestureRecognized:(UITapGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateEnded) {
        [self.view endEditing:YES];
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if (gestureRecognizer != self.keyboardDismissTapGesture) {
        return YES;
    }

    UIView *touchedView = touch.view;
    while (touchedView != nil && touchedView != self.view) {
        if ([touchedView isKindOfClass:UIControl.class]) {
            return NO;
        }
        if ([touchedView isKindOfClass:UITextView.class] || [touchedView isKindOfClass:UITextField.class]) {
            return NO;
        }
        touchedView = touchedView.superview;
    }
    return YES;
}

- (void)yg_updateScrollViewKeyboardDismissMode {
    [self applyKeyboardDismissModeInView:self.view];
}

- (void)applyKeyboardDismissModeInView:(UIView *)view {
    if ([view isKindOfClass:UIScrollView.class]) {
        ((UIScrollView *)view).keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    }

    for (UIView *subview in view.subviews) {
        [self applyKeyboardDismissModeInView:subview];
    }
}

- (void)updateNavigationBarHeight {
    CGFloat statusBarHeight = [self currentStatusBarHeight];
    self.navigationBarHeightConstraint.constant = self.yg_customNavigationBarHidden ? 0.0 : statusBarHeight + 44.0;
}

- (NSLayoutYAxisAnchor *)yg_navigationBarBottomAnchor {
    return self.yg_navigationBarView.bottomAnchor;
}

- (void)yg_setNavigationTitle:(NSString *)title {
    self.yg_titleLabel.text = title;
}

- (void)setTitle:(NSString *)title {
    [super setTitle:title];
    [self yg_setNavigationTitle:title];
}

- (void)setYg_customNavigationBarHidden:(BOOL)yg_customNavigationBarHidden {
    _yg_customNavigationBarHidden = yg_customNavigationBarHidden;
    [self updateCustomNavigationBarVisibility];
    [self updateNavigationBarHeight];
    [self updateAdditionalSafeAreaInsets];
}

- (void)yg_setLeftView:(UIView *)leftView {
    [NSLayoutConstraint deactivateConstraints:self.leftViewConstraints];
    self.leftViewConstraints = nil;

    for (UIView *subview in self.yg_leftContainerView.subviews) {
        [subview removeFromSuperview];
    }
    self.usesCustomLeftView = (leftView != nil);

    if (leftView == nil) {
        self.leftContainerWidthConstraint.constant = 44.0;
        [self.yg_leftContainerView addSubview:self.yg_backButton];
        self.yg_backButton.translatesAutoresizingMaskIntoConstraints = NO;
        self.leftViewConstraints = @[
            [self.yg_backButton.topAnchor constraintEqualToAnchor:self.yg_leftContainerView.topAnchor],
            [self.yg_backButton.leadingAnchor constraintEqualToAnchor:self.yg_leftContainerView.leadingAnchor],
            [self.yg_backButton.trailingAnchor constraintEqualToAnchor:self.yg_leftContainerView.trailingAnchor],
            [self.yg_backButton.bottomAnchor constraintEqualToAnchor:self.yg_leftContainerView.bottomAnchor]
        ];
        [NSLayoutConstraint activateConstraints:self.leftViewConstraints];
        [self updateBackButtonVisibility];
        return;
    }

    leftView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.yg_leftContainerView addSubview:leftView];
    CGFloat targetWidth = CGRectGetWidth(leftView.bounds);
    if (targetWidth <= 0.0) {
        targetWidth = [leftView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].width;
    }
    self.leftContainerWidthConstraint.constant = targetWidth > 0.0 ? targetWidth : 44.0;
    self.leftViewConstraints = @[
        [leftView.topAnchor constraintEqualToAnchor:self.yg_leftContainerView.topAnchor],
        [leftView.leadingAnchor constraintEqualToAnchor:self.yg_leftContainerView.leadingAnchor],
        [leftView.trailingAnchor constraintEqualToAnchor:self.yg_leftContainerView.trailingAnchor],
        [leftView.bottomAnchor constraintEqualToAnchor:self.yg_leftContainerView.bottomAnchor]
    ];
    [NSLayoutConstraint activateConstraints:self.leftViewConstraints];
}

- (void)yg_setRightView:(UIView *)rightView {
    [NSLayoutConstraint deactivateConstraints:self.rightViewConstraints];
    self.rightViewConstraints = nil;

    for (UIView *subview in self.yg_rightContainerView.subviews) {
        [subview removeFromSuperview];
    }
    if (rightView == nil) {
        return;
    }

    rightView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.yg_rightContainerView addSubview:rightView];
    self.rightViewConstraints = @[
        [rightView.topAnchor constraintEqualToAnchor:self.yg_rightContainerView.topAnchor],
        [rightView.leadingAnchor constraintEqualToAnchor:self.yg_rightContainerView.leadingAnchor],
        [rightView.trailingAnchor constraintEqualToAnchor:self.yg_rightContainerView.trailingAnchor],
        [rightView.bottomAnchor constraintEqualToAnchor:self.yg_rightContainerView.bottomAnchor],
        [self.yg_rightContainerView.widthAnchor constraintEqualToAnchor:rightView.widthAnchor]
    ];
    [NSLayoutConstraint activateConstraints:self.rightViewConstraints];
}

- (void)yg_backButtonTapped {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)updateBackButtonVisibility {
    if (self.usesCustomLeftView) {
        return;
    }
    self.yg_backButton.hidden = (self.navigationController.viewControllers.count <= 1);
}

- (void)updateAdditionalSafeAreaInsets {
    UIEdgeInsets insets = self.additionalSafeAreaInsets;
    insets.top = self.yg_customNavigationBarHidden ? 0.0 : 44.0;
    if (!UIEdgeInsetsEqualToEdgeInsets(self.additionalSafeAreaInsets, insets)) {
        self.additionalSafeAreaInsets = insets;
    }
}

- (void)attachCustomNavigationBarToHostViewIfNeeded {
    UIView *hostView = self.navigationController.view ?: self.view;
    if (hostView == nil || self.yg_navigationBarView.superview == hostView) {
        return;
    }

    [NSLayoutConstraint deactivateConstraints:self.navigationBarHostConstraints];
    [self.yg_navigationBarView removeFromSuperview];
    [hostView addSubview:self.yg_navigationBarView];

    self.navigationBarHostConstraints = @[
        [self.yg_navigationBarView.topAnchor constraintEqualToAnchor:hostView.topAnchor],
        [self.yg_navigationBarView.leadingAnchor constraintEqualToAnchor:hostView.leadingAnchor],
        [self.yg_navigationBarView.trailingAnchor constraintEqualToAnchor:hostView.trailingAnchor],
        self.navigationBarHeightConstraint
    ];
    [NSLayoutConstraint activateConstraints:self.navigationBarHostConstraints];
}

- (void)updateCustomNavigationBarVisibility {
    self.yg_navigationBarView.hidden = self.yg_customNavigationBarHidden;
}

- (CGFloat)currentStatusBarHeight {
    UIWindowScene *windowScene = self.view.window.windowScene;
    if (windowScene == nil) {
        for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
            if ([scene isKindOfClass:UIWindowScene.class]) {
                windowScene = (UIWindowScene *)scene;
                break;
            }
        }
    }
    return windowScene.statusBarManager.statusBarFrame.size.height;
}

@end
