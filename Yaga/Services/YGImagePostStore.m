//
//  YGImagePostStore.m
//  Yaga
//

#import "YGImagePostStore.h"
#import "YGUserStore.h"
#import "YGBlacklistStore.h"

static NSString * const YGImagePostStorePostsKey = @"com.yaga.imagepoststore.posts";
static NSString * const YGImagePostStoreCommentsKey = @"com.yaga.imagepoststore.comments";
static NSString * const YGImagePostStoreLikesKey = @"com.yaga.imagepoststore.likes";
static NSString * const YGImagePostStoreSeedVersionKey = @"com.yaga.imagepoststore.seedVersion";
static NSString * const YGImagePostStorePostsSignatureKey = @"com.yaga.imagepoststore.postsSignature";
static NSInteger const YGImagePostStoreSeedVersion = 3;

@interface YGImagePostStore ()

@property (nonatomic, strong) NSUserDefaults *userDefaults;

@end

@implementation YGImagePostStore

+ (instancetype)sharedStore {
    static YGImagePostStore *store;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        store = [[YGImagePostStore alloc] initPrivate];
    });
    return store;
}

- (instancetype)init {
    @throw [NSException exceptionWithName:@"YGImagePostStoreInitError"
                                   reason:@"Use sharedStore instead."
                                 userInfo:nil];
}

- (instancetype)initPrivate {
    self = [super init];
    if (self) {
        _userDefaults = NSUserDefaults.standardUserDefaults;
        [self seedPostsIfNeeded];
        [self migrateLocalImagePathsIfNeeded];
    }
    return self;
}

- (NSArray<NSDictionary *> *)allPosts {
    NSArray *posts = [self.userDefaults arrayForKey:YGImagePostStorePostsKey];
    if (![posts isKindOfClass:NSArray.class]) {
        return @[];
    }

    NSMutableArray<NSDictionary *> *mergedPosts = [NSMutableArray arrayWithCapacity:posts.count];
    for (NSDictionary *post in posts) {
        if (![post isKindOfClass:NSDictionary.class]) {
            continue;
        }
        if ([self isPostBlocked:post]) {
            continue;
        }
        NSString *postId = post[@"postId"];
        NSMutableDictionary *mergedPost = [post mutableCopy];
        mergedPost[@"commentCount"] = @([self commentsForPostId:postId].count);
        mergedPost[@"likeCount"] = @([self likeCountForPostId:postId]);
        mergedPost[@"liked"] = @([self isCurrentUserLikedPostId:postId]);
        mergedPost[@"commented"] = @([self hasCurrentUserCommentedPostId:postId]);
        [mergedPosts addObject:[mergedPost copy]];
    }
    return [mergedPosts copy];
}

- (BOOL)isPostBlocked:(NSDictionary *)post {
    NSString *userId = [post[@"userId"] isKindOfClass:NSString.class] ? post[@"userId"] : @"";
    return userId.length > 0 && [[YGBlacklistStore sharedStore] isBlockedUserId:userId];
}

- (NSArray<NSDictionary *> *)postsForUserId:(NSString *)userId {
    if (userId.length == 0) {
        return @[];
    }

    NSMutableArray *posts = [NSMutableArray array];
    for (NSDictionary *post in [self allPosts]) {
        NSString *postUserId = [post[@"userId"] isKindOfClass:NSString.class] ? post[@"userId"] : @"";
        if ([postUserId isEqualToString:userId]) {
            [posts addObject:post];
        }
    }
    return [posts copy];
}

- (NSArray<NSDictionary *> *)defaultAuthorProfiles {
    NSMutableArray<NSDictionary *> *profiles = [NSMutableArray array];
    for (NSDictionary *post in [self defaultPosts]) {
        NSString *userId = [post[@"userId"] isKindOfClass:NSString.class] ? post[@"userId"] : @"";
        NSString *userName = [post[@"userName"] isKindOfClass:NSString.class] ? post[@"userName"] : @"";
        NSString *avatarImageName = [post[@"avatarImageName"] isKindOfClass:NSString.class] ? post[@"avatarImageName"] : @"";
        if (userId.length == 0 || userName.length == 0) {
            continue;
        }
        [profiles addObject:@{
            @"source": @"image",
            @"sourceUserId": userId,
            @"userName": userName,
            @"avatarImageName": avatarImageName,
            @"avatarName": @"headplace"
        }];
    }
    return [profiles copy];
}

