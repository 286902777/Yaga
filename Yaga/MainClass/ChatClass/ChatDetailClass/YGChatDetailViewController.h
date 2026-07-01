//
//  YGChatDetailViewController.h
//  Yaga
//

#import "YGBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface YGChatDetailViewController : YGBaseViewController

- (instancetype)initWithUserInfo:(NSDictionary<NSString *, id> *)userInfo;

- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
