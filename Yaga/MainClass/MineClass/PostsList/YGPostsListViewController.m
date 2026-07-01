//
//  YGPostsListViewController.m
//  Yaga
//

#import "YGPostsListViewController.h"
#import "YGPostsListCell.h"
#import "YGImagePostStore.h"
#import "YGVideoPostStore.h"
#import "YGPersonDetailViewController.h"
#import "YGPersonVideoDetailViewController.h"

@interface YGPostsListViewController () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (nonatomic, copy) NSString *titleText;
@property (nonatomic, copy) NSString *userId;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UIImageView *emptyImageView;
@property (nonatomic, copy) NSArray<NSDictionary *> *items;

@end

@implementation YGPostsListViewController

- (instancetype)initWithTitleText:(NSString *)titleText {
    return [self initWithTitleText:titleText userId:@""];
}

- (instancetype)initWithTitleText:(NSString *)titleText userId:(NSString *)userId {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _titleText = [titleText copy];
        _userId = [userId copy];
        _items = [self currentItems];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.yg_customNavigationBarHidden = YES;
    self.title = self.titleText;
    self.view.backgroundColor = UIColor.whiteColor;
    [self setupCollectionView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.items = [self currentItems];
    [self.collectionView reloadData];
    [self updateEmptyState];
}

- (void)setupCollectionView {
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.minimumInteritemSpacing = 0.0;
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
    [self.collectionView registerClass:YGPostsListCell.class forCellWithReuseIdentifier:YGPostsListCell.reuseIdentifier];
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
    BOOL isEmpty = self.items.count == 0;
    self.emptyImageView.hidden = !isEmpty;
    self.collectionView.hidden = isEmpty;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.items.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    YGPostsListCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:YGPostsListCell.reuseIdentifier forIndexPath:indexPath];
    NSDictionary *item = self.items[indexPath.item];
    if ([self.titleText isEqualToString:@"Videos"]) {
        NSMutableDictionary *videoItem = [item mutableCopy];
        UIImage *thumbnailImage = [[YGVideoPostStore sharedStore] thumbnailImageForPost:item];
        if (thumbnailImage != nil) {
            videoItem[@"previewImage"] = thumbnailImage;
        }
        [cell configureWithVideoPost:videoItem];
    } else {
        [cell configureWithImagePost:item];
    }
    [cell setMoreHidden:YES];
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat itemWidth = CGRectGetWidth(collectionView.bounds) - 40.0;
    CGFloat itemHeight = itemWidth * 318.0 / 335.0;
    return CGSizeMake(itemWidth, itemHeight);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *item = self.items[indexPath.item];
    if ([self.titleText isEqualToString:@"Videos"]) {
        YGPersonVideoDetailViewController *viewController = [[YGPersonVideoDetailViewController alloc] initWithItem:item];
        [self.navigationController pushViewController:viewController animated:YES];
        return;
    }

    YGPersonDetailViewController *viewController = [[YGPersonDetailViewController alloc] initWithItem:item];
    [self.navigationController pushViewController:viewController animated:YES];
}

- (NSArray<NSDictionary *> *)currentItems {
    if (self.userId.length == 0) {
        return @[];
    }
    if ([self.titleText isEqualToString:@"Videos"]) {
        return [[YGVideoPostStore sharedStore] postsForUserId:self.userId];
    }
    return [[YGImagePostStore sharedStore] postsForUserId:self.userId];
}

@end
