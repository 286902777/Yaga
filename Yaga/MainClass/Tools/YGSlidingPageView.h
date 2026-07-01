//
//  YGSlidingPageView.h
//  Yaga
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface YGSlidingPageView : UIView

@property (nonatomic, assign) CGFloat horizontalInset;
@property (nonatomic, assign) CGFloat titleIndicatorSpacing;
@property (nonatomic, assign) CGFloat indicatorHeight;
@property (nonatomic, strong) UIColor *selectedColor;
@property (nonatomic, strong) UIColor *normalColor;

- (instancetype)initWithTitles:(NSArray<NSString *> *)titles
               viewControllers:(NSArray<UIViewController *> *)viewControllers
          parentViewController:(UIViewController *)parentViewController;

- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
