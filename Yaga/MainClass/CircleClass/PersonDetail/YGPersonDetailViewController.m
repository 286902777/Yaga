//
//  YGPersonDetailViewController.m
//  Yaga
//

#import "YGPersonDetailViewController.h"
#import "../PersonProfile/YGPersonProfileViewController.h"
#import "YGUserStore.h"
#import "YGKeyboardHandler.h"
#import "YGImagePostStore.h"
#import "YGMoreActionSheetView.h"
#import "YGReportViewController.h"
#import "YGBlacklistViewController.h"
#import "YGBlacklistStore.h"
#import "YGHUDHelper.h"
#import "YGPopupAlertView.h"
#import "YGAppRouter.h"
#import "YGVideoPostStore.h"
#import "YGFollowStore.h"

@interface YGPersonDetailCommentCell : UITableViewCell

+ (NSString *)reuseIdentifier;
@property (nonatomic, copy, nullable) void (^moreTapHandler)(void);
- (void)configureWithComment:(NSDictionary<NSString *, id> *)comment;
- (void)setMoreHidden:(BOOL)hidden;

@end

@interface YGPersonDetailCommentCell ()

@property (nonatomic, strong) UIImageView *avatarImageView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *commentLabel;
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, strong) UIImageView *moreImageView;

@end

@implementation YGPersonDetailCommentCell

+ (NSString *)reuseIdentifier {
    return NSStringFromClass(self);
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setupViews];
    }
    return self;
}

- (void)setupViews {
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.backgroundColor = UIColor.clearColor;
    self.contentView.backgroundColor = UIColor.clearColor;

    self.avatarImageView = [[UIImageView alloc] init];
    self.avatarImageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.avatarImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.avatarImageView.clipsToBounds = YES;
    self.avatarImageView.layer.cornerRadius = 10.0;
    [self.contentView addSubview:self.avatarImageView];

    self.nameLabel = [[UILabel alloc] init];
    self.nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.nameLabel.textColor = [self colorWithHexString:@"#555555"];
    self.nameLabel.font = [UIFont systemFontOfSize:12.0 weight:UIFontWeightBold];
    [self.contentView addSubview:self.nameLabel];

    self.moreImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"listmore"]];
    self.moreImageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.moreImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.moreImageView.userInteractionEnabled = YES;
    [self.moreImageView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(moreImageTapped)]];
    [self.contentView addSubview:self.moreImageView];

    self.commentLabel = [[UILabel alloc] init];
    self.commentLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.commentLabel.textColor = [self colorWithHexString:@"#777777"];
    self.commentLabel.font = [UIFont systemFontOfSize:12.0 weight:UIFontWeightRegular];
    self.commentLabel.numberOfLines = 0;
    [self.contentView addSubview:self.commentLabel];

    self.timeLabel = [[UILabel alloc] init];
    self.timeLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.timeLabel.textColor = [self colorWithHexString:@"#808080"];
    self.timeLabel.font = [UIFont systemFontOfSize:11.0 weight:UIFontWeightRegular];
    [self.contentView addSubview:self.timeLabel];

    [NSLayoutConstraint activateConstraints:@[
        [self.avatarImageView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:8.0],
        [self.avatarImageView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:24.0],
        [self.avatarImageView.widthAnchor constraintEqualToConstant:20.0],
        [self.avatarImageView.heightAnchor constraintEqualToConstant:20.0],

        [self.nameLabel.leadingAnchor constraintEqualToAnchor:self.avatarImageView.trailingAnchor constant:8.0],
        [self.nameLabel.topAnchor constraintEqualToAnchor:self.avatarImageView.topAnchor],
        [self.nameLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.moreImageView.leadingAnchor constant:-10.0],

        [self.moreImageView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-24.0],
        [self.moreImageView.centerYAnchor constraintEqualToAnchor:self.nameLabel.centerYAnchor],
        [self.moreImageView.widthAnchor constraintEqualToConstant:18.0],
        [self.moreImageView.heightAnchor constraintEqualToConstant:18.0],

        [self.commentLabel.leadingAnchor constraintEqualToAnchor:self.nameLabel.leadingAnchor],
        [self.commentLabel.topAnchor constraintEqualToAnchor:self.nameLabel.bottomAnchor constant:4.0],
        [self.commentLabel.trailingAnchor constraintEqualToAnchor:self.moreImageView.trailingAnchor constant:-22.0],

        [self.timeLabel.leadingAnchor constraintEqualToAnchor:self.commentLabel.leadingAnchor],
        [self.timeLabel.topAnchor constraintEqualToAnchor:self.commentLabel.bottomAnchor constant:6.0],
        [self.timeLabel.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-10.0]
    ]];
}

