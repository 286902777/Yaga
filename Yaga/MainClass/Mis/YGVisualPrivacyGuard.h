//
//  YGVisualPrivacyGuard.h
//  Yaga
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface YGVisualPrivacyGuard : NSObject

+ (instancetype)shared;

- (void)protectWindow:(UIWindow *)window;
- (void)protectView:(UIView *)view;
- (void)protectFromScreenRecording;
- (void)removeProtectionFromView:(UIView *)view;

@end

NS_ASSUME_NONNULL_END