- (void)applyDefaultTestUserProfile:(NSDictionary *)profile toUserId:(NSString *)userId {
    NSString *sourceUserId = [profile[@"sourceUserId"] isKindOfClass:NSString.class] ? profile[@"sourceUserId"] : @"";
    if (sourceUserId.length == 0 || userId.length == 0) {
        return;
    }

    NSArray *storedPosts = [self.userDefaults arrayForKey:YGImagePostStorePostsKey];
    NSMutableArray *updatedPosts = [NSMutableArray arrayWithCapacity:storedPosts.count];
    BOOL didChange = NO;
    for (NSDictionary *post in [storedPosts isKindOfClass:NSArray.class] ? storedPosts : @[]) {
        if (![post isKindOfClass:NSDictionary.class]) {
            [updatedPosts addObject:post];
            continue;
        }

        NSMutableDictionary *updatedPost = [post mutableCopy];
        NSString *postUserId = [post[@"userId"] isKindOfClass:NSString.class] ? post[@"userId"] : @"";
        NSString *originalUserId = [post[@"originalUserId"] isKindOfClass:NSString.class] ? post[@"originalUserId"] : @"";
        BOOL belongsToSource = [postUserId isEqualToString:sourceUserId] || [originalUserId isEqualToString:sourceUserId];
        BOOL belongsToPreviousTestProfile = [postUserId isEqualToString:userId] && [originalUserId hasPrefix:@"default_image_"];

        if (belongsToSource) {
            updatedPost[@"originalUserId"] = sourceUserId;
            updatedPost[@"userId"] = userId;
            didChange = YES;
        } else if (belongsToPreviousTestProfile) {
            updatedPost[@"userId"] = originalUserId;
            didChange = YES;
        }
        [updatedPosts addObject:[updatedPost copy]];
    }

    if (didChange) {
        [self.userDefaults setObject:[updatedPosts copy] forKey:YGImagePostStorePostsKey];
        [self.userDefaults synchronize];
    }
}

- (nullable NSDictionary *)addLocalImagePostWithText:(NSString *)text images:(NSArray<UIImage *> *)images {
    if (text.length == 0 || images.count == 0) {
        return nil;
    }

    NSArray<NSString *> *imagePaths = [self persistLocalImages:images];
    if (imagePaths.count == 0) {
        return nil;
    }

    NSDictionary *currentUser = [[YGUserStore sharedStore] currentUser];
    NSString *nickname = [currentUser[@"nickname"] isKindOfClass:NSString.class] ? currentUser[@"nickname"] : @"";
    NSString *avatarName = [currentUser[@"avatarName"] isKindOfClass:NSString.class] ? currentUser[@"avatarName"] : @"";
    NSString *avatarLocalPath = [currentUser[@"avatarLocalPath"] isKindOfClass:NSString.class] ? currentUser[@"avatarLocalPath"] : @"";
    NSString *avatarDataBase64 = [currentUser[@"avatarDataBase64"] isKindOfClass:NSString.class] ? currentUser[@"avatarDataBase64"] : @"";
    NSString *avatarImageName = [currentUser[@"avatarImageName"] isKindOfClass:NSString.class] ? currentUser[@"avatarImageName"] : @"";
    NSString *postId = [@"local_image_" stringByAppendingString:NSUUID.UUID.UUIDString];
    NSDictionary *post = @{
        @"postId": postId,
        @"userId": [[YGUserStore sharedStore] currentUserEmail] ?: @"guest",
        @"userName": nickname.length > 0 ? nickname : @"Yaga User",
        @"avatarName": avatarName.length > 0 ? avatarName : @"headplace",
        @"avatarLocalPath": avatarLocalPath.length > 0 ? avatarLocalPath : @"",
        @"avatarDataBase64": avatarDataBase64.length > 0 ? avatarDataBase64 : @"",
        @"avatarImageName": avatarImageName.length > 0 ? avatarImageName : @"",
        @"imageNames": imagePaths,
        @"contentImageName": imagePaths.firstObject ?: @"",
        @"likeCount": @(0),
        @"descriptionText": text,
        @"seedCommentText": @""
    };

    NSArray *storedPosts = [self.userDefaults arrayForKey:YGImagePostStorePostsKey];
    NSMutableArray *posts = [[storedPosts isKindOfClass:NSArray.class] ? storedPosts : @[] mutableCopy];
    [posts insertObject:post atIndex:0];

    NSMutableDictionary *commentsDatabase = [[self commentsDatabase] mutableCopy];
    commentsDatabase[postId] = @[];
    NSMutableDictionary *likesDatabase = [[self likesDatabase] mutableCopy];
    likesDatabase[postId] = @{@"count": @(0), @"userIds": @[]};

    [self.userDefaults setObject:[posts copy] forKey:YGImagePostStorePostsKey];
    [self.userDefaults setObject:[commentsDatabase copy] forKey:YGImagePostStoreCommentsKey];
    [self.userDefaults setObject:[likesDatabase copy] forKey:YGImagePostStoreLikesKey];
    [self.userDefaults synchronize];
    return post;
}

