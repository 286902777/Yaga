//
//  YGFollowStore.m
//  Yaga
//

#import "YGFollowStore.h"
#import "YGUserStore.h"
#import "YGBlacklistStore.h"

static NSString * const YGFollowStoreRelationsKey = @"com.yaga.followstore.relations";
NSString * const YGFollowRelationDidChangeNotification = @"YGFollowRelationDidChangeNotification";

@interface YGFollowStore ()

@property (nonatomic, strong) NSUserDefaults *userDefaults;

@end

@implementation YGFollowStore

+ (instancetype)sharedStore {
    static YGFollowStore *store;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        store = [[YGFollowStore alloc] initPrivate];
    });
    return store;
}

- (instancetype)init {
    @throw [NSException exceptionWithName:@"YGFollowStoreInitError" reason:@"Use sharedStore instead." userInfo:nil];
}

- (instancetype)initPrivate {
    self = [super init];
    if (self) {
        _userDefaults = NSUserDefaults.standardUserDefaults;
    }
    return self;
}

- (BOOL)isFollowingUserId:(NSString *)userId {
    if (userId.length == 0) {
        return NO;
    }
    return [[self followingUserIdsForUserId:[self currentUserId]] containsObject:userId];
}

- (BOOL)isMutualFollowingUserId:(NSString *)userId {
    NSString *currentUserId = [self currentUserId];
    if (currentUserId.length == 0 || userId.length == 0) {
        return NO;
    }
    return [[self followingUserIdsForUserId:currentUserId] containsObject:userId] &&
        [[self followingUserIdsForUserId:userId] containsObject:currentUserId];
}

- (void)followUserId:(NSString *)userId {
    NSString *currentUserId = [self currentUserId];
    [self userId:currentUserId followUserId:userId];
}

- (void)unfollowUserId:(NSString *)userId {
    NSString *currentUserId = [self currentUserId];
    if (userId.length == 0) {
        return;
    }

    NSMutableDictionary *relations = [[self relationsDictionary] mutableCopy];
    NSMutableArray *following = [[self followingUserIdsForUserId:currentUserId] mutableCopy];
    if (![following containsObject:userId]) {
        return;
    }

    [following removeObject:userId];
    relations[currentUserId] = [following copy];
    [self.userDefaults setObject:[relations copy] forKey:YGFollowStoreRelationsKey];
    [self.userDefaults synchronize];
    [self postRelationDidChangeNotification];
}

- (void)userId:(NSString *)followerUserId followUserId:(NSString *)followedUserId {
    if (followerUserId.length == 0 || followedUserId.length == 0 || [followerUserId isEqualToString:followedUserId]) {
        return;
    }

    NSMutableDictionary *relations = [[self relationsDictionary] mutableCopy];
    NSMutableArray *following = [[self followingUserIdsForUserId:followerUserId] mutableCopy];
    if (![following containsObject:followedUserId]) {
        [following addObject:followedUserId];
    }
    relations[followerUserId] = [following copy];
    [self.userDefaults setObject:[relations copy] forKey:YGFollowStoreRelationsKey];
    [self.userDefaults synchronize];
    [self postRelationDidChangeNotification];
}

- (NSInteger)followingCountForCurrentUser {
    return [self followingUserIdsForUserId:[self currentUserId]].count;
}

- (NSInteger)followersCountForUserId:(NSString *)userId {
    if (userId.length == 0) {
        return 0;
    }

    NSInteger count = 0;
    NSDictionary *relations = [self relationsDictionary];
    for (NSArray *following in relations.allValues) {
        if ([following isKindOfClass:NSArray.class] && [following containsObject:userId]) {
            count += 1;
        }
    }
    return count;
}

- (NSInteger)visibleFollowingCountForCurrentUser {
    return [self visibleFollowingCountForUserId:[self currentUserId]];
}

- (NSInteger)visibleFollowingCountForUserId:(NSString *)userId {
    NSInteger count = 0;
    for (NSString *followingUserId in [self followingUserIdsForUserId:userId]) {
        if (followingUserId.length > 0 && ![[YGBlacklistStore sharedStore] isBlockedUserId:followingUserId]) {
            count += 1;
        }
    }
    return count;
}

- (NSInteger)visibleFollowersCountForUserId:(NSString *)userId {
    NSInteger count = 0;
    for (NSString *followerId in [self followerUserIdsForUserId:userId]) {
        if (followerId.length > 0 && ![[YGBlacklistStore sharedStore] isBlockedUserId:followerId]) {
            count += 1;
        }
    }
    return count;
}

- (NSArray<NSString *> *)followingUserIdsForCurrentUser {
    return [self followingUserIdsForUserId:[self currentUserId]];
}

- (NSArray<NSString *> *)followerUserIdsForUserId:(NSString *)userId {
    if (userId.length == 0) {
        return @[];
    }

    NSMutableArray<NSString *> *followers = [NSMutableArray array];
    NSDictionary *relations = [self relationsDictionary];
    [relations enumerateKeysAndObjectsUsingBlock:^(NSString *followerId, NSArray *following, __unused BOOL *stop) {
        if ([followerId isKindOfClass:NSString.class] &&
            [following isKindOfClass:NSArray.class] &&
            [following containsObject:userId]) {
            [followers addObject:followerId];
        }
    }];
    return [followers copy];
}

- (NSArray<NSString *> *)followingUserIdsForUserId:(NSString *)userId {
    NSArray *following = [self relationsDictionary][userId];
    return [following isKindOfClass:NSArray.class] ? following : @[];
}

- (NSDictionary *)relationsDictionary {
    NSDictionary *relations = [self.userDefaults dictionaryForKey:YGFollowStoreRelationsKey];
    return [relations isKindOfClass:NSDictionary.class] ? relations : @{};
}

- (NSString *)currentUserId {
    NSString *email = [[YGUserStore sharedStore] currentUserEmail];
    return email.length > 0 ? email : @"guest";
}

- (void)postRelationDidChangeNotification {
    [[NSNotificationCenter defaultCenter] postNotificationName:YGFollowRelationDidChangeNotification object:nil];
}

@end
