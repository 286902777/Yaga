//
//  YGBaseViewController.h
//  Yaga
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface YGBaseViewController : UIViewController

@property (nonatomic, strong, readonly) UIView *yg_navigationBarView;
@property (nonatomic, strong, readonly) UIView *yg_leftContainerView;
@property (nonatomic, strong, readonly) UIButton *yg_backButton;
@property (nonatomic, strong, readonly) UILabel *yg_titleLabel;
@property (nonatomic, strong, readonly) UIView *yg_rightContainerView;
@property (nonatomic, strong, readonly) NSLayoutYAxisAnchor *yg_navigationBarBottomAnchor;
@property (nonatomic, assign, getter=yg_isCustomNavigationBarHidden) BOOL yg_customNavigationBarHidden;
@property (nonatomic, assign) BOOL yg_tapToDismissKeyboardEnabled;

- (void)yg_setNavigationTitle:(NSString *)title;
- (void)yg_setLeftView:(nullable UIView *)leftView;
- (void)yg_setRightView:(nullable UIView *)rightView;
- (void)yg_backButtonTapped;
- (void)yg_updateScrollViewKeyboardDismissMode;

@end

NS_ASSUME_NONNULL_END