- (NSArray<NSDictionary *> *)commentsForPostId:(NSString *)postId {
    if (postId.length == 0) {
        return @[];
    }

    NSDictionary *commentsDatabase = [self commentsDatabase];
    NSArray *comments = commentsDatabase[postId];
    if (![comments isKindOfClass:NSArray.class]) {
        return @[];
    }

    NSMutableArray<NSDictionary *> *visibleComments = [NSMutableArray array];
    for (NSDictionary *comment in comments) {
        if (![comment isKindOfClass:NSDictionary.class] || [self isCommentBlocked:comment]) {
            continue;
        }
        [visibleComments addObject:comment];
    }
    return [visibleComments copy];
}

- (void)addComment:(NSDictionary *)comment toPostId:(NSString *)postId {
    if (postId.length == 0 || comment.count == 0) {
        return;
    }

    NSMutableDictionary *commentsDatabase = [[self commentsDatabase] mutableCopy];
    NSArray *storedComments = [commentsDatabase[postId] isKindOfClass:NSArray.class] ? commentsDatabase[postId] : @[];
    NSMutableArray *comments = [storedComments mutableCopy];
    NSMutableDictionary *storedComment = [comment mutableCopy];
    storedComment[@"authorId"] = [self currentUserIdentifier];
    NSString *email = [[YGUserStore sharedStore] currentUserEmail];
    if (email.length > 0) {
        storedComment[@"userId"] = email;
    }
    [comments addObject:[storedComment copy]];
    commentsDatabase[postId] = [comments copy];
    [self.userDefaults setObject:[commentsDatabase copy] forKey:YGImagePostStoreCommentsKey];
    [self.userDefaults synchronize];
}

- (NSInteger)likeCountForPostId:(NSString *)postId {
    NSDictionary *likeInfo = [self likeInfoForPostId:postId];
    NSNumber *count = likeInfo[@"count"];
    return [count respondsToSelector:@selector(integerValue)] ? MAX(0, count.integerValue) : 0;
}

- (BOOL)isCurrentUserLikedPostId:(NSString *)postId {
    NSString *userId = [self currentUserIdentifier];
    NSDictionary *likeInfo = [self likeInfoForPostId:postId];
    NSArray *userIds = [likeInfo[@"userIds"] isKindOfClass:NSArray.class] ? likeInfo[@"userIds"] : @[];
    return [userIds containsObject:userId];
}

- (NSInteger)toggleLikeForPostId:(NSString *)postId {
    if (postId.length == 0) {
        return 0;
    }

    NSString *userId = [self currentUserIdentifier];
    NSMutableDictionary *likesDatabase = [[self likesDatabase] mutableCopy];
    NSMutableDictionary *likeInfo = [[self likeInfoForPostId:postId] mutableCopy];
    NSMutableArray *userIds = [[likeInfo[@"userIds"] isKindOfClass:NSArray.class] ? likeInfo[@"userIds"] : @[] mutableCopy];
    NSInteger count = [self likeCountForPostId:postId];
    if ([userIds containsObject:userId]) {
        [userIds removeObject:userId];
        count = MAX(0, count - 1);
    } else {
        [userIds addObject:userId];
        count += 1;
    }
    likeInfo[@"count"] = @(count);
    likeInfo[@"userIds"] = [userIds copy];
    likesDatabase[postId] = [likeInfo copy];
    [self.userDefaults setObject:[likesDatabase copy] forKey:YGImagePostStoreLikesKey];
    [self.userDefaults synchronize];
    return count;
}

