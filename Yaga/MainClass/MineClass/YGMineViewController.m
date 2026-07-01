//
//  YGMineViewController.m
//  Yaga
//

#import "YGMineViewController.h"
#import "YGAppRouter.h"
#import "YGSettingViewController.h"
#import "YGSlidingPageView.h"
#import "YGPostsListViewController.h"
#import "YGPersonMessageViewController.h"
#import "YGUserStore.h"
#import "YGFollowListViewController.h"
#import "YGRechargeViewController.h"
#import "YGFollowStore.h"
#import "YGImagePostStore.h"
#import "YGVideoPostStore.h"
@interface YGMineViewController ()

@property (nonatomic, strong) UIImageView *avatarImageView;
@property (nonatomic, strong) UIView *firstInfoView;
@property (nonatomic, strong) UIView *secondInfoView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UIButton *editButton;
@property (nonatomic, strong) UIImageView *rechargeImageView;
@property (nonatomic, strong) UILabel *rechargeTitleLabel;
@property (nonatomic, strong) UILabel *rechargeSubtitleLabel;
@property (nonatomic, strong) YGSlidingPageView *postsPageView;
@property (nonatomic, strong) UILabel *followingCountLabel;
@property (nonatomic, strong) UILabel *followersCountLabel;

@end

@implementation YGMineViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = UIColor.whiteColor;
    [self setupNavigationItems];
    [self setupProfileHeader];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.avatarImageView.image = [self currentAvatarImage];
    self.nameLabel.text = [self currentUserName];
    [self updateFollowCounts];
    [self updateBalanceText];
}

- (void)setupNavigationItems {
    UIButton *settingButton = [UIButton buttonWithType:UIButtonTypeCustom];
    settingButton.translatesAutoresizingMaskIntoConstraints = NO;
    [settingButton setImage:[UIImage imageNamed:@"minesetting"] forState:UIControlStateNormal];
    settingButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [settingButton addTarget:self action:@selector(settingButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [settingButton.widthAnchor constraintEqualToConstant:32.0].active = YES;
    [settingButton.heightAnchor constraintEqualToConstant:32.0].active = YES;
    [self yg_setRightView:settingButton];
}

- (void)setupProfileHeader {
    self.avatarImageView = [[UIImageView alloc] initWithImage:[self currentAvatarImage]];
    self.avatarImageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.avatarImageView.backgroundColor = UIColor.whiteColor;
    self.avatarImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.avatarImageView.clipsToBounds = YES;
    self.avatarImageView.layer.cornerRadius = 44.0;
    [self.view addSubview:self.avatarImageView];

    self.firstInfoView = [self infoViewWithTopText:@"0" bottomText:@"Following" topLabel:&_followingCountLabel];
    self.secondInfoView = [self infoViewWithTopText:@"0" bottomText:@"Followers" topLabel:&_followersCountLabel];
    self.firstInfoView.userInteractionEnabled = YES;
    self.secondInfoView.userInteractionEnabled = YES;
    [self.firstInfoView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(followingInfoViewTapped)]];
    [self.secondInfoView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(followersInfoViewTapped)]];
    [self.view addSubview:self.firstInfoView];
    [self.view addSubview:self.secondInfoView];

    self.nameLabel = [[UILabel alloc] init];
    self.nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.nameLabel.text = [self currentUserName];
    self.nameLabel.textColor = UIColor.blackColor;
    self.nameLabel.font = [UIFont boldSystemFontOfSize:24.0];
    [self.view addSubview:self.nameLabel];

    self.editButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.editButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.editButton.backgroundColor = [self colorWithHexString:@"#B829FF"];
    self.editButton.layer.cornerRadius = 16.0;
    self.editButton.clipsToBounds = YES;
    [self.editButton setTitle:@"Edit" forState:UIControlStateNormal];
    [self.editButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    self.editButton.titleLabel.font = [UIFont systemFontOfSize:16.0 weight:UIFontWeightBold];
    [self.editButton addTarget:self action:@selector(editButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.editButton];

    self.rechargeImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"rechtop"]];
    self.rechargeImageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.rechargeImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.rechargeImageView.clipsToBounds = YES;
    self.rechargeImageView.userInteractionEnabled = YES;
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(rechargeImageTapped)];
    [self.rechargeImageView addGestureRecognizer:tapGesture];
    [self.view addSubview:self.rechargeImageView];

    self.rechargeTitleLabel = [[UILabel alloc] init];
    self.rechargeTitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.rechargeTitleLabel.textColor = UIColor.whiteColor;
    self.rechargeTitleLabel.font = [UIFont systemFontOfSize:18.0 weight:UIFontWeightHeavy];
    [self.rechargeImageView addSubview:self.rechargeTitleLabel];

    self.rechargeSubtitleLabel = [[UILabel alloc] init];
    self.rechargeSubtitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.rechargeSubtitleLabel.text = @"Balance";
    self.rechargeSubtitleLabel.textColor = UIColor.whiteColor;
    self.rechargeSubtitleLabel.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightRegular];
    [self.rechargeImageView addSubview:self.rechargeSubtitleLabel];

    NSArray<NSString *> *titles = @[@"Posts", @"Videos"];
    NSString *currentUserId = [self currentUserId];
    YGPostsListViewController *postsViewController = [[YGPostsListViewController alloc] initWithTitleText:titles[0] userId:currentUserId];
    YGPostsListViewController *videosViewController = [[YGPostsListViewController alloc] initWithTitleText:titles[1] userId:currentUserId];
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
        [self.nameLabel.leadingAnchor constraintEqualToAnchor:self.avatarImageView.leadingAnchor],
        [self.nameLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.editButton.leadingAnchor constant:-12.0],

        [self.editButton.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-15.0],
        [self.editButton.centerYAnchor constraintEqualToAnchor:self.nameLabel.centerYAnchor],
        [self.editButton.widthAnchor constraintEqualToConstant:68.0],
        [self.editButton.heightAnchor constraintEqualToConstant:32.0],

        [self.rechargeImageView.topAnchor constraintEqualToAnchor:self.nameLabel.bottomAnchor constant:20.0],
        [self.rechargeImageView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20.0],
        [self.rechargeImageView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20.0],
        [self.rechargeImageView.heightAnchor constraintEqualToAnchor:self.rechargeImageView.widthAnchor multiplier:60.0 / 335.0],

        [self.rechargeTitleLabel.leadingAnchor constraintEqualToAnchor:self.rechargeImageView.leadingAnchor constant:22.0],
        [self.rechargeTitleLabel.centerYAnchor constraintEqualToAnchor:self.rechargeImageView.centerYAnchor constant:-11.0],
        [self.rechargeSubtitleLabel.leadingAnchor constraintEqualToAnchor:self.rechargeTitleLabel.leadingAnchor],
        [self.rechargeSubtitleLabel.topAnchor constraintEqualToAnchor:self.rechargeTitleLabel.bottomAnchor constant:3.0],

        [self.postsPageView.topAnchor constraintEqualToAnchor:self.rechargeImageView.bottomAnchor constant:20.0],
        [self.postsPageView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.postsPageView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.postsPageView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor]
    ]];
    [self updateFollowCounts];
    [self updateBalanceText];
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

