//
//  YGPersonVideoDetailViewController.m
//  Yaga
//

#import "YGPersonVideoDetailViewController.h"
#import "YGVideoCommentSheetView.h"
#import "YGVideoPostStore.h"
#import "YGPersonProfileViewController.h"
#import "YGMoreActionSheetView.h"
#import "YGReportViewController.h"
#import "YGBlacklistViewController.h"
#import "YGBlacklistStore.h"
#import "YGHUDHelper.h"
#import "YGUserStore.h"
#import "YGPopupAlertView.h"
#import "YGAppRouter.h"
#import "YGFollowStore.h"
#import <AVFoundation/AVFoundation.h>

@interface YGPersonVideoDetailViewController ()

@property (nonatomic, copy) NSDictionary *item;
@property (nonatomic, strong) UIButton *rightIconButton;
@property (nonatomic, strong) UIImageView *titleAvatarImageView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UIView *playerContainerView;
@property (nonatomic, strong) UIImageView *placeholderImageView;
@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVPlayerLayer *playerLayer;
@property (nonatomic, strong) UIButton *playButton;
@property (nonatomic, assign) BOOL playbackControlVisible;
@property (nonatomic, strong) UIScrollView *descriptionScrollView;
@property (nonatomic, strong) UILabel *descriptionLabel;
@property (nonatomic, strong) NSLayoutConstraint *descriptionHeightConstraint;
@property (nonatomic, strong) UIView *likeBadgeView;
@property (nonatomic, strong) UIImageView *heartImageView;
@property (nonatomic, strong) UILabel *likeCountLabel;
@property (nonatomic, strong) UIView *commentBadgeView;
@property (nonatomic, strong) UIImageView *commentImageView;
@property (nonatomic, strong) UILabel *commentCountLabel;
@property (nonatomic, assign) NSInteger likeCount;
@property (nonatomic, assign) BOOL liked;
@property (nonatomic, assign) NSInteger commentCount;
@property (nonatomic, assign) BOOL commented;

@end

@implementation YGPersonVideoDetailViewController

- (instancetype)initWithItem:(NSDictionary *)item {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _item = [item copy];
        _likeCount = [[YGVideoPostStore sharedStore] likeCountForPostId:_item[@"postId"]];
        _liked = [[YGVideoPostStore sharedStore] isCurrentUserLikedPostId:_item[@"postId"]];
        _commentCount = [[YGVideoPostStore sharedStore] commentsForPostId:_item[@"postId"]].count;
        _commented = [[YGVideoPostStore sharedStore] hasCurrentUserCommentedPostId:_item[@"postId"]];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = UIColor.blackColor;
    [self setupNavigationHeader];
    [self setupPlayer];
    [self setupOverlayContent];
    [self updateLikeView];
    [self updateCommentView];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(blacklistDidChange:)
                                                 name:YGBlacklistDidChangeNotification
                                               object:nil];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.playerLayer.frame = self.playerContainerView.bounds;
    [self updateDescriptionHeight];
}

