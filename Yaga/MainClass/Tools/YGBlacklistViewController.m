//
//  YGBlacklistViewController.m
//  Yaga
//

#import "YGBlacklistViewController.h"
#import "YGBlacklistStore.h"
#import "YGImagePostStore.h"
#import "YGVideoPostStore.h"
#import "YGFollowStore.h"
#import "YGUserStore.h"

@interface YGGradientButton : UIButton

@end

@implementation YGGradientButton

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    if (CGRectIsEmpty(rect)) {
        return;
    }

    CGContextRef context = UIGraphicsGetCurrentContext();
    if (context == NULL) {
        return;
    }

    CGContextSaveGState(context);
    UIBezierPath *clipPath = [UIBezierPath bezierPathWithRoundedRect:self.bounds cornerRadius:CGRectGetHeight(self.bounds) / 2.0];
    [clipPath addClip];

    NSArray *colors = @[
        (__bridge id)[UIColor colorWithRed:184.0 / 255.0 green:41.0 / 255.0 blue:255.0 / 255.0 alpha:1.0].CGColor,
        (__bridge id)[UIColor colorWithRed:252.0 / 255.0 green:32.0 / 255.0 blue:135.0 / 255.0 alpha:1.0].CGColor,
        (__bridge id)[UIColor colorWithRed:255.0 / 255.0 green:167.0 / 255.0 blue:135.0 / 255.0 alpha:1.0].CGColor
    ];
    CGFloat locations[] = {0.0, 0.5, 1.0};
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)colors, locations);
    CGContextDrawLinearGradient(context,
                                gradient,
                                CGPointMake(0.0, CGRectGetMidY(self.bounds)),
                                CGPointMake(CGRectGetWidth(self.bounds), CGRectGetMidY(self.bounds)),
                                0);
    CGGradientRelease(gradient);
    CGColorSpaceRelease(colorSpace);
    CGContextRestoreGState(context);
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self setNeedsDisplay];
}

@end

@interface YGBlacklistCell : UITableViewCell

+ (NSString *)reuseIdentifier;
- (void)configureWithItem:(NSDictionary *)item;
@property (nonatomic, copy) void (^removeHandler)(void);

@end

@interface YGBlacklistCell ()

@property (nonatomic, strong) UIImageView *avatarImageView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) YGGradientButton *removeBackgroundView;
@property (nonatomic, strong) UIButton *removeButton;

@end

@implementation YGBlacklistCell

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

- (void)layoutSubviews {
    [super layoutSubviews];
}

