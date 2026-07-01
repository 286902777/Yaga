//
//  YGPostimagesViewController.m
//  Yaga
//

#import "YGPostimagesViewController.h"
#import <PhotosUI/PhotosUI.h>
#import "YGHUDHelper.h"
#import "YGImagePostStore.h"

static NSInteger const YGPostImagesMaxSelectionCount = 3;
extern NSString * const YGImagePostDidPublishNotification;

@interface YGPostImageCell : UICollectionViewCell

+ (NSString *)reuseIdentifier;
- (void)configureAsAddCell;
- (void)configureWithImage:(UIImage *)image deleteHandler:(void (^)(void))deleteHandler;

@end

@interface YGPostImageCell ()

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIButton *deleteButton;
@property (nonatomic, copy) void (^deleteHandler)(void);
@property (nonatomic, strong) NSArray<NSLayoutConstraint *> *fillImageConstraints;
@property (nonatomic, strong) NSArray<NSLayoutConstraint *> *centerImageConstraints;

@end

@implementation YGPostImageCell

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
    self.imageView.image = nil;
    self.deleteButton.hidden = YES;
    self.deleteHandler = nil;
}

- (void)setupViews {
    self.contentView.backgroundColor = UIColor.clearColor;
    self.contentView.layer.cornerRadius = 14.0;
    self.contentView.clipsToBounds = YES;

    self.imageView = [[UIImageView alloc] init];
    self.imageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.imageView.contentMode = UIViewContentModeScaleAspectFill;
    self.imageView.clipsToBounds = YES;
    [self.contentView addSubview:self.imageView];

    self.deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.deleteButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.deleteButton.hidden = YES;
    [self.deleteButton setImage:[UIImage imageNamed:@"postimage"] forState:UIControlStateNormal];
    [self.deleteButton addTarget:self action:@selector(deleteButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.deleteButton];

    self.fillImageConstraints = @[
        [self.imageView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],
        [self.imageView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor],
        [self.imageView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor],
        [self.imageView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor]
    ];
    self.centerImageConstraints = @[
        [self.imageView.centerXAnchor constraintEqualToAnchor:self.contentView.centerXAnchor],
        [self.imageView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
        [self.imageView.widthAnchor constraintEqualToConstant:52.0],
        [self.imageView.heightAnchor constraintEqualToConstant:52.0]
    ];

    [NSLayoutConstraint activateConstraints:@[
        [self.deleteButton.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:3.0],
        [self.deleteButton.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-3.0],
        [self.deleteButton.widthAnchor constraintEqualToConstant:24.0],
        [self.deleteButton.heightAnchor constraintEqualToConstant:24.0]
    ]];
}

- (void)configureAsAddCell {
    [NSLayoutConstraint deactivateConstraints:self.fillImageConstraints];
    [NSLayoutConstraint activateConstraints:self.centerImageConstraints];
    self.contentView.backgroundColor = UIColor.whiteColor;
    self.contentView.layer.cornerRadius = 14.0;
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.imageView.image = [UIImage imageNamed:@"placeaddimage"];
    self.deleteButton.hidden = YES;
    self.deleteHandler = nil;
}

- (void)configureWithImage:(UIImage *)image deleteHandler:(void (^)(void))deleteHandler {
    [NSLayoutConstraint deactivateConstraints:self.centerImageConstraints];
    [NSLayoutConstraint activateConstraints:self.fillImageConstraints];
    self.contentView.backgroundColor = UIColor.clearColor;
    self.contentView.layer.cornerRadius = 14.0;
    self.imageView.contentMode = UIViewContentModeScaleAspectFill;
    self.imageView.image = image;
    self.deleteButton.hidden = NO;
    self.deleteHandler = deleteHandler;
}

- (void)deleteButtonTapped {
    if (self.deleteHandler != nil) {
        self.deleteHandler();
    }
}

@end

@interface YGPostimagesViewController () <UITextViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, PHPickerViewControllerDelegate>

@property (nonatomic, strong) UIButton *postButton;
@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, strong) UILabel *placeholderLabel;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) NSMutableArray<UIImage *> *selectedImages;

@end

@implementation YGPostimagesViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = UIColor.whiteColor;
    self.selectedImages = [NSMutableArray array];
    [self setupSubviews];
}

