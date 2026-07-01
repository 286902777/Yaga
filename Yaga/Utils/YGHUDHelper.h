//
//  YGHUDHelper.h
//  Yaga
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class MBProgressHUD;

@interface YGHUDHelper : NSObject

+ (MBProgressHUD *)showLoadingAddedTo:(UIView *)view text:(nullable NSString *)text;
+ (void)hideLoadingForView:(UIView *)view;
+ (void)showText:(NSString *)text inView:(UIView *)view;
+ (void)showCenterText:(NSString *)text inView:(UIView *)view;

@end

NS_ASSUME_NONNULL_END
