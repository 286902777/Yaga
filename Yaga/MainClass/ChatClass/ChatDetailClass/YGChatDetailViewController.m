//
//  YGChatDetailViewController.m
//  Yaga
//

#import "YGChatDetailViewController.h"
#import "YGUserStore.h"
#import "YGKeyboardHandler.h"
#import "YGImagePostStore.h"
#import "YGVideoPostStore.h"
#import "YGChatStore.h"
#import "YGMoreActionSheetView.h"
#import "YGReportViewController.h"
#import "YGBlacklistStore.h"
#import "YGFollowStore.h"
#import "YGHUDHelper.h"
#import <AVFoundation/AVFoundation.h>

@interface YGChatDetailMessageCell : UITableViewCell

+ (NSString *)reuseIdentifier;
- (void)configureWithMessage:(NSDictionary<NSString *, id> *)message avatarImage:(UIImage *)avatarImage isCurrentUser:(BOOL)isCurrentUser;

@end

@interface YGChatDetailMessageCell ()

@property (nonatomic, strong) UIImageView *avatarImageView;
@property (nonatomic, strong) UIView *bubbleView;
@property (nonatomic, strong) UILabel *messageLabel;
@property (nonatomic, strong) UIView *voiceContentView;
@property (nonatomic, strong) UILabel *voiceDurationLabel;
@property (nonatomic, strong) NSArray<UIView *> *voiceBars;
@property (nonatomic, strong) NSLayoutConstraint *bubbleWidthConstraint;
@property (nonatomic, strong) NSLayoutConstraint *bubbleHeightConstraint;
@property (nonatomic, strong) NSArray<NSLayoutConstraint *> *leftConstraints;
@property (nonatomic, strong) NSArray<NSLayoutConstraint *> *rightConstraints;

@end

@implementation YGChatDetailMessageCell

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

- (void)prepareForReuse {
    [super prepareForReuse];
    self.avatarImageView.image = nil;
    self.messageLabel.text = nil;
    self.messageLabel.hidden = NO;
    self.voiceContentView.hidden = YES;
    self.voiceDurationLabel.text = nil;
    self.bubbleWidthConstraint.active = NO;
    self.bubbleHeightConstraint.active = NO;
    [NSLayoutConstraint deactivateConstraints:self.leftConstraints];
    [NSLayoutConstraint deactivateConstraints:self.rightConstraints];
}

- (void)setupViews {
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.backgroundColor = UIColor.clearColor;
    self.contentView.backgroundColor = UIColor.clearColor;

    self.avatarImageView = [[UIImageView alloc] init];
    self.avatarImageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.avatarImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.avatarImageView.clipsToBounds = YES;
    self.avatarImageView.layer.cornerRadius = 18.0;
    [self.contentView addSubview:self.avatarImageView];

    self.bubbleView = [[UIView alloc] init];
    self.bubbleView.translatesAutoresizingMaskIntoConstraints = NO;
    self.bubbleView.layer.cornerRadius = 14.0;
    self.bubbleView.clipsToBounds = YES;
    [self.contentView addSubview:self.bubbleView];

    self.messageLabel = [[UILabel alloc] init];
    self.messageLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.messageLabel.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightRegular];
    self.messageLabel.numberOfLines = 0;
    [self.bubbleView addSubview:self.messageLabel];

    self.voiceContentView = [[UIView alloc] init];
    self.voiceContentView.translatesAutoresizingMaskIntoConstraints = NO;
    self.voiceContentView.hidden = YES;
    [self.bubbleView addSubview:self.voiceContentView];

    NSMutableArray<UIView *> *bars = [NSMutableArray array];
    NSArray<NSNumber *> *barHeights = @[@5.0, @8.0, @12.0, @8.0, @5.0];
    UIView *previousBar = nil;
    for (NSNumber *height in barHeights) {
        UIView *bar = [[UIView alloc] init];
        bar.translatesAutoresizingMaskIntoConstraints = NO;
        bar.backgroundColor = UIColor.whiteColor;
        bar.layer.cornerRadius = 1.0;
        [self.voiceContentView addSubview:bar];
        [NSLayoutConstraint activateConstraints:@[
            [bar.centerYAnchor constraintEqualToAnchor:self.voiceContentView.centerYAnchor],
            [bar.widthAnchor constraintEqualToConstant:1.2],
            [bar.heightAnchor constraintEqualToConstant:height.doubleValue]
        ]];
        if (previousBar == nil) {
            [bar.leadingAnchor constraintEqualToAnchor:self.voiceContentView.leadingAnchor].active = YES;
        } else {
            [bar.leadingAnchor constraintEqualToAnchor:previousBar.trailingAnchor constant:2.6].active = YES;
        }
        previousBar = bar;
        [bars addObject:bar];
    }
    self.voiceBars = [bars copy];

    self.voiceDurationLabel = [[UILabel alloc] init];
    self.voiceDurationLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.voiceDurationLabel.textColor = UIColor.whiteColor;
    self.voiceDurationLabel.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightMedium];
    [self.voiceContentView addSubview:self.voiceDurationLabel];

    self.bubbleWidthConstraint = [self.bubbleView.widthAnchor constraintEqualToConstant:82.0];
    self.bubbleHeightConstraint = [self.bubbleView.heightAnchor constraintEqualToConstant:36.0];

    self.leftConstraints = @[
        [self.avatarImageView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:20.0],
        [self.bubbleView.leadingAnchor constraintEqualToAnchor:self.avatarImageView.trailingAnchor constant:10.0],
        [self.bubbleView.trailingAnchor constraintLessThanOrEqualToAnchor:self.contentView.trailingAnchor constant:-86.0]
    ];

    self.rightConstraints = @[
        [self.avatarImageView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-20.0],
        [self.bubbleView.trailingAnchor constraintEqualToAnchor:self.avatarImageView.leadingAnchor constant:-10.0],
        [self.bubbleView.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.contentView.leadingAnchor constant:86.0]
    ];

    [NSLayoutConstraint activateConstraints:@[
        [self.avatarImageView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:6.0],
        [self.avatarImageView.widthAnchor constraintEqualToConstant:36.0],
        [self.avatarImageView.heightAnchor constraintEqualToConstant:36.0],

        [self.bubbleView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:6.0],
        [self.bubbleView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-14.0],

        [self.messageLabel.topAnchor constraintEqualToAnchor:self.bubbleView.topAnchor constant:10.0],
        [self.messageLabel.leadingAnchor constraintEqualToAnchor:self.bubbleView.leadingAnchor constant:12.0],
        [self.messageLabel.trailingAnchor constraintEqualToAnchor:self.bubbleView.trailingAnchor constant:-12.0],
        [self.messageLabel.bottomAnchor constraintEqualToAnchor:self.bubbleView.bottomAnchor constant:-10.0],

        [self.voiceContentView.topAnchor constraintEqualToAnchor:self.bubbleView.topAnchor],
        [self.voiceContentView.leadingAnchor constraintEqualToAnchor:self.bubbleView.leadingAnchor constant:9.0],
        [self.voiceContentView.trailingAnchor constraintEqualToAnchor:self.bubbleView.trailingAnchor constant:-12.0],
        [self.voiceContentView.bottomAnchor constraintEqualToAnchor:self.bubbleView.bottomAnchor],
        [self.voiceDurationLabel.leadingAnchor constraintEqualToAnchor:previousBar.trailingAnchor constant:8.0],
        [self.voiceDurationLabel.centerYAnchor constraintEqualToAnchor:self.voiceContentView.centerYAnchor],
        [self.voiceDurationLabel.trailingAnchor constraintEqualToAnchor:self.voiceContentView.trailingAnchor]
    ]];
}

