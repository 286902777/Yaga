//
//  YGPersonProfileViewController.m
//  Yaga
//

#import "YGPersonProfileViewController.h"
#import "YGSlidingPageView.h"
#import "YGPostsListViewController.h"
#import "YGChatDetailViewController.h"
#import "YGMoreActionSheetView.h"
#import "YGReportViewController.h"
#import "YGPopupAlertView.h"
#import "YGBlacklistViewController.h"
#import "YGImagePostStore.h"
#import "YGVideoPostStore.h"
#import "YGFollowStore.h"
#import "YGBlacklistStore.h"
#import "YGHUDHelper.h"
#import "YGUserStore.h"

@interface YGPersonProfileViewController ()

@property (nonatomic, copy) NSDictionary *userInfo;
@property (nonatomic, strong) UIImageView *avatarImageView;
@property (nonatomic, strong) UIView *firstInfoView;
@property (nonatomic, strong) UIView *secondInfoView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UIButton *followButton;
@property (nonatomic, strong) UIButton *chatButton;
@property (nonatomic, strong) UIButton *rightIconButton;
@property (nonatomic, strong) YGSlidingPageView *postsPageView;
@property (nonatomic, strong) UILabel *followingCountLabel;
@property (nonatomic, strong) UILabel *followersCountLabel;

@end

@implementation YGPersonProfileViewController

- (instancetype)initWithUserInfo:(NSDictionary *)userInfo {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _userInfo = [userInfo copy];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = UIColor.whiteColor;
    [self setupNavigationItems];
    [self setupProfileContent];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self updateSelfProfileVisibility];
    [self updateFollowState];
}

- (void)setupNavigationItems {
    self.rightIconButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.rightIconButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.rightIconButton.backgroundColor = UIColor.clearColor;
    self.rightIconButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.rightIconButton setImage:[UIImage imageNamed:@"whitemore"] forState:UIControlStateNormal];
    [self.rightIconButton addTarget:self action:@selector(moreButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.rightIconButton.widthAnchor constraintEqualToConstant:44.0].active = YES;
    [self.rightIconButton.heightAnchor constraintEqualToConstant:44.0].active = YES;
    [self yg_setRightView:self.rightIconButton];
    [self updateSelfProfileVisibility];
}