- (void)updateFollowCounts {
    self.followingCountLabel.text = [NSString stringWithFormat:@"%ld", (long)[[YGFollowStore sharedStore] visibleFollowingCountForCurrentUser]];
    self.followersCountLabel.text = [NSString stringWithFormat:@"%ld", (long)[[YGFollowStore sharedStore] visibleFollowersCountForUserId:[self currentUserId]]];
}

- (void)updateBalanceText {
    NSInteger balance = [[YGUserStore sharedStore] currentUserBalance];
    self.rechargeTitleLabel.text = [NSString stringWithFormat:@"%ld", (long)balance];
}

- (void)settingButtonTapped {
    if (![[YGUserStore sharedStore] canPerformSensitiveAction]) {
        [self presentGuestLoginAlert];
        return;
    }
    YGSettingViewController *controller = [[YGSettingViewController alloc] init];
    [self.navigationController pushViewController:controller animated:YES];
}

- (void)editButtonTapped {
    if (![[YGUserStore sharedStore] canPerformSensitiveAction]) {
        [self presentGuestLoginAlert];
        return;
    }
    YGPersonMessageViewController *controller = [[YGPersonMessageViewController alloc] init];
    [self.navigationController pushViewController:controller animated:YES];
}

- (void)rechargeImageTapped {
    YGRechargeViewController *ygrechVC = [[YGRechargeViewController alloc]init];
    [self.navigationController pushViewController:ygrechVC animated:YES];
}

- (void)followingInfoViewTapped {
    YGFollowListViewController *controller = [[YGFollowListViewController alloc] initWithType:YGFollowListTypeFollowing];
    [self.navigationController pushViewController:controller animated:YES];
}

- (void)followersInfoViewTapped {
    YGFollowListViewController *controller = [[YGFollowListViewController alloc] initWithType:YGFollowListTypeFollowers];
    [self.navigationController pushViewController:controller animated:YES];
}

- (void)presentGuestLoginAlert {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Guest mode"
                                                                             message:@"Please sign in to access settings."
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"Confirm" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction * _Nonnull action) {
        [[YGUserStore sharedStore] logout];
        [YGAppRouter switchToLoginInterface];
    }]];
    [self presentViewController:alertController animated:YES completion:nil];
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

- (NSString *)currentUserName {
    NSDictionary *currentUser = [[YGUserStore sharedStore] currentUser];
    NSString *nickname = currentUser[@"nickname"];
    return nickname.length > 0 ? nickname : @"Yaga User";
}

- (NSString *)currentUserId {
    NSString *email = [[YGUserStore sharedStore] currentUserEmail];
    return email.length > 0 ? email : @"guest";
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