- (void)configureWithMessage:(NSDictionary<NSString *, id> *)message avatarImage:(UIImage *)avatarImage isCurrentUser:(BOOL)isCurrentUser {
    NSString *text = [message[@"text"] isKindOfClass:NSString.class] ? message[@"text"] : @"";
    BOOL isVoiceMessage = [message[@"voiceLocalPath"] isKindOfClass:NSString.class] && [message[@"voiceLocalPath"] length] > 0;
    self.avatarImageView.image = avatarImage;
    self.messageLabel.hidden = isVoiceMessage;
    self.voiceContentView.hidden = !isVoiceMessage;
    if (isVoiceMessage) {
        self.messageLabel.text = nil;
        self.voiceDurationLabel.text = text.length > 0 ? text : @"1''";
        self.bubbleWidthConstraint.active = YES;
        self.bubbleHeightConstraint.active = YES;
        self.bubbleView.layer.cornerRadius = 18.0;
    } else {
        self.messageLabel.text = text;
        self.bubbleWidthConstraint.active = NO;
        self.bubbleHeightConstraint.active = NO;
        self.bubbleView.layer.cornerRadius = 14.0;
    }
    self.bubbleView.backgroundColor = isCurrentUser ? [self colorWithHexString:@"#C719F3"] : UIColor.whiteColor;
    self.messageLabel.textColor = isCurrentUser ? UIColor.whiteColor : UIColor.blackColor;
    self.voiceDurationLabel.textColor = isCurrentUser ? UIColor.whiteColor : UIColor.blackColor;
    for (UIView *bar in self.voiceBars) {
        bar.backgroundColor = isCurrentUser ? UIColor.whiteColor : UIColor.blackColor;
    }

    [NSLayoutConstraint deactivateConstraints:self.leftConstraints];
    [NSLayoutConstraint deactivateConstraints:self.rightConstraints];
    [NSLayoutConstraint activateConstraints:isCurrentUser ? self.rightConstraints : self.leftConstraints];
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

@interface YGChatDetailViewController () <UITextViewDelegate, UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate, AVAudioRecorderDelegate, AVAudioPlayerDelegate>

@property (nonatomic, copy) NSDictionary<NSString *, id> *userInfo;
@property (nonatomic, strong) UIButton *rightIconButton;
@property (nonatomic, strong) UIImageView *titleAvatarImageView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIView *inputBarView;
@property (nonatomic, strong) UIView *fieldContainerView;
@property (nonatomic, strong) UITextView *inputTextView;
@property (nonatomic, strong) UILabel *placeholderLabel;
@property (nonatomic, strong) NSLayoutConstraint *inputBarBottomConstraint;
@property (nonatomic, strong) NSLayoutConstraint *inputBarHeightConstraint;
@property (nonatomic, strong) NSLayoutConstraint *fieldContainerHeightConstraint;
@property (nonatomic, strong) UIButton *sendButton;
@property (nonatomic, strong) UIButton *voiceButton;
@property (nonatomic, strong) UIView *voiceOverlayView;
@property (nonatomic, strong) UIView *voicePanelView;
@property (nonatomic, strong) UIButton *voiceRecordButton;
@property (nonatomic, assign) BOOL voiceRecording;
@property (nonatomic, strong) UILabel *voiceStatusLabel;
@property (nonatomic, strong) CAShapeLayer *voiceRippleLayer;
@property (nonatomic, strong) AVAudioRecorder *audioRecorder;
@property (nonatomic, strong) AVAudioPlayer *audioPlayer;
@property (nonatomic, strong) NSTimer *voiceMeterTimer;
@property (nonatomic, strong) NSDate *voiceRecordStartDate;
@property (nonatomic, copy) NSString *currentVoicePath;
@property (nonatomic, strong) NSMutableArray<NSDictionary<NSString *, id> *> *messages;
@property (nonatomic, strong) YGKeyboardHandler *keyboardHandler;

@end

@implementation YGChatDetailViewController

- (instancetype)initWithUserInfo:(NSDictionary<NSString *, id> *)userInfo {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _userInfo = [userInfo copy];
        _messages = [[[YGChatStore sharedStore] messagesForUserInfo:userInfo] mutableCopy];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = UIColor.whiteColor;
    [self setupNavigationHeader];
    [self setupInputBarView];
    [self setupTableView];
    [self setupKeyboardHandler];
}

- (void)dealloc {
    [self.voiceMeterTimer invalidate];
    [self.audioRecorder stop];
    [self.audioPlayer stop];
}

- (void)setupNavigationHeader {
    self.rightIconButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.rightIconButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.rightIconButton.backgroundColor = UIColor.clearColor;
    self.rightIconButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.rightIconButton setImage:[UIImage imageNamed:@"whitemore"] forState:UIControlStateNormal];
    [self.rightIconButton addTarget:self action:@selector(moreButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.rightIconButton.widthAnchor constraintEqualToConstant:40.0].active = YES;
    [self.rightIconButton.heightAnchor constraintEqualToConstant:40.0].active = YES;
    [self yg_setRightView:self.rightIconButton];

    self.titleAvatarImageView = [[UIImageView alloc] initWithImage:[self otherAvatarImage]];
    self.titleAvatarImageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.titleAvatarImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.titleAvatarImageView.clipsToBounds = YES;
    self.titleAvatarImageView.layer.cornerRadius = 20.0;
    [self.yg_navigationBarView addSubview:self.titleAvatarImageView];

    self.nameLabel = [[UILabel alloc] init];
    self.nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.nameLabel.text = [self displayName];
    self.nameLabel.textColor = UIColor.blackColor;
    self.nameLabel.font = [UIFont boldSystemFontOfSize:17.0];
    [self.yg_navigationBarView addSubview:self.nameLabel];

    [NSLayoutConstraint activateConstraints:@[
        [self.titleAvatarImageView.leadingAnchor constraintEqualToAnchor:self.yg_leftContainerView.trailingAnchor constant:10.0],
        [self.titleAvatarImageView.centerYAnchor constraintEqualToAnchor:self.yg_rightContainerView.centerYAnchor],
        [self.titleAvatarImageView.widthAnchor constraintEqualToConstant:40.0],
        [self.titleAvatarImageView.heightAnchor constraintEqualToConstant:40.0],

        [self.nameLabel.leadingAnchor constraintEqualToAnchor:self.titleAvatarImageView.trailingAnchor constant:8.0],
        [self.nameLabel.centerYAnchor constraintEqualToAnchor:self.titleAvatarImageView.centerYAnchor],
        [self.nameLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.yg_rightContainerView.leadingAnchor constant:-12.0]
    ]];
}

- (void)moreButtonTapped {
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
        [[YGBlacklistStore sharedStore] addBlockedUser:[strongSelf blacklistUserInfo]];
        [[YGFollowStore sharedStore] unfollowUserId:[strongSelf otherUserId]];
        [YGHUDHelper showCenterText:@"Block successful." inView:targetView];
        [strongSelf.navigationController popViewControllerAnimated:YES];
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

    self.voiceButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.voiceButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.voiceButton.backgroundColor = UIColor.clearColor;
    self.voiceButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.voiceButton setImage:[UIImage imageNamed:@"talkone"] forState:UIControlStateNormal];
    [self.voiceButton addTarget:self action:@selector(voiceButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.fieldContainerView addSubview:self.voiceButton];

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

        [self.fieldContainerView.leadingAnchor constraintEqualToAnchor:self.inputBarView.leadingAnchor constant:20.0],
        [self.fieldContainerView.topAnchor constraintEqualToAnchor:self.inputBarView.topAnchor constant:10.0],
        [self.fieldContainerView.trailingAnchor constraintEqualToAnchor:self.sendButton.leadingAnchor constant:-10.0],
        self.fieldContainerHeightConstraint,

        [self.inputTextView.leadingAnchor constraintEqualToAnchor:self.fieldContainerView.leadingAnchor constant:16.0],
        [self.inputTextView.trailingAnchor constraintEqualToAnchor:self.voiceButton.leadingAnchor constant:-8.0],
        [self.inputTextView.topAnchor constraintEqualToAnchor:self.fieldContainerView.topAnchor],
        [self.inputTextView.bottomAnchor constraintEqualToAnchor:self.fieldContainerView.bottomAnchor],

        [self.placeholderLabel.leadingAnchor constraintEqualToAnchor:self.inputTextView.leadingAnchor],
        [self.placeholderLabel.topAnchor constraintEqualToAnchor:self.fieldContainerView.topAnchor constant:12.0],
        [self.placeholderLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.inputTextView.trailingAnchor],

        [self.voiceButton.trailingAnchor constraintEqualToAnchor:self.fieldContainerView.trailingAnchor constant:-10.0],
        [self.voiceButton.centerYAnchor constraintEqualToAnchor:self.fieldContainerView.centerYAnchor],
        [self.voiceButton.widthAnchor constraintEqualToConstant:30.0],
        [self.voiceButton.heightAnchor constraintEqualToConstant:30.0],

        [self.sendButton.trailingAnchor constraintEqualToAnchor:self.inputBarView.trailingAnchor constant:-20.0],
        [self.sendButton.centerYAnchor constraintEqualToAnchor:self.fieldContainerView.centerYAnchor],
        [self.sendButton.widthAnchor constraintEqualToConstant:44.0],
        [self.sendButton.heightAnchor constraintEqualToConstant:44.0]
    ]];
}