- (void)setupNavigationHeader {
    self.rightIconButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.rightIconButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.rightIconButton.backgroundColor = UIColor.clearColor;
    self.rightIconButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.rightIconButton setImage:[UIImage imageNamed:@"whitemore"] forState:UIControlStateNormal];
    [self.rightIconButton addTarget:self action:@selector(moreButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.rightIconButton.widthAnchor constraintEqualToConstant:44.0].active = YES;
    [self.rightIconButton.heightAnchor constraintEqualToConstant:44.0].active = YES;
    [self yg_setRightView:self.rightIconButton];
    self.rightIconButton.hidden = [self isCurrentUserPost];
    self.yg_rightContainerView.hidden = [self isCurrentUserPost];

    self.titleAvatarImageView = [[UIImageView alloc] initWithImage:[self avatarImage]];
    self.titleAvatarImageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.titleAvatarImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.titleAvatarImageView.clipsToBounds = YES;
    self.titleAvatarImageView.layer.cornerRadius = 20.0;
    self.titleAvatarImageView.userInteractionEnabled = YES;
    [self.titleAvatarImageView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(titleAvatarTapped)]];
    [self.yg_navigationBarView addSubview:self.titleAvatarImageView];

    self.nameLabel = [[UILabel alloc] init];
    self.nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.nameLabel.text = [self userName];
    self.nameLabel.textColor = UIColor.whiteColor;
    self.nameLabel.font = [UIFont boldSystemFontOfSize:17.0];
    [self.yg_navigationBarView addSubview:self.nameLabel];

    [NSLayoutConstraint activateConstraints:@[
        [self.titleAvatarImageView.leadingAnchor constraintEqualToAnchor:self.yg_leftContainerView.trailingAnchor constant:14.0],
        [self.titleAvatarImageView.centerYAnchor constraintEqualToAnchor:self.yg_leftContainerView.centerYAnchor],
        [self.titleAvatarImageView.widthAnchor constraintEqualToConstant:40.0],
        [self.titleAvatarImageView.heightAnchor constraintEqualToConstant:40.0],

        [self.nameLabel.leadingAnchor constraintEqualToAnchor:self.titleAvatarImageView.trailingAnchor constant:8.0],
        [self.nameLabel.centerYAnchor constraintEqualToAnchor:self.titleAvatarImageView.centerYAnchor],
        [self.nameLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.yg_rightContainerView.leadingAnchor constant:-12.0]
    ]];
}

- (void)titleAvatarTapped {
    if ([self showLoginPromptIfNeeded]) {
        return;
    }
    YGPersonProfileViewController *controller = [[YGPersonProfileViewController alloc] initWithUserInfo:self.item];
    [self.navigationController pushViewController:controller animated:YES];
}

- (void)moreButtonTapped {
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
        [[YGBlacklistStore sharedStore] addBlockedUser:strongSelf.item];
        [[YGFollowStore sharedStore] unfollowUserId:[strongSelf userId]];
        [YGHUDHelper showCenterText:@"Block successful." inView:targetView];
        [strongSelf.navigationController popToRootViewControllerAnimated:YES];
    }];
}

- (void)setupPlayer {
    self.playerContainerView = [[UIView alloc] init];
    self.playerContainerView.translatesAutoresizingMaskIntoConstraints = NO;
    self.playerContainerView.backgroundColor = UIColor.blackColor;
    self.playerContainerView.clipsToBounds = YES;
    [self.view addSubview:self.playerContainerView];

    NSURL *videoURL = [[YGVideoPostStore sharedStore] videoURLForPost:self.item];
    if (videoURL == nil) {
        videoURL = [[NSBundle mainBundle] URLForResource:@"xxxx" withExtension:@"mp4"];
    }
    if (videoURL != nil) {
        self.player = [AVPlayer playerWithURL:videoURL];
        self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
        self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        [self.playerContainerView.layer addSublayer:self.playerLayer];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(playerDidFinishPlaying:)
                                                     name:AVPlayerItemDidPlayToEndTimeNotification
                                                   object:self.player.currentItem];
    }

    UIImage *coverImage = [[YGVideoPostStore sharedStore] thumbnailImageForPost:self.item];
    self.placeholderImageView = [[UIImageView alloc] initWithImage:coverImage ?: [UIImage imageNamed:@"bigimage"]];
    self.placeholderImageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.placeholderImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.placeholderImageView.clipsToBounds = YES;
    [self.playerContainerView addSubview:self.placeholderImageView];

    [NSLayoutConstraint activateConstraints:@[
        [self.playerContainerView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.playerContainerView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.playerContainerView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.playerContainerView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],

        [self.placeholderImageView.topAnchor constraintEqualToAnchor:self.playerContainerView.topAnchor],
        [self.placeholderImageView.leadingAnchor constraintEqualToAnchor:self.playerContainerView.leadingAnchor],
        [self.placeholderImageView.trailingAnchor constraintEqualToAnchor:self.playerContainerView.trailingAnchor],
        [self.placeholderImageView.bottomAnchor constraintEqualToAnchor:self.playerContainerView.bottomAnchor]
    ]];
}