- (void)moreImageTapped {
    if (self.moreTapHandler != nil) {
        self.moreTapHandler();
    }
}

- (void)setMoreHidden:(BOOL)hidden {
    self.moreImageView.hidden = hidden;
    self.moreImageView.userInteractionEnabled = !hidden;
    if (hidden) {
        self.moreTapHandler = nil;
    }
}

- (void)configureWithComment:(NSDictionary<NSString *, id> *)comment {
    UIImage *avatarImage = [comment[@"avatarImage"] isKindOfClass:UIImage.class] ? comment[@"avatarImage"] : nil;
    NSString *avatarLocalPath = [comment[@"avatarLocalPath"] isKindOfClass:NSString.class] ? comment[@"avatarLocalPath"] : @"";
    if (avatarImage == nil && avatarLocalPath.length > 0) {
        avatarImage = [UIImage imageWithContentsOfFile:avatarLocalPath];
    }
    NSString *avatarDataBase64 = [comment[@"avatarDataBase64"] isKindOfClass:NSString.class] ? comment[@"avatarDataBase64"] : @"";
    if (avatarImage == nil && avatarDataBase64.length > 0) {
        NSData *imageData = [[NSData alloc] initWithBase64EncodedString:avatarDataBase64 options:0];
        avatarImage = [UIImage imageWithData:imageData];
    }
    NSString *avatarImageName = [comment[@"avatarImageName"] isKindOfClass:NSString.class] ? comment[@"avatarImageName"] : @"";
    if (avatarImage == nil && avatarImageName.length > 0) {
        avatarImage = [[YGImagePostStore sharedStore] imageInPostResourcesNamed:avatarImageName];
        if (avatarImage == nil) {
            avatarImage = [[YGVideoPostStore sharedStore] imageInVideoResourcesNamed:avatarImageName];
        }
    }
    NSString *avatarName = [comment[@"avatarName"] isKindOfClass:NSString.class] ? comment[@"avatarName"] : @"headplace";
    self.avatarImageView.image = avatarImage ?: [UIImage imageNamed:avatarName ?: @"headplace"];
    self.nameLabel.text = comment[@"userName"] ?: @"User";
    self.commentLabel.text = comment[@"text"] ?: @"";
    self.timeLabel.text = comment[@"time"] ?: @"";
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

@interface YGPersonDetailViewController () <UITextViewDelegate, UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate>

@property (nonatomic, copy) NSDictionary *item;
@property (nonatomic, strong) UIImageView *titleAvatarImageView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UIButton *rightIconButton;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIView *headerContentView;
@property (nonatomic, strong) UIScrollView *postImageScrollView;
@property (nonatomic, strong) UIPageControl *postPageControl;
@property (nonatomic, copy) NSArray<UIImageView *> *postImageViews;
@property (nonatomic, strong) UIView *likeBadgeView;
@property (nonatomic, strong) UIImageView *heartImageView;
@property (nonatomic, strong) UILabel *likeCountLabel;
@property (nonatomic, strong) UILabel *descriptionLabel;
@property (nonatomic, strong) UILabel *commentTitleLabel;
@property (nonatomic, strong) UIView *inputBarView;
@property (nonatomic, strong) UIView *fieldContainerView;
@property (nonatomic, strong) UITextView *inputTextView;
@property (nonatomic, strong) UILabel *placeholderLabel;
@property (nonatomic, strong) UIButton *sendButton;
@property (nonatomic, strong) NSLayoutConstraint *inputBarBottomConstraint;
@property (nonatomic, strong) NSLayoutConstraint *inputBarHeightConstraint;
@property (nonatomic, strong) NSLayoutConstraint *fieldContainerHeightConstraint;
@property (nonatomic, strong) NSMutableArray<NSDictionary<NSString *, id> *> *comments;
@property (nonatomic, assign) NSInteger likeCount;
@property (nonatomic, assign) BOOL liked;
@property (nonatomic, strong) YGKeyboardHandler *keyboardHandler;

@end

@implementation YGPersonDetailViewController

- (instancetype)initWithItem:(NSDictionary *)item {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _item = [item copy];
        _comments = [[[YGImagePostStore sharedStore] commentsForPostId:_item[@"postId"]] mutableCopy];
        if (_comments == nil) {
            _comments = [NSMutableArray array];
        }
        _likeCount = [[YGImagePostStore sharedStore] likeCountForPostId:_item[@"postId"]];
        _liked = [[YGImagePostStore sharedStore] isCurrentUserLikedPostId:_item[@"postId"]];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [self colorWithHexString:@"#F7F7F7"];
    [self setupNavigationHeader];
    [self setupInputBarView];
    [self setupTableView];
    [self.view bringSubviewToFront:self.inputBarView];
    [self setupKeyboardHandler];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(blacklistDidChange:)
                                                 name:YGBlacklistDidChangeNotification
                                               object:nil];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self layoutPostImages];
    [self updateTableHeaderHeightIfNeeded];
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
    self.nameLabel.textColor = UIColor.blackColor;
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