- (void)voiceButtonTapped {
    [self.view endEditing:YES];
    [self showVoiceSheet];
}

- (void)showVoiceSheet {
    if (self.voiceOverlayView.superview != nil) {
        return;
    }

    UIView *containerView = self.navigationController.view ?: self.view;

    self.voiceOverlayView = [[UIView alloc] init];
    self.voiceOverlayView.translatesAutoresizingMaskIntoConstraints = NO;
    self.voiceOverlayView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.25];
    [containerView addSubview:self.voiceOverlayView];

    UITapGestureRecognizer *overlayTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissVoiceSheet)];
    overlayTap.delegate = self;
    [self.voiceOverlayView addGestureRecognizer:overlayTap];

    self.voicePanelView = [[UIView alloc] init];
    self.voicePanelView.translatesAutoresizingMaskIntoConstraints = NO;
    self.voicePanelView.backgroundColor = UIColor.whiteColor;
    self.voicePanelView.layer.cornerRadius = 20.0;
    if (@available(iOS 11.0, *)) {
        self.voicePanelView.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
    }
    self.voicePanelView.clipsToBounds = YES;
    [self.voiceOverlayView addSubview:self.voicePanelView];

    self.voiceRecordButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.voiceRecordButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.voiceRecordButton.backgroundColor = UIColor.clearColor;
    self.voiceRecordButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.voiceRecordButton setImage:[UIImage imageNamed:@"talktwo"] forState:UIControlStateNormal];
    [self.voiceRecordButton addTarget:self action:@selector(voiceRecordTouchDown) forControlEvents:UIControlEventTouchDown];
    [self.voiceRecordButton addTarget:self action:@selector(voiceRecordTouchUp) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside | UIControlEventTouchCancel];
    [self.voicePanelView addSubview:self.voiceRecordButton];

    self.voiceStatusLabel = [[UILabel alloc] init];
    self.voiceStatusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.voiceStatusLabel.text = @"Hold to talk";
    self.voiceStatusLabel.textColor = [self colorWithHexString:@"#808080"];
    self.voiceStatusLabel.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightMedium];
    self.voiceStatusLabel.textAlignment = NSTextAlignmentCenter;
    [self.voicePanelView addSubview:self.voiceStatusLabel];

    [NSLayoutConstraint activateConstraints:@[
        [self.voiceOverlayView.topAnchor constraintEqualToAnchor:containerView.topAnchor],
        [self.voiceOverlayView.leadingAnchor constraintEqualToAnchor:containerView.leadingAnchor],
        [self.voiceOverlayView.trailingAnchor constraintEqualToAnchor:containerView.trailingAnchor],
        [self.voiceOverlayView.bottomAnchor constraintEqualToAnchor:containerView.bottomAnchor],

        [self.voicePanelView.leadingAnchor constraintEqualToAnchor:containerView.leadingAnchor],
        [self.voicePanelView.trailingAnchor constraintEqualToAnchor:containerView.trailingAnchor],
        [self.voicePanelView.bottomAnchor constraintEqualToAnchor:containerView.bottomAnchor],
        [self.voicePanelView.heightAnchor constraintEqualToConstant:190.0],

        [self.voiceRecordButton.centerXAnchor constraintEqualToAnchor:self.voicePanelView.centerXAnchor],
        [self.voiceRecordButton.centerYAnchor constraintEqualToAnchor:self.voicePanelView.centerYAnchor constant:-12.0],
        [self.voiceRecordButton.widthAnchor constraintEqualToConstant:56.0],
        [self.voiceRecordButton.heightAnchor constraintEqualToConstant:56.0],

        [self.voiceStatusLabel.topAnchor constraintEqualToAnchor:self.voiceRecordButton.bottomAnchor constant:8.0],
        [self.voiceStatusLabel.leadingAnchor constraintEqualToAnchor:self.voicePanelView.leadingAnchor constant:20.0],
        [self.voiceStatusLabel.trailingAnchor constraintEqualToAnchor:self.voicePanelView.trailingAnchor constant:-20.0]
    ]];
    [self setupVoiceRippleLayer];

    self.voiceOverlayView.alpha = 0.0;
    self.voicePanelView.transform = CGAffineTransformMakeTranslation(0.0, 190.0);
    [UIView animateWithDuration:0.25 animations:^{
        self.voiceOverlayView.alpha = 1.0;
        self.voicePanelView.transform = CGAffineTransformIdentity;
    }];
}