- (void)setupOverlayContent {
    self.playButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.playButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.playButton.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.55];
    self.playButton.layer.cornerRadius = 22.0;
    self.playButton.clipsToBounds = YES;
    UIImage *playImage = [[UIImage imageNamed:@"playimage"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    [self.playButton setImage:playImage forState:UIControlStateNormal];
    [self.playButton addTarget:self action:@selector(playButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    self.playbackControlVisible = YES;
    [self.view addSubview:self.playButton];

    UITapGestureRecognizer *playerTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(playerAreaTapped)];
    [self.playerContainerView addGestureRecognizer:playerTapGesture];

    self.descriptionScrollView = [[UIScrollView alloc] init];
    self.descriptionScrollView.translatesAutoresizingMaskIntoConstraints = NO;
    self.descriptionScrollView.backgroundColor = UIColor.clearColor;
    self.descriptionScrollView.showsVerticalScrollIndicator = NO;
    self.descriptionScrollView.alwaysBounceVertical = NO;
    [self.view addSubview:self.descriptionScrollView];

    self.descriptionLabel = [[UILabel alloc] init];
    self.descriptionLabel.translatesAutoresizingMaskIntoConstraints = YES;
    self.descriptionLabel.text = [self detailDescriptionText];
    self.descriptionLabel.textColor = UIColor.whiteColor;
    self.descriptionLabel.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightRegular];
    self.descriptionLabel.numberOfLines = 0;
    self.descriptionLabel.lineBreakMode = NSLineBreakByWordWrapping;
    [self.descriptionLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    [self.descriptionScrollView addSubview:self.descriptionLabel];

    self.likeBadgeView = [self badgeViewWithAction:@selector(likeBadgeTapped)];
    [self.view addSubview:self.likeBadgeView];

    self.heartImageView = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"heart.fill"]];
    self.heartImageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.heartImageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.likeBadgeView addSubview:self.heartImageView];

    self.likeCountLabel = [self badgeLabelWithText:@"123"];
    [self.likeBadgeView addSubview:self.likeCountLabel];

    self.commentBadgeView = [self badgeViewWithAction:@selector(commentBadgeTapped)];
    [self.view addSubview:self.commentBadgeView];

    self.commentImageView = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"ellipsis.bubble.fill"]];
    self.commentImageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.commentImageView.tintColor = UIColor.whiteColor;
    self.commentImageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.commentBadgeView addSubview:self.commentImageView];

    self.commentCountLabel = [self badgeLabelWithText:@""];
    [self.commentBadgeView addSubview:self.commentCountLabel];

    self.descriptionHeightConstraint = [self.descriptionScrollView.heightAnchor constraintEqualToConstant:44.0];

    [NSLayoutConstraint activateConstraints:@[
        [self.playButton.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.playButton.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
        [self.playButton.widthAnchor constraintEqualToConstant:44.0],
        [self.playButton.heightAnchor constraintEqualToConstant:44.0],

        [self.descriptionScrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:24.0],
        [self.descriptionScrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-24.0],
        [self.descriptionScrollView.bottomAnchor constraintEqualToAnchor:self.likeBadgeView.topAnchor constant:-14.0],
        self.descriptionHeightConstraint,

        [self.likeBadgeView.leadingAnchor constraintEqualToAnchor:self.descriptionScrollView.leadingAnchor],
        [self.likeBadgeView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-18.0],
        [self.likeBadgeView.heightAnchor constraintEqualToConstant:30.0],
        [self.likeBadgeView.widthAnchor constraintGreaterThanOrEqualToConstant:64.0],

        [self.heartImageView.leadingAnchor constraintEqualToAnchor:self.likeBadgeView.leadingAnchor constant:10.0],
        [self.heartImageView.centerYAnchor constraintEqualToAnchor:self.likeBadgeView.centerYAnchor],
        [self.heartImageView.widthAnchor constraintEqualToConstant:15.0],
        [self.heartImageView.heightAnchor constraintEqualToConstant:15.0],
        [self.likeCountLabel.leadingAnchor constraintEqualToAnchor:self.heartImageView.trailingAnchor constant:5.0],
        [self.likeCountLabel.trailingAnchor constraintEqualToAnchor:self.likeBadgeView.trailingAnchor constant:-10.0],
        [self.likeCountLabel.centerYAnchor constraintEqualToAnchor:self.likeBadgeView.centerYAnchor],

        [self.commentBadgeView.leadingAnchor constraintEqualToAnchor:self.likeBadgeView.trailingAnchor constant:14.0],
        [self.commentBadgeView.centerYAnchor constraintEqualToAnchor:self.likeBadgeView.centerYAnchor],
        [self.commentBadgeView.heightAnchor constraintEqualToConstant:30.0],
        [self.commentBadgeView.widthAnchor constraintGreaterThanOrEqualToConstant:64.0],

        [self.commentImageView.leadingAnchor constraintEqualToAnchor:self.commentBadgeView.leadingAnchor constant:10.0],
        [self.commentImageView.centerYAnchor constraintEqualToAnchor:self.commentBadgeView.centerYAnchor],
        [self.commentImageView.widthAnchor constraintEqualToConstant:15.0],
        [self.commentImageView.heightAnchor constraintEqualToConstant:15.0],
        [self.commentCountLabel.leadingAnchor constraintEqualToAnchor:self.commentImageView.trailingAnchor constant:5.0],
        [self.commentCountLabel.trailingAnchor constraintEqualToAnchor:self.commentBadgeView.trailingAnchor constant:-10.0],
        [self.commentCountLabel.centerYAnchor constraintEqualToAnchor:self.commentBadgeView.centerYAnchor]
    ]];
}