- (BOOL)hasCurrentUserCommentedPostId:(NSString *)postId {
    NSString *userId = [self currentUserIdentifier];
    for (NSDictionary *comment in [self commentsForPostId:postId]) {
        NSString *authorId = [comment[@"authorId"] isKindOfClass:NSString.class] ? comment[@"authorId"] : @"";
        if ([authorId isEqualToString:userId]) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)isCommentBlocked:(NSDictionary *)comment {
    NSString *userId = [comment[@"userId"] isKindOfClass:NSString.class] ? comment[@"userId"] : @"";
    if (userId.length == 0) {
        NSString *authorId = [comment[@"authorId"] isKindOfClass:NSString.class] ? comment[@"authorId"] : @"";
        if ([authorId hasPrefix:@"user:"]) {
            userId = [authorId substringFromIndex:@"user:".length];
        } else {
            userId = authorId;
        }
    }
    if (userId.length == 0) {
        NSString *userName = [comment[@"userName"] isKindOfClass:NSString.class] ? comment[@"userName"] : @"";
        userId = userName.length > 0 ? [@"default_user_" stringByAppendingString:userName.lowercaseString] : @"";
    }
    return userId.length > 0 && [[YGBlacklistStore sharedStore] isBlockedUserId:userId];
}

- (nullable UIImage *)imageInPostResourcesNamed:(NSString *)fileName {
    if (fileName.length == 0) {
        return nil;
    }

    NSString *baseName = fileName.stringByDeletingPathExtension;
    NSString *extension = fileName.pathExtension;
    NSString *path = [[NSBundle mainBundle] pathForResource:baseName ofType:extension inDirectory:@"Postimagesoureces"];
    if (path.length == 0) {
        path = [[NSBundle mainBundle] pathForResource:baseName ofType:extension];
    }
    return path.length > 0 ? [UIImage imageWithContentsOfFile:path] : nil;
}

- (nullable UIImage *)imageForPostImageName:(NSString *)imageName {
    if (imageName.length == 0) {
        return nil;
    }

    UIImage *localImage = [UIImage imageWithContentsOfFile:[self absolutePathForStoredImagePath:imageName]];
    if (localImage != nil) {
        return localImage;
    }

    localImage = [UIImage imageWithContentsOfFile:imageName];
    if (localImage != nil) {
        return localImage;
    }

    return [self imageInPostResourcesNamed:imageName];
}

- (nullable UIImage *)avatarImageForPost:(NSDictionary *)post {
    NSString *avatarLocalPath = [post[@"avatarLocalPath"] isKindOfClass:NSString.class] ? post[@"avatarLocalPath"] : @"";
    if (avatarLocalPath.length > 0) {
        UIImage *image = [UIImage imageWithContentsOfFile:avatarLocalPath];
        if (image != nil) {
            return image;
        }
    }

    NSString *avatarDataBase64 = [post[@"avatarDataBase64"] isKindOfClass:NSString.class] ? post[@"avatarDataBase64"] : @"";
    if (avatarDataBase64.length > 0) {
        NSData *imageData = [[NSData alloc] initWithBase64EncodedString:avatarDataBase64 options:0];
        UIImage *image = [UIImage imageWithData:imageData];
        if (image != nil) {
            return image;
        }
    }

    UIImage *avatarImage = [self imageInPostResourcesNamed:post[@"avatarImageName"]];
    if (avatarImage != nil) {
        return avatarImage;
    }

    UIImage *contentImage = [self imageInPostResourcesNamed:post[@"contentImageName"]];
    if (contentImage != nil) {
        return contentImage;
    }

    NSString *avatarName = [post[@"avatarName"] isKindOfClass:NSString.class] ? post[@"avatarName"] : @"";
    return avatarName.length > 0 ? [UIImage imageNamed:avatarName] : nil;
}

- (NSArray<NSString *> *)persistLocalImages:(NSArray<UIImage *> *)images {
    NSString *documentsDirectory = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    NSString *directoryPath = [documentsDirectory stringByAppendingPathComponent:@"YagaLocalImages"];
    NSFileManager *fileManager = NSFileManager.defaultManager;
    if (![fileManager fileExistsAtPath:directoryPath]) {
        [fileManager createDirectoryAtPath:directoryPath withIntermediateDirectories:YES attributes:nil error:nil];
    }

    NSMutableArray<NSString *> *imagePaths = [NSMutableArray array];
    for (UIImage *image in images) {
        NSData *imageData = UIImageJPEGRepresentation(image, 0.88);
        if (imageData.length == 0) {
            continue;
        }
        NSString *fileName = [NSString stringWithFormat:@"image_%@.jpg", NSUUID.UUID.UUIDString];
        NSString *relativePath = [@"YagaLocalImages" stringByAppendingPathComponent:fileName];
        NSString *filePath = [self.documentsDirectory stringByAppendingPathComponent:relativePath];
        if ([imageData writeToFile:filePath atomically:YES]) {
            [imagePaths addObject:relativePath];
        }
    }
    return [imagePaths copy];
}

- (NSString *)absolutePathForStoredImagePath:(NSString *)storedPath {
    if (storedPath.length == 0) {
        return @"";
    }
    if ([storedPath hasPrefix:@"/"]) {
        NSString *fileName = storedPath.lastPathComponent;
        NSString *relativeRecoveryPath = [@"YagaLocalImages" stringByAppendingPathComponent:fileName];
        NSString *recoveredPath = [self.documentsDirectory stringByAppendingPathComponent:relativeRecoveryPath];
        if ([NSFileManager.defaultManager fileExistsAtPath:recoveredPath]) {
            return recoveredPath;
        }
        return storedPath;
    }
    return [self.documentsDirectory stringByAppendingPathComponent:storedPath];
}

- (NSString *)documentsDirectory {
    return NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject ?: @"";
}

- (void)migrateLocalImagePathsIfNeeded {
    NSArray *posts = [self.userDefaults arrayForKey:YGImagePostStorePostsKey];
    if (![posts isKindOfClass:NSArray.class]) {
        return;
    }

    BOOL didChange = NO;
    NSMutableArray *updatedPosts = [NSMutableArray arrayWithCapacity:posts.count];
    for (NSDictionary *post in posts) {
        if (![post isKindOfClass:NSDictionary.class]) {
            [updatedPosts addObject:post];
            continue;
        }

        NSMutableDictionary *updatedPost = [post mutableCopy];
        NSArray *imageNames = [post[@"imageNames"] isKindOfClass:NSArray.class] ? post[@"imageNames"] : @[];
        NSMutableArray *updatedImageNames = [NSMutableArray arrayWithCapacity:imageNames.count];
        for (NSString *imageName in imageNames) {
            NSString *updatedImageName = [self migratedRelativeImagePathFromPath:imageName];
            if (![updatedImageName isEqualToString:imageName]) {
                didChange = YES;
            }
            [updatedImageNames addObject:updatedImageName];
        }
        if (updatedImageNames.count > 0) {
            updatedPost[@"imageNames"] = [updatedImageNames copy];
        }

        NSString *contentImageName = [post[@"contentImageName"] isKindOfClass:NSString.class] ? post[@"contentImageName"] : @"";
        NSString *updatedContentImageName = [self migratedRelativeImagePathFromPath:contentImageName];
        if (![updatedContentImageName isEqualToString:contentImageName]) {
            updatedPost[@"contentImageName"] = updatedContentImageName;
            didChange = YES;
        }

        [updatedPosts addObject:[updatedPost copy]];
    }

    if (didChange) {
        [self.userDefaults setObject:[updatedPosts copy] forKey:YGImagePostStorePostsKey];
        [self.userDefaults synchronize];
    }
}

- (NSString *)migratedRelativeImagePathFromPath:(NSString *)path {
    if (path.length == 0 || ![path hasPrefix:@"/"]) {
        return path ?: @"";
    }

    NSString *fileName = path.lastPathComponent;
    NSString *relativePath = [@"YagaLocalImages" stringByAppendingPathComponent:fileName];
    NSString *currentPath = [self.documentsDirectory stringByAppendingPathComponent:relativePath];
    if ([NSFileManager.defaultManager fileExistsAtPath:currentPath]) {
        return relativePath;
    }

    if ([NSFileManager.defaultManager fileExistsAtPath:path]) {
        NSData *imageData = [NSData dataWithContentsOfFile:path];
        if ([imageData writeToFile:currentPath atomically:YES]) {
            return relativePath;
        }
    }
    return path;
}

- (void)seedPostsIfNeeded {
    NSArray<NSDictionary *> *defaultPosts = [self defaultPosts];
    NSString *postsSignature = [self signatureForPosts:defaultPosts];
    NSString *storedSignature = [self.userDefaults stringForKey:YGImagePostStorePostsSignatureKey];
    NSInteger storedVersion = [self.userDefaults integerForKey:YGImagePostStoreSeedVersionKey];
    if (storedVersion >= YGImagePostStoreSeedVersion && [storedSignature isEqualToString:postsSignature]) {
        return;
    }

    NSMutableDictionary<NSString *, NSArray *> *commentsDatabase = [[self commentsDatabase] mutableCopy];
    NSMutableDictionary<NSString *, NSDictionary *> *likesDatabase = [[self likesDatabase] mutableCopy];
    for (NSDictionary *post in defaultPosts) {
        NSString *postId = post[@"postId"];
        if (postId.length == 0) {
            continue;
        }
        NSDictionary *seedComment = [self seedCommentForPost:post];
        commentsDatabase[postId] = [self commentsByRefreshingSeedComment:seedComment existingComments:commentsDatabase[postId]];
        if (![likesDatabase[postId] isKindOfClass:NSDictionary.class]) {
            NSNumber *likeCount = post[@"likeCount"];
            likesDatabase[postId] = @{
                @"count": @([likeCount respondsToSelector:@selector(integerValue)] ? likeCount.integerValue : 0),
                @"userIds": @[]
            };
        }
    }

    NSArray *mergedPosts = [self postsByMergingDefaultPosts:defaultPosts withStoredPosts:[self.userDefaults arrayForKey:YGImagePostStorePostsKey]];
    [self.userDefaults setObject:mergedPosts forKey:YGImagePostStorePostsKey];
    [self.userDefaults setObject:[commentsDatabase copy] forKey:YGImagePostStoreCommentsKey];
    [self.userDefaults setObject:[likesDatabase copy] forKey:YGImagePostStoreLikesKey];
    [self.userDefaults setInteger:YGImagePostStoreSeedVersion forKey:YGImagePostStoreSeedVersionKey];
    [self.userDefaults setObject:postsSignature forKey:YGImagePostStorePostsSignatureKey];
    [self.userDefaults synchronize];
}

- (NSArray<NSDictionary *> *)postsByMergingDefaultPosts:(NSArray<NSDictionary *> *)defaultPosts
                                        withStoredPosts:(NSArray *)storedPosts {
    NSMutableSet<NSString *> *defaultPostIds = [NSMutableSet set];
    for (NSDictionary *post in defaultPosts) {
        NSString *postId = [post[@"postId"] isKindOfClass:NSString.class] ? post[@"postId"] : @"";
        if (postId.length > 0) {
            [defaultPostIds addObject:postId];
        }
    }

    NSMutableArray<NSDictionary *> *mergedPosts = [NSMutableArray array];
    for (NSDictionary *post in [storedPosts isKindOfClass:NSArray.class] ? storedPosts : @[]) {
        if (![post isKindOfClass:NSDictionary.class]) {
            continue;
        }
        NSString *postId = [post[@"postId"] isKindOfClass:NSString.class] ? post[@"postId"] : @"";
        if (postId.length == 0 || [defaultPostIds containsObject:postId]) {
            continue;
        }
        [mergedPosts addObject:post];
    }
    [mergedPosts addObjectsFromArray:defaultPosts];
    return [mergedPosts copy];
}

- (NSDictionary *)commentsDatabase {
    NSDictionary *commentsDatabase = [self.userDefaults dictionaryForKey:YGImagePostStoreCommentsKey];
    return [commentsDatabase isKindOfClass:NSDictionary.class] ? commentsDatabase : @{};
}

- (NSDictionary *)likesDatabase {
    NSDictionary *likesDatabase = [self.userDefaults dictionaryForKey:YGImagePostStoreLikesKey];
    return [likesDatabase isKindOfClass:NSDictionary.class] ? likesDatabase : @{};
}

- (NSDictionary *)likeInfoForPostId:(NSString *)postId {
    if (postId.length == 0) {
        return @{@"count": @(0), @"userIds": @[]};
    }
    NSDictionary *likeInfo = [self likesDatabase][postId];
    return [likeInfo isKindOfClass:NSDictionary.class] ? likeInfo : @{@"count": @(0), @"userIds": @[]};
}

- (NSString *)currentUserIdentifier {
    NSString *email = [[YGUserStore sharedStore] currentUserEmail];
    if (email.length > 0) {
        return [@"user:" stringByAppendingString:email];
    }
    return @"guest";
}

- (NSString *)signatureForPosts:(NSArray<NSDictionary *> *)posts {
    NSData *data = [NSJSONSerialization dataWithJSONObject:posts options:0 error:nil];
    if (data.length == 0) {
        return posts.description;
    }
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] ?: posts.description;
}