- (void)setupProfileContent {
    self.avatarImageView = [[UIImageView alloc] initWithImage:[self avatarImage]];
    self.avatarImageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.avatarImageView.backgroundColor = UIColor.whiteColor;
    self.avatarImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.avatarImageView.clipsToBounds = YES;
    self.avatarImageView.layer.cornerRadius = 44.0;
    [self.view addSubview:self.avatarImageView];

    self.firstInfoView = [self infoViewWithTopText:@"0" bottomText:@"Following" topLabel:&_followingCountLabel];
    self.secondInfoView = [self infoViewWithTopText:@"0" bottomText:@"Followers" topLabel:&_followersCountLabel];
    [self.view addSubview:self.firstInfoView];
    [self.view addSubview:self.secondInfoView];

    self.nameLabel = [[UILabel alloc] init];
    self.nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.nameLabel.text = [self userName];
    self.nameLabel.textColor = UIColor.blackColor;
    self.nameLabel.font = [UIFont boldSystemFontOfSize:24.0];
    [self.view addSubview:self.nameLabel];

    self.chatButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.chatButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.chatButton.backgroundColor = UIColor.whiteColor;
    self.chatButton.layer.cornerRadius = 16.0;
    self.chatButton.clipsToBounds = YES;
    [self.chatButton setTitle:@"Chat" forState:UIControlStateNormal];
    [self.chatButton setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
    self.chatButton.titleLabel.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightBold];
    [self.chatButton addTarget:self action:@selector(chatButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.chatButton];

    self.followButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.followButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.followButton.backgroundColor = [self colorWithHexString:@"#B829FF"];
    self.followButton.layer.cornerRadius = 16.0;
    self.followButton.clipsToBounds = YES;
    [self.followButton setTitle:@"+Follow" forState:UIControlStateNormal];
    [self.followButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    self.followButton.titleLabel.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightBold];
    [self.followButton addTarget:self action:@selector(followButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.followButton];

    NSArray<NSString *> *titles = @[@"Posts", @"Videos"];
    YGPostsListViewController *postsViewController = [[YGPostsListViewController alloc] initWithTitleText:titles[0] userId:[self userId]];
    YGPostsListViewController *videosViewController = [[YGPostsListViewController alloc] initWithTitleText:titles[1] userId:[self userId]];
    YGSlidingPageView *postsPageView = [[YGSlidingPageView alloc] initWithTitles:titles
                                                                  viewControllers:@[postsViewController, videosViewController]
                                                             parentViewController:self];
    postsPageView.translatesAutoresizingMaskIntoConstraints = NO;
    postsPageView.horizontalInset = 20.0;
    postsPageView.titleIndicatorSpacing = 8.0;
    [self.view addSubview:postsPageView];
    self.postsPageView = postsPageView;

    [NSLayoutConstraint activateConstraints:@[
        [self.avatarImageView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:30.0],
        [self.avatarImageView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:15.0],
        [self.avatarImageView.widthAnchor constraintEqualToConstant:88.0],
        [self.avatarImageView.heightAnchor constraintEqualToConstant:88.0],

        [self.firstInfoView.leadingAnchor constraintEqualToAnchor:self.avatarImageView.trailingAnchor constant:15.0],
        [self.firstInfoView.centerYAnchor constraintEqualToAnchor:self.avatarImageView.centerYAnchor],
        [self.secondInfoView.leadingAnchor constraintEqualToAnchor:self.firstInfoView.trailingAnchor],
        [self.secondInfoView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-15.0],
        [self.secondInfoView.centerYAnchor constraintEqualToAnchor:self.avatarImageView.centerYAnchor],
        [self.secondInfoView.widthAnchor constraintEqualToAnchor:self.firstInfoView.widthAnchor],
        [self.firstInfoView.heightAnchor constraintEqualToConstant:58.0],
        [self.secondInfoView.heightAnchor constraintEqualToAnchor:self.firstInfoView.heightAnchor],

        [self.nameLabel.topAnchor constraintEqualToAnchor:self.avatarImageView.bottomAnchor constant:10.0],
        [self.nameLabel.centerXAnchor constraintEqualToAnchor:self.avatarImageView.centerXAnchor],
        [self.nameLabel.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.view.leadingAnchor constant:15.0],
        [self.nameLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.followButton.leadingAnchor constant:-12.0],

        [self.chatButton.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-15.0],
        [self.chatButton.centerYAnchor constraintEqualToAnchor:self.nameLabel.centerYAnchor],
        [self.chatButton.widthAnchor constraintEqualToConstant:68.0],
        [self.chatButton.heightAnchor constraintEqualToConstant:32.0],

        [self.followButton.trailingAnchor constraintEqualToAnchor:self.chatButton.leadingAnchor constant:-10.0],
        [self.followButton.centerYAnchor constraintEqualToAnchor:self.nameLabel.centerYAnchor],
        [self.followButton.widthAnchor constraintEqualToConstant:88.0],
        [self.followButton.heightAnchor constraintEqualToConstant:32.0],

        [self.postsPageView.topAnchor constraintEqualToAnchor:self.nameLabel.bottomAnchor constant:20.0],
        [self.postsPageView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.postsPageView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.postsPageView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor]
    ]];
    [self updateSelfProfileVisibility];
    [self updateFollowState];
}

- (UIView *)infoViewWithTopText:(NSString *)topText bottomText:(NSString *)bottomText {
    UILabel *unusedLabel = nil;
    return [self infoViewWithTopText:topText bottomText:bottomText topLabel:&unusedLabel];
}

- (UIView *)infoViewWithTopText:(NSString *)topText bottomText:(NSString *)bottomText topLabel:(UILabel * __strong *)topLabelPointer {
    UIView *containerView = [[UIView alloc] init];
    containerView.translatesAutoresizingMaskIntoConstraints = NO;
    containerView.backgroundColor = UIColor.clearColor;

    UILabel *bottomLabel = [[UILabel alloc] init];
    bottomLabel.translatesAutoresizingMaskIntoConstraints = NO;
    bottomLabel.text = bottomText;
    bottomLabel.textColor = [self colorWithHexString:@"#808080"];
    bottomLabel.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightRegular];
    bottomLabel.textAlignment = NSTextAlignmentCenter;
    [containerView addSubview:bottomLabel];

    UILabel *topLabel = [[UILabel alloc] init];
    topLabel.translatesAutoresizingMaskIntoConstraints = NO;
    topLabel.text = topText;
    topLabel.textColor = UIColor.blackColor;
    topLabel.font = [UIFont boldSystemFontOfSize:18.0];
    [containerView addSubview:topLabel];
    if (topLabelPointer != NULL) {
        *topLabelPointer = topLabel;
    }

    [NSLayoutConstraint activateConstraints:@[
        [bottomLabel.centerXAnchor constraintEqualToAnchor:containerView.centerXAnchor],
        [bottomLabel.centerYAnchor constraintEqualToAnchor:containerView.centerYAnchor constant:12.0],
        [bottomLabel.leadingAnchor constraintGreaterThanOrEqualToAnchor:containerView.leadingAnchor],
        [bottomLabel.trailingAnchor constraintLessThanOrEqualToAnchor:containerView.trailingAnchor],

        [topLabel.leadingAnchor constraintEqualToAnchor:bottomLabel.leadingAnchor],
        [topLabel.bottomAnchor constraintEqualToAnchor:bottomLabel.topAnchor constant:-4.0],
        [topLabel.trailingAnchor constraintLessThanOrEqualToAnchor:containerView.trailingAnchor]
    ]];

    return containerView;
}

- (void)chatButtonTapped {
    if ([self isCurrentLoginUser]) {
        return;
    }
    if ([[YGFollowStore sharedStore] isMutualFollowingUserId:[self userId]]) {
        [self pushChatDetail];
        return;
    }

    UIView *targetView = self.navigationController.view ?: self.view;
    [YGPopupAlertView showInView:targetView
                        iconName:@"hint.png"
                         message:@"You can only chat after following\neach other."
                 leftButtonTitle:@"Cancel"
                rightButtonTitle:@"Get it"
             rightButtonHandler:nil];
}

- (void)pushChatDetail {
    NSMutableDictionary *chatUserInfo = [@{
        @"userId": [self userId],
        @"name": [self userName],
        @"imageName": [self avatarName],
        @"avatarName": [self avatarName],
        @"avatarLocalPath": [self stringValueForKey:@"avatarLocalPath"],
        @"avatarDataBase64": [self stringValueForKey:@"avatarDataBase64"],
        @"avatarImageName": [self stringValueForKey:@"avatarImageName"],
        @"contentImageName": [self stringValueForKey:@"contentImageName"]
    } mutableCopy];
    UIImage *avatarImage = [self avatarImage];
    if (avatarImage != nil) {
        chatUserInfo[@"avatarImage"] = avatarImage;
    }
    YGChatDetailViewController *viewController = [[YGChatDetailViewController alloc] initWithUserInfo:chatUserInfo];
    [self.navigationController pushViewController:viewController animated:YES];
}

- (void)followButtonTapped {
    if ([self isCurrentLoginUser]) {
        return;
    }
    if ([[YGFollowStore sharedStore] isFollowingUserId:[self userId]]) {
        [[YGFollowStore sharedStore] unfollowUserId:[self userId]];
    } else {
        [[YGFollowStore sharedStore] followUserId:[self userId]];
    }
    [self updateFollowState];
}

- (void)followCurrentUserIfNeeded {
    if ([self isCurrentLoginUser]) {
        return;
    }
    [[YGFollowStore sharedStore] followUserId:[self userId]];
    [self updateFollowState];
}

- (void)updateFollowState {
    NSString *profileUserId = [self userId];
    self.followersCountLabel.text = [NSString stringWithFormat:@"%ld", (long)[[YGFollowStore sharedStore] visibleFollowersCountForUserId:profileUserId]];
    self.followingCountLabel.text = [NSString stringWithFormat:@"%ld", (long)[[YGFollowStore sharedStore] visibleFollowingCountForUserId:profileUserId]];
    if ([self isCurrentLoginUser]) {
        return;
    }
    BOOL followed = [[YGFollowStore sharedStore] isFollowingUserId:profileUserId];
    if (followed) {
        self.followButton.backgroundColor = UIColor.whiteColor;
        [self.followButton setTitle:@"Followed" forState:UIControlStateNormal];
        [self.followButton setTitleColor:[self colorWithHexString:@"#B829FF"] forState:UIControlStateNormal];
    } else {
        self.followButton.backgroundColor = [self colorWithHexString:@"#B829FF"];
        [self.followButton setTitle:@"+Follow" forState:UIControlStateNormal];
        [self.followButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    }
}

- (void)moreButtonTapped {
    if ([self isCurrentLoginUser]) {
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
        [[YGBlacklistStore sharedStore] addBlockedUser:strongSelf.userInfo];
        [[YGFollowStore sharedStore] unfollowUserId:[strongSelf userId]];
        [strongSelf updateFollowState];
        [YGHUDHelper showCenterText:@"Block successful." inView:targetView];
        [strongSelf.navigationController popToRootViewControllerAnimated:YES];
    }];
}

- (void)updateSelfProfileVisibility {
    BOOL isSelf = [self isCurrentLoginUser];
    self.followButton.hidden = isSelf;
    self.chatButton.hidden = isSelf;
    self.rightIconButton.hidden = isSelf;
    self.yg_rightContainerView.hidden = isSelf;
}

- (NSString *)avatarName {
    NSString *avatarName = self.userInfo[@"avatarName"];
    return avatarName.length > 0 ? avatarName : @"headplace";
}

- (NSString *)userId {
    NSString *userId = self.userInfo[@"userId"];
    if (userId.length > 0) {
        return userId;
    }
    NSString *userName = [self userName].lowercaseString;
    return userName.length > 0 ? [@"default_user_" stringByAppendingString:userName] : @"default_user_unknown";
}

- (BOOL)isCurrentLoginUser {
    NSString *currentUserId = [[YGUserStore sharedStore] currentUserEmail];
    return currentUserId.length > 0 && [[self userId] isEqualToString:currentUserId];
}

- (UIImage *)avatarImage {
    UIImage *avatarImage = [[YGImagePostStore sharedStore] avatarImageForPost:self.userInfo];
    if (avatarImage != nil) {
        return avatarImage;
    }
    avatarImage = [[YGVideoPostStore sharedStore] avatarImageForPost:self.userInfo];
    if (avatarImage != nil) {
        return avatarImage;
    }
    return [UIImage imageNamed:[self avatarName]];
}

- (NSString *)userName {
    NSString *userName = self.userInfo[@"userName"];
    return userName.length > 0 ? userName : @"Allan";
}

- (NSString *)stringValueForKey:(NSString *)key {
    NSString *value = self.userInfo[key];
    return [value isKindOfClass:NSString.class] ? value : @"";
}

- (UIColor *)colorWithHexString:(NSString *)hexString {
    NSString *cleanString = [[hexString stringByReplacingOccurrencesOfString:@"#" withString:@""] uppercaseString];
    unsigned int value = 0;
    [[NSScanner scannerWithString:cleanString] scanHexInt:&value];
    return [UIColor colorWithRed:((value >> 16) & 0xFF) / 255.0
                           green:((value >> 8) & 0xFF) / 255.0
                            blue:(value & 0xFF) / 255.0
                           alpha:1.0];
}

@end