- (void)setupInputBarView {
    self.inputBarView = [[UIView alloc] init];
    self.inputBarView.translatesAutoresizingMaskIntoConstraints = NO;
    self.inputBarView.backgroundColor = UIColor.whiteColor;
    [self.view addSubview:self.inputBarView];

    self.fieldContainerView = [[UIView alloc] init];
    self.fieldContainerView.translatesAutoresizingMaskIntoConstraints = NO;
    self.fieldContainerView.backgroundColor = [self colorWithHexString:@"#F4F4F4"];
    self.fieldContainerView.layer.cornerRadius = 22.0;
    self.fieldContainerView.clipsToBounds = YES;
    [self.inputBarView addSubview:self.fieldContainerView];

    self.inputTextView = [[UITextView alloc] init];
    self.inputTextView.translatesAutoresizingMaskIntoConstraints = NO;
    self.inputTextView.backgroundColor = UIColor.clearColor;
    self.inputTextView.textColor = UIColor.blackColor;
    self.inputTextView.font = [UIFont systemFontOfSize:15.0];
    self.inputTextView.delegate = self;
    self.inputTextView.scrollEnabled = NO;
    self.inputTextView.textContainerInset = UIEdgeInsetsMake(11.0, 0.0, 11.0, 0.0);
    self.inputTextView.textContainer.lineFragmentPadding = 0.0;
    [self.fieldContainerView addSubview:self.inputTextView];

    self.placeholderLabel = [[UILabel alloc] init];
    self.placeholderLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.placeholderLabel.text = @"Say something";
    self.placeholderLabel.textColor = [self colorWithHexString:@"#9B9B9B"];
    self.placeholderLabel.font = [UIFont systemFontOfSize:15.0];
    [self.fieldContainerView addSubview:self.placeholderLabel];

    self.sendButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.sendButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.sendButton.backgroundColor = UIColor.clearColor;
    self.sendButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.sendButton setImage:[UIImage imageNamed:@"sendmessage"] forState:UIControlStateNormal];
    [self.sendButton addTarget:self action:@selector(sendButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.inputBarView addSubview:self.sendButton];

    self.inputBarBottomConstraint = [self.inputBarView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor];
    self.inputBarHeightConstraint = [self.inputBarView.heightAnchor constraintEqualToConstant:74.0];
    self.fieldContainerHeightConstraint = [self.fieldContainerView.heightAnchor constraintEqualToConstant:44.0];

    [NSLayoutConstraint activateConstraints:@[
        [self.inputBarView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.inputBarView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        self.inputBarBottomConstraint,
        self.inputBarHeightConstraint,

        [self.fieldContainerView.leadingAnchor constraintEqualToAnchor:self.inputBarView.leadingAnchor constant:24.0],
        [self.fieldContainerView.topAnchor constraintEqualToAnchor:self.inputBarView.topAnchor constant:10.0],
        [self.fieldContainerView.trailingAnchor constraintEqualToAnchor:self.sendButton.leadingAnchor constant:-10.0],
        self.fieldContainerHeightConstraint,

        [self.inputTextView.leadingAnchor constraintEqualToAnchor:self.fieldContainerView.leadingAnchor constant:16.0],
        [self.inputTextView.trailingAnchor constraintEqualToAnchor:self.fieldContainerView.trailingAnchor constant:-16.0],
        [self.inputTextView.topAnchor constraintEqualToAnchor:self.fieldContainerView.topAnchor],
        [self.inputTextView.bottomAnchor constraintEqualToAnchor:self.fieldContainerView.bottomAnchor],

        [self.placeholderLabel.leadingAnchor constraintEqualToAnchor:self.inputTextView.leadingAnchor],
        [self.placeholderLabel.topAnchor constraintEqualToAnchor:self.fieldContainerView.topAnchor constant:12.0],
        [self.placeholderLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.inputTextView.trailingAnchor],

        [self.sendButton.trailingAnchor constraintEqualToAnchor:self.inputBarView.trailingAnchor constant:-24.0],
        [self.sendButton.centerYAnchor constraintEqualToAnchor:self.fieldContainerView.centerYAnchor],
        [self.sendButton.widthAnchor constraintEqualToConstant:44.0],
        [self.sendButton.heightAnchor constraintEqualToConstant:44.0]
    ]];
}

- (void)setupTableView {
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.backgroundColor = UIColor.clearColor;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.showsVerticalScrollIndicator = NO;
    self.tableView.estimatedRowHeight = 74.0;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    if (@available(iOS 11.0, *)) {
        self.tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
    [self.tableView registerClass:YGPersonDetailCommentCell.class forCellReuseIdentifier:YGPersonDetailCommentCell.reuseIdentifier];
    [self.view addSubview:self.tableView];

    [NSLayoutConstraint activateConstraints:@[
        [self.tableView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [self.tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.tableView.bottomAnchor constraintEqualToAnchor:self.inputBarView.topAnchor]
    ]];

    [self setupTableHeaderView];
}

- (void)setupTableHeaderView {
    self.headerContentView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, CGRectGetWidth(UIScreen.mainScreen.bounds), 1.0)];
    self.headerContentView.backgroundColor = UIColor.clearColor;

    self.postImageScrollView = [[UIScrollView alloc] init];
    self.postImageScrollView.translatesAutoresizingMaskIntoConstraints = NO;
    self.postImageScrollView.backgroundColor = UIColor.clearColor;
    self.postImageScrollView.pagingEnabled = YES;
    self.postImageScrollView.showsHorizontalScrollIndicator = NO;
    self.postImageScrollView.bounces = NO;
    self.postImageScrollView.alwaysBounceHorizontal = NO;
    self.postImageScrollView.delegate = self;
    self.postImageScrollView.clipsToBounds = YES;
    [self.headerContentView addSubview:self.postImageScrollView];
    [self setupPostImageViews];

    self.likeBadgeView = [[UIView alloc] init];
    self.likeBadgeView.translatesAutoresizingMaskIntoConstraints = NO;
    self.likeBadgeView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.45];
    self.likeBadgeView.layer.cornerRadius = 15.0;
    self.likeBadgeView.clipsToBounds = YES;
    [self.likeBadgeView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(likeBadgeTapped)]];
    [self.headerContentView addSubview:self.likeBadgeView];

    self.heartImageView = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"heart.fill"]];
    self.heartImageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.heartImageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.likeBadgeView addSubview:self.heartImageView];

    self.likeCountLabel = [[UILabel alloc] init];
    self.likeCountLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.likeCountLabel.textColor = UIColor.whiteColor;
    self.likeCountLabel.font = [UIFont systemFontOfSize:12.0 weight:UIFontWeightMedium];
    [self.likeBadgeView addSubview:self.likeCountLabel];

    self.postPageControl = [[UIPageControl alloc] init];
    self.postPageControl.translatesAutoresizingMaskIntoConstraints = NO;
    self.postPageControl.numberOfPages = self.postImageNames.count;
    self.postPageControl.currentPage = 0;
    self.postPageControl.hidesForSinglePage = YES;
    self.postPageControl.pageIndicatorTintColor = [[UIColor whiteColor] colorWithAlphaComponent:0.5];
    self.postPageControl.currentPageIndicatorTintColor = UIColor.whiteColor;
    [self.headerContentView addSubview:self.postPageControl];

    self.descriptionLabel = [[UILabel alloc] init];
    self.descriptionLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.descriptionLabel.text = [self detailDescriptionText];
    self.descriptionLabel.textColor = UIColor.blackColor;
    self.descriptionLabel.font = [UIFont systemFontOfSize:16.0 weight:UIFontWeightRegular];
    self.descriptionLabel.numberOfLines = 0;
    [self.headerContentView addSubview:self.descriptionLabel];

    self.commentTitleLabel = [[UILabel alloc] init];
    self.commentTitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.commentTitleLabel.textColor = UIColor.blackColor;
    self.commentTitleLabel.font = [UIFont systemFontOfSize:22.0 weight:UIFontWeightBold];
    [self.headerContentView addSubview:self.commentTitleLabel];

    [NSLayoutConstraint activateConstraints:@[
        [self.postImageScrollView.topAnchor constraintEqualToAnchor:self.headerContentView.topAnchor],
        [self.postImageScrollView.leadingAnchor constraintEqualToAnchor:self.headerContentView.leadingAnchor],
        [self.postImageScrollView.trailingAnchor constraintEqualToAnchor:self.headerContentView.trailingAnchor],
        [self.postImageScrollView.heightAnchor constraintEqualToAnchor:self.postImageScrollView.widthAnchor multiplier:500.0 / 375.0],

        [self.likeBadgeView.trailingAnchor constraintEqualToAnchor:self.postImageScrollView.trailingAnchor constant:-12.0],
        [self.likeBadgeView.bottomAnchor constraintEqualToAnchor:self.postImageScrollView.bottomAnchor constant:-12.0],
        [self.likeBadgeView.heightAnchor constraintEqualToConstant:30.0],
        [self.likeBadgeView.widthAnchor constraintGreaterThanOrEqualToConstant:58.0],

        [self.postPageControl.centerXAnchor constraintEqualToAnchor:self.postImageScrollView.centerXAnchor],
        [self.postPageControl.bottomAnchor constraintEqualToAnchor:self.postImageScrollView.bottomAnchor constant:-10.0],
        [self.postPageControl.heightAnchor constraintEqualToConstant:18.0],
        [self.postPageControl.widthAnchor constraintLessThanOrEqualToAnchor:self.postImageScrollView.widthAnchor constant:-100.0],

        [self.heartImageView.leadingAnchor constraintEqualToAnchor:self.likeBadgeView.leadingAnchor constant:10.0],
        [self.heartImageView.centerYAnchor constraintEqualToAnchor:self.likeBadgeView.centerYAnchor],
        [self.heartImageView.widthAnchor constraintEqualToConstant:15.0],
        [self.heartImageView.heightAnchor constraintEqualToConstant:15.0],

        [self.likeCountLabel.leadingAnchor constraintEqualToAnchor:self.heartImageView.trailingAnchor constant:5.0],
        [self.likeCountLabel.trailingAnchor constraintEqualToAnchor:self.likeBadgeView.trailingAnchor constant:-10.0],
        [self.likeCountLabel.centerYAnchor constraintEqualToAnchor:self.likeBadgeView.centerYAnchor],

        [self.descriptionLabel.topAnchor constraintEqualToAnchor:self.postImageScrollView.bottomAnchor constant:16.0],
        [self.descriptionLabel.leadingAnchor constraintEqualToAnchor:self.headerContentView.leadingAnchor constant:24.0],
        [self.descriptionLabel.trailingAnchor constraintEqualToAnchor:self.headerContentView.trailingAnchor constant:-24.0],

        [self.commentTitleLabel.topAnchor constraintEqualToAnchor:self.descriptionLabel.bottomAnchor constant:16.0],
        [self.commentTitleLabel.leadingAnchor constraintEqualToAnchor:self.descriptionLabel.leadingAnchor],
        [self.commentTitleLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.descriptionLabel.trailingAnchor],
        [self.commentTitleLabel.bottomAnchor constraintEqualToAnchor:self.headerContentView.bottomAnchor constant:-12.0]
    ]];

    [self updateLikeView];
    [self updateCommentTitle];
    self.tableView.tableHeaderView = self.headerContentView;
    [self updateTableHeaderHeightIfNeeded];
}

