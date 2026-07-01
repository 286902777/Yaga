//
//  YGHomeMainListViewController.m
//  Yaga
//

#import "YGHomeMainListViewController.h"
#import "YGHomeMainListCell.h"
#import "YGPersonVideoDetailViewController.h"
#import "YGVideoPostStore.h"
#import "YGUserStore.h"

@interface YGHomeMainListViewController () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (nonatomic, copy) NSString *titleText;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UIImageView *emptyImageView;
@property (nonatomic, copy) NSArray<NSDictionary *> *items;

@end

@implementation YGHomeMainListViewController

- (instancetype)initWithTitleText:(NSString *)titleText {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _titleText = [titleText copy];
        _items = [[YGVideoPostStore sharedStore] postsForSectionTitle:titleText];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.yg_customNavigationBarHidden = YES;
    self.view.backgroundColor = UIColor.whiteColor;
    [self setupCollectionView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.suppressAutomaticReload) {
        return;
    }
    [self reloadData];
}

- (void)reloadData {
    self.items = [[YGVideoPostStore sharedStore] postsForSectionTitle:self.titleText];
    [self.collectionView reloadData];
    [self updateEmptyState];
}

- (void)setupCollectionView {
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.minimumInteritemSpacing = 20.0;
    layout.minimumLineSpacing = 10.0;
    layout.sectionInset = UIEdgeInsetsMake(0.0, 20.0, 20.0, 20.0);

    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    self.collectionView.translatesAutoresizingMaskIntoConstraints = NO;
    self.collectionView.backgroundColor = UIColor.clearColor;
    self.collectionView.showsVerticalScrollIndicator = NO;
    self.collectionView.alwaysBounceVertical = YES;
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    if (@available(iOS 11.0, *)) {
        self.collectionView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
    [self.collectionView registerClass:YGHomeMainListCell.class forCellWithReuseIdentifier:YGHomeMainListCell.reuseIdentifier];
    [self.view addSubview:self.collectionView];

    self.emptyImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"nodata"]];
    self.emptyImageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.emptyImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.emptyImageView.hidden = YES;
    [self.view addSubview:self.emptyImageView];

    [NSLayoutConstraint activateConstraints:@[
        [self.collectionView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.collectionView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.collectionView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.collectionView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],

        [self.emptyImageView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.emptyImageView.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
        [self.emptyImageView.widthAnchor constraintLessThanOrEqualToAnchor:self.view.widthAnchor multiplier:0.55],
        [self.emptyImageView.heightAnchor constraintLessThanOrEqualToAnchor:self.view.heightAnchor multiplier:0.28]
    ]];
    [self updateEmptyState];
}

- (void)updateEmptyState {
    BOOL shouldShowEmpty = [self.titleText isEqualToString:@"Follow"] && self.items.count == 0;
    self.emptyImageView.hidden = !shouldShowEmpty;
    self.collectionView.hidden = shouldShowEmpty;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.items.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    YGHomeMainListCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:YGHomeMainListCell.reuseIdentifier forIndexPath:indexPath];
    NSDictionary *item = self.items[indexPath.item];
    [cell configureWithVideoPost:item];
    [cell setMoreHidden:[self isCurrentUserVideoPost:item]];
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    UIEdgeInsets sectionInset = UIEdgeInsetsMake(0.0, 20.0, 20.0, 20.0);
    CGFloat itemSpacing = 20.0;
    CGFloat itemWidth = floor((CGRectGetWidth(collectionView.bounds) - sectionInset.left - sectionInset.right - itemSpacing) / 2.0);
    CGFloat imageHeight = itemWidth * 200.0 / 156.0;
    CGFloat descriptionHeight = 38.0;
    CGFloat metaHeight = 24.0;
    CGFloat itemHeight = imageHeight + 8.0 + descriptionHeight + 8.0 + metaHeight;
    return CGSizeMake(itemWidth, itemHeight);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *item = self.items[indexPath.item];
    YGPersonVideoDetailViewController *viewController = [[YGPersonVideoDetailViewController alloc] initWithItem:item];
    [self.navigationController pushViewController:viewController animated:YES];
}

- (BOOL)isCurrentUserVideoPost:(NSDictionary *)post {
    NSString *currentUserId = [[YGUserStore sharedStore] currentUserEmail];
    NSString *postUserId = [post[@"userId"] isKindOfClass:NSString.class] ? post[@"userId"] : @"";
    return currentUserId.length > 0 && [postUserId isEqualToString:currentUserId];
}

@end
