//
//  YGPostsListViewController.h
//  Yaga
//

#import "YGBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface YGPostsListViewController : YGBaseViewController

- (instancetype)initWithTitleText:(NSString *)titleText;
- (instancetype)initWithTitleText:(NSString *)titleText userId:(NSString *)userId;

- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