- (void)voiceRecordTouchDown {
    [self requestAudioPermissionAndStartRecording];
}

- (void)voiceRecordTouchUp {
    if (!self.voiceRecording) {
        return;
    }
    self.voiceRecording = NO;
    [self stopVoiceMeterTimer];
    NSTimeInterval duration = [[NSDate date] timeIntervalSinceDate:self.voiceRecordStartDate ?: [NSDate date]];
    [self.audioRecorder stop];
    self.audioRecorder = nil;
    [self stopVoiceRipple];
    self.voiceStatusLabel.text = @"Hold to talk";
    [UIView animateWithDuration:0.12 animations:^{
        self.voiceRecordButton.transform = CGAffineTransformIdentity;
    } completion:^(__unused BOOL finished) {
        [self sendVoiceMessageWithDuration:duration];
    }];
}

- (void)requestAudioPermissionAndStartRecording {
    AVAudioSessionRecordPermission permission = AVAudioSession.sharedInstance.recordPermission;
    if (permission == AVAudioSessionRecordPermissionGranted) {
        [self startVoiceRecording];
        return;
    }
    if (permission == AVAudioSessionRecordPermissionDenied) {
        [YGHUDHelper showCenterText:@"Microphone permission is required." inView:self.navigationController.view ?: self.view];
        return;
    }

    __weak typeof(self) weakSelf = self;
    [AVAudioSession.sharedInstance requestRecordPermission:^(BOOL granted) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (granted) {
                weakSelf.voiceRecording = NO;
                weakSelf.voiceStatusLabel.text = @"Hold to talk";
                [YGHUDHelper showCenterText:@"Hold again to record." inView:weakSelf.navigationController.view ?: weakSelf.view];
            } else {
                [YGHUDHelper showCenterText:@"Microphone permission is required." inView:weakSelf.navigationController.view ?: weakSelf.view];
            }
        });
    }];
}