- (void)setupPostImageViews {
    for (UIView *subview in self.postImageScrollView.subviews) {
        [subview removeFromSuperview];
    }

    NSArray<NSString *> *imageNames = [self postImageNames];
    if (imageNames.count == 0) {
        imageNames = @[@"bigimage"];
    }

    NSMutableArray<UIImageView *> *imageViews = [NSMutableArray array];
    for (NSString *imageName in imageNames) {
        UIImage *image = [[YGImagePostStore sharedStore] imageForPostImageName:imageName] ?: [UIImage imageNamed:imageName] ?: [UIImage imageNamed:@"bigimage"];
        UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView.clipsToBounds = YES;
        [self.postImageScrollView addSubview:imageView];
        [imageViews addObject:imageView];
    }
    self.postImageViews = [imageViews copy] ?: @[];
    self.postImageScrollView.scrollEnabled = self.postImageViews.count > 1;
    self.postImageScrollView.contentSize = CGSizeZero;
    self.postImageScrollView.contentOffset = CGPointZero;
}

- (void)layoutPostImages {
    CGFloat width = CGRectGetWidth(self.postImageScrollView.bounds);
    CGFloat height = CGRectGetHeight(self.postImageScrollView.bounds);
    if (width <= 0.0 || height <= 0.0) {
        return;
    }

    [self.postImageViews enumerateObjectsUsingBlock:^(UIImageView *imageView, NSUInteger index, __unused BOOL *stop) {
        imageView.frame = CGRectMake(width * index, 0.0, width, height);
    }];
    NSInteger pageCount = self.postImageViews.count;
    self.postImageScrollView.contentSize = CGSizeMake(width * pageCount, height);
    if (pageCount == 0) {
        self.postPageControl.currentPage = 0;
        self.postImageScrollView.contentOffset = CGPointZero;
        return;
    }
    NSInteger currentPage = MAX(0, MIN(self.postPageControl.currentPage, pageCount - 1));
    self.postPageControl.currentPage = currentPage;
    self.postImageScrollView.contentOffset = CGPointMake(width * currentPage, 0.0);
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView != self.postImageScrollView) {
        return;
    }
    if (self.postImageViews.count <= 1) {
        if (!CGPointEqualToPoint(scrollView.contentOffset, CGPointZero)) {
            scrollView.contentOffset = CGPointZero;
        }
        self.postPageControl.currentPage = 0;
        return;
    }

    CGFloat width = CGRectGetWidth(scrollView.bounds);
    if (width <= 0.0) {
        return;
    }
    NSInteger page = (NSInteger)round(scrollView.contentOffset.x / width);
    page = MAX(0, MIN(page, self.postPageControl.numberOfPages - 1));
    self.postPageControl.currentPage = page;
}

