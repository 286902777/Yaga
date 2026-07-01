//
//  YGFollowStore.h
//  Yaga
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString * const YGFollowRelationDidChangeNotification;

@interface YGFollowStore : NSObject

+ (instancetype)sharedStore;

- (BOOL)isFollowingUserId:(NSString *)userId;
- (BOOL)isMutualFollowingUserId:(NSString *)userId;
- (void)followUserId:(NSString *)userId;
- (void)unfollowUserId:(NSString *)userId;
- (void)userId:(NSString *)followerUserId followUserId:(NSString *)followedUserId;
- (NSInteger)followingCountForCurrentUser;
- (NSInteger)followersCountForUserId:(NSString *)userId;
- (NSInteger)visibleFollowingCountForCurrentUser;
- (NSInteger)visibleFollowingCountForUserId:(NSString *)userId;
- (NSInteger)visibleFollowersCountForUserId:(NSString *)userId;
- (NSArray<NSString *> *)followingUserIdsForCurrentUser;
- (NSArray<NSString *> *)followingUserIdsForUserId:(NSString *)userId;
- (NSArray<NSString *> *)followerUserIdsForUserId:(NSString *)userId;

@end

NS_ASSUME_NONNULL_END
