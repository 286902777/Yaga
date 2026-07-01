//
//  YGFollowListViewController.h
//  Yaga
//

#import "YGBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, YGFollowListType) {
    YGFollowListTypeFollowers,
    YGFollowListTypeFollowing
};

@interface YGFollowListViewController : YGBaseViewController

- (instancetype)initWithType:(YGFollowListType)type;
- (instancetype)initWithType:(YGFollowListType)type userId:(NSString *)userId;

@end

NS_ASSUME_NONNULL_END