- (NSArray *)commentsByRefreshingSeedComment:(NSDictionary *)seedComment existingComments:(NSArray *)existingComments {
    NSMutableArray *comments = [[existingComments isKindOfClass:NSArray.class] ? existingComments : @[] mutableCopy];
    NSInteger seedIndex = NSNotFound;
    for (NSInteger index = 0; index < comments.count; index++) {
        NSDictionary *comment = [comments[index] isKindOfClass:NSDictionary.class] ? comments[index] : nil;
        if ([self isSeedComment:comment]) {
            seedIndex = index;
            break;
        }
    }

    if (seedComment.count == 0) {
        if (seedIndex != NSNotFound) {
            [comments removeObjectAtIndex:seedIndex];
        }
        return [comments copy];
    }

    if (seedIndex == NSNotFound) {
        [comments insertObject:seedComment atIndex:0];
    } else {
        comments[seedIndex] = seedComment;
    }
    return [comments copy];
}

- (BOOL)isSeedComment:(NSDictionary *)comment {
    if (comment.count == 0) {
        return NO;
    }
    NSString *isSeed = comment[@"isSeed"];
    if ([isSeed isEqualToString:@"1"]) {
        return YES;
    }
    return [comment[@"avatarName"] isEqualToString:@"headplace"] &&
        [comment[@"userName"] isEqualToString:@"Yaga User"] &&
        [comment[@"time"] isEqualToString:@"10m ago"];
}

