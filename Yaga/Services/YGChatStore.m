//
//  YGChatStore.m
//  Yaga
//

#import "YGChatStore.h"
#import "YGImagePostStore.h"
#import "YGVideoPostStore.h"
#import "YGFollowStore.h"
#import "YGUserStore.h"
#import "YGBlacklistStore.h"

static NSString * const YGChatStoreChatsKey = @"com.yaga.chatstore.chats";
static NSString * const YGChatStoreMessagesKey = @"com.yaga.chatstore.messages";
static NSString * const YGChatStoreDidSeedKey = @"com.yaga.chatstore.didSeed";
static NSString * const YGChatStoreDidSeedMutualFollowV2Prefix = @"com.yaga.chatstore.didSeedMutualFollow.v2.";
static NSString * const YGChatStoreDemoUserEmail = @"yagahobby@gmail.com";

@interface YGChatStore ()

@property (nonatomic, strong) NSUserDefaults *userDefaults;

@end

@implementation YGChatStore

+ (instancetype)sharedStore {
    static YGChatStore *store;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        store = [[YGChatStore alloc] initPrivate];
    });
    return store;
}

- (instancetype)init {
    @throw [NSException exceptionWithName:@"YGChatStoreInitError" reason:@"Use sharedStore instead." userInfo:nil];
}

- (instancetype)initPrivate {
    self = [super init];
    if (self) {
        _userDefaults = NSUserDefaults.standardUserDefaults;
    }
    return self;
}

- (NSArray<NSDictionary<NSString *, id> *> *)chats {
    NSString *currentUserId = [self currentUserId];
    if (currentUserId.length == 0) {
        return @[];
    }

    NSMutableArray<NSDictionary<NSString *, id> *> *mutualChats = [NSMutableArray array];
    for (NSDictionary *chat in [self rawChats]) {
        NSString *userId = [self userIdFromUserInfo:chat];
        if ([[YGBlacklistStore sharedStore] isBlockedUserId:userId]) {
            continue;
        }
        if (![self isMutualFollowUserId:userId currentUserId:currentUserId]) {
            continue;
        }
        NSArray *messages = [chat[@"messages"] isKindOfClass:NSArray.class] ? chat[@"messages"] : @[];
        NSString *message = [chat[@"message"] isKindOfClass:NSString.class] ? chat[@"message"] : @"";
        if (messages.count > 0 || message.length > 0) {
            [mutualChats addObject:chat];
        }
    }
    return [mutualChats copy];
}

- (NSArray<NSDictionary<NSString *, id> *> *)rawChats {
    NSArray *chats = [self.userDefaults arrayForKey:YGChatStoreChatsKey];
    if (![chats isKindOfClass:NSArray.class]) {
        return @[];
    }

    NSMutableArray *mergedChats = [NSMutableArray arrayWithCapacity:chats.count];
    for (NSDictionary *chat in chats) {
        NSMutableDictionary *mergedChat = [chat mutableCopy];
        NSArray *messages = [self storedMessagesForUserId:[self userIdFromUserInfo:chat]];
        if (messages.count == 0) {
            messages = [chat[@"messages"] isKindOfClass:NSArray.class] ? chat[@"messages"] : @[];
        }
        mergedChat[@"messages"] = messages;
        NSDictionary *lastMessage = messages.lastObject;
        BOOL isVoiceMessage = [lastMessage[@"voiceLocalPath"] isKindOfClass:NSString.class] && [lastMessage[@"voiceLocalPath"] length] > 0;
        NSString *text = [lastMessage[@"text"] isKindOfClass:NSString.class] ? lastMessage[@"text"] : @"";
        if (isVoiceMessage) {
            mergedChat[@"message"] = @"[Voice]";
        } else if (text.length > 0) {
            mergedChat[@"message"] = text;
        }
        mergedChat[@"badge"] = @(0);
        [mergedChats addObject:[mergedChat copy]];
    }
    return [mergedChats copy];
}

