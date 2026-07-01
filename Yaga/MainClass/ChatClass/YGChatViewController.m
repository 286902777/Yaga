//
//  YGChatViewController.m
//  Yaga
//

#import "YGChatViewController.h"
#import "YGChatDetailViewController.h"
#import "YGChatStore.h"
#import "YGImagePostStore.h"
#import "YGVideoPostStore.h"
#import "YGFollowStore.h"

@interface YGChatStoryCell : UICollectionViewCell

+ (NSString *)reuseIdentifier;
- (void)configureWithInfo:(NSDictionary<NSString *, id> *)info;

@end

@interface YGChatStoryCell ()

@property (nonatomic, strong) UIView *contentContainerView;
@property (nonatomic, strong) UIImageView *avatarImageView;
@property (nonatomic, strong) UILabel *nameLabel;

@end

@implementation YGChatStoryCell

+ (NSString *)reuseIdentifier {
    return NSStringFromClass(self);
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupViews];
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.avatarImageView.image = nil;
    self.nameLabel.text = nil;
}

- (void)setupViews {
    self.contentView.backgroundColor = UIColor.whiteColor;
    self.contentView.layer.cornerRadius = 20.0;
    self.contentView.clipsToBounds = YES;

    self.contentContainerView = [[UIView alloc] init];
    self.contentContainerView.translatesAutoresizingMaskIntoConstraints = NO;
    self.contentContainerView.backgroundColor = UIColor.clearColor;
    [self.contentView addSubview:self.contentContainerView];

    self.avatarImageView = [[UIImageView alloc] init];
    self.avatarImageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.avatarImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.avatarImageView.clipsToBounds = YES;
    self.avatarImageView.layer.cornerRadius = 26.0;
    self.avatarImageView.layer.borderWidth = 2.0;
    self.avatarImageView.layer.borderColor = [self colorWithHexString:@"#C742FF"].CGColor;
    [self.contentContainerView addSubview:self.avatarImageView];

    self.nameLabel = [[UILabel alloc] init];
    self.nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.nameLabel.textColor = UIColor.blackColor;
    self.nameLabel.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightMedium];
    self.nameLabel.textAlignment = NSTextAlignmentCenter;
    [self.contentContainerView addSubview:self.nameLabel];

    [NSLayoutConstraint activateConstraints:@[
        [self.contentContainerView.centerXAnchor constraintEqualToAnchor:self.contentView.centerXAnchor],
        [self.contentContainerView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
        [self.contentContainerView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor],
        [self.contentContainerView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor],

        [self.avatarImageView.topAnchor constraintEqualToAnchor:self.contentContainerView.topAnchor],
        [self.avatarImageView.centerXAnchor constraintEqualToAnchor:self.contentContainerView.centerXAnchor],
        [self.avatarImageView.widthAnchor constraintEqualToConstant:52.0],
        [self.avatarImageView.heightAnchor constraintEqualToConstant:52.0],

        [self.nameLabel.topAnchor constraintEqualToAnchor:self.avatarImageView.bottomAnchor constant:6.0],
        [self.nameLabel.leadingAnchor constraintEqualToAnchor:self.contentContainerView.leadingAnchor constant:4.0],
        [self.nameLabel.trailingAnchor constraintEqualToAnchor:self.contentContainerView.trailingAnchor constant:-4.0],
        [self.nameLabel.bottomAnchor constraintEqualToAnchor:self.contentContainerView.bottomAnchor]
    ]];
}

- (void)configureWithInfo:(NSDictionary<NSString *, id> *)info {
    self.nameLabel.text = info[@"name"];
    self.avatarImageView.image = [self avatarImageForInfo:info];
}

- (UIImage *)avatarImageForInfo:(NSDictionary *)info {
    UIImage *avatarImage = [info[@"avatarImage"] isKindOfClass:UIImage.class] ? info[@"avatarImage"] : nil;
    if (avatarImage != nil) {
        return avatarImage;
    }

    avatarImage = [[YGImagePostStore sharedStore] avatarImageForPost:info];
    if (avatarImage == nil) {
        avatarImage = [[YGVideoPostStore sharedStore] avatarImageForPost:info];
    }
    NSString *imageName = [info[@"imageName"] isKindOfClass:NSString.class] ? info[@"imageName"] : @"headplace";
    return avatarImage ?: [UIImage imageNamed:imageName] ?: [UIImage imageNamed:@"headplace"];
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

@interface YGChatMessageCell : UITableViewCell

+ (NSString *)reuseIdentifier;
- (void)configureWithInfo:(NSDictionary<NSString *, id> *)info;

@end

@interface YGChatMessageCell ()

@property (nonatomic, strong) UIImageView *avatarImageView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, strong) UILabel *messageLabel;

@end

