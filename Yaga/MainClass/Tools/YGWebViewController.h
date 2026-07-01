//
//  YGWebViewController.h
//  Yaga
//

#import "YGBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface YGWebViewController : YGBaseViewController

- (instancetype)initWithTitle:(NSString *)title URLString:(NSString *)URLString;

- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