- (void)updateDescriptionHeight {
    if (self.descriptionHeightConstraint == nil) {
        return;
    }

    CGFloat width = CGRectGetWidth(self.descriptionScrollView.bounds);
    if (width <= 0.0) {
        return;
    }

    CGSize fittingSize = [self.descriptionLabel sizeThatFits:CGSizeMake(width, CGFLOAT_MAX)];
    CGFloat safeTop = CGRectGetMaxY(self.yg_navigationBarView.frame) + 12.0;
    CGFloat maxBottom = CGRectGetMinY(self.likeBadgeView.frame) - 14.0;
    CGFloat availableHeight = MAX(44.0, maxBottom - safeTop);
    CGFloat targetHeight = MIN(ceil(fittingSize.height), availableHeight);
    targetHeight = MAX(20.0, targetHeight);
    if (fabs(self.descriptionHeightConstraint.constant - targetHeight) > 0.5) {
        self.descriptionHeightConstraint.constant = targetHeight;
    }
    self.descriptionLabel.frame = CGRectMake(0.0, 0.0, width, ceil(fittingSize.height));
    self.descriptionScrollView.contentSize = CGSizeMake(width, ceil(fittingSize.height));
    self.descriptionScrollView.scrollEnabled = ceil(fittingSize.height) > targetHeight + 0.5;
}

- (UIView *)badgeViewWithAction:(SEL)action {
    UIView *view = [[UIView alloc] init];
    view.translatesAutoresizingMaskIntoConstraints = NO;
    view.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.45];
    view.layer.cornerRadius = 15.0;
    view.clipsToBounds = YES;
    [view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:action]];
    return view;
}

- (UILabel *)badgeLabelWithText:(NSString *)text {
    UILabel *label = [[UILabel alloc] init];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.text = text;
    label.textColor = UIColor.whiteColor;
    label.font = [UIFont systemFontOfSize:12.0 weight:UIFontWeightMedium];
    return label;
}