@implementation YGChatMessageCell

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
    self.nameLabel.text = nil;
    self.timeLabel.text = nil;
    self.messageLabel.text = nil;
}

- (void)setupViews {
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.backgroundColor = UIColor.clearColor;
    self.contentView.backgroundColor = UIColor.clearColor;

    self.avatarImageView = [[UIImageView alloc] init];
    self.avatarImageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.avatarImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.avatarImageView.clipsToBounds = YES;
    self.avatarImageView.layer.cornerRadius = 21.0;
    [self.contentView addSubview:self.avatarImageView];

    self.nameLabel = [[UILabel alloc] init];
    self.nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.nameLabel.textColor = UIColor.blackColor;
    self.nameLabel.font = [UIFont boldSystemFontOfSize:16.0];
    [self.contentView addSubview:self.nameLabel];

    self.timeLabel = [[UILabel alloc] init];
    self.timeLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.timeLabel.textColor = [self colorWithHexString:@"#9B9B9B"];
    self.timeLabel.font = [UIFont systemFontOfSize:12.0 weight:UIFontWeightMedium];
    [self.contentView addSubview:self.timeLabel];

    self.messageLabel = [[UILabel alloc] init];
    self.messageLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.messageLabel.textColor = [self colorWithHexString:@"#9B9B9B"];
    self.messageLabel.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightRegular];
    self.messageLabel.numberOfLines = 1;
    self.messageLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    [self.contentView addSubview:self.messageLabel];

    [NSLayoutConstraint activateConstraints:@[
        [self.avatarImageView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:16.0],
        [self.avatarImageView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:7.0],
        [self.avatarImageView.widthAnchor constraintEqualToConstant:42.0],
        [self.avatarImageView.heightAnchor constraintEqualToConstant:42.0],

        [self.nameLabel.leadingAnchor constraintEqualToAnchor:self.avatarImageView.trailingAnchor constant:12.0],
        [self.nameLabel.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:8.0],
        [self.nameLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.timeLabel.leadingAnchor constant:-8.0],

        [self.timeLabel.topAnchor constraintEqualToAnchor:self.nameLabel.topAnchor],
        [self.timeLabel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-16.0],

        [self.messageLabel.leadingAnchor constraintEqualToAnchor:self.nameLabel.leadingAnchor],
        [self.messageLabel.topAnchor constraintEqualToAnchor:self.nameLabel.bottomAnchor constant:6.0],
        [self.messageLabel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-16.0]
    ]];
}

- (void)configureWithInfo:(NSDictionary<NSString *, id> *)info {
    self.avatarImageView.image = [self avatarImageForInfo:info];
    self.nameLabel.text = info[@"name"];
    self.messageLabel.text = info[@"message"];
    self.timeLabel.text = info[@"time"];
}

- (UIImage *)avatarImageForInfo:(NSDictionary *)info {
    UIImage *avatarImage = [[YGImagePostStore sharedStore] avatarImageForPost:info];
    if (avatarImage == nil) {
        avatarImage = [[YGVideoPostStore sharedStore] avatarImageForPost:info];
    }
    NSString *imageName = [info[@"imageName"] isKindOfClass:NSString.class] ? info[@"imageName"] : @"headplace";
    return avatarImage ?: [UIImage imageNamed:imageName] ?: [UIImage imageNamed:@"headplace"];
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

@interface YGChatViewController () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UIImageView *messageLeftImageView;
@property (nonatomic, strong) UICollectionView *storyCollectionView;
@property (nonatomic, strong) UILabel *sectionLabel;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIImageView *emptyImageView;
@property (nonatomic, copy) NSArray<NSDictionary<NSString *, id> *> *stories;
@property (nonatomic, copy) NSArray<NSDictionary<NSString *, id> *> *chats;

@end

@implementation YGChatViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = UIColor.whiteColor;
    [self reloadChatData];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(followRelationDidChange:)
                                                 name:YGFollowRelationDidChangeNotification
                                               object:nil];
    [self setupNavigationItems];
    [self setupStoryCollectionView];
    [self setupSectionLabel];
    [self setupTableView];
    [self setupEmptyImageView];
    [self updateEmptyState];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self reloadChatData];
}

- (void)reloadChatData {
    [[YGChatStore sharedStore] seedMutualFollowFriendIfNeeded];
    self.stories = [[YGChatStore sharedStore] mutualFollowStories];
    self.chats = [[YGChatStore sharedStore] chats];
    [self.storyCollectionView reloadData];
    [self.tableView reloadData];
    [self updateEmptyState];
}

- (void)followRelationDidChange:(NSNotification *)notification {
    [self reloadChatData];
}