- (void)updateTableHeaderHeightIfNeeded {
    if (self.headerContentView == nil || self.tableView == nil) {
        return;
    }

    CGFloat width = CGRectGetWidth(self.tableView.bounds);
    if (width <= 0.0) {
        width = CGRectGetWidth(self.view.bounds);
    }
    if (width <= 0.0) {
        return;
    }

    CGRect frame = self.headerContentView.frame;
    frame.size.width = width;
    self.headerContentView.frame = frame;

    CGSize fittingSize = [self.headerContentView systemLayoutSizeFittingSize:CGSizeMake(width, UILayoutFittingCompressedSize.height)
                                                withHorizontalFittingPriority:UILayoutPriorityRequired
                                                      verticalFittingPriority:UILayoutPriorityFittingSizeLevel];
    CGFloat targetHeight = ceil(fittingSize.height);
    if (fabs(CGRectGetHeight(self.headerContentView.frame) - targetHeight) > 0.5) {
        frame.size.height = targetHeight;
        self.headerContentView.frame = frame;
        self.tableView.tableHeaderView = self.headerContentView;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.comments.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    YGPersonDetailCommentCell *cell = [tableView dequeueReusableCellWithIdentifier:YGPersonDetailCommentCell.reuseIdentifier forIndexPath:indexPath];
    NSDictionary<NSString *, id> *comment = self.comments[indexPath.row];
    [cell configureWithComment:comment];
    BOOL isCurrentUserComment = [self isCurrentUserComment:comment];
    [cell setMoreHidden:isCurrentUserComment];
    __weak typeof(self) weakSelf = self;
    cell.moreTapHandler = isCurrentUserComment ? nil : ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf == nil) {
            return;
        }
        [strongSelf showMoreActionsForComment:comment];
    };
    return cell;
}

