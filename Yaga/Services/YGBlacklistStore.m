//
//  YGBlacklistStore.m
//  Yaga
//

#import "YGBlacklistStore.h"
#import "YGUserStore.h"
#import "YGFollowStore.h"

static NSString * const YGBlacklistStoreKey = @"com.yaga.blackliststore.items";
NSString * const YGBlacklistDidChangeNotification = @"YGBlacklistDidChangeNotification";

@interface YGBlacklistStore ()

@property (nonatomic, strong) NSUserDefaults *userDefaults;

@end

@implementation YGBlacklistStore

+ (instancetype)sharedStore {
    static YGBlacklistStore *store;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        store = [[YGBlacklistStore alloc] initPrivate];
    });
    return store;
}

- (instancetype)init {
    @throw [NSException exceptionWithName:@"YGBlacklistStoreInitError" reason:@"Use sharedStore instead." userInfo:nil];
}

- (instancetype)initPrivate {
    self = [super init];
    if (self) {
        _userDefaults = NSUserDefaults.standardUserDefaults;
    }
    return self;
}

- (NSArray<NSDictionary *> *)blacklist {
    NSArray *items = [self scopedItemsDictionary][[self currentUserId]];
    return [items isKindOfClass:NSArray.class] ? items : @[];
}

- (void)addBlockedUser:(NSDictionary *)userInfo {
    NSDictionary *item = [self normalizedUserInfo:userInfo];
    NSString *userId = item[@"userId"];
    if (userId.length == 0 || [userId isEqualToString:[self currentUserId]]) {
        return;
    }

    NSMutableDictionary *scopedItems = [[self scopedItemsDictionary] mutableCopy];
    NSMutableArray *items = [[self blacklist] mutableCopy];
    NSIndexSet *existingIndexes = [items indexesOfObjectsPassingTest:^BOOL(NSDictionary *storedItem, __unused NSUInteger idx, __unused BOOL *stop) {
        NSString *storedUserId = [storedItem[@"userId"] isKindOfClass:NSString.class] ? storedItem[@"userId"] : @"";
        return [storedUserId isEqualToString:userId];
    }];
    if (existingIndexes.count > 0) {
        [items removeObjectsAtIndexes:existingIndexes];
    }
    [items insertObject:item atIndex:0];

    scopedItems[[self currentUserId]] = [items copy];
    [self.userDefaults setObject:[scopedItems copy] forKey:YGBlacklistStoreKey];
    [self.userDefaults synchronize];
    [self postBlacklistDidChangeNotification];
}

- (void)removeBlockedUserId:(NSString *)userId {
    if (userId.length == 0) {
        return;
    }

    NSMutableDictionary *scopedItems = [[self scopedItemsDictionary] mutableCopy];
    NSMutableArray *items = [[self blacklist] mutableCopy];
    NSIndexSet *removeIndexes = [items indexesOfObjectsPassingTest:^BOOL(NSDictionary *storedItem, __unused NSUInteger idx, __unused BOOL *stop) {
        NSString *storedUserId = [storedItem[@"userId"] isKindOfClass:NSString.class] ? storedItem[@"userId"] : @"";
        return [storedUserId isEqualToString:userId];
    }];
    if (removeIndexes.count == 0) {
        return;
    }

    [items removeObjectsAtIndexes:removeIndexes];
    scopedItems[[self currentUserId]] = [items copy];
    [self.userDefaults setObject:[scopedItems copy] forKey:YGBlacklistStoreKey];
    [self.userDefaults synchronize];
    [self postBlacklistDidChangeNotification];
}

- (BOOL)isBlockedUserId:(NSString *)userId {
    if (userId.length == 0) {
        return NO;
    }
    for (NSDictionary *item in [self blacklist]) {
        NSString *blockedUserId = [item[@"userId"] isKindOfClass:NSString.class] ? item[@"userId"] : @"";
        if ([blockedUserId isEqualToString:userId]) {
            return YES;
        }
    }
    return NO;
}

- (NSDictionary *)normalizedUserInfo:(NSDictionary *)userInfo {
    NSString *userId = [userInfo[@"userId"] isKindOfClass:NSString.class] ? userInfo[@"userId"] : @"";
    if (userId.length == 0) {
        NSString *authorId = [userInfo[@"authorId"] isKindOfClass:NSString.class] ? userInfo[@"authorId"] : @"";
        if ([authorId hasPrefix:@"user:"]) {
            userId = [authorId substringFromIndex:@"user:".length];
        } else {
            userId = authorId;
        }
    }
    if (userId.length == 0) {
        NSString *name = [userInfo[@"userName"] isKindOfClass:NSString.class] ? userInfo[@"userName"] : @"";
        if (name.length == 0) {
            name = [userInfo[@"name"] isKindOfClass:NSString.class] ? userInfo[@"name"] : @"";
        }
        userId = name.length > 0 ? [@"default_user_" stringByAppendingString:name.lowercaseString] : NSUUID.UUID.UUIDString;
    }

    NSString *userName = [userInfo[@"userName"] isKindOfClass:NSString.class] ? userInfo[@"userName"] : @"";
    if (userName.length == 0) {
        userName = [userInfo[@"name"] isKindOfClass:NSString.class] ? userInfo[@"name"] : @"";
    }
    NSNumber *restoreFollowing = [userInfo[@"restoreFollowing"] respondsToSelector:@selector(boolValue)] ?
        userInfo[@"restoreFollowing"] :
        @([[YGFollowStore sharedStore] isFollowingUserId:userId]);
    return @{
        @"userId": userId,
        @"userName": userName.length > 0 ? userName : @"Yaga User",
        @"avatarName": [userInfo[@"avatarName"] isKindOfClass:NSString.class] ? userInfo[@"avatarName"] : @"headplace",
        @"avatarLocalPath": [userInfo[@"avatarLocalPath"] isKindOfClass:NSString.class] ? userInfo[@"avatarLocalPath"] : @"",
        @"avatarDataBase64": [userInfo[@"avatarDataBase64"] isKindOfClass:NSString.class] ? userInfo[@"avatarDataBase64"] : @"",
        @"avatarImageName": [userInfo[@"avatarImageName"] isKindOfClass:NSString.class] ? userInfo[@"avatarImageName"] : @"",
        @"contentImageName": [userInfo[@"contentImageName"] isKindOfClass:NSString.class] ? userInfo[@"contentImageName"] : @"",
        @"restoreFollowing": restoreFollowing
    };
}

- (NSDictionary *)scopedItemsDictionary {
    NSDictionary *items = [self.userDefaults dictionaryForKey:YGBlacklistStoreKey];
    return [items isKindOfClass:NSDictionary.class] ? items : @{};
}

- (NSString *)currentUserId {
    NSString *email = [[YGUserStore sharedStore] currentUserEmail];
    return email.length > 0 ? email : @"guest";
}

- (void)postBlacklistDidChangeNotification {
    [[NSNotificationCenter defaultCenter] postNotificationName:YGBlacklistDidChangeNotification object:nil];
}

@end