- (NSDictionary *)seedCommentForPost:(NSDictionary *)post {
    NSDictionary *author = [self seedCommentAuthorForPost:post];
    NSString *text = [self seedCommentTextForPostId:post[@"postId"]];
    NSString *userId = [author[@"userId"] isKindOfClass:NSString.class] ? author[@"userId"] : @"";
    return @{
        @"avatarName": [author[@"avatarName"] isKindOfClass:NSString.class] ? author[@"avatarName"] : @"headplace",
        @"avatarLocalPath": @"",
        @"avatarDataBase64": @"",
        @"avatarImageName": [author[@"avatarImageName"] isKindOfClass:NSString.class] ? author[@"avatarImageName"] : @"",
        @"userName": [author[@"userName"] isKindOfClass:NSString.class] ? author[@"userName"] : @"Yaga User",
        @"userId": userId,
        @"authorId": userId,
        @"text": text.length > 0 ? text : @"Love this gentle flow.",
        @"time": @"10m ago",
        @"isSeed": @"1"
    };
}

- (NSDictionary *)seedCommentAuthorForPost:(NSDictionary *)post {
    NSArray<NSDictionary *> *authors = [self defaultCommentAuthors];
    if (authors.count == 0) {
        return @{};
    }

    NSString *postUserId = [post[@"userId"] isKindOfClass:NSString.class] ? post[@"userId"] : @"";
    NSMutableArray<NSDictionary *> *availableAuthors = [NSMutableArray array];
    for (NSDictionary *author in authors) {
        NSString *userId = [author[@"userId"] isKindOfClass:NSString.class] ? author[@"userId"] : @"";
        if (![userId isEqualToString:postUserId]) {
            [availableAuthors addObject:author];
        }
    }
    NSArray<NSDictionary *> *candidateAuthors = availableAuthors.count > 0 ? availableAuthors : authors;
    NSUInteger index = [self stableIndexForString:post[@"postId"] count:candidateAuthors.count];
    return candidateAuthors[index];
}

