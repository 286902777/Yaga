//
//  YGRechargeViewController.m
//  Yaga
//

#import "YGRechargeViewController.h"
#import "YGRechargeOptionCell.h"
#import "YGUserStore.h"
#import "YGHUDHelper.h"
#import "YGIAPManager.h"

@interface YGRechargeViewController () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (nonatomic, strong) UIImageView *topImageView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, copy) NSArray<NSDictionary<NSString *, NSString *> *> *items;

@end

@implementation YGRechargeViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = UIColor.whiteColor;
    self.title = @"Recharge";
    self.items = @[
        @{@"title": @"400", @"buttonTitle": @"$0.99", @"productId": @"aroaukhoebtzckkw"},
        @{@"title": @"800", @"buttonTitle": @"$1.99", @"productId": @"aiuebsdqqeazzvby"},
        @{@"title": @"2190", @"buttonTitle": @"$3.99", @"productId": @"kqmzrvbtjdxsghpn"},
        @{@"title": @"2450", @"buttonTitle": @"$4.99", @"productId": @"atwmniibcyrthvkd"},
        @{@"title": @"3950", @"buttonTitle": @"$8.99", @"productId": @"asdfghjklnzxcvbm"},
        
        @{@"title": @"5150", @"buttonTitle": @"$9.99", @"productId": @"txudwhnwewkawjol"},
        @{@"title": @"5700", @"buttonTitle": @"$13.99", @"productId": @"wtyuioplazrcnbkdf"},
        @{@"title": @"10800", @"buttonTitle": @"$19.99", @"productId": @"allcimxthcixslbm"},
        @{@"title": @"29400", @"buttonTitle": @"$49.99", @"productId": @"yfdaeppkgqpudmkv"},
        @{@"title": @"63700", @"buttonTitle": @"$99.99", @"productId": @"dtdjdbmtlxdlteoq"}
    ];
    [self setupSubviews];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self updateBalanceText];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self.collectionView.collectionViewLayout invalidateLayout];
    [self.collectionView.visibleCells makeObjectsPerformSelector:@selector(setNeedsLayout)];
    [self.collectionView.visibleCells makeObjectsPerformSelector:@selector(layoutIfNeeded)];
}

- (void)setupSubviews {
    UIImage *topImage = [UIImage imageNamed:@"rechtop"] ?: [UIImage imageNamed:@" rechtop"];
    self.topImageView = [[UIImageView alloc] initWithImage:topImage];
    self.topImageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.topImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.topImageView.clipsToBounds = YES;
    [self.view addSubview:self.topImageView];

    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.titleLabel.textColor = UIColor.whiteColor;
    self.titleLabel.font = [UIFont systemFontOfSize:18.0 weight:UIFontWeightHeavy];
    [self.topImageView addSubview:self.titleLabel];

    self.subtitleLabel = [[UILabel alloc] init];
    self.subtitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.subtitleLabel.text = @"Balance";
    self.subtitleLabel.textColor = UIColor.whiteColor;
    self.subtitleLabel.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightRegular];
    [self.topImageView addSubview:self.subtitleLabel];

    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.minimumInteritemSpacing = 15.0;
    layout.minimumLineSpacing = 10.0;
    layout.sectionInset = UIEdgeInsetsMake(0.0, 20.0, 20.0, 20.0);

    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    self.collectionView.translatesAutoresizingMaskIntoConstraints = NO;
    self.collectionView.backgroundColor = UIColor.clearColor;
    self.collectionView.showsVerticalScrollIndicator = NO;
    self.collectionView.alwaysBounceVertical = YES;
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    [self.collectionView registerClass:YGRechargeOptionCell.class forCellWithReuseIdentifier:YGRechargeOptionCell.reuseIdentifier];
    [self.view addSubview:self.collectionView];

    [NSLayoutConstraint activateConstraints:@[
        [self.topImageView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:20.0],
        [self.topImageView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20.0],
        [self.topImageView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20.0],
        [self.topImageView.heightAnchor constraintEqualToAnchor:self.topImageView.widthAnchor multiplier:60.0 / 335.0],

        [self.titleLabel.leadingAnchor constraintEqualToAnchor:self.topImageView.leadingAnchor constant:22.0],
        [self.titleLabel.centerYAnchor constraintEqualToAnchor:self.topImageView.centerYAnchor constant:-11.0],
        [self.subtitleLabel.leadingAnchor constraintEqualToAnchor:self.titleLabel.leadingAnchor],
        [self.subtitleLabel.topAnchor constraintEqualToAnchor:self.titleLabel.bottomAnchor constant:3.0],

        [self.collectionView.topAnchor constraintEqualToAnchor:self.topImageView.bottomAnchor constant:20.0],
        [self.collectionView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.collectionView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.collectionView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor]
    ]];
    [self updateBalanceText];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.items.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    YGRechargeOptionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:YGRechargeOptionCell.reuseIdentifier forIndexPath:indexPath];
    NSDictionary<NSString *, NSString *> *item = self.items[indexPath.item];
    [cell configureWithTitle:item[@"title"] buttonTitle:item[@"buttonTitle"]];
    __weak typeof(self) weakSelf = self;
    cell.actionHandler = ^{
        [weakSelf rechargeWithItem:item];
    };
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    UIEdgeInsets sectionInset = UIEdgeInsetsMake(0.0, 20.0, 20.0, 20.0);
    CGFloat spacing = 15.0;
    CGFloat width = floor((CGRectGetWidth(collectionView.bounds) - sectionInset.left - sectionInset.right - spacing) / 2.0);
    CGFloat height = width * 128.0 / 160.0;
    return CGSizeMake(width, height);
}

- (void)rechargeWithItem:(NSDictionary<NSString *, NSString *> *)item {
    NSInteger amount = [item[@"title"] integerValue];
    NSString *productId = item[@"productId"];
    if (amount <= 0 || productId.length == 0) {
        return;
    }

    [YGHUDHelper showLoadingAddedTo:self.view text:@"Purchasing..."];
    __weak typeof(self) weakSelf = self;
    [[YGIAPManager sharedManager] purchaseProductWithIdentifier:productId completion:^(BOOL purchaseSuccess, NSString * _Nullable message) {
        __strong typeof(weakSelf) self = weakSelf;
        if (self == nil) {
            return;
        }
        [YGHUDHelper hideLoadingForView:self.view];
        if (!purchaseSuccess) {
            [YGHUDHelper showCenterText:message ?: @"Purchase failed." inView:self.view];
            return;
        }

        NSString *errorMessage = nil;
        BOOL success = [[YGUserStore sharedStore] addBalanceToCurrentUser:amount error:&errorMessage];
        if (!success) {
            [YGHUDHelper showCenterText:errorMessage ?: @"Recharge failed." inView:self.view];
            return;
        }
        [self updateBalanceText];
        [YGHUDHelper showCenterText:@"Recharge successful." inView:self.view];
    }];
}

- (void)updateBalanceText {
    NSInteger balance = [[YGUserStore sharedStore] currentUserBalance];
    self.titleLabel.text = [NSString stringWithFormat:@"%ld", (long)balance];
}

@end
