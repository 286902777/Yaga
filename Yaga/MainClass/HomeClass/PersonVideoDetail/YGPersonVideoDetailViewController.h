//
//  YGPersonVideoDetailViewController.h
//  Yaga
//

#import "YGBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface YGPersonVideoDetailViewController : YGBaseViewController

- (instancetype)initWithItem:(NSDictionary *)item;

- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