- (void)startVoiceRecording {
    if (self.voiceRecording) {
        return;
    }

    NSError *sessionError = nil;
    AVAudioSession *session = AVAudioSession.sharedInstance;
    [session setCategory:AVAudioSessionCategoryPlayAndRecord mode:AVAudioSessionModeDefault options:AVAudioSessionCategoryOptionDefaultToSpeaker error:&sessionError];
    [session setActive:YES error:&sessionError];

    NSString *voicePath = [self newVoiceFilePath];
    NSURL *voiceURL = [NSURL fileURLWithPath:voicePath];
    NSDictionary *settings = @{
        AVFormatIDKey: @(kAudioFormatMPEG4AAC),
        AVSampleRateKey: @(44100.0),
        AVNumberOfChannelsKey: @(1),
        AVEncoderAudioQualityKey: @(AVAudioQualityHigh)
    };
    NSError *recorderError = nil;
    self.audioRecorder = [[AVAudioRecorder alloc] initWithURL:voiceURL settings:settings error:&recorderError];
    self.audioRecorder.delegate = self;
    self.audioRecorder.meteringEnabled = YES;
    if (self.audioRecorder == nil || recorderError != nil) {
        [YGHUDHelper showCenterText:@"Recording failed. Please try again." inView:self.navigationController.view ?: self.view];
        return;
    }

    self.currentVoicePath = voicePath;
    self.voiceRecordStartDate = [NSDate date];
    self.voiceRecording = [self.audioRecorder record];
    if (!self.voiceRecording) {
        [YGHUDHelper showCenterText:@"Recording failed. Please try again." inView:self.navigationController.view ?: self.view];
        return;
    }
    self.voiceStatusLabel.text = @"Release to send";
    [self startVoiceRipple];
    [self startVoiceMeterTimer];
    [UIView animateWithDuration:0.12 animations:^{
        self.voiceRecordButton.transform = CGAffineTransformMakeScale(0.94, 0.94);
    }];
}

