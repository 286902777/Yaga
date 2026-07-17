//
//  YGSplashViewController.h
//  Yaga
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface YGSplashViewController : UIViewController

- (instancetype)initWithCompletion:(void (^)(void))completion;

@end

NS_ASSUME_NONNULL_END