- (void)playButtonTapped {
    if (self.player == nil) {
        return;
    }
    if (self.player.timeControlStatus == AVPlayerTimeControlStatusPlaying) {
        [self.player pause];
        [self showPlaybackControlWithPauseImage:NO autoHide:NO];
    } else {
        self.placeholderImageView.hidden = YES;
        [self.player play];
        [self showPlaybackControlWithPauseImage:YES autoHide:YES];
    }
}

- (void)playerAreaTapped {
    if (self.player == nil) {
        return;
    }

    BOOL isPlaying = self.player.timeControlStatus == AVPlayerTimeControlStatusPlaying;
    if (!isPlaying) {
        [self showPlaybackControlWithPauseImage:NO autoHide:NO];
        return;
    }

    if (self.playbackControlVisible) {
        [self hidePlaybackControl];
    } else {
        [self showPlaybackControlWithPauseImage:YES autoHide:YES];
    }
}

- (void)showPlaybackControlWithPauseImage:(BOOL)pauseImage autoHide:(BOOL)autoHide {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hidePlaybackControl) object:nil];
    UIImage *image = [[UIImage imageNamed:pauseImage ? @"zanting" : @"playimage"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    [self.playButton setImage:image forState:UIControlStateNormal];
    self.playButton.hidden = NO;
    self.playbackControlVisible = YES;
    [UIView animateWithDuration:0.2 animations:^{
        self.playButton.alpha = 1.0;
    }];
    if (autoHide) {
        [self performSelector:@selector(hidePlaybackControl) withObject:nil afterDelay:1.2];
    }
}

- (void)hidePlaybackControl {
    if (self.player.timeControlStatus != AVPlayerTimeControlStatusPlaying) {
        return;
    }
    self.playbackControlVisible = NO;
    [UIView animateWithDuration:0.2 animations:^{
        self.playButton.alpha = 0.0;
    } completion:^(__unused BOOL finished) {
        if (!self.playbackControlVisible) {
            self.playButton.hidden = YES;
        }
    }];
}

- (void)playerDidFinishPlaying:(NSNotification *)notification {
    if (notification.object != self.player.currentItem) {
        return;
    }
    [self.player seekToTime:kCMTimeZero];
    self.placeholderImageView.hidden = NO;
    [self showPlaybackControlWithPauseImage:NO autoHide:NO];
}

- (void)likeBadgeTapped {
    if ([self showLoginPromptIfNeeded]) {
        return;
    }
    self.likeCount = [[YGVideoPostStore sharedStore] toggleLikeForPostId:self.item[@"postId"]];
    self.liked = [[YGVideoPostStore sharedStore] isCurrentUserLikedPostId:self.item[@"postId"]];
    [self updateLikeView];
}

- (void)commentBadgeTapped {
    if ([self showLoginPromptIfNeeded]) {
        return;
    }
    UIView *containerView = self.navigationController.view ?: self.view;
    __weak typeof(self) weakSelf = self;
    NSArray *comments = [[YGVideoPostStore sharedStore] commentsForPostId:self.item[@"postId"]];
    [YGVideoCommentSheetView showInView:containerView
                           commentCount:comments.count
                               comments:comments
                          submitHandler:^(NSDictionary *comment) {
        __strong typeof(weakSelf) self = weakSelf;
        if (self == nil) {
            return;
        }
        [[YGVideoPostStore sharedStore] addComment:comment toPostId:self.item[@"postId"]];
        self.commentCount = [[YGVideoPostStore sharedStore] commentsForPostId:self.item[@"postId"]].count;
        self.commented = [[YGVideoPostStore sharedStore] hasCurrentUserCommentedPostId:self.item[@"postId"]];
        [self updateCommentView];
    } blockHandler:^(NSDictionary *comment) {
        __strong typeof(weakSelf) self = weakSelf;
        if (self == nil) {
            return;
        }
        [self showMoreActionsForComment:comment];
    }];
}

- (void)showMoreActionsForComment:(NSDictionary *)comment {
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
        [[YGBlacklistStore sharedStore] addBlockedUser:comment];
        NSString *userId = [strongSelf userIdFromComment:comment];
        if (userId.length > 0) {
            [[YGFollowStore sharedStore] unfollowUserId:userId];
        }
        strongSelf.commentCount = [[YGVideoPostStore sharedStore] commentsForPostId:strongSelf.item[@"postId"]].count;
        [strongSelf updateCommentView];
        [YGHUDHelper showCenterText:@"Block successful." inView:targetView];
    }];
}