- (void)setupViews {
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.backgroundColor = UIColor.clearColor;
    self.contentView.backgroundColor = UIColor.clearColor;

    self.avatarImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"headplace"]];
    self.avatarImageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.avatarImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.avatarImageView.clipsToBounds = YES;
    self.avatarImageView.layer.cornerRadius = 20.0;
    [self.contentView addSubview:self.avatarImageView];

    self.nameLabel = [[UILabel alloc] init];
    self.nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.nameLabel.textColor = UIColor.blackColor;
    self.nameLabel.font = [UIFont systemFontOfSize:16.0 weight:UIFontWeightBold];
    [self.contentView addSubview:self.nameLabel];

    self.removeBackgroundView = [YGGradientButton buttonWithType:UIButtonTypeCustom];
    self.removeBackgroundView.translatesAutoresizingMaskIntoConstraints = NO;
    self.removeBackgroundView.userInteractionEnabled = NO;
    self.removeBackgroundView.layer.cornerRadius = 18.0;
    self.removeBackgroundView.clipsToBounds = YES;
    self.removeBackgroundView.backgroundColor = [self colorWithHexString:@"#B829FF"];
    [self.contentView addSubview:self.removeBackgroundView];

    self.removeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.removeButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.removeButton.layer.cornerRadius = 18.0;
    self.removeButton.clipsToBounds = YES;
    self.removeButton.backgroundColor = UIColor.clearColor;
    [self.removeButton setTitle:@"Remove" forState:UIControlStateNormal];
    [self.removeButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    self.removeButton.titleLabel.font = [UIFont systemFontOfSize:13.0 weight:UIFontWeightBold];
    [self.removeButton addTarget:self action:@selector(removeButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.removeButton];

    [NSLayoutConstraint activateConstraints:@[
        [self.avatarImageView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:20.0],
        [self.avatarImageView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
        [self.avatarImageView.widthAnchor constraintEqualToConstant:40.0],
        [self.avatarImageView.heightAnchor constraintEqualToConstant:40.0],

        [self.nameLabel.leadingAnchor constraintEqualToAnchor:self.avatarImageView.trailingAnchor constant:18.0],
        [self.nameLabel.centerYAnchor constraintEqualToAnchor:self.avatarImageView.centerYAnchor],
        [self.nameLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.removeBackgroundView.leadingAnchor constant:-12.0],

        [self.removeBackgroundView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-23.0],
        [self.removeBackgroundView.centerYAnchor constraintEqualToAnchor:self.avatarImageView.centerYAnchor],
        [self.removeBackgroundView.widthAnchor constraintEqualToConstant:88.0],
        [self.removeBackgroundView.heightAnchor constraintEqualToConstant:36.0],

        [self.removeButton.topAnchor constraintEqualToAnchor:self.removeBackgroundView.topAnchor],
        [self.removeButton.leadingAnchor constraintEqualToAnchor:self.removeBackgroundView.leadingAnchor],
        [self.removeButton.trailingAnchor constraintEqualToAnchor:self.removeBackgroundView.trailingAnchor],
        [self.removeButton.bottomAnchor constraintEqualToAnchor:self.removeBackgroundView.bottomAnchor]
    ]];
}

- (void)configureWithItem:(NSDictionary *)item {
    self.nameLabel.text = item[@"userName"] ?: @"Yaga User";
    UIImage *avatarImage = [[YGImagePostStore sharedStore] avatarImageForPost:item];
    if (avatarImage == nil) {
        avatarImage = [[YGVideoPostStore sharedStore] avatarImageForPost:item];
    }
    self.avatarImageView.image = avatarImage ?: [UIImage imageNamed:@"headplace"];
}

- (void)removeButtonTapped {
    if (self.removeHandler != nil) {
        self.removeHandler();
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

@interface YGBlacklistViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIImageView *emptyImageView;
@property (nonatomic, copy) NSArray<NSDictionary *> *items;

@end

@implementation YGBlacklistViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = UIColor.whiteColor;
    self.title = @"Blacklist";
    self.items = [[YGBlacklistStore sharedStore] blacklist];
    [self setupTableView];
    [self setupEmptyView];
    [self updateEmptyViewVisibility];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.items = [[YGBlacklistStore sharedStore] blacklist];
    [self.tableView reloadData];
    [self updateEmptyViewVisibility];
}

- (void)setupTableView {
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.backgroundColor = UIColor.clearColor;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.showsVerticalScrollIndicator = NO;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.rowHeight = 70.0;
    [self.tableView registerClass:YGBlacklistCell.class forCellReuseIdentifier:YGBlacklistCell.reuseIdentifier];
    [self.view addSubview:self.tableView];

    [NSLayoutConstraint activateConstraints:@[
        [self.tableView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:16.0],
        [self.tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.tableView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor]
    ]];
}

- (void)setupEmptyView {
    self.emptyImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"nodata"]];
    self.emptyImageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.emptyImageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.view addSubview:self.emptyImageView];

    [NSLayoutConstraint activateConstraints:@[
        [self.emptyImageView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.emptyImageView.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
        [self.emptyImageView.widthAnchor constraintLessThanOrEqualToAnchor:self.view.widthAnchor multiplier:0.55],
        [self.emptyImageView.heightAnchor constraintLessThanOrEqualToAnchor:self.view.heightAnchor multiplier:0.28]
    ]];
}

- (void)updateEmptyViewVisibility {
    BOOL isEmpty = self.items.count == 0;
    self.emptyImageView.hidden = !isEmpty;
    self.tableView.hidden = isEmpty;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    YGBlacklistCell *cell = [tableView dequeueReusableCellWithIdentifier:YGBlacklistCell.reuseIdentifier forIndexPath:indexPath];
    NSDictionary *item = self.items[indexPath.row];
    [cell configureWithItem:item];
    __weak typeof(self) weakSelf = self;
    cell.removeHandler = ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf == nil) {
            return;
        }
        NSString *userId = [item[@"userId"] isKindOfClass:NSString.class] ? item[@"userId"] : @"";
        BOOL shouldRestoreFollowing = [item[@"restoreFollowing"] respondsToSelector:@selector(boolValue)] && [item[@"restoreFollowing"] boolValue];
        [[YGBlacklistStore sharedStore] removeBlockedUserId:userId];
        if (shouldRestoreFollowing) {
            [strongSelf restoreFollowingForUserId:userId];
        }
        [strongSelf reloadBlacklistData];
    };
    return cell;
}

- (void)restoreFollowingForUserId:(NSString *)userId {
    NSString *currentUserId = [[YGUserStore sharedStore] currentUserEmail];
    if (userId.length == 0 || currentUserId.length == 0 || [userId isEqualToString:currentUserId]) {
        return;
    }

    [[YGFollowStore sharedStore] followUserId:userId];
}

- (void)reloadBlacklistData {
    self.items = [[YGBlacklistStore sharedStore] blacklist];
    [self.tableView reloadData];
    [self updateEmptyViewVisibility];
}

@end