- (void)sendVoiceMessageWithDuration:(NSTimeInterval)duration {
    if (self.currentVoicePath.length == 0 || duration < 0.5) {
        if (self.currentVoicePath.length > 0) {
            [NSFileManager.defaultManager removeItemAtPath:self.currentVoicePath error:nil];
        }
        [YGHUDHelper showCenterText:@"Recording is too short." inView:self.navigationController.view ?: self.view];
        return;
    }

    NSInteger roundedDuration = MAX(1, (NSInteger)ceil(duration));
    NSString *voiceText = [NSString stringWithFormat:@"%ld''", (long)roundedDuration];
    NSString *storedVoicePath = [self storedVoicePathForAbsolutePath:self.currentVoicePath];
    NSDictionary *message = @{
        @"text": voiceText,
        @"voiceLocalPath": storedVoicePath,
        @"voiceDuration": @(duration),
        @"isCurrentUser": @YES
    };
    [self.messages addObject:message];
    [[YGChatStore sharedStore] appendCurrentUserVoicePath:storedVoicePath duration:duration toUserInfo:self.userInfo];

    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.messages.count - 1 inSection:0];
    [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    [self scrollToBottomAnimated:YES];
    self.currentVoicePath = nil;
    [self dismissVoiceSheet];
}

- (void)dismissVoiceSheet {
    if (self.voiceOverlayView.superview == nil) {
        return;
    }

    if (self.voiceRecording) {
        [self stopVoiceMeterTimer];
        [self.audioRecorder stop];
        self.audioRecorder = nil;
        self.voiceRecording = NO;
        if (self.currentVoicePath.length > 0) {
            [NSFileManager.defaultManager removeItemAtPath:self.currentVoicePath error:nil];
            self.currentVoicePath = nil;
        }
    }
    [self stopVoiceRipple];
    [UIView animateWithDuration:0.2 animations:^{
        self.voiceOverlayView.alpha = 0.0;
        self.voicePanelView.transform = CGAffineTransformMakeTranslation(0.0, 190.0);
    } completion:^(__unused BOOL finished) {
        [self.voiceOverlayView removeFromSuperview];
        self.voiceOverlayView = nil;
        self.voicePanelView = nil;
        self.voiceRecordButton = nil;
        self.voiceRecording = NO;
    }];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if (gestureRecognizer.view == self.voiceOverlayView) {
        return touch.view == self.voiceOverlayView;
    }
    return YES;
}