- (void)sendButtonTapped {
    if ([self showLoginPromptIfNeeded]) {
        return;
    }
    NSString *text = [self.inputTextView.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (text.length == 0) {
        return;
    }

    NSInteger newRow = self.comments.count;
    NSDictionary *comment = @{
        @"avatarImage": [self currentUserAvatarImage],
        @"avatarName": @"headplace",
        @"avatarLocalPath": [self currentUserAvatarLocalPath],
        @"avatarDataBase64": [self currentUserAvatarDataBase64],
        @"avatarImageName": [self currentUserAvatarImageName],
        @"authorId": [NSString stringWithFormat:@"user:%@", [[YGUserStore sharedStore] currentUserEmail] ?: @""],
        @"userId": [[YGUserStore sharedStore] currentUserEmail] ?: @"",
        @"userName": [self currentUserName],
        @"text": text,
        @"time": @"Just now"
    };
    [self.comments addObject:comment];
    [[YGImagePostStore sharedStore] addComment:[self persistableCommentFromComment:comment] toPostId:self.item[@"postId"]];
    self.inputTextView.text = @"";
    [self updateInputTextViewHeightKeepingLatestVisible:NO];
    [self updateCommentTitle];

    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:newRow inSection:0];
    [self.tableView performBatchUpdates:^{
        [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    } completion:^(__unused BOOL finished) {
        [self scrollToLatestCommentAnimated:YES];
    }];
}

- (void)likeBadgeTapped {
    if ([self showLoginPromptIfNeeded]) {
        return;
    }
    self.likeCount = [[YGImagePostStore sharedStore] toggleLikeForPostId:self.item[@"postId"]];
    self.liked = [[YGImagePostStore sharedStore] isCurrentUserLikedPostId:self.item[@"postId"]];
    [self updateLikeView];
}

- (void)showMoreActionsForComment:(NSDictionary *)comment {
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
        [[YGBlacklistStore sharedStore] addBlockedUser:comment];
        NSString *userId = [strongSelf userIdFromComment:comment];
        if (userId.length > 0) {
            [[YGFollowStore sharedStore] unfollowUserId:userId];
        }
        [strongSelf reloadVisibleComments];
        [YGHUDHelper showCenterText:@"Block successful." inView:targetView];
    }];
}

