//
//  YGBlacklistStore.h
//  Yaga
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString * const YGBlacklistDidChangeNotification;

@interface YGBlacklistStore : NSObject

+ (instancetype)sharedStore;

- (NSArray<NSDictionary *> *)blacklist;
- (void)addBlockedUser:(NSDictionary *)userInfo;
- (void)removeBlockedUserId:(NSString *)userId;
- (BOOL)isBlockedUserId:(NSString *)userId;

@end

NS_ASSUME_NONNULL_END