- (NSArray<NSDictionary<NSString *, id> *> *)stories {
    return [self mutualFollowStories];
}

- (NSArray<NSDictionary<NSString *, id> *> *)mutualFollowStories {
    NSString *currentUserId = [self currentUserId];
    if (currentUserId.length == 0) {
        return @[];
    }

    NSArray<NSString *> *followingUserIds = [[YGFollowStore sharedStore] followingUserIdsForUserId:currentUserId];
    if (followingUserIds.count == 0) {
        return @[];
    }

    NSMutableArray<NSDictionary<NSString *, id> *> *stories = [NSMutableArray array];
    for (NSString *userId in followingUserIds) {
        if ([[YGBlacklistStore sharedStore] isBlockedUserId:userId]) {
            continue;
        }
        if (![self isMutualFollowUserId:userId currentUserId:currentUserId]) {
            continue;
        }
        NSDictionary *chatInfo = [self chatInfoForUserId:userId];
        if (chatInfo != nil) {
            [stories addObject:chatInfo];
        }
    }
    return [stories copy];
}

- (void)seedMutualFollowFriendIfNeeded {
    NSString *currentUserId = [self currentUserId];
    if (currentUserId.length == 0 || ![self shouldSeedDemoChatDataForUserId:currentUserId]) {
        return;
    }
    NSString *seedKey = [YGChatStoreDidSeedMutualFollowV2Prefix stringByAppendingString:currentUserId];
    if ([self.userDefaults boolForKey:seedKey]) {
        return;
    }

    NSMutableSet<NSString *> *mutualUserIds = [NSMutableSet set];
    for (NSDictionary *story in [self mutualFollowStories]) {
        NSString *userId = [self userIdFromUserInfo:story];
        if (userId.length > 0) {
            [mutualUserIds addObject:userId];
            [self storeDefaultChatForAuthorIfNeeded:story];
        }
    }

    NSArray<NSDictionary *> *authors = [self shuffledAuthorsFromPosts];
    for (NSDictionary *author in authors) {
        NSString *userId = [self userIdFromUserInfo:author];
        if (userId.length == 0 || [userId isEqualToString:currentUserId] || [mutualUserIds containsObject:userId]) {
            continue;
        }
        [[YGFollowStore sharedStore] userId:currentUserId followUserId:userId];
        [[YGFollowStore sharedStore] userId:userId followUserId:currentUserId];
        [mutualUserIds addObject:userId];
        [self storeDefaultChatForAuthorIfNeeded:author];
        if (mutualUserIds.count >= 2) {
            break;
        }
    }

    if (mutualUserIds.count > 0) {
        [self.userDefaults setBool:YES forKey:seedKey];
        [self.userDefaults synchronize];
    }
}

- (nullable NSDictionary<NSString *, id> *)chatInfoForUserId:(NSString *)userId {
    if (userId.length == 0) {
        return nil;
    }
    if ([[YGBlacklistStore sharedStore] isBlockedUserId:userId]) {
        return nil;
    }

    for (NSDictionary *chat in [self rawChats]) {
        if ([[self userIdFromUserInfo:chat] isEqualToString:userId]) {
            return chat;
        }
    }

    NSDictionary *author = [self authorInfoForUserId:userId];
    return author != nil ? [self chatInfoFromUserInfo:author] : nil;
}

- (NSArray<NSDictionary<NSString *, id> *> *)messagesForUserInfo:(NSDictionary<NSString *, id> *)userInfo {
    NSString *userId = [self userIdFromUserInfo:userInfo];
    NSArray *messages = [self storedMessagesForUserId:userId];
    if (messages.count > 0) {
        return messages;
    }

    for (NSDictionary *chat in [self rawChats]) {
        if ([[self userIdFromUserInfo:chat] isEqualToString:userId]) {
            NSArray *chatMessages = [chat[@"messages"] isKindOfClass:NSArray.class] ? chat[@"messages"] : @[];
            return chatMessages;
        }
    }
    return @[];
}