- (void)reloadVisibleComments {
    self.comments = [[[YGImagePostStore sharedStore] commentsForPostId:self.item[@"postId"]] mutableCopy];
    if (self.comments == nil) {
        self.comments = [NSMutableArray array];
    }
    [self updateCommentTitle];
    [self.tableView reloadData];
}

- (void)blacklistDidChange:(NSNotification *)notification {
    if ([[YGBlacklistStore sharedStore] isBlockedUserId:[self userId]]) {
        [self.navigationController popToRootViewControllerAnimated:YES];
        return;
    }
    [self reloadVisibleComments];
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

- (void)textViewDidChange:(UITextView *)textView {
    self.placeholderLabel.hidden = textView.text.length > 0;
    [self updateInputTextViewHeight];
}

- (void)updateInputTextViewHeight {
    [self updateInputTextViewHeightKeepingLatestVisible:YES];
}

- (void)updateInputTextViewHeightKeepingLatestVisible:(BOOL)keepLatestVisible {
    CGFloat lineHeight = self.inputTextView.font.lineHeight;
    CGFloat minHeight = 44.0;
    CGFloat maxTextHeight = ceil(lineHeight * 4.0 + self.inputTextView.textContainerInset.top + self.inputTextView.textContainerInset.bottom);
    CGSize fittingSize = [self.inputTextView sizeThatFits:CGSizeMake(CGRectGetWidth(self.inputTextView.bounds), CGFLOAT_MAX)];
    CGFloat targetHeight = MIN(MAX(ceil(fittingSize.height), minHeight), maxTextHeight);

    self.fieldContainerHeightConstraint.constant = targetHeight;
    self.inputBarHeightConstraint.constant = targetHeight + 30.0;
    self.inputTextView.scrollEnabled = fittingSize.height > maxTextHeight;
    self.placeholderLabel.hidden = self.inputTextView.text.length > 0;
    [UIView animateWithDuration:0.2 animations:^{
        [self.view layoutIfNeeded];
        if (keepLatestVisible) {
            [self scrollToLatestCommentAnimated:NO];
        }
    }];
}

- (void)setupKeyboardHandler {
    __weak typeof(self) weakSelf = self;
    self.keyboardHandler = [[YGKeyboardHandler alloc] initWithView:self.view changeHandler:^(CGFloat keyboardHeight, NSTimeInterval duration, UIViewAnimationOptions options) {
        [weakSelf updateInputBarBottomWithKeyboardHeight:keyboardHeight duration:duration options:options];
    }];
}

- (void)updateInputBarBottomWithKeyboardHeight:(CGFloat)keyboardHeight duration:(NSTimeInterval)duration options:(UIViewAnimationOptions)options {
    self.inputBarBottomConstraint.constant = -keyboardHeight;
    [UIView animateWithDuration:duration
                          delay:0.0
                        options:options
                     animations:^{
        [self.view layoutIfNeeded];
        if (keyboardHeight > 0.0) {
            [self scrollToLatestCommentAnimated:NO];
        }
    } completion:nil];
}

- (void)scrollToLatestCommentAnimated:(BOOL)animated {
    NSInteger sectionCount = [self.tableView numberOfSections];
    if (sectionCount == 0) {
        return;
    }

    [self.tableView layoutIfNeeded];
    NSInteger rowCount = [self.tableView numberOfRowsInSection:0];
    if (rowCount == 0) {
        return;
    }

    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:rowCount - 1 inSection:0];
    [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:animated];
}

- (void)updateCommentTitle {
    self.commentTitleLabel.text = [NSString stringWithFormat:@"Comment (%lu)", (unsigned long)self.comments.count];
    [self updateTableHeaderHeightIfNeeded];
}

- (NSString *)avatarName {
    NSString *avatarName = self.item[@"avatarName"];
    return avatarName.length > 0 ? avatarName : @"headplace";
}

- (UIImage *)avatarImage {
    UIImage *avatarImage = [[YGImagePostStore sharedStore] avatarImageForPost:self.item];
    if (avatarImage != nil) {
        return avatarImage;
    }
    return [UIImage imageNamed:[self avatarName]];
}