- (NSString *)newVoiceFilePath {
    NSString *documentsDirectory = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    NSString *directoryPath = [documentsDirectory stringByAppendingPathComponent:@"YagaVoiceMessages"];
    if (![NSFileManager.defaultManager fileExistsAtPath:directoryPath]) {
        [NSFileManager.defaultManager createDirectoryAtPath:directoryPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSString *fileName = [NSString stringWithFormat:@"voice_%@.m4a", NSUUID.UUID.UUIDString];
    return [directoryPath stringByAppendingPathComponent:fileName];
}

- (NSString *)storedVoicePathForAbsolutePath:(NSString *)absolutePath {
    NSString *documentsDirectory = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    if (absolutePath.length > documentsDirectory.length && [absolutePath hasPrefix:documentsDirectory]) {
        NSString *relativePath = [absolutePath substringFromIndex:documentsDirectory.length];
        if ([relativePath hasPrefix:@"/"]) {
            relativePath = [relativePath substringFromIndex:1];
        }
        return relativePath;
    }
    return absolutePath ?: @"";
}

- (NSString *)absoluteVoicePathForStoredPath:(NSString *)storedPath {
    if (storedPath.length == 0) {
        return @"";
    }
    if ([storedPath hasPrefix:@"/"]) {
        if ([NSFileManager.defaultManager fileExistsAtPath:storedPath]) {
            return storedPath;
        }
        NSString *fileName = storedPath.lastPathComponent;
        NSString *fallbackPath = [[self documentsDirectory] stringByAppendingPathComponent:[@"YagaVoiceMessages" stringByAppendingPathComponent:fileName]];
        return fallbackPath;
    }
    return [[self documentsDirectory] stringByAppendingPathComponent:storedPath];
}

- (NSString *)documentsDirectory {
    return NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
}

- (void)setupVoiceRippleLayer {
    [self.voiceRippleLayer removeFromSuperlayer];
    CGFloat size = 92.0;
    CGRect rippleFrame = CGRectMake(0.0, 0.0, size, size);
    UIBezierPath *path = [UIBezierPath bezierPathWithOvalInRect:rippleFrame];
    CAShapeLayer *rippleLayer = [CAShapeLayer layer];
    rippleLayer.frame = CGRectMake(0.0, 0.0, size, size);
    rippleLayer.path = path.CGPath;
    rippleLayer.fillColor = [[self colorWithHexString:@"#B829FF"] colorWithAlphaComponent:0.18].CGColor;
    rippleLayer.opacity = 0.0;
    rippleLayer.position = CGPointMake(CGRectGetMidX(self.voicePanelView.bounds), CGRectGetMidY(self.voicePanelView.bounds));
    [self.voicePanelView.layer insertSublayer:rippleLayer below:self.voiceRecordButton.layer];
    self.voiceRippleLayer = rippleLayer;
    dispatch_async(dispatch_get_main_queue(), ^{
        self.voiceRippleLayer.position = self.voiceRecordButton.center;
    });
}

- (void)startVoiceRipple {
    [self.voiceRippleLayer removeAnimationForKey:@"voiceRipple"];
    self.voiceRippleLayer.opacity = 0.18;
    self.voiceRippleLayer.transform = CATransform3DMakeScale(0.9, 0.9, 1.0);
}

- (void)stopVoiceRipple {
    [self.voiceRippleLayer removeAnimationForKey:@"voiceRipple"];
    self.voiceRippleLayer.opacity = 0.0;
}

- (void)startVoiceMeterTimer {
    [self stopVoiceMeterTimer];
    self.voiceMeterTimer = [NSTimer scheduledTimerWithTimeInterval:0.14 target:self selector:@selector(updateVoiceMeter) userInfo:nil repeats:YES];
}

- (void)stopVoiceMeterTimer {
    [self.voiceMeterTimer invalidate];
    self.voiceMeterTimer = nil;
}

- (void)updateVoiceMeter {
    if (!self.voiceRecording || self.audioRecorder == nil) {
        return;
    }
    [self.audioRecorder updateMeters];
    float power = [self.audioRecorder averagePowerForChannel:0];
    CGFloat normalized = MIN(1.0, MAX(0.0, (power + 50.0) / 50.0));
    CGFloat scale = 0.92 + normalized * 0.38;
    CGFloat opacity = 0.14 + normalized * 0.38;
    [CATransaction begin];
    [CATransaction setAnimationDuration:0.16];
    [CATransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]];
    self.voiceRippleLayer.transform = CATransform3DMakeScale(scale, scale, 1.0);
    self.voiceRippleLayer.opacity = opacity;
    [CATransaction commit];
    NSTimeInterval duration = [[NSDate date] timeIntervalSinceDate:self.voiceRecordStartDate ?: [NSDate date]];
    self.voiceStatusLabel.text = [NSString stringWithFormat:@"Release to send %.0fs", floor(duration)];
}

- (void)setupTableView {
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.backgroundColor = UIColor.clearColor;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.showsVerticalScrollIndicator = NO;
    self.tableView.estimatedRowHeight = 70.0;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    if (@available(iOS 11.0, *)) {
        self.tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
    [self.tableView registerClass:YGChatDetailMessageCell.class forCellReuseIdentifier:YGChatDetailMessageCell.reuseIdentifier];
    [self.view addSubview:self.tableView];

    [NSLayoutConstraint activateConstraints:@[
        [self.tableView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:24.0],
        [self.tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.tableView.bottomAnchor constraintEqualToAnchor:self.inputBarView.topAnchor]
    ]];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.messages.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    YGChatDetailMessageCell *cell = [tableView dequeueReusableCellWithIdentifier:YGChatDetailMessageCell.reuseIdentifier forIndexPath:indexPath];
    NSDictionary<NSString *, id> *message = self.messages[indexPath.row];
    BOOL isCurrentUser = [message[@"isCurrentUser"] boolValue];
    UIImage *avatarImage = isCurrentUser ? [self currentUserAvatarImage] : [self otherAvatarImage];
    [cell configureWithMessage:message avatarImage:avatarImage isCurrentUser:isCurrentUser];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary<NSString *, id> *message = self.messages[indexPath.row];
    NSString *voicePath = [message[@"voiceLocalPath"] isKindOfClass:NSString.class] ? message[@"voiceLocalPath"] : @"";
    if (voicePath.length == 0) {
        return;
    }
    [self playVoiceAtPath:voicePath];
}

- (void)playVoiceAtPath:(NSString *)voicePath {
    if (voicePath.length == 0) {
        return;
    }
    if (self.audioPlayer.isPlaying) {
        [self.audioPlayer stop];
        self.audioPlayer = nil;
        return;
    }

    NSString *absolutePath = [self absoluteVoicePathForStoredPath:voicePath];
    NSURL *voiceURL = [NSURL fileURLWithPath:absolutePath];
    if (![NSFileManager.defaultManager fileExistsAtPath:voiceURL.path]) {
        [YGHUDHelper showCenterText:@"Voice file not found." inView:self.navigationController.view ?: self.view];
        return;
    }

    NSError *sessionError = nil;
    [AVAudioSession.sharedInstance setCategory:AVAudioSessionCategoryPlayback error:&sessionError];
    [AVAudioSession.sharedInstance setActive:YES error:&sessionError];
    NSError *playerError = nil;
    self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:voiceURL error:&playerError];
    self.audioPlayer.delegate = self;
    if (self.audioPlayer == nil || playerError != nil) {
        [YGHUDHelper showCenterText:@"Unable to play this voice." inView:self.navigationController.view ?: self.view];
        return;
    }
    [self.audioPlayer prepareToPlay];
    [self.audioPlayer play];
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    if (player == self.audioPlayer) {
        self.audioPlayer = nil;
    }
}

- (void)sendButtonTapped {
    NSString *text = [self.inputTextView.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (text.length == 0) {
        return;
    }

    [self.messages addObject:@{
        @"text": text,
        @"isCurrentUser": @YES
    }];
    [[YGChatStore sharedStore] appendCurrentUserMessageText:text toUserInfo:self.userInfo];
    self.inputTextView.text = @"";
    [self updateInputTextViewHeight];

    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.messages.count - 1 inSection:0];
    [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    [self scrollToBottomAnimated:YES];
}

- (void)textViewDidChange:(UITextView *)textView {
    self.placeholderLabel.hidden = textView.text.length > 0;
    [self updateInputTextViewHeight];
}

- (void)updateInputTextViewHeight {
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
        [self scrollToBottomAnimated:NO];
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
    UIEdgeInsets contentInset = self.tableView.contentInset;
    contentInset.bottom = 8.0;
    self.tableView.contentInset = contentInset;
    self.tableView.scrollIndicatorInsets = contentInset;

    [UIView animateWithDuration:duration
                          delay:0.0
                        options:options
                     animations:^{
        [self.view layoutIfNeeded];
        if (keyboardHeight > 0.0) {
            [self scrollToBottomAnimated:NO];
        }
    } completion:nil];
}

- (void)scrollToBottomAnimated:(BOOL)animated {
    if (self.messages.count == 0) {
        return;
    }

    [self.tableView layoutIfNeeded];
    CGFloat contentHeight = self.tableView.contentSize.height + self.tableView.contentInset.bottom;
    CGFloat visibleHeight = CGRectGetHeight(self.tableView.bounds);
    CGFloat minOffsetY = -self.tableView.contentInset.top;
    CGFloat targetOffsetY = MAX(minOffsetY, contentHeight - visibleHeight);

    if (animated) {
        [self.tableView setContentOffset:CGPointMake(0.0, targetOffsetY) animated:YES];
    } else {
        self.tableView.contentOffset = CGPointMake(0.0, targetOffsetY);
    }
}

- (NSArray<NSDictionary<NSString *, id> *> *)mockMessages {
    return @[
        @{@"text": @"Morning yoga flow to start the day. Calm breathing and a soft stretch.", @"isCurrentUser": @YES},
        @{@"text": @"That sounds lovely. Send me the full routine when you can.", @"isCurrentUser": @NO},
        @{@"text": @"Sure, I will share it after I finish editing the clips.", @"isCurrentUser": @YES},
        @{@"text": @"Perfect. I want to try it tonight.", @"isCurrentUser": @NO}
    ];
}

- (NSString *)displayName {
    NSString *name = [self.userInfo[@"name"] isKindOfClass:NSString.class] ? self.userInfo[@"name"] : @"Pasquale";
    return name.length > 0 ? name : @"Pasquale";
}

- (NSString *)otherUserId {
    NSString *userId = [self.userInfo[@"userId"] isKindOfClass:NSString.class] ? self.userInfo[@"userId"] : @"";
    if (userId.length > 0) {
        return userId;
    }
    NSString *name = [self displayName].lowercaseString;
    return name.length > 0 ? [@"chat_user_" stringByAppendingString:name] : @"";
}

- (NSDictionary *)blacklistUserInfo {
    return @{
        @"userId": [self otherUserId],
        @"userName": [self displayName],
        @"avatarName": [self otherAvatarImageName],
        @"avatarLocalPath": [self stringValueForKey:@"avatarLocalPath"],
        @"avatarDataBase64": [self stringValueForKey:@"avatarDataBase64"],
        @"avatarImageName": [self stringValueForKey:@"avatarImageName"],
        @"contentImageName": [self stringValueForKey:@"contentImageName"]
    };
}

- (NSString *)otherAvatarImageName {
    NSString *imageName = [self.userInfo[@"imageName"] isKindOfClass:NSString.class] ? self.userInfo[@"imageName"] : @"personplace";
    return imageName.length > 0 ? imageName : @"personplace";
}

- (UIImage *)otherAvatarImage {
    UIImage *avatarImage = [self.userInfo[@"avatarImage"] isKindOfClass:UIImage.class] ? self.userInfo[@"avatarImage"] : nil;
    if (avatarImage != nil) {
        return avatarImage;
    }

    avatarImage = [[YGImagePostStore sharedStore] avatarImageForPost:self.userInfo];
    if (avatarImage != nil) {
        return avatarImage;
    }

    avatarImage = [[YGVideoPostStore sharedStore] avatarImageForPost:self.userInfo];
    if (avatarImage != nil) {
        return avatarImage;
    }

    return [UIImage imageNamed:[self otherAvatarImageName]] ?: [UIImage imageNamed:@"headplace"];
}

- (NSString *)stringValueForKey:(NSString *)key {
    NSString *value = [self.userInfo[key] isKindOfClass:NSString.class] ? self.userInfo[key] : @"";
    return value.length > 0 ? value : @"";
}

- (UIImage *)currentUserAvatarImage {
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
