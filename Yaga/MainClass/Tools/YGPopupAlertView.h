//
//  YGPopupAlertView.h
//  Yaga
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface YGPopupAlertView : UIView

+ (void)showInView:(UIView *)view
          iconName:(NSString *)iconName
           message:(NSString *)message
   leftButtonTitle:(NSString *)leftButtonTitle
  rightButtonTitle:(NSString *)rightButtonTitle;

+ (void)showInView:(UIView *)view
          iconName:(NSString *)iconName
           message:(NSString *)message
   leftButtonTitle:(NSString *)leftButtonTitle
  rightButtonTitle:(NSString *)rightButtonTitle
rightButtonHandler:(nullable void (^)(void))rightButtonHandler;

@end

NS_ASSUME_NONNULL_END