- (void)appendCurrentUserMessageText:(NSString *)text toUserInfo:(NSDictionary<NSString *, id> *)userInfo {
    NSString *trimmedText = [text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    NSString *userId = [self userIdFromUserInfo:userInfo];
    if (trimmedText.length == 0 || userId.length == 0) {
        return;
    }

    NSMutableDictionary *messagesDatabase = [[self messagesDatabase] mutableCopy];
    NSMutableArray *messages = [[self messagesForUserInfo:userInfo] mutableCopy];
    [messages addObject:@{
        @"text": trimmedText,
        @"isCurrentUser": @YES
    }];
    messagesDatabase[userId] = [messages copy];
    [self.userDefaults setObject:[messagesDatabase copy] forKey:YGChatStoreMessagesKey];

    NSMutableArray *chats = [[[self.userDefaults arrayForKey:YGChatStoreChatsKey] isKindOfClass:NSArray.class] ? [self.userDefaults arrayForKey:YGChatStoreChatsKey] : @[] mutableCopy];
    BOOL didUpdateExistingChat = NO;
    for (NSInteger index = 0; index < chats.count; index++) {
        NSDictionary *chat = chats[index];
        if (![[self userIdFromUserInfo:chat] isEqualToString:userId]) {
            continue;
        }
        NSMutableDictionary *updatedChat = [chat mutableCopy];
        updatedChat[@"messages"] = [messages copy];
        updatedChat[@"message"] = trimmedText;
        updatedChat[@"time"] = @"now";
        updatedChat[@"badge"] = @(0);
        chats[index] = [updatedChat copy];
        didUpdateExistingChat = YES;
        break;
    }
    if (!didUpdateExistingChat) {
        NSMutableDictionary *newChat = [[self chatInfoFromUserInfo:userInfo] mutableCopy];
        newChat[@"message"] = trimmedText;
        newChat[@"time"] = @"now";
        newChat[@"badge"] = @(0);
        newChat[@"messages"] = [messages copy];
        [chats insertObject:[newChat copy] atIndex:0];
    }
    [self.userDefaults setObject:[chats copy] forKey:YGChatStoreChatsKey];
    [self.userDefaults synchronize];
}

- (void)appendCurrentUserVoicePath:(NSString *)voicePath duration:(NSTimeInterval)duration toUserInfo:(NSDictionary<NSString *, id> *)userInfo {
    NSString *userId = [self userIdFromUserInfo:userInfo];
    if (voicePath.length == 0 || userId.length == 0) {
        return;
    }

    NSString *storedVoicePath = [self storedVoicePathForPath:voicePath];
    NSInteger roundedDuration = MAX(1, (NSInteger)ceil(duration));
    NSString *messageText = [NSString stringWithFormat:@"%ld''", (long)roundedDuration];
    NSMutableDictionary *messagesDatabase = [[self messagesDatabase] mutableCopy];
    NSMutableArray *messages = [[self messagesForUserInfo:userInfo] mutableCopy];
    [messages addObject:@{
        @"text": messageText,
        @"voiceLocalPath": storedVoicePath,
        @"voiceDuration": @(duration),
        @"isCurrentUser": @YES
    }];
    messagesDatabase[userId] = [messages copy];
    [self.userDefaults setObject:[messagesDatabase copy] forKey:YGChatStoreMessagesKey];

    NSMutableArray *chats = [[[self.userDefaults arrayForKey:YGChatStoreChatsKey] isKindOfClass:NSArray.class] ? [self.userDefaults arrayForKey:YGChatStoreChatsKey] : @[] mutableCopy];
    BOOL didUpdateExistingChat = NO;
    for (NSInteger index = 0; index < chats.count; index++) {
        NSDictionary *chat = chats[index];
        if (![[self userIdFromUserInfo:chat] isEqualToString:userId]) {
            continue;
        }
        NSMutableDictionary *updatedChat = [chat mutableCopy];
        updatedChat[@"messages"] = [messages copy];
        updatedChat[@"message"] = @"[Voice]";
        updatedChat[@"time"] = @"now";
        updatedChat[@"badge"] = @(0);
        chats[index] = [updatedChat copy];
        didUpdateExistingChat = YES;
        break;
    }
    if (!didUpdateExistingChat) {
        NSMutableDictionary *newChat = [[self chatInfoFromUserInfo:userInfo] mutableCopy];
        newChat[@"message"] = @"[Voice]";
        newChat[@"time"] = @"now";
        newChat[@"badge"] = @(0);
        newChat[@"messages"] = [messages copy];
        [chats insertObject:[newChat copy] atIndex:0];
    }
    [self.userDefaults setObject:[chats copy] forKey:YGChatStoreChatsKey];
    [self.userDefaults synchronize];
}

- (NSString *)storedVoicePathForPath:(NSString *)path {
    NSString *documentsDirectory = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    if (path.length > documentsDirectory.length && [path hasPrefix:documentsDirectory]) {
        NSString *relativePath = [path substringFromIndex:documentsDirectory.length];
        if ([relativePath hasPrefix:@"/"]) {
            relativePath = [relativePath substringFromIndex:1];
        }
        return relativePath;
    }
    return path ?: @"";
}

- (void)seedChatsIfNeeded {
    if (![self shouldSeedDemoChatDataForUserId:[self currentUserId]]) {
        return;
    }
    if ([self.userDefaults boolForKey:YGChatStoreDidSeedKey]) {
        return;
    }

    NSArray<NSDictionary *> *authors = [self shuffledAuthorsFromPosts];
    NSMutableArray<NSDictionary *> *chats = [NSMutableArray array];
    NSInteger count = MIN(2, authors.count);
    for (NSInteger index = 0; index < count; index++) {
        NSDictionary *author = authors[index];
        [chats addObject:[self chatInfoForAuthor:author index:index]];
    }

    [self.userDefaults setObject:[chats copy] forKey:YGChatStoreChatsKey];
    [self.userDefaults setBool:YES forKey:YGChatStoreDidSeedKey];
    [self.userDefaults synchronize];
}

- (void)storeDefaultChatForAuthorIfNeeded:(NSDictionary *)author {
    NSString *userId = [self userIdFromUserInfo:author];
    if (userId.length == 0) {
        return;
    }

    NSMutableArray *chats = [[[self.userDefaults arrayForKey:YGChatStoreChatsKey] isKindOfClass:NSArray.class] ? [self.userDefaults arrayForKey:YGChatStoreChatsKey] : @[] mutableCopy];
    for (NSDictionary *chat in chats) {
        if ([[self userIdFromUserInfo:chat] isEqualToString:userId]) {
            return;
        }
    }

    NSDictionary *chat = [self chatInfoForAuthor:[self chatInfoFromUserInfo:author] index:chats.count];
    [chats addObject:chat];
    [self.userDefaults setObject:[chats copy] forKey:YGChatStoreChatsKey];
    [self.userDefaults synchronize];
}

- (NSArray<NSDictionary *> *)shuffledAuthorsFromPosts {
    NSMutableDictionary<NSString *, NSDictionary *> *authorMap = [NSMutableDictionary dictionary];
    NSMutableArray<NSDictionary *> *posts = [NSMutableArray array];
    [posts addObjectsFromArray:[[YGVideoPostStore sharedStore] allPosts]];
    [posts addObjectsFromArray:[[YGImagePostStore sharedStore] allPosts]];

    for (NSDictionary *post in posts) {
        NSString *userId = [post[@"userId"] isKindOfClass:NSString.class] ? post[@"userId"] : @"";
        if (userId.length == 0 || authorMap[userId] != nil) {
            continue;
        }
        authorMap[userId] = [self authorInfoFromPost:post];
    }

    NSMutableArray *authors = [authorMap.allValues mutableCopy];
    for (NSInteger index = authors.count - 1; index > 0; index--) {
        NSInteger swapIndex = arc4random_uniform((uint32_t)(index + 1));
        [authors exchangeObjectAtIndex:index withObjectAtIndex:swapIndex];
    }
    return [authors copy];
}

- (NSDictionary *)authorInfoFromPost:(NSDictionary *)post {
    return @{
        @"userId": [post[@"userId"] isKindOfClass:NSString.class] ? post[@"userId"] : @"",
        @"name": [post[@"userName"] isKindOfClass:NSString.class] ? post[@"userName"] : @"Yaga User",
        @"imageName": [post[@"avatarName"] isKindOfClass:NSString.class] ? post[@"avatarName"] : @"headplace",
        @"avatarName": [post[@"avatarName"] isKindOfClass:NSString.class] ? post[@"avatarName"] : @"headplace",
        @"avatarLocalPath": [post[@"avatarLocalPath"] isKindOfClass:NSString.class] ? post[@"avatarLocalPath"] : @"",
        @"avatarDataBase64": [post[@"avatarDataBase64"] isKindOfClass:NSString.class] ? post[@"avatarDataBase64"] : @"",
        @"avatarImageName": [post[@"avatarImageName"] isKindOfClass:NSString.class] ? post[@"avatarImageName"] : @"",
        @"contentImageName": [post[@"contentImageName"] isKindOfClass:NSString.class] ? post[@"contentImageName"] : @""
    };
}

- (NSDictionary *)chatInfoFromUserInfo:(NSDictionary *)userInfo {
    NSString *name = [userInfo[@"name"] isKindOfClass:NSString.class] ? userInfo[@"name"] : @"";
    if (name.length == 0) {
        name = [userInfo[@"userName"] isKindOfClass:NSString.class] ? userInfo[@"userName"] : @"Yaga User";
    }
    NSString *avatarName = [userInfo[@"avatarName"] isKindOfClass:NSString.class] ? userInfo[@"avatarName"] : @"";
    if (avatarName.length == 0) {
        avatarName = [userInfo[@"imageName"] isKindOfClass:NSString.class] ? userInfo[@"imageName"] : @"headplace";
    }
    return @{
        @"userId": [self userIdFromUserInfo:userInfo],
        @"name": name.length > 0 ? name : @"Yaga User",
        @"imageName": [userInfo[@"imageName"] isKindOfClass:NSString.class] ? userInfo[@"imageName"] : avatarName,
        @"avatarName": avatarName.length > 0 ? avatarName : @"headplace",
        @"avatarLocalPath": [userInfo[@"avatarLocalPath"] isKindOfClass:NSString.class] ? userInfo[@"avatarLocalPath"] : @"",
        @"avatarDataBase64": [userInfo[@"avatarDataBase64"] isKindOfClass:NSString.class] ? userInfo[@"avatarDataBase64"] : @"",
        @"avatarImageName": [userInfo[@"avatarImageName"] isKindOfClass:NSString.class] ? userInfo[@"avatarImageName"] : @"",
        @"contentImageName": [userInfo[@"contentImageName"] isKindOfClass:NSString.class] ? userInfo[@"contentImageName"] : @""
    };
}

- (NSDictionary *)chatInfoForAuthor:(NSDictionary *)author index:(NSInteger)index {
    NSArray<NSString *> *lastMessages = @[
        @"I just finished a calm yoga flow. Want to try it together?",
        @"Your latest post made me want to get back on the mat.",
        @"That stretch sequence looks perfect for tonight.",
        @"I saved your routine. It feels really beginner friendly."
    ];
    NSArray<NSString *> *times = @[@"1.m ago", @"5.m ago", @"8.m ago", @"12.m ago"];
    NSString *lastMessage = lastMessages[arc4random_uniform((uint32_t)lastMessages.count)];

    NSMutableDictionary *chat = [author mutableCopy];
    chat[@"message"] = lastMessage;
    chat[@"time"] = times[arc4random_uniform((uint32_t)times.count)];
    chat[@"badge"] = @(0);
    chat[@"messages"] = [self randomMessagesWithLastMessage:lastMessage];
    return [chat copy];
}

- (nullable NSDictionary *)authorInfoForUserId:(NSString *)userId {
    if (userId.length == 0) {
        return nil;
    }

    NSMutableArray<NSDictionary *> *posts = [NSMutableArray array];
    [posts addObjectsFromArray:[[YGVideoPostStore sharedStore] allPosts]];
    [posts addObjectsFromArray:[[YGImagePostStore sharedStore] allPosts]];
    for (NSDictionary *post in posts) {
        NSString *postUserId = [post[@"userId"] isKindOfClass:NSString.class] ? post[@"userId"] : @"";
        if ([postUserId isEqualToString:userId]) {
            return [self authorInfoFromPost:post];
        }
    }
    return nil;
}

- (NSArray<NSDictionary *> *)randomMessagesWithLastMessage:(NSString *)lastMessage {
    NSArray<NSString *> *otherMessages = @[
        @"I tried your routine this morning and felt so much better.",
        @"Do you usually practice in the morning or at night?",
        @"The breathing part is harder than it looks, but I like it.",
        @"Can you share another beginner sequence next time?"
    ];
    NSArray<NSString *> *myMessages = @[
        @"Morning works best for me, but a short night stretch is nice too.",
        @"Start slowly and keep the movement soft.",
        @"I can send you a simple version later.",
        @"That is exactly why I like gentle yoga."
    ];
    NSString *otherFirst = otherMessages[arc4random_uniform((uint32_t)otherMessages.count)];
    NSString *myReply = myMessages[arc4random_uniform((uint32_t)myMessages.count)];
    return @[
        @{@"text": otherFirst, @"isCurrentUser": @NO},
        @{@"text": myReply, @"isCurrentUser": @YES},
        @{@"text": lastMessage.length > 0 ? lastMessage : @"Let's keep practicing.", @"isCurrentUser": @NO}
    ];
}

- (BOOL)isMutualFollowUserId:(NSString *)userId currentUserId:(NSString *)currentUserId {
    if (userId.length == 0 || currentUserId.length == 0) {
        return NO;
    }
    NSArray<NSString *> *currentFollowing = [[YGFollowStore sharedStore] followingUserIdsForUserId:currentUserId];
    if (![currentFollowing containsObject:userId]) {
        return NO;
    }
    NSArray<NSString *> *theirFollowing = [[YGFollowStore sharedStore] followingUserIdsForUserId:userId];
    return [theirFollowing containsObject:currentUserId];
}

- (NSDictionary *)messagesDatabase {
    NSDictionary *messagesDatabase = [self.userDefaults dictionaryForKey:YGChatStoreMessagesKey];
    return [messagesDatabase isKindOfClass:NSDictionary.class] ? messagesDatabase : @{};
}

- (NSArray *)storedMessagesForUserId:(NSString *)userId {
    if (userId.length == 0) {
        return @[];
    }
    NSArray *messages = [self messagesDatabase][userId];
    return [messages isKindOfClass:NSArray.class] ? messages : @[];
}

- (NSString *)userIdFromUserInfo:(NSDictionary *)userInfo {
    NSString *userId = [userInfo[@"userId"] isKindOfClass:NSString.class] ? userInfo[@"userId"] : @"";
    if (userId.length > 0) {
        return userId;
    }

    NSString *name = [userInfo[@"name"] isKindOfClass:NSString.class] ? userInfo[@"name"] : @"";
    if (name.length == 0) {
        name = [userInfo[@"userName"] isKindOfClass:NSString.class] ? userInfo[@"userName"] : @"";
    }
    return name.length > 0 ? [@"chat_user_" stringByAppendingString:name.lowercaseString] : @"";
}

- (NSString *)currentUserId {
    NSString *email = [[YGUserStore sharedStore] currentUserEmail];
    return email.length > 0 ? email : @"";
}

- (BOOL)shouldSeedDemoChatDataForUserId:(NSString *)userId {
    return [userId.lowercaseString isEqualToString:YGChatStoreDemoUserEmail];
}

@end
