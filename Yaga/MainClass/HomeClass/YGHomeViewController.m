//
//  YGHomeViewController.m
//  Yaga
//

#import "YGHomeViewController.h"
#import "YGUserStore.h"
#import "YGSlidingPageView.h"
#import "YGHomeMainListViewController.h"
#import "YGSubmitViewController.h"
#import "YGPostVideoSubmitViewController.h"
#import "YGHUDHelper.h"
#import "YGPopupAlertView.h"
#import "YGAppRouter.h"
#import "YGImagePostStore.h"
#import "YGVideoPostStore.h"

NSString * const YGVideoPostDidPublishNotification = @"YGVideoPostDidPublishNotification";

@interface YGHomeViewController ()

@property (nonatomic, strong) UIImageView *logoImageView;
@property (nonatomic, strong) UIImageView *topImageView;
@property (nonatomic, strong) YGSlidingPageView *mainPageView;
@property (nonatomic, strong) UIButton *avatarButton;
@property (nonatomic, strong) UIView *avatarContainerView;
@property (nonatomic, strong) UIImageView *avatarImageView;
@property (nonatomic, strong) UIButton *floatingAddButton;
@property (nonatomic, assign) BOOL hasPositionedFloatingAddButton;
@property (nonatomic, copy) NSArray<YGHomeMainListViewController *> *listViewControllers;
@property (nonatomic, assign) BOOL hasShownInitialLoading;
@property (nonatomic, assign) BOOL pendingPublishRefresh;

@end

@implementation YGHomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = UIColor.whiteColor;
    [self setupNavigationItems];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(videoPostDidPublish:)
                                                 name:YGVideoPostDidPublishNotification
                                               object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self updateAvatarImage];
    if (!self.hasShownInitialLoading || self.pendingPublishRefresh) {
        self.hasShownInitialLoading = YES;
        self.pendingPublishRefresh = NO;
        [self showLoadingThenReloadLists];
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self layoutAvatarContent];
    [self layoutFloatingAddButtonIfNeeded];
}

- (void)setupTitleLabelWithText:(NSString *)text {
    UILabel *label = [[UILabel alloc] init];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.text = text;
    label.textColor = UIColor.blackColor;
    label.font = [UIFont boldSystemFontOfSize:24.0];
    label.textAlignment = NSTextAlignmentCenter;
    
    [self.view addSubview:label];
    [NSLayoutConstraint activateConstraints:@[
        [label.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [label.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor]
    ]];
}

- (void)setupNavigationItems {
    if (self.avatarButton != nil) {
        [self updateAvatarImage];
        return;
    }

    UIImageView *logoImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Yaga"]];
    logoImageView.translatesAutoresizingMaskIntoConstraints = NO;
    logoImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.logoImageView = logoImageView;
    [logoImageView.widthAnchor constraintEqualToConstant:75.0].active = YES;
    [logoImageView.heightAnchor constraintEqualToConstant:44.0].active = YES;
    [self yg_setLeftView:logoImageView];

    UIImageView *topImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"hometop"]];
    topImageView.translatesAutoresizingMaskIntoConstraints = NO;
    topImageView.contentMode = UIViewContentModeScaleAspectFill;
