//
//  YGSlidingPageView.m
//  Yaga
//

#import "YGSlidingPageView.h"

@interface YGSlidingPageView () <UIScrollViewDelegate>

@property (nonatomic, copy) NSArray<NSString *> *titles;
@property (nonatomic, copy) NSArray<UIViewController *> *viewControllers;
@property (nonatomic, weak) UIViewController *parentViewController;
@property (nonatomic, strong) UIView *tabContainerView;
@property (nonatomic, strong) UIScrollView *contentScrollView;
@property (nonatomic, strong) UIView *bottomLineView;
@property (nonatomic, strong) UIView *indicatorView;
@property (nonatomic, strong) NSMutableArray<UIButton *> *titleButtons;
@property (nonatomic, assign) NSInteger selectedIndex;

@end

@implementation YGSlidingPageView

- (instancetype)initWithTitles:(NSArray<NSString *> *)titles
               viewControllers:(NSArray<UIViewController *> *)viewControllers
          parentViewController:(UIViewController *)parentViewController {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        _titles = [titles copy];
        _viewControllers = [viewControllers copy];
        _parentViewController = parentViewController;
        _horizontalInset = 20.0;
        _titleIndicatorSpacing = 8.0;
        _indicatorHeight = 4.0;
        _selectedColor = [UIColor colorWithRed:158.0 / 255.0 green:25.0 / 255.0 blue:232.0 / 255.0 alpha:1.0];
        _normalColor = UIColor.blackColor;
        _selectedIndex = 0;
        _titleButtons = [NSMutableArray array];

        [self setupViews];
        [self setupViewControllers];
        [self updateSelectedIndex:0 animated:NO];
    }
    return self;
}