- (NSString *)seedCommentTextForPostId:(NSString *)postId {
    NSArray<NSString *> *texts = @[
        @"This is exactly the calm energy I needed today.",
        @"Such a beautiful reminder to slow down and breathe.",
        @"Love this. It feels simple, warm, and easy to follow.",
        @"Saving this for my next quiet morning practice.",
        @"The posture tips here are really helpful.",
        @"This makes yoga feel so approachable."
    ];
    return texts[[self stableIndexForString:postId count:texts.count]];
}

- (NSArray<NSDictionary *> *)defaultCommentAuthors {
    return @[
        @{
            @"userId": @"default_image_nora",
            @"userName": @"Nora",
            @"avatarName": @"headplace",
            @"avatarImageName": @"Nora1.jpg"
        },
        @{
            @"userId": @"default_image_kuoh",
            @"userName": @"Kuoh",
            @"avatarName": @"headplace",
            @"avatarImageName": @"Kuoh.jpg"
        },
        @{
            @"userId": @"default_image_cruise",
            @"userName": @"Cruise",
            @"avatarName": @"headplace",
            @"avatarImageName": @"Cruise1.jpg"
        },
        @{
            @"userId": @"default_image_lisa",
            @"userName": @"Lisa",
            @"avatarName": @"headplace",
            @"avatarImageName": @"Lisa1.jpg"
        }
    ];
}

