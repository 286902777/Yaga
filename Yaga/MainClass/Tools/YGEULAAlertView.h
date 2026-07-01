//
//  YGEULAAlertView.h
//  Yaga
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface YGEULAAlertView : UIView

+ (void)showInView:(UIView *)view
           message:(NSString *)message
     cancelHandler:(void (^)(void))cancelHandler
      agreeHandler:(void (^)(void))agreeHandler;

@end

NS_ASSUME_NONNULL_END
