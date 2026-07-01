//
//  YGVideoCommentSheetView.m
//  Yaga
//

#import "YGVideoCommentSheetView.h"
#import "YGKeyboardHandler.h"
#import "YGUserStore.h"
#import "YGImagePostStore.h"
#import "YGVideoPostStore.h"
#import "YGBlacklistStore.h"

@interface YGVideoCommentCell : UITableViewCell

+ (NSString *)reuseIdentifier;
@property (nonatomic, copy, nullable) void (^moreTapHandler)(void);
- (void)configureWithComment:(NSDictionary<NSString *, NSString *> *)comment;
- (void)setMoreHidden:(BOOL)hidden;

@end

@interface YGVideoCommentCell ()

@property (nonatomic, strong) UIImageView *avatarImageView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *contentLabel;
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, strong) UIImageView *moreImageView;

@end

@implementation YGVideoCommentCell

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
    self.avatarImageView.layer.cornerRadius = 12.0;
    [self.contentView addSubview:self.avatarImageView];

    self.nameLabel = [[UILabel alloc] init];
    self.nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.nameLabel.textColor = UIColor.blackColor;
    self.nameLabel.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightBold];
    [self.contentView addSubview:self.nameLabel];

    self.moreImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"listmore"]];
    self.moreImageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.moreImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.moreImageView.userInteractionEnabled = YES;
    [self.moreImageView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(moreImageTapped)]];
    [self.contentView addSubview:self.moreImageView];

    self.contentLabel = [[UILabel alloc] init];
    self.contentLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.contentLabel.textColor = [self colorWithHexString:@"#666666"];
    self.contentLabel.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightRegular];
    self.contentLabel.numberOfLines = 0;
    [self.contentView addSubview:self.contentLabel];

    self.timeLabel = [[UILabel alloc] init];
    self.timeLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.timeLabel.textColor = [self colorWithHexString:@"#666666"];
    self.timeLabel.font = [UIFont systemFontOfSize:13.0 weight:UIFontWeightRegular];
    [self.contentView addSubview:self.timeLabel];

    UIView *separatorView = [[UIView alloc] init];
    separatorView.translatesAutoresizingMaskIntoConstraints = NO;
    separatorView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.12];
    [self.contentView addSubview:separatorView];

    [NSLayoutConstraint activateConstraints:@[
        [self.avatarImageView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:20.0],
        [self.avatarImageView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:16.0],
        [self.avatarImageView.widthAnchor constraintEqualToConstant:24.0],
        [self.avatarImageView.heightAnchor constraintEqualToConstant:24.0],

        [self.nameLabel.leadingAnchor constraintEqualToAnchor:self.avatarImageView.trailingAnchor constant:10.0],
        [self.nameLabel.topAnchor constraintEqualToAnchor:self.avatarImageView.topAnchor],
        [self.nameLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.moreImageView.leadingAnchor constant:-10.0],

        [self.moreImageView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor],
        [self.moreImageView.centerYAnchor constraintEqualToAnchor:self.nameLabel.centerYAnchor],
        [self.moreImageView.widthAnchor constraintEqualToConstant:24.0],
        [self.moreImageView.heightAnchor constraintEqualToConstant:24.0],

        [self.contentLabel.leadingAnchor constraintEqualToAnchor:self.nameLabel.leadingAnchor],
        [self.contentLabel.topAnchor constraintEqualToAnchor:self.nameLabel.bottomAnchor constant:8.0],
        [self.contentLabel.trailingAnchor constraintEqualToAnchor:self.moreImageView.trailingAnchor],

        [self.timeLabel.leadingAnchor constraintEqualToAnchor:self.contentLabel.leadingAnchor],
        [self.timeLabel.topAnchor constraintEqualToAnchor:self.contentLabel.bottomAnchor constant:8.0],

        [separatorView.leadingAnchor constraintEqualToAnchor:self.contentLabel.leadingAnchor],
        [separatorView.trailingAnchor constraintEqualToAnchor:self.moreImageView.trailingAnchor],
        [separatorView.topAnchor constraintEqualToAnchor:self.timeLabel.bottomAnchor constant:16.0],
        [separatorView.heightAnchor constraintEqualToConstant:1.0],
        [separatorView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor]
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

- (void)configureWithComment:(NSDictionary<NSString *, NSString *> *)comment {
    self.avatarImageView.image = [self avatarImageForComment:comment];
    self.nameLabel.text = comment[@"userName"];
    self.contentLabel.text = comment[@"text"];
    self.timeLabel.text = comment[@"time"];
}

- (UIImage *)avatarImageForComment:(NSDictionary<NSString *, NSString *> *)comment {
    NSString *avatarLocalPath = comment[@"avatarLocalPath"];
    if (avatarLocalPath.length > 0) {
        UIImage *image = [UIImage imageWithContentsOfFile:avatarLocalPath];
        if (image != nil) {
            return image;
        }
    }

    NSString *avatarBase64 = comment[@"avatarDataBase64"];
    if (avatarBase64.length > 0) {
        NSData *imageData = [[NSData alloc] initWithBase64EncodedString:avatarBase64 options:0];
        UIImage *image = [UIImage imageWithData:imageData];
        if (image != nil) {
            return image;
        }
    }

    NSString *avatarImageName = comment[@"avatarImageName"];
    UIImage *assetImage = nil;
    if (avatarImageName.length > 0) {
        assetImage = [[YGImagePostStore sharedStore] imageInPostResourcesNamed:avatarImageName];
        if (assetImage == nil) {
            assetImage = [[YGVideoPostStore sharedStore] imageInVideoResourcesNamed:avatarImageName];
        }
    }

    NSString *avatarName = comment[@"avatarName"];
    if (assetImage == nil && avatarName.length > 0) {
        assetImage = [UIImage imageNamed:avatarName];
    }
    return assetImage ?: [UIImage imageNamed:@"headplace"];
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

@interface YGVideoCommentSheetView () <UITableViewDataSource, UITableViewDelegate, UITextViewDelegate>

@property (nonatomic, strong) UIView *overlayView;
@property (nonatomic, strong) UIView *sheetView;
@property (nonatomic, strong) UIImageView *backgroundImageView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIView *inputBarView;
@property (nonatomic, strong) UIView *fieldContainerView;
@property (nonatomic, strong) UITextView *inputTextView;
@property (nonatomic, strong) UILabel *placeholderLabel;
@property (nonatomic, strong) UIButton *sendButton;
@property (nonatomic, strong) NSLayoutConstraint *sheetBottomConstraint;
@property (nonatomic, strong) NSLayoutConstraint *inputBarHeightConstraint;
@property (nonatomic, strong) NSLayoutConstraint *fieldContainerHeightConstraint;
@property (nonatomic, strong) YGKeyboardHandler *keyboardHandler;
@property (nonatomic, strong) NSMutableArray<NSDictionary<NSString *, NSString *> *> *comments;
@property (nonatomic, copy) void (^submitHandler)(NSDictionary *comment);
@property (nonatomic, copy) void (^blockHandler)(NSDictionary *comment);
@property (nonatomic, assign) BOOL submittedComment;
@property (nonatomic, assign) NSInteger displayCommentCount;

@end

@implementation YGVideoCommentSheetView

+ (void)showInView:(UIView *)view submitHandler:(void (^)(void))submitHandler {
    [self showInView:view commentCount:23 submitHandler:submitHandler];
}

+ (void)showInView:(UIView *)view commentCount:(NSInteger)commentCount submitHandler:(void (^)(void))submitHandler {
    [self showInView:view commentCount:commentCount comments:nil submitHandler:^(__unused NSDictionary *comment) {
        if (submitHandler != nil) {
            submitHandler();
        }
    }];
}

+ (void)showInView:(UIView *)view
      commentCount:(NSInteger)commentCount
          comments:(NSArray<NSDictionary *> *)comments
     submitHandler:(void (^)(NSDictionary *comment))submitHandler {
    [self showInView:view commentCount:commentCount comments:comments submitHandler:submitHandler blockHandler:nil];
}

+ (void)showInView:(UIView *)view
      commentCount:(NSInteger)commentCount
          comments:(NSArray<NSDictionary *> *)comments
     submitHandler:(void (^)(NSDictionary *comment))submitHandler
      blockHandler:(void (^)(NSDictionary *comment))blockHandler {
    YGVideoCommentSheetView *sheetView = [[YGVideoCommentSheetView alloc] initWithCommentCount:commentCount comments:comments submitHandler:submitHandler blockHandler:blockHandler];
    sheetView.frame = view.bounds;
    sheetView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [view addSubview:sheetView];
}

- (instancetype)initWithSubmitHandler:(void (^)(NSDictionary *comment))submitHandler {
    return [self initWithCommentCount:23 comments:nil submitHandler:submitHandler blockHandler:nil];
}

- (instancetype)initWithCommentCount:(NSInteger)commentCount
                            comments:(NSArray<NSDictionary *> *)comments
                       submitHandler:(void (^)(NSDictionary *comment))submitHandler {
    return [self initWithCommentCount:commentCount comments:comments submitHandler:submitHandler blockHandler:nil];
}

- (instancetype)initWithCommentCount:(NSInteger)commentCount
                            comments:(NSArray<NSDictionary *> *)comments
                       submitHandler:(void (^)(NSDictionary *comment))submitHandler
                        blockHandler:(void (^)(NSDictionary *comment))blockHandler {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        _submitHandler = [submitHandler copy];
        _blockHandler = [blockHandler copy];
        _comments = comments != nil ? [comments mutableCopy] : [[self mockComments] mutableCopy];
        _displayCommentCount = MAX(commentCount, _comments.count);
        [self setupViews];
        [self setupKeyboardHandler];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(blacklistDidChange:)
                                                     name:YGBlacklistDidChangeNotification
                                                   object:nil];
    }
    return self;
}

- (void)setupViews {
    self.backgroundColor = UIColor.clearColor;

    self.overlayView = [[UIView alloc] init];
    self.overlayView.translatesAutoresizingMaskIntoConstraints = NO;
    self.overlayView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.58];
    [self.overlayView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(closeSheet)]];
    [self addSubview:self.overlayView];

    self.sheetView = [[UIView alloc] init];
    self.sheetView.translatesAutoresizingMaskIntoConstraints = NO;
    self.sheetView.backgroundColor = [UIColor colorWithWhite:0.96 alpha:0.96];
    self.sheetView.layer.cornerRadius = 28.0;
    self.sheetView.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
    self.sheetView.clipsToBounds = YES;
    [self addSubview:self.sheetView];

    self.backgroundImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"backimage"]];
    self.backgroundImageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.backgroundImageView.contentMode = UIViewContentModeScaleToFill;
    [self.sheetView addSubview:self.backgroundImageView];

    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self updateTitleText];
    self.titleLabel.textColor = UIColor.blackColor;
    self.titleLabel.font = [UIFont systemFontOfSize:24.0 weight:UIFontWeightBold];
    [self.sheetView addSubview:self.titleLabel];

    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.backgroundColor = UIColor.clearColor;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.estimatedRowHeight = 116.0;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    [self.tableView registerClass:YGVideoCommentCell.class forCellReuseIdentifier:YGVideoCommentCell.reuseIdentifier];
    [self.sheetView addSubview:self.tableView];

    self.inputBarView = [[UIView alloc] init];
    self.inputBarView.translatesAutoresizingMaskIntoConstraints = NO;
    self.inputBarView.backgroundColor = UIColor.whiteColor;
    [self.sheetView addSubview:self.inputBarView];

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

    self.sheetBottomConstraint = [self.sheetView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor];
    self.inputBarHeightConstraint = [self.inputBarView.heightAnchor constraintEqualToConstant:74.0];
    self.fieldContainerHeightConstraint = [self.fieldContainerView.heightAnchor constraintEqualToConstant:44.0];

    [NSLayoutConstraint activateConstraints:@[
        [self.overlayView.topAnchor constraintEqualToAnchor:self.topAnchor],
        [self.overlayView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [self.overlayView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [self.overlayView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],

        [self.sheetView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [self.sheetView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        self.sheetBottomConstraint,
        [self.sheetView.heightAnchor constraintEqualToAnchor:self.heightAnchor multiplier:0.64],

        [self.backgroundImageView.topAnchor constraintEqualToAnchor:self.sheetView.topAnchor],
        [self.backgroundImageView.leadingAnchor constraintEqualToAnchor:self.sheetView.leadingAnchor],
        [self.backgroundImageView.trailingAnchor constraintEqualToAnchor:self.sheetView.trailingAnchor],
        [self.backgroundImageView.bottomAnchor constraintEqualToAnchor:self.sheetView.bottomAnchor],

        [self.titleLabel.topAnchor constraintEqualToAnchor:self.sheetView.topAnchor constant:30.0],
        [self.titleLabel.leadingAnchor constraintEqualToAnchor:self.sheetView.leadingAnchor constant:20.0],
        [self.titleLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.sheetView.trailingAnchor constant:-40.0],

        [self.inputBarView.leadingAnchor constraintEqualToAnchor:self.sheetView.leadingAnchor],
        [self.inputBarView.trailingAnchor constraintEqualToAnchor:self.sheetView.trailingAnchor],
        [self.inputBarView.bottomAnchor constraintEqualToAnchor:self.sheetView.safeAreaLayoutGuide.bottomAnchor],
        self.inputBarHeightConstraint,

        [self.fieldContainerView.leadingAnchor constraintEqualToAnchor:self.inputBarView.leadingAnchor constant:25.0],
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

        [self.sendButton.trailingAnchor constraintEqualToAnchor:self.inputBarView.trailingAnchor constant:-25.0],
        [self.sendButton.centerYAnchor constraintEqualToAnchor:self.fieldContainerView.centerYAnchor],
        [self.sendButton.widthAnchor constraintEqualToConstant:44.0],
        [self.sendButton.heightAnchor constraintEqualToConstant:44.0],

        [self.tableView.topAnchor constraintEqualToAnchor:self.titleLabel.bottomAnchor constant:20.0],
        [self.tableView.leadingAnchor constraintEqualToAnchor:self.sheetView.leadingAnchor],
        [self.tableView.trailingAnchor constraintEqualToAnchor:self.sheetView.trailingAnchor constant:-15.0],
        [self.tableView.bottomAnchor constraintEqualToAnchor:self.inputBarView.topAnchor constant:-16.0]
    ]];
}

- (void)setupKeyboardHandler {
    __weak typeof(self) weakSelf = self;
    self.keyboardHandler = [[YGKeyboardHandler alloc] initWithView:self changeHandler:^(CGFloat keyboardHeight, NSTimeInterval duration, UIViewAnimationOptions options) {
        [weakSelf updateSheetForKeyboardHeight:keyboardHeight duration:duration options:options];
    }];
}

- (void)updateSheetForKeyboardHeight:(CGFloat)keyboardHeight duration:(NSTimeInterval)duration options:(UIViewAnimationOptions)options {
    self.sheetBottomConstraint.constant = keyboardHeight > 0.0 ? -keyboardHeight : 0.0;
    [UIView animateWithDuration:duration
                          delay:0.0
                        options:options
                     animations:^{
        [self layoutIfNeeded];
    } completion:nil];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.comments.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    YGVideoCommentCell *cell = [tableView dequeueReusableCellWithIdentifier:YGVideoCommentCell.reuseIdentifier forIndexPath:indexPath];
    NSDictionary<NSString *, NSString *> *comment = self.comments[indexPath.row];
    [cell configureWithComment:comment];
    BOOL isCurrentUserComment = [self isCurrentUserComment:comment];
    [cell setMoreHidden:isCurrentUserComment];
    __weak typeof(self) weakSelf = self;
    cell.moreTapHandler = isCurrentUserComment ? nil : ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf == nil) {
            return;
        }
        [strongSelf moreTappedForComment:comment];
    };
    return cell;
}

- (void)moreTappedForComment:(NSDictionary *)comment {
    if (self.blockHandler != nil) {
        self.blockHandler(comment);
    }
    [self reloadCommentsFilteringBlockedUsers];
}

- (void)reloadWithComments:(NSArray<NSDictionary *> *)comments commentCount:(NSInteger)commentCount {
    self.comments = comments != nil ? [comments mutableCopy] : [NSMutableArray array];
    self.displayCommentCount = MAX(commentCount, self.comments.count);
    [self updateTitleText];
    [self.tableView reloadData];
}

- (void)reloadCommentsFilteringBlockedUsers {
    NSMutableArray *visibleComments = [NSMutableArray array];
    for (NSDictionary *comment in self.comments) {
        if ([self isCommentBlocked:comment]) {
            continue;
        }
        [visibleComments addObject:comment];
    }
    self.comments = visibleComments;
    self.displayCommentCount = self.comments.count;
    [self updateTitleText];
    [self.tableView reloadData];
}

- (void)blacklistDidChange:(NSNotification *)notification {
    [self reloadCommentsFilteringBlockedUsers];
}

- (BOOL)isCommentBlocked:(NSDictionary *)comment {
    NSString *userId = [self userIdFromComment:comment];
    return userId.length > 0 && [[YGBlacklistStore sharedStore] isBlockedUserId:userId];
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

- (void)sendButtonTapped {
    NSString *text = [self.inputTextView.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (text.length == 0) {
        return;
    }

    NSDictionary *comment = [self currentUserCommentWithText:text];
    NSInteger newRow = self.comments.count;
    [self.comments addObject:comment];
    self.submittedComment = YES;
    self.displayCommentCount += 1;
    if (self.submitHandler != nil) {
        self.submitHandler(comment);
    }
    self.inputTextView.text = @"";
    [self updateInputTextViewHeightKeepingLatestVisible:NO];
    [self updateTitleText];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:newRow inSection:0];
    [self.tableView performBatchUpdates:^{
        [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    } completion:^(__unused BOOL finished) {
        [self scrollToLatestCommentAnimated:YES];
    }];
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
        [self layoutIfNeeded];
        if (keepLatestVisible) {
            [self scrollToLatestCommentAnimated:NO];
        }
    }];
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

- (void)closeSheet {
    [self endEditing:YES];
    [self removeFromSuperview];
}

- (NSArray<NSDictionary<NSString *, NSString *> *> *)mockComments {
    return @[
        @{
            @"avatarName": @"headplace",
            @"userName": @"Dustin Grant",
            @"text": @"Would you like to try chatting with me about those things that bother you?",
            @"time": @"10m ago"
        },
        @{
            @"avatarName": @"headplace",
            @"userName": @"Dustin Grant",
            @"text": @"Would you like to try chatting with me about those things that bother you?",
            @"time": @"10m ago"
        }
    ];
}

- (void)updateTitleText {
    NSString *countText = [NSString stringWithFormat:@" (%ld)", (long)self.displayCommentCount];
    NSString *titleText = [NSString stringWithFormat:@"Comment%@", countText];
    NSMutableAttributedString *attributedTitle = [[NSMutableAttributedString alloc] initWithString:titleText];
    [attributedTitle addAttribute:NSFontAttributeName
                            value:[UIFont systemFontOfSize:24.0 weight:UIFontWeightBold]
                            range:NSMakeRange(0, @"Comment".length)];
    [attributedTitle addAttribute:NSFontAttributeName
                            value:[UIFont systemFontOfSize:14.0 weight:UIFontWeightBold]
                            range:NSMakeRange(@"Comment".length, countText.length)];
    self.titleLabel.attributedText = attributedTitle;
}

- (NSDictionary<NSString *, NSString *> *)currentUserCommentWithText:(NSString *)text {
    NSDictionary *currentUser = [[YGUserStore sharedStore] currentUser];
    NSString *avatarName = currentUser[@"avatarName"];
    NSString *nickname = currentUser[@"nickname"];
    NSString *avatarLocalPath = currentUser[@"avatarLocalPath"];
    NSString *avatarDataBase64 = currentUser[@"avatarDataBase64"];
    NSString *avatarImageName = currentUser[@"avatarImageName"];
    NSString *userId = [[YGUserStore sharedStore] currentUserEmail] ?: @"";
    return @{
        @"avatarName": avatarName.length > 0 ? avatarName : @"headplace",
        @"avatarLocalPath": avatarLocalPath.length > 0 ? avatarLocalPath : @"",
        @"avatarDataBase64": avatarDataBase64.length > 0 ? avatarDataBase64 : @"",
        @"avatarImageName": avatarImageName.length > 0 ? avatarImageName : @"",
        @"authorId": userId.length > 0 ? [NSString stringWithFormat:@"user:%@", userId] : @"",
        @"userId": userId,
        @"userName": nickname.length > 0 ? nickname : @"Me",
        @"text": text.length > 0 ? text : @"",
        @"time": @"Just now"
    };
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