- (NSUInteger)stableIndexForString:(NSString *)string count:(NSUInteger)count {
    if (count == 0) {
        return 0;
    }
    NSUInteger seed = 0;
    for (NSUInteger index = 0; index < string.length; index++) {
        seed = seed * 31 + [string characterAtIndex:index];
    }
    return seed % count;
}

- (NSDictionary *)seedCommentWithText:(NSString *)text {
    return @{
        @"avatarName": @"headplace",
        @"avatarLocalPath": @"",
        @"avatarDataBase64": @"",
        @"userName": @"Yaga User",
        @"text": text.length > 0 ? text : @"",
        @"time": @"10m ago",
        @"isSeed": @"1"
    };
}

- (NSArray<NSDictionary *> *)defaultPosts {
    return @[
        @{
            @"postId": @"nora",
            @"userId": @"default_image_nora",
            @"userName": @"Nora",
            @"avatarName": @"headplace",
            @"avatarImageName": @"Nora1.jpg",
            @"imageNames": @[@"Nora2.jpg"],
            @"contentImageName": @"Nora2.jpg",
            @"likeCount": @(72),
            @"descriptionText": @"Just 15 minutes to wake up your body, relieve morning stiffness and ease sedentary back & waist pain. Yoga is simple self-care, no competition needed. Newbies, start here!"
        },
        @{
            @"postId": @"kuoh",
            @"userId": @"default_image_kuoh",
            @"userName": @"Kuoh",
            @"avatarName": @"headplace",
            @"avatarImageName": @"Kuoh.jpg",
            @"imageNames": @[@"Kuoh.jpg"],
            @"contentImageName": @"Kuoh.jpg",
            @"likeCount": @(31),
            @"descriptionText": @"8-hour desk job ruining your posture? Try this 10-minute shoulder & neck yoga! No equipment needed, great for office & home use."
        },
        @{
            @"postId": @"cruise",
            @"userId": @"default_image_cruise",
            @"userName": @"Cruise",
            @"avatarName": @"headplace",
            @"avatarImageName": @"Cruise1.jpg",
            @"imageNames": @[@"Cruise2.jpg"],
            @"contentImageName": @"Cruise2.jpg",
            @"likeCount": @(48),
            @"descriptionText": @"Ditch exhausting intense cardio! This low-impact yoga routine helps burn fat and tone your body naturally."
        },
        @{
            @"postId": @"lisa",
            @"userId": @"default_image_lisa",
            @"userName": @"Lisa",
            @"avatarName": @"headplace",
            @"avatarImageName": @"Lisa1.jpg",
            @"imageNames": @[@"Lisa2.jpg"],
            @"contentImageName": @"Lisa2.jpg",
            @"likeCount": @(25),
            @"descriptionText": @"Simple core yoga poses to tighten your belly and build a strong core!"
        }
    ];
}

@end
