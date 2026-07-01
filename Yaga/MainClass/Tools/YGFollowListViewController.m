//
//  YGFollowListViewController.m
//  Yaga
//

#import "YGFollowListViewController.h"
#import "YGFollowStore.h"
#import "YGUserStore.h"
#import "YGImagePostStore.h"
#import "YGVideoPostStore.h"
#import "YGBlacklistStore.h"

@interface YGFollowListCell : UITableViewCell

+ (NSString *)reuseIdentifier;
- (void)configureWithInfo:(NSDictionary *)info;
@property (nonatomic, copy) void (^actionHandler)(void);

@end

@interface YGFollowListCell ()

@property (nonatomic, strong) UIImageView *avatarImageView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UIButton *actionButton;

@end

@implementation YGFollowListCell

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

    self.avatarImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"headplace"]];
    self.avatarImageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.avatarImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.avatarImageView.clipsToBounds = YES;
    self.avatarImageView.layer.cornerRadius = 16.0;
    [self.contentView addSubview:self.avatarImageView];

    self.nameLabel = [[UILabel alloc] init];
    self.nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.nameLabel.textColor = UIColor.blackColor;
    self.nameLabel.font = [UIFont systemFontOfSize:13.0 weight:UIFontWeightBold];
    [self.contentView addSubview:self.nameLabel];

    self.actionButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.actionButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.actionButton.layer.cornerRadius = 14.0;
    self.actionButton.clipsToBounds = YES;
    self.actionButton.titleLabel.font = [UIFont systemFontOfSize:10.0 weight:UIFontWeightBold];
    [self.actionButton addTarget:self action:@selector(actionButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.actionButton];

    [NSLayoutConstraint activateConstraints:@[
        [self.avatarImageView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:20.0],
        [self.avatarImageView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
        [self.avatarImageView.widthAnchor constraintEqualToConstant:32.0],
        [self.avatarImageView.heightAnchor constraintEqualToConstant:32.0],

        [self.nameLabel.leadingAnchor constraintEqualToAnchor:self.avatarImageView.trailingAnchor constant:14.0],
        [self.nameLabel.centerYAnchor constraintEqualToAnchor:self.avatarImageView.centerYAnchor],
        [self.nameLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.actionButton.leadingAnchor constant:-12.0],

        [self.actionButton.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-23.0],
        [self.actionButton.centerYAnchor constraintEqualToAnchor:self.avatarImageView.centerYAnchor],
        [self.actionButton.widthAnchor constraintEqualToConstant:68.0],
        [self.actionButton.heightAnchor constraintEqualToConstant:28.0]
    ]];
}

- (void)configureWithInfo:(NSDictionary *)info {
    self.nameLabel.text = info[@"name"] ?: @"Yaga User";
    UIImage *avatarImage = info[@"avatarImage"];
    if ([avatarImage isKindOfClass:UIImage.class]) {
        self.avatarImageView.image = avatarImage;
    } else {
        NSString *avatarName = [info[@"avatarName"] isKindOfClass:NSString.class] ? info[@"avatarName"] : @"headplace";
        self.avatarImageView.image = [UIImage imageNamed:avatarName] ?: [UIImage imageNamed:@"headplace"];
    }
    BOOL hideActionButton = [info[@"hideActionButton"] boolValue];
    self.actionButton.hidden = hideActionButton;
    self.actionButton.userInteractionEnabled = !hideActionButton;
    if (hideActionButton) {
        return;
    }

    BOOL followed = [info[@"followed"] boolValue];
    if (followed) {
        [self.actionButton setTitle:@"Followed" forState:UIControlStateNormal];
        [self.actionButton setTitleColor:[self colorWithHexString:@"#B829FF"] forState:UIControlStateNormal];
        self.actionButton.backgroundColor = UIColor.whiteColor;
    } else {
        [self.actionButton setTitle:@"+Follow" forState:UIControlStateNormal];
        [self.actionButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
        self.actionButton.backgroundColor = [self colorWithHexString:@"#B829FF"];
    }
    self.actionButton.userInteractionEnabled = YES;
}

- (void)actionButtonTapped {
    if (self.actionHandler != nil) {
        self.actionHandler();
    }
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

@interface YGFollowListViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, assign) YGFollowListType type;
@property (nonatomic, copy) NSString *userId;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIImageView *emptyImageView;
@property (nonatomic, copy) NSArray<NSDictionary *> *items;

@end

@implementation YGFollowListViewController

- (instancetype)initWithType:(YGFollowListType)type {
    NSString *currentUserId = [[YGUserStore sharedStore] currentUserEmail] ?: @"guest";
    return [self initWithType:type userId:currentUserId];
}

- (instancetype)initWithType:(YGFollowListType)type userId:(NSString *)userId {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _type = type;
        _userId = userId.length > 0 ? [userId copy] : @"guest";
        _items = [self currentItems];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = UIColor.whiteColor;
    self.title = self.type == YGFollowListTypeFollowers ? @"Followers" : @"Following";
    [self setupTableView];
    [self setupEmptyView];
    [self updateEmptyState];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.items = [self currentItems];
    [self.tableView reloadData];
    [self updateEmptyState];
}

- (void)setupTableView {
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.backgroundColor = UIColor.clearColor;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.showsVerticalScrollIndicator = NO;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.rowHeight = 52.0;
    [self.tableView registerClass:YGFollowListCell.class forCellReuseIdentifier:YGFollowListCell.reuseIdentifier];
    [self.view addSubview:self.tableView];

    [NSLayoutConstraint activateConstraints:@[
        [self.tableView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:12.0],
        [self.tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.tableView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor]
    ]];
}

- (void)setupEmptyView {
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
    BOOL isEmpty = self.items.count == 0;
    self.emptyImageView.hidden = !isEmpty;
    self.tableView.hidden = isEmpty;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    YGFollowListCell *cell = [tableView dequeueReusableCellWithIdentifier:YGFollowListCell.reuseIdentifier forIndexPath:indexPath];
    NSDictionary *item = self.items[indexPath.row];
    [cell configureWithInfo:item];
    __weak typeof(self) weakSelf = self;
    cell.actionHandler = ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf == nil) {
            return;
        }
        NSString *userId = [item[@"userId"] isKindOfClass:NSString.class] ? item[@"userId"] : @"";
        if ([[YGFollowStore sharedStore] isFollowingUserId:userId]) {
            [[YGFollowStore sharedStore] unfollowUserId:userId];
        } else {
            [[YGFollowStore sharedStore] followUserId:userId];
        }
        [strongSelf reloadFollowData];
    };
    return cell;
}