- (void)setupViews {
    self.backgroundColor = UIColor.clearColor;

    self.tabContainerView = [[UIView alloc] init];
    self.tabContainerView.backgroundColor = UIColor.clearColor;
    [self addSubview:self.tabContainerView];

    for (NSInteger index = 0; index < self.titles.count; index++) {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.tag = index;
        button.titleLabel.font = [UIFont systemFontOfSize:16.0 weight:UIFontWeightMedium];
        [button setTitle:self.titles[index] forState:UIControlStateNormal];
        [button setTitleColor:self.normalColor forState:UIControlStateNormal];
        [button setTitleColor:self.selectedColor forState:UIControlStateSelected];
        [button addTarget:self action:@selector(titleButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self.tabContainerView addSubview:button];
        [self.titleButtons addObject:button];
    }

    self.bottomLineView = [[UIView alloc] init];
    self.bottomLineView.backgroundColor = [UIColor colorWithRed:204.0 / 255.0 green:204.0 / 255.0 blue:204.0 / 255.0 alpha:1.0];
    [self.tabContainerView addSubview:self.bottomLineView];

    self.indicatorView = [[UIView alloc] init];
    self.indicatorView.backgroundColor = self.selectedColor;
    self.indicatorView.layer.cornerRadius = self.indicatorHeight / 2.0;
    self.indicatorView.clipsToBounds = YES;
    [self.tabContainerView addSubview:self.indicatorView];

    self.contentScrollView = [[UIScrollView alloc] init];
    self.contentScrollView.backgroundColor = UIColor.clearColor;
    self.contentScrollView.pagingEnabled = YES;
    self.contentScrollView.showsHorizontalScrollIndicator = NO;
    self.contentScrollView.showsVerticalScrollIndicator = NO;
    self.contentScrollView.bounces = YES;
    self.contentScrollView.delegate = self;
    self.contentScrollView.alwaysBounceHorizontal = YES;
    [self addSubview:self.contentScrollView];
}

- (void)setupViewControllers {
    NSInteger pageCount = MIN(self.titles.count, self.viewControllers.count);
    for (NSInteger index = 0; index < pageCount; index++) {
        UIViewController *viewController = self.viewControllers[index];
        [self.parentViewController addChildViewController:viewController];
        [self.contentScrollView addSubview:viewController.view];
        [viewController didMoveToParentViewController:self.parentViewController];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];

    NSInteger pageCount = MIN(self.titles.count, self.viewControllers.count);
    if (pageCount == 0) {
        return;
    }

    CGFloat titleHeight = 28.0;
    CGFloat indicatorY = titleHeight + self.titleIndicatorSpacing;
    CGFloat tabHeight = indicatorY + self.indicatorHeight + 16.0;
    CGFloat availableWidth = MAX(CGRectGetWidth(self.bounds) - self.horizontalInset * 2.0, 0.0);
    CGFloat tabWidth = availableWidth / pageCount;

    self.tabContainerView.frame = CGRectMake(0.0, 0.0, CGRectGetWidth(self.bounds), tabHeight);
    for (NSInteger index = 0; index < self.titleButtons.count; index++) {
        UIButton *button = self.titleButtons[index];
        button.frame = CGRectMake(self.horizontalInset + tabWidth * index, 0.0, tabWidth, titleHeight);
    }

    CGFloat indicatorX = self.horizontalInset + tabWidth * self.selectedIndex;
    self.bottomLineView.frame = CGRectMake(self.horizontalInset, indicatorY + (self.indicatorHeight - 1.0) / 2.0, availableWidth, 1.0);
    self.indicatorView.frame = CGRectMake(indicatorX, indicatorY, tabWidth, self.indicatorHeight);
    self.indicatorView.layer.cornerRadius = self.indicatorHeight / 2.0;

    CGFloat contentY = CGRectGetMaxY(self.tabContainerView.frame);
    CGFloat contentHeight = MAX(CGRectGetHeight(self.bounds) - contentY, 0.0);
    self.contentScrollView.frame = CGRectMake(0.0, contentY, CGRectGetWidth(self.bounds), contentHeight);
    self.contentScrollView.contentSize = CGSizeMake(CGRectGetWidth(self.contentScrollView.bounds) * pageCount, contentHeight);

    for (NSInteger index = 0; index < pageCount; index++) {
        UIViewController *viewController = self.viewControllers[index];
        viewController.view.frame = CGRectMake(CGRectGetWidth(self.contentScrollView.bounds) * index, 0.0, CGRectGetWidth(self.contentScrollView.bounds), contentHeight);
    }

    self.contentScrollView.contentOffset = CGPointMake(CGRectGetWidth(self.contentScrollView.bounds) * self.selectedIndex, 0.0);
}

- (void)setHorizontalInset:(CGFloat)horizontalInset {
    _horizontalInset = horizontalInset;
    [self setNeedsLayout];
}

- (void)setTitleIndicatorSpacing:(CGFloat)titleIndicatorSpacing {
    _titleIndicatorSpacing = titleIndicatorSpacing;
    [self setNeedsLayout];
}

- (void)setIndicatorHeight:(CGFloat)indicatorHeight {
    _indicatorHeight = indicatorHeight;
    [self setNeedsLayout];
}

- (void)setSelectedColor:(UIColor *)selectedColor {
    _selectedColor = selectedColor;
    self.indicatorView.backgroundColor = selectedColor;
    for (UIButton *button in self.titleButtons) {
        [button setTitleColor:selectedColor forState:UIControlStateSelected];
    }
}

- (void)setNormalColor:(UIColor *)normalColor {
    _normalColor = normalColor;
    for (UIButton *button in self.titleButtons) {
        [button setTitleColor:normalColor forState:UIControlStateNormal];
    }
}

- (void)titleButtonTapped:(UIButton *)button {
    [self updateSelectedIndex:button.tag animated:YES];
}

- (void)updateSelectedIndex:(NSInteger)index animated:(BOOL)animated {
    NSInteger pageCount = MIN(self.titles.count, self.viewControllers.count);
    if (index < 0 || index >= pageCount) {
        return;
    }

    self.selectedIndex = index;
    for (NSInteger buttonIndex = 0; buttonIndex < self.titleButtons.count; buttonIndex++) {
        self.titleButtons[buttonIndex].selected = (buttonIndex == index);
    }

    CGFloat targetX = CGRectGetWidth(self.contentScrollView.bounds) * index;
    if (CGRectGetWidth(self.contentScrollView.bounds) > 0.0) {
        [self.contentScrollView setContentOffset:CGPointMake(targetX, 0.0) animated:animated];
    }

    [self updateIndicatorWithProgress:index animated:animated];
}

- (void)updateIndicatorWithProgress:(CGFloat)progress animated:(BOOL)animated {
    NSInteger pageCount = MIN(self.titles.count, self.viewControllers.count);
    if (pageCount == 0) {
        return;
    }

    progress = MIN(MAX(progress, 0.0), pageCount - 1);
    CGFloat availableWidth = MAX(CGRectGetWidth(self.bounds) - self.horizontalInset * 2.0, 0.0);
    CGFloat tabWidth = availableWidth / pageCount;
    CGRect indicatorFrame = self.indicatorView.frame;
    indicatorFrame.origin.x = self.horizontalInset + tabWidth * progress;
    indicatorFrame.size.width = tabWidth;

    void (^changes)(void) = ^{
        self.indicatorView.frame = indicatorFrame;
    };

    if (animated) {
        [UIView animateWithDuration:0.25 animations:changes];
    } else {
        changes();
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView != self.contentScrollView || CGRectGetWidth(scrollView.bounds) <= 0.0) {
        return;
    }

    CGFloat progress = scrollView.contentOffset.x / CGRectGetWidth(scrollView.bounds);
    [self updateIndicatorWithProgress:progress animated:NO];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self updateSelectedIndexFromScrollView:scrollView];
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    [self updateSelectedIndexFromScrollView:scrollView];
}

- (void)updateSelectedIndexFromScrollView:(UIScrollView *)scrollView {
    if (scrollView != self.contentScrollView || CGRectGetWidth(scrollView.bounds) <= 0.0) {
        return;
    }

    NSInteger index = (NSInteger)lround(scrollView.contentOffset.x / CGRectGetWidth(scrollView.bounds));
    self.selectedIndex = index;
    for (NSInteger buttonIndex = 0; buttonIndex < self.titleButtons.count; buttonIndex++) {
        self.titleButtons[buttonIndex].selected = (buttonIndex == index);
    }
}

@end