- (void)setupNavigationItems {
    UIImageView *messageLeftImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Messageleft"]];
    messageLeftImageView.translatesAutoresizingMaskIntoConstraints = NO;
    messageLeftImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.messageLeftImageView = messageLeftImageView;
    [messageLeftImageView.widthAnchor constraintEqualToConstant:108.0].active = YES;
    [messageLeftImageView.heightAnchor constraintEqualToConstant:44.0].active = YES;
    [self yg_setLeftView:messageLeftImageView];
}

- (void)setupStoryCollectionView {
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    layout.minimumLineSpacing = 12.0;
    layout.minimumInteritemSpacing = 12.0;
    layout.sectionInset = UIEdgeInsetsMake(0.0, 16.0, 0.0, 16.0);

    self.storyCollectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    self.storyCollectionView.translatesAutoresizingMaskIntoConstraints = NO;
    self.storyCollectionView.backgroundColor = UIColor.clearColor;
    self.storyCollectionView.showsHorizontalScrollIndicator = NO;
    self.storyCollectionView.alwaysBounceHorizontal = YES;
    self.storyCollectionView.dataSource = self;
    self.storyCollectionView.delegate = self;
    if (@available(iOS 11.0, *)) {
        self.storyCollectionView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
    [self.storyCollectionView registerClass:YGChatStoryCell.class forCellWithReuseIdentifier:YGChatStoryCell.reuseIdentifier];
    [self.view addSubview:self.storyCollectionView];

    [NSLayoutConstraint activateConstraints:@[
        [self.storyCollectionView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:20.0],
        [self.storyCollectionView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.storyCollectionView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.storyCollectionView.heightAnchor constraintEqualToConstant:105.0]
    ]];
}

- (void)setupSectionLabel {
    self.sectionLabel = [[UILabel alloc] init];
    self.sectionLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.sectionLabel.text = @"Chats";
    self.sectionLabel.textColor = [self colorWithHexString:@"#6E6E6E"];
    self.sectionLabel.font = [UIFont systemFontOfSize:22.0 weight:UIFontWeightSemibold];
    [self.view addSubview:self.sectionLabel];

    [NSLayoutConstraint activateConstraints:@[
        [self.sectionLabel.topAnchor constraintEqualToAnchor:self.storyCollectionView.bottomAnchor constant:16.0],
        [self.sectionLabel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16.0],
        [self.sectionLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.view.trailingAnchor constant:-16.0]
    ]];
}

- (void)setupTableView {
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.backgroundColor = UIColor.clearColor;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.showsVerticalScrollIndicator = NO;
    self.tableView.rowHeight = 62.0;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    if (@available(iOS 11.0, *)) {
        self.tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
    [self.tableView registerClass:YGChatMessageCell.class forCellReuseIdentifier:YGChatMessageCell.reuseIdentifier];
    [self.view addSubview:self.tableView];

    [NSLayoutConstraint activateConstraints:@[
        [self.tableView.topAnchor constraintEqualToAnchor:self.sectionLabel.bottomAnchor constant:18.0],
        [self.tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.tableView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor]
    ]];
}

- (void)setupEmptyImageView {
    self.emptyImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"nodata"]];
    self.emptyImageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.emptyImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.emptyImageView.hidden = YES;
    [self.view addSubview:self.emptyImageView];

    [NSLayoutConstraint activateConstraints:@[
        [self.emptyImageView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.emptyImageView.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
        [self.emptyImageView.widthAnchor constraintLessThanOrEqualToAnchor:self.view.widthAnchor multiplier:0.55],
        [self.emptyImageView.heightAnchor constraintLessThanOrEqualToAnchor:self.view.heightAnchor multiplier:0.28]
    ]];
}

- (void)updateEmptyState {
    BOOL isEmpty = self.stories.count == 0 && self.chats.count == 0;
    self.emptyImageView.hidden = !isEmpty;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.stories.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    YGChatStoryCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:YGChatStoryCell.reuseIdentifier forIndexPath:indexPath];
    NSDictionary<NSString *, id> *story = self.stories[indexPath.item];
    [cell configureWithInfo:story];
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(100.0, 105.0);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary<NSString *, id> *story = self.stories[indexPath.item];
    YGChatDetailViewController *viewController = [[YGChatDetailViewController alloc] initWithUserInfo:story];
    [self.navigationController pushViewController:viewController animated:YES];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.chats.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    YGChatMessageCell *cell = [tableView dequeueReusableCellWithIdentifier:YGChatMessageCell.reuseIdentifier forIndexPath:indexPath];
    [cell configureWithInfo:self.chats[indexPath.row]];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 62.0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    YGChatDetailViewController *viewController = [[YGChatDetailViewController alloc] initWithUserInfo:self.chats[indexPath.row]];
    [self.navigationController pushViewController:viewController animated:YES];
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
