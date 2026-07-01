//
//  YGCircleViewController.m
//  Yaga
//

#import "YGCircleViewController.h"
#import "YGPostsListCell.h"
#import "YGPostimagesViewController.h"
#import "YGPersonDetailViewController.h"
#import "YGImagePostStore.h"
#import "YGHUDHelper.h"
#import "YGUserStore.h"
#import "YGPopupAlertView.h"
#import "YGAppRouter.h"
#import "YGMoreActionSheetView.h"
#import "YGReportViewController.h"
#import "YGBlacklistStore.h"
#import "YGFollowStore.h"

NSString * const YGImagePostDidPublishNotification = @"YGImagePostDidPublishNotification";

@interface YGCircleViewController () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (nonatomic, strong) UIImageView *discoverImageView;
@property (nonatomic, strong) UIButton *addButton;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) NSArray<NSDictionary *> *items;
@property (nonatomic, assign) BOOL hasShownInitialLoading;
@property (nonatomic, assign) BOOL pendingPublishRefresh;

@end

@implementation YGCircleViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = UIColor.whiteColor;
    self.items = [[YGImagePostStore sharedStore] allPosts];
    [self setupNavigationItems];
    [self setupCollectionView];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(imagePostDidPublish:)
                                                 name:YGImagePostDidPublishNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(blacklistDidChange:)
                                                 name:YGBlacklistDidChangeNotification
                                               object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (!self.hasShownInitialLoading || self.pendingPublishRefresh) {
        self.hasShownInitialLoading = YES;
        self.pendingPublishRefresh = NO;
        [self showLoadingThenReloadData];
        return;
    }
    [self reloadData];
}

- (void)reloadData {
    self.items = [[YGImagePostStore sharedStore] allPosts];
    [self.collectionView reloadData];
}

- (void)imagePostDidPublish:(NSNotification *)notification {
    self.pendingPublishRefresh = YES;
}

- (void)blacklistDidChange:(NSNotification *)notification {
    [self reloadData];
}

- (void)showLoadingThenReloadData {
    self.collectionView.hidden = YES;
    [YGHUDHelper showLoadingAddedTo:self.view text:@"Loading..."];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)([self randomLoadingDelay] * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self reloadData];
        self.collectionView.hidden = NO;
        [YGHUDHelper hideLoadingForView:self.view];
    });
}

- (NSTimeInterval)randomLoadingDelay {
    return 1.0 + (NSTimeInterval)arc4random_uniform(2001) / 1000.0;
}

- (void)setupNavigationItems {
    UIImageView *discoverImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Discover"]];
    discoverImageView.translatesAutoresizingMaskIntoConstraints = NO;
    discoverImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.discoverImageView = discoverImageView;
    [discoverImageView.widthAnchor constraintEqualToConstant:133.0].active = YES;
    [discoverImageView.heightAnchor constraintEqualToConstant:44.0].active = YES;
    [self yg_setLeftView:discoverImageView];

    self.addButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.addButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.addButton.backgroundColor = UIColor.clearColor;
    self.addButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.addButton setImage:[UIImage imageNamed:@"circleadd"] forState:UIControlStateNormal];
    [self.addButton addTarget:self action:@selector(addButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.addButton.widthAnchor constraintEqualToConstant:44.0].active = YES;
    [self.addButton.heightAnchor constraintEqualToConstant:44.0].active = YES;
    [self yg_setRightView:self.addButton];
}

- (void)setupCollectionView {
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.minimumInteritemSpacing = 0.0;
    layout.minimumLineSpacing = 10.0;
    layout.sectionInset = UIEdgeInsetsMake(0.0, 20.0, 20.0, 20.0);

    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    self.collectionView.translatesAutoresizingMaskIntoConstraints = NO;
    self.collectionView.backgroundColor = UIColor.clearColor;
    self.collectionView.showsVerticalScrollIndicator = NO;
    self.collectionView.alwaysBounceVertical = YES;
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    if (@available(iOS 11.0, *)) {
        self.collectionView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
    [self.collectionView registerClass:YGPostsListCell.class forCellWithReuseIdentifier:YGPostsListCell.reuseIdentifier];
    [self.view addSubview:self.collectionView];

    [NSLayoutConstraint activateConstraints:@[
        [self.collectionView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:20.0],
        [self.collectionView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.collectionView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.collectionView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor]
    ]];
}

- (void)addButtonTapped {
    if ([self showLoginPromptIfNeeded]) {
        return;
    }
    YGPostimagesViewController *viewController = [[YGPostimagesViewController alloc] init];
    [self.navigationController pushViewController:viewController animated:YES];
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

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.items.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    YGPostsListCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:YGPostsListCell.reuseIdentifier forIndexPath:indexPath];
    NSDictionary *item = self.items[indexPath.item];
    [cell configureWithImagePost:item];
    BOOL isCurrentUserPost = [self isCurrentUserPost:item];
    [cell setMoreHidden:isCurrentUserPost];
    __weak typeof(self) weakSelf = self;
    cell.moreTapHandler = isCurrentUserPost ? nil : ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf == nil) {
            return;
        }
        [strongSelf showMoreActionsForItem:item];
    };
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat itemWidth = CGRectGetWidth(collectionView.bounds) - 40.0;
    CGFloat itemHeight = itemWidth * 318.0 / 335.0;
    return CGSizeMake(itemWidth, itemHeight);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    YGPersonDetailViewController *viewController = [[YGPersonDetailViewController alloc] initWithItem:self.items[indexPath.item]];
    [self.navigationController pushViewController:viewController animated:YES];
}

- (BOOL)isCurrentUserPost:(NSDictionary *)item {
    NSString *currentUserId = [[YGUserStore sharedStore] currentUserEmail];
    NSString *postUserId = [item[@"userId"] isKindOfClass:NSString.class] ? item[@"userId"] : @"";
    return currentUserId.length > 0 && [postUserId isEqualToString:currentUserId];
}

- (void)showMoreActionsForItem:(NSDictionary *)item {
    if ([self showLoginPromptIfNeeded]) {
        return;
    }

    UIView *targetView = self.navigationController.view ?: self.view;
    __weak typeof(self) weakSelf = self;
    [YGMoreActionSheetView showInView:targetView reportHandler:^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf == nil) {
            return;
        }
        YGReportViewController *viewController = [[YGReportViewController alloc] init];
        [strongSelf.navigationController pushViewController:viewController animated:YES];
    } blockHandler:^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf == nil) {
            return;
        }
        [[YGBlacklistStore sharedStore] addBlockedUser:item];
        NSString *userId = [item[@"userId"] isKindOfClass:NSString.class] ? item[@"userId"] : @"";
        if (userId.length > 0) {
            [[YGFollowStore sharedStore] unfollowUserId:userId];
        }
        [strongSelf reloadData];
        [YGHUDHelper showCenterText:@"Block successful." inView:targetView];
    }];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