//    topImageView.clipsToBounds = YES;
    topImageView.userInteractionEnabled = YES;
    UITapGestureRecognizer *topTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(topImageTapped)];
    [topImageView addGestureRecognizer:topTapGesture];
    [self.view addSubview:topImageView];
    self.topImageView = topImageView;

    [NSLayoutConstraint activateConstraints:@[
        [topImageView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:20.0],
        [topImageView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20.0],
        [topImageView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20.0]
    ]];

    NSArray<NSString *> *titles = @[@"Trends", @"Newest", @"Follow"];
    YGHomeMainListViewController *trendsViewController = [[YGHomeMainListViewController alloc] initWithTitleText:titles[0]];
    YGHomeMainListViewController *newestViewController = [[YGHomeMainListViewController alloc] initWithTitleText:titles[1]];
    YGHomeMainListViewController *followViewController = [[YGHomeMainListViewController alloc] initWithTitleText:titles[2]];
    self.listViewControllers = @[trendsViewController, newestViewController, followViewController];
    YGSlidingPageView *mainPageView = [[YGSlidingPageView alloc] initWithTitles:titles
                                                                viewControllers:@[trendsViewController, newestViewController, followViewController]
                                                           parentViewController:self];
    mainPageView.translatesAutoresizingMaskIntoConstraints = NO;
    mainPageView.horizontalInset = 20.0;
    mainPageView.titleIndicatorSpacing = 8.0;
    [self.view addSubview:mainPageView];
    self.mainPageView = mainPageView;

    [NSLayoutConstraint activateConstraints:@[
        [mainPageView.topAnchor constraintEqualToAnchor:topImageView.bottomAnchor constant:20.0],
        [mainPageView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [mainPageView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [mainPageView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor]
    ]];

    CGFloat avatarSize = 44.0;

    self.avatarButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.avatarButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.avatarButton.backgroundColor = UIColor.clearColor;

    self.avatarContainerView = [[UIView alloc] initWithFrame:self.avatarButton.bounds];
    self.avatarContainerView.userInteractionEnabled = NO;
    self.avatarContainerView.backgroundColor = UIColor.whiteColor;
    self.avatarContainerView.layer.cornerRadius = avatarSize / 2.0;
    self.avatarContainerView.clipsToBounds = YES;
    [self.avatarButton addSubview:self.avatarContainerView];

    self.avatarImageView = [[UIImageView alloc] initWithFrame:self.avatarContainerView.bounds];
    self.avatarImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.avatarImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.avatarImageView.clipsToBounds = YES;
    [self.avatarContainerView addSubview:self.avatarImageView];

    [self.avatarButton.widthAnchor constraintEqualToConstant:avatarSize].active = YES;
    [self.avatarButton.heightAnchor constraintEqualToConstant:avatarSize].active = YES;
    [self yg_setRightView:self.avatarButton];
    [self updateAvatarImage];
    [self setupFloatingAddButton];
}

- (void)layoutAvatarContent {
    if (self.avatarButton == nil) {
        return;
    }

    CGFloat avatarSize = CGRectGetWidth(self.avatarButton.bounds);
    self.avatarContainerView.frame = self.avatarButton.bounds;
    self.avatarContainerView.layer.cornerRadius = avatarSize / 2.0;
    self.avatarImageView.frame = self.avatarContainerView.bounds;
}

- (void)setupFloatingAddButton {
    if (self.floatingAddButton != nil) {
        return;
    }

    CGFloat buttonSize = 44.0;
    self.floatingAddButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.floatingAddButton.frame = CGRectMake(0.0, 0.0, buttonSize, buttonSize);
    self.floatingAddButton.backgroundColor = UIColor.clearColor;
    self.floatingAddButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.floatingAddButton setImage:[UIImage imageNamed:@"circleadd"] forState:UIControlStateNormal];
    [self.floatingAddButton addTarget:self action:@selector(floatingAddButtonTapped) forControlEvents:UIControlEventTouchUpInside];

    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleFloatingAddPan:)];
    [self.floatingAddButton addGestureRecognizer:panGesture];

    [self.view addSubview:self.floatingAddButton];
}

- (void)layoutFloatingAddButtonIfNeeded {
    if (self.floatingAddButton == nil) {
        return;
    }

    [self.view bringSubviewToFront:self.floatingAddButton];

    if (!self.hasPositionedFloatingAddButton) {
        CGFloat buttonSize = CGRectGetWidth(self.floatingAddButton.bounds);
        CGFloat bottomInset = 30.0;
        UIEdgeInsets safeInsets = self.view.safeAreaInsets;
        CGFloat x = CGRectGetWidth(self.view.bounds) - safeInsets.right - buttonSize;
        CGFloat y = CGRectGetHeight(self.view.bounds) - safeInsets.bottom - bottomInset - buttonSize;
        self.floatingAddButton.frame = CGRectMake(x, y, buttonSize, buttonSize);
        self.hasPositionedFloatingAddButton = YES;
        return;
    }

    self.floatingAddButton.center = [self clampedFloatingAddCenter:self.floatingAddButton.center];
}

- (void)handleFloatingAddPan:(UIPanGestureRecognizer *)gestureRecognizer {
    UIView *button = self.floatingAddButton;
    CGPoint translation = [gestureRecognizer translationInView:self.view];
    CGPoint targetCenter = CGPointMake(button.center.x + translation.x, button.center.y + translation.y);
    button.center = [self clampedFloatingAddCenter:targetCenter];
    [gestureRecognizer setTranslation:CGPointZero inView:self.view];

    if (gestureRecognizer.state == UIGestureRecognizerStateEnded ||
        gestureRecognizer.state == UIGestureRecognizerStateCancelled ||
        gestureRecognizer.state == UIGestureRecognizerStateFailed) {
        [self dockFloatingAddButton];
    }
}

- (CGPoint)clampedFloatingAddCenter:(CGPoint)center {
    CGFloat halfWidth = CGRectGetWidth(self.floatingAddButton.bounds) / 2.0;
    CGFloat halfHeight = CGRectGetHeight(self.floatingAddButton.bounds) / 2.0;
    UIEdgeInsets safeInsets = self.view.safeAreaInsets;
    CGFloat minX = safeInsets.left + halfWidth;
    CGFloat maxX = CGRectGetWidth(self.view.bounds) - safeInsets.right - halfWidth;
    CGFloat minY = safeInsets.top + halfHeight;
    CGFloat maxY = CGRectGetHeight(self.view.bounds) - safeInsets.bottom - halfHeight;

    center.x = MIN(MAX(center.x, minX), maxX);
    center.y = MIN(MAX(center.y, minY), maxY);
    return center;
}