- (void)blacklistDidChange:(NSNotification *)notification {
    if ([[YGBlacklistStore sharedStore] isBlockedUserId:[self userId]]) {
        [self.navigationController popToRootViewControllerAnimated:YES];
        return;
    }
    self.commentCount = [[YGVideoPostStore sharedStore] commentsForPostId:self.item[@"postId"]].count;
    self.commented = [[YGVideoPostStore sharedStore] hasCurrentUserCommentedPostId:self.item[@"postId"]];
    [self updateCommentView];
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

- (void)updateLikeView {
    self.heartImageView.tintColor = self.liked ? [self colorWithHexString:@"#B829FF"] : UIColor.whiteColor;
    self.likeCountLabel.text = [NSString stringWithFormat:@"%ld", (long)self.likeCount];
}

- (void)updateCommentView {
    self.commentImageView.tintColor = self.commented ? [self colorWithHexString:@"#B829FF"] : UIColor.whiteColor;
    self.commentCountLabel.text = [NSString stringWithFormat:@"%ld", (long)self.commentCount];
}

- (NSString *)avatarName {
    NSString *avatarName = self.item[@"avatarName"];
    return avatarName.length > 0 ? avatarName : @"headplace";
}

- (UIImage *)avatarImage {
    UIImage *avatarImage = [[YGVideoPostStore sharedStore] avatarImageForPost:self.item];
    if (avatarImage != nil) {
        return avatarImage;
    }
    return [UIImage imageNamed:[self avatarName]];
}

- (NSString *)userName {
    NSString *userName = self.item[@"userName"];
    return userName.length > 0 ? userName : @"Pasquale";
}

- (NSString *)userId {
    NSString *userId = self.item[@"userId"];
    if (userId.length > 0) {
        return userId;
    }
    NSString *userName = [self userName].lowercaseString;
    return userName.length > 0 ? [@"default_user_" stringByAppendingString:userName] : @"default_user_unknown";
}

- (BOOL)isCurrentUserPost {
    NSString *currentUserId = [[YGUserStore sharedStore] currentUserEmail];
    return currentUserId.length > 0 && [[self userId] isEqualToString:currentUserId];
}

- (NSString *)userIdFromComment:(NSDictionary *)comment {
    NSString *userId = [comment[@"userId"] isKindOfClass:NSString.class] ? comment[@"userId"] : @"";
    if (userId.length > 0) {
        return userId;
    }

    NSString *authorId = [comment[@"authorId"] isKindOfClass:NSString.class] ? comment[@"authorId"] : @"";
    if ([authorId hasPrefix:@"user:"]) {
        return [authorId substringFromIndex:@"user:".length];
    }
    if (authorId.length > 0) {
        return authorId;
    }

    NSString *userName = [comment[@"userName"] isKindOfClass:NSString.class] ? comment[@"userName"] : @"";
    return userName.length > 0 ? [@"default_user_" stringByAppendingString:userName.lowercaseString] : @"";
}

- (NSString *)detailDescriptionText {
    NSString *text = self.item[@"text"];
    return text.length > 0 ? text : @"Tennis is a dancing poem on the football field. Every swing of the racket is a dialogue with the wind.";
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

- (void)dealloc {
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