- (void)reloadFollowData {
    self.items = [self currentItems];
    [self.tableView reloadData];
    [self updateEmptyState];
}

- (NSArray<NSDictionary *> *)currentItems {
    NSArray<NSString *> *userIds = self.type == YGFollowListTypeFollowers ?
        [[YGFollowStore sharedStore] followerUserIdsForUserId:self.userId] :
        [[YGFollowStore sharedStore] followingUserIdsForUserId:self.userId];

    NSMutableArray<NSDictionary *> *items = [NSMutableArray arrayWithCapacity:userIds.count];
    NSString *currentUserId = [[YGUserStore sharedStore] currentUserEmail] ?: @"guest";
    for (NSString *userId in userIds) {
        if ([userId isEqualToString:currentUserId]) {
            continue;
        }
        if ([[YGBlacklistStore sharedStore] isBlockedUserId:userId]) {
            continue;
        }
        NSDictionary *info = [self displayInfoForUserId:userId];
        if (info.count > 0) {
            [items addObject:info];
        }
    }
    return [items copy];
}

- (NSDictionary *)displayInfoForUserId:(NSString *)userId {
    if (userId.length == 0) {
        return @{};
    }

    NSDictionary *localUser = [[YGUserStore sharedStore] userForEmail:userId];
    if (localUser.count > 0) {
        UIImage *avatarImage = [self avatarImageForLocalUser:localUser];
        NSMutableDictionary *info = [@{
            @"userId": userId,
            @"name": localUser[@"nickname"] ?: @"Yaga User",
            @"avatarName": localUser[@"avatarName"] ?: @"headplace",
            @"followed": @([[YGFollowStore sharedStore] isFollowingUserId:userId]),
            @"hideActionButton": @([self shouldHideActionButtonForUserId:userId])
        } mutableCopy];
        if (avatarImage != nil) {
            info[@"avatarImage"] = avatarImage;
        }
        return [info copy];
    }

    NSDictionary *post = [self postForUserId:userId];
    if (post.count > 0) {
        UIImage *avatarImage = [[YGImagePostStore sharedStore] avatarImageForPost:post];
        if (avatarImage == nil) {
            avatarImage = [[YGVideoPostStore sharedStore] avatarImageForPost:post];
        }
        NSMutableDictionary *info = [@{
            @"userId": userId,
            @"name": post[@"userName"] ?: @"Yaga User",
            @"avatarName": post[@"avatarName"] ?: @"headplace",
            @"followed": @([[YGFollowStore sharedStore] isFollowingUserId:userId]),
            @"hideActionButton": @([self shouldHideActionButtonForUserId:userId])
        } mutableCopy];
        if (avatarImage != nil) {
            info[@"avatarImage"] = avatarImage;
        }
        return [info copy];
    }

    return @{
        @"userId": userId,
        @"name": [userId containsString:@"@"] ? userId : @"Yaga User",
        @"avatarName": @"headplace",
        @"followed": @([[YGFollowStore sharedStore] isFollowingUserId:userId]),
        @"hideActionButton": @([self shouldHideActionButtonForUserId:userId])
    };
}

- (BOOL)shouldHideActionButtonForUserId:(NSString *)userId {
    if (self.type != YGFollowListTypeFollowers) {
        return NO;
    }
    return [[YGFollowStore sharedStore] isFollowingUserId:userId];
}

- (NSDictionary *)postForUserId:(NSString *)userId {
    NSArray *imagePosts = [[YGImagePostStore sharedStore] postsForUserId:userId];
    if (imagePosts.count > 0) {
        return imagePosts.firstObject;
    }

    NSArray *videoPosts = [[YGVideoPostStore sharedStore] postsForUserId:userId];
    if (videoPosts.count > 0) {
        return videoPosts.firstObject;
    }
    return @{};
}

- (UIImage *)avatarImageForLocalUser:(NSDictionary *)user {
    NSString *avatarLocalPath = [user[@"avatarLocalPath"] isKindOfClass:NSString.class] ? user[@"avatarLocalPath"] : @"";
    if (avatarLocalPath.length > 0) {
        UIImage *image = [UIImage imageWithContentsOfFile:avatarLocalPath];
        if (image != nil) {
            return image;
        }
    }

    NSString *avatarDataBase64 = [user[@"avatarDataBase64"] isKindOfClass:NSString.class] ? user[@"avatarDataBase64"] : @"";
    if (avatarDataBase64.length > 0) {
        NSData *imageData = [[NSData alloc] initWithBase64EncodedString:avatarDataBase64 options:0];
        UIImage *image = [UIImage imageWithData:imageData];
        if (image != nil) {
            return image;
        }
    }

    NSString *avatarName = [user[@"avatarName"] isKindOfClass:NSString.class] ? user[@"avatarName"] : @"";
    return avatarName.length > 0 ? [UIImage imageNamed:avatarName] : nil;
}

@end