- (void)dockFloatingAddButton {
    CGFloat halfWidth = CGRectGetWidth(self.floatingAddButton.bounds) / 2.0;
    UIEdgeInsets safeInsets = self.view.safeAreaInsets;
    CGFloat leftCenterX = safeInsets.left + halfWidth;
    CGFloat rightCenterX = CGRectGetWidth(self.view.bounds) - safeInsets.right - halfWidth;
    CGFloat targetX = self.floatingAddButton.center.x < CGRectGetMidX(self.view.bounds) ? leftCenterX : rightCenterX;
    CGPoint targetCenter = [self clampedFloatingAddCenter:CGPointMake(targetX, self.floatingAddButton.center.y)];

    [UIView animateWithDuration:0.25
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
        self.floatingAddButton.center = targetCenter;
    } completion:nil];
}

- (void)floatingAddButtonTapped {
    if ([self showLoginPromptIfNeeded]) {
        return;
    }
    YGPostVideoSubmitViewController *viewController = [[YGPostVideoSubmitViewController alloc] init];
    [self.navigationController pushViewController:viewController animated:YES];
}

- (void)topImageTapped {
    YGSubmitViewController *viewController = [[YGSubmitViewController alloc] init];
    [self.navigationController pushViewController:viewController animated:YES];
}

- (void)videoPostDidPublish:(NSNotification *)notification {
    self.pendingPublishRefresh = YES;
    for (YGHomeMainListViewController *viewController in self.listViewControllers) {
        viewController.suppressAutomaticReload = YES;
    }
}

- (void)showLoadingThenReloadLists {
    self.mainPageView.hidden = YES;
    [YGHUDHelper showLoadingAddedTo:self.view text:@"Loading..."];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)([self randomLoadingDelay] * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        for (YGHomeMainListViewController *viewController in self.listViewControllers) {
            viewController.suppressAutomaticReload = NO;
            [viewController reloadData];
        }
        self.mainPageView.hidden = NO;
        [YGHUDHelper hideLoadingForView:self.view];
    });
}

- (NSTimeInterval)randomLoadingDelay {
    return 1.0 + (NSTimeInterval)arc4random_uniform(2001) / 1000.0;
}

- (void)updateAvatarImage {
    BOOL isGuest = [[YGUserStore sharedStore] isGuestMode];
    self.avatarButton.hidden = isGuest;
    self.yg_rightContainerView.hidden = isGuest;
    if (isGuest) {
        return;
    }
    self.avatarImageView.image = [self currentAvatarImage];
}

- (BOOL)showLoginPromptIfNeeded {
    if (![[YGUserStore sharedStore] isGuestMode]) {
        return NO;
    }

    UIView *targetView = self.navigationController.view ?: self.view;
    [YGPopupAlertView showInView:targetView
                        iconName:@"hint.png"
                         message:@"You are not logged in.\nPlease log in and try again."
                 leftButtonTitle:@"Cancel"
                rightButtonTitle:@"OK"
             rightButtonHandler:^{
        [YGAppRouter switchToLoginInterface];
    }];
    return YES;
}

- (UIImage *)currentAvatarImage {
    NSDictionary *currentUser = [[YGUserStore sharedStore] currentUser];
    NSString *avatarLocalPath = currentUser[@"avatarLocalPath"];
    if (avatarLocalPath.length > 0) {
        UIImage *image = [UIImage imageWithContentsOfFile:avatarLocalPath];
        if (image != nil) {
            return image;
        }
    }

    NSString *avatarBase64 = currentUser[@"avatarDataBase64"];
    if (avatarBase64.length > 0) {
        NSData *imageData = [[NSData alloc] initWithBase64EncodedString:avatarBase64 options:0];
        UIImage *image = [UIImage imageWithData:imageData];
        if (image != nil) {
            return image;
        }
    }

    NSString *avatarImageName = currentUser[@"avatarImageName"];
    if (avatarImageName.length > 0) {
        UIImage *image = [[YGImagePostStore sharedStore] imageInPostResourcesNamed:avatarImageName];
        if (image != nil) {
            return image;
        }
        image = [[YGVideoPostStore sharedStore] imageInVideoResourcesNamed:avatarImageName];
        if (image != nil) {
            return image;
        }
    }

    NSString *avatarName = currentUser[@"avatarName"];
    if (avatarName.length > 0) {
        UIImage *image = [UIImage imageNamed:avatarName];
        if (image != nil) {
            return image;
        }
    }

    return [UIImage imageNamed:@"headplace"];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