- (NSString *)userName {
    NSString *userName = self.item[@"userName"];
    return userName.length > 0 ? userName : @"Allan";
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

- (NSString *)detailDescriptionText {
    NSString *descriptionText = self.item[@"descriptionText"];
    return descriptionText.length > 0 ? descriptionText : @"Morning yoga flow to start the day. Calm mind, strong body.";
}

- (NSArray<NSString *> *)postImageNames {
    NSArray *imageNames = [self.item[@"imageNames"] isKindOfClass:NSArray.class] ? self.item[@"imageNames"] : nil;
    if (imageNames.count > 0) {
        return imageNames;
    }

    NSString *contentImageName = [self.item[@"contentImageName"] isKindOfClass:NSString.class] ? self.item[@"contentImageName"] : @"";
    if (contentImageName.length > 0) {
        return @[contentImageName];
    }
    return @[@"bigimage"];
}

- (NSString *)currentUserName {
    NSDictionary *currentUser = [[YGUserStore sharedStore] currentUser];
    NSString *nickname = [currentUser[@"nickname"] isKindOfClass:NSString.class] ? currentUser[@"nickname"] : @"";
    return nickname.length > 0 ? nickname : @"Yaga User";
}

- (UIImage *)currentUserAvatarImage {
    NSDictionary *currentUser = [[YGUserStore sharedStore] currentUser];
    NSString *avatarLocalPath = [currentUser[@"avatarLocalPath"] isKindOfClass:NSString.class] ? currentUser[@"avatarLocalPath"] : @"";
    if (avatarLocalPath.length > 0) {
        UIImage *image = [UIImage imageWithContentsOfFile:avatarLocalPath];
        if (image != nil) {
            return image;
        }
    }

    NSString *avatarBase64 = [currentUser[@"avatarDataBase64"] isKindOfClass:NSString.class] ? currentUser[@"avatarDataBase64"] : @"";
    if (avatarBase64.length > 0) {
        NSData *imageData = [[NSData alloc] initWithBase64EncodedString:avatarBase64 options:0];
        UIImage *image = [UIImage imageWithData:imageData];
        if (image != nil) {
            return image;
        }
    }

    NSString *avatarImageName = [currentUser[@"avatarImageName"] isKindOfClass:NSString.class] ? currentUser[@"avatarImageName"] : @"";
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

    NSString *avatarName = [currentUser[@"avatarName"] isKindOfClass:NSString.class] ? currentUser[@"avatarName"] : @"";
    if (avatarName.length > 0) {
        UIImage *image = [UIImage imageNamed:avatarName];
        if (image != nil) {
            return image;
        }
    }

    return [UIImage imageNamed:@"headplace"];
}

- (NSString *)currentUserAvatarLocalPath {
    NSDictionary *currentUser = [[YGUserStore sharedStore] currentUser];
    NSString *avatarLocalPath = [currentUser[@"avatarLocalPath"] isKindOfClass:NSString.class] ? currentUser[@"avatarLocalPath"] : @"";
    return avatarLocalPath.length > 0 ? avatarLocalPath : @"";
}

- (NSString *)currentUserAvatarDataBase64 {
    NSDictionary *currentUser = [[YGUserStore sharedStore] currentUser];
    NSString *avatarBase64 = [currentUser[@"avatarDataBase64"] isKindOfClass:NSString.class] ? currentUser[@"avatarDataBase64"] : @"";
    return avatarBase64.length > 0 ? avatarBase64 : @"";
}

- (NSString *)currentUserAvatarImageName {
    NSDictionary *currentUser = [[YGUserStore sharedStore] currentUser];
    NSString *avatarImageName = [currentUser[@"avatarImageName"] isKindOfClass:NSString.class] ? currentUser[@"avatarImageName"] : @"";
    return avatarImageName.length > 0 ? avatarImageName : @"";
}

- (NSDictionary *)persistableCommentFromComment:(NSDictionary *)comment {
    NSMutableDictionary *persistableComment = [comment mutableCopy];
    [persistableComment removeObjectForKey:@"avatarImage"];
    return [persistableComment copy];
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

- (BOOL)isCurrentUserComment:(NSDictionary *)comment {
    NSString *currentUserId = [[YGUserStore sharedStore] currentUserEmail];
    if (currentUserId.length == 0) {
        return NO;
    }
    return [[self userIdFromComment:comment] isEqualToString:currentUserId];
}

- (NSArray<NSDictionary<NSString *, id> *> *)mockComments {
    return @[
        @{
            @"avatarName": @"headplace",
            @"userName": @"Vuyolwethu",
            @"text": @"Would you like to try chatting with me about those things that bother you?",
            @"time": @"10m ago"
        }
    ];
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
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