- (void)setupSubviews {
    self.postButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.postButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.postButton.backgroundColor = [self colorWithHexString:@"#B829FF"];
    self.postButton.layer.cornerRadius = 20.0;
    self.postButton.clipsToBounds = YES;
    [self.postButton setTitle:@"Post" forState:UIControlStateNormal];
    [self.postButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    self.postButton.titleLabel.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightBold];
    [self.postButton addTarget:self action:@selector(postButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.postButton.widthAnchor constraintEqualToConstant:68.0].active = YES;
    [self.postButton.heightAnchor constraintEqualToConstant:40.0].active = YES;
    [self yg_setRightView:self.postButton];

    self.textView = [[UITextView alloc] init];
    self.textView.translatesAutoresizingMaskIntoConstraints = NO;
    self.textView.backgroundColor = UIColor.clearColor;
    self.textView.textColor = UIColor.blackColor;
    self.textView.font = [UIFont systemFontOfSize:15.0];
    self.textView.textContainerInset = UIEdgeInsetsZero;
    self.textView.textContainer.lineFragmentPadding = 0.0;
    self.textView.delegate = self;
    [self.view addSubview:self.textView];

    self.placeholderLabel = [[UILabel alloc] init];
    self.placeholderLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.placeholderLabel.text = @"Say something";
    self.placeholderLabel.textColor = [self colorWithHexString:@"#808080"];
    self.placeholderLabel.font = [UIFont systemFontOfSize:14.0];
    [self.textView addSubview:self.placeholderLabel];

    UILabel *addVideoLabel = [[UILabel alloc] init];
    addVideoLabel.translatesAutoresizingMaskIntoConstraints = NO;
    addVideoLabel.text = @"Add image";
    addVideoLabel.textColor = UIColor.blackColor;
    addVideoLabel.font = [UIFont boldSystemFontOfSize:18.0];
    [self.view addSubview:addVideoLabel];

    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.minimumInteritemSpacing = 15.0;
    layout.minimumLineSpacing = 15.0;
    layout.sectionInset = UIEdgeInsetsMake(0.0, 15.0, 20.0, 15.0);

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
    [self.collectionView registerClass:YGPostImageCell.class forCellWithReuseIdentifier:YGPostImageCell.reuseIdentifier];
    [self.view addSubview:self.collectionView];

    [NSLayoutConstraint activateConstraints:@[
        [self.textView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:28.0],
        [self.textView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:15.0],
        [self.textView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-15.0],
        [self.textView.heightAnchor constraintEqualToConstant:86.0],

        [self.placeholderLabel.topAnchor constraintEqualToAnchor:self.textView.topAnchor],
        [self.placeholderLabel.leadingAnchor constraintEqualToAnchor:self.textView.leadingAnchor],
        [self.placeholderLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.textView.trailingAnchor],

        [addVideoLabel.topAnchor constraintEqualToAnchor:self.textView.bottomAnchor constant:58.0],
        [addVideoLabel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:15.0],
        [addVideoLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.view.trailingAnchor constant:-15.0],

        [self.collectionView.topAnchor constraintEqualToAnchor:addVideoLabel.bottomAnchor constant:12.0],
        [self.collectionView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.collectionView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.collectionView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor]
    ]];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.selectedImages.count + 1;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    YGPostImageCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:YGPostImageCell.reuseIdentifier forIndexPath:indexPath];
    if (indexPath.item == 0) {
        [cell configureAsAddCell];
        return cell;
    }

    NSInteger imageIndex = indexPath.item - 1;
    __weak typeof(self) weakSelf = self;
    [cell configureWithImage:self.selectedImages[imageIndex] deleteHandler:^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf == nil || imageIndex >= strongSelf.selectedImages.count) {
            return;
        }
        [strongSelf.selectedImages removeObjectAtIndex:imageIndex];
        [strongSelf.collectionView reloadData];
    }];
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat itemWidth = floor((CGRectGetWidth(collectionView.bounds) - 15.0 * 3.0) / 2.0);
    CGFloat itemHeight = itemWidth * 200.0 / 160.0;
    return CGSizeMake(itemWidth, itemHeight);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.item == 0) {
        [self presentImagePicker];
    }
}

- (void)presentImagePicker {
    NSInteger remainingCount = YGPostImagesMaxSelectionCount - self.selectedImages.count;
    if (remainingCount <= 0) {
        [YGHUDHelper showText:@"You can select up to 3 images." inView:self.view];
        return;
    }

    PHPickerConfiguration *configuration = [[PHPickerConfiguration alloc] init];
    configuration.filter = [PHPickerFilter imagesFilter];
    configuration.selectionLimit = remainingCount;

    PHPickerViewController *picker = [[PHPickerViewController alloc] initWithConfiguration:configuration];
    picker.delegate = self;
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)picker:(PHPickerViewController *)picker didFinishPicking:(NSArray<PHPickerResult *> *)results {
    [picker dismissViewControllerAnimated:YES completion:nil];
    for (PHPickerResult *result in results) {
        if (self.selectedImages.count >= YGPostImagesMaxSelectionCount) {
            break;
        }
        if (![result.itemProvider canLoadObjectOfClass:UIImage.class]) {
            continue;
        }
        [result.itemProvider loadObjectOfClass:UIImage.class completionHandler:^(__kindof id<NSItemProviderReading>  _Nullable object, NSError * _Nullable error) {
            if (![object isKindOfClass:UIImage.class]) {
                return;
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                if (self.selectedImages.count >= YGPostImagesMaxSelectionCount) {
                    return;
                }
                [self.selectedImages addObject:(UIImage *)object];
                [self.collectionView reloadData];
            });
        }];
    }
}

- (void)postButtonTapped {
    [self.view endEditing:YES];
    NSString *content = [self.textView.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (content.length == 0) {
        [YGHUDHelper showText:@"Please enter content." inView:self.view];
        return;
    }
    if (self.selectedImages.count == 0) {
        [YGHUDHelper showText:@"Please add image." inView:self.view];
        return;
    }

    self.postButton.enabled = NO;
    [YGHUDHelper showLoadingAddedTo:self.view text:@"Posting..."];
    NSTimeInterval delay = [self randomPostingDelay];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSDictionary *post = [[YGImagePostStore sharedStore] addLocalImagePostWithText:content images:self.selectedImages];
        self.postButton.enabled = YES;
        [YGHUDHelper hideLoadingForView:self.view];
        if (post == nil) {
            [YGHUDHelper showText:@"Post failed." inView:self.view];
            return;
        }

        [YGHUDHelper showText:@"Post successful." inView:self.view];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:YGImagePostDidPublishNotification object:nil];
            [self.navigationController popViewControllerAnimated:YES];
        });
    });
}

- (NSTimeInterval)randomPostingDelay {
    return 1.0 + (NSTimeInterval)arc4random_uniform(2001) / 1000.0;
}

- (void)textViewDidChange:(UITextView *)textView {
    self.placeholderLabel.hidden = textView.text.length > 0;
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
