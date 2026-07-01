//
//  YGChatStore.h
//  Yaga
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface YGChatStore : NSObject

+ (instancetype)sharedStore;

- (NSArray<NSDictionary<NSString *, id> *> *)chats;
- (NSArray<NSDictionary<NSString *, id> *> *)stories;
- (NSArray<NSDictionary<NSString *, id> *> *)mutualFollowStories;
- (void)seedMutualFollowFriendIfNeeded;
- (nullable NSDictionary<NSString *, id> *)chatInfoForUserId:(NSString *)userId;
- (NSArray<NSDictionary<NSString *, id> *> *)messagesForUserInfo:(NSDictionary<NSString *, id> *)userInfo;
- (void)appendCurrentUserMessageText:(NSString *)text toUserInfo:(NSDictionary<NSString *, id> *)userInfo;
- (void)appendCurrentUserVoicePath:(NSString *)voicePath duration:(NSTimeInterval)duration toUserInfo:(NSDictionary<NSString *, id> *)userInfo;

@end

NS_ASSUME_NONNULL_END
