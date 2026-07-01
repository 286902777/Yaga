//
//  YGVideoPostStore.m
//  Yaga
//

#import "YGVideoPostStore.h"
#import "YGUserStore.h"
#import "YGFollowStore.h"
#import "YGBlacklistStore.h"
#import <AVFoundation/AVFoundation.h>

static NSString * const YGVideoPostStorePostsKey = @"com.yaga.videopoststore.posts";
static NSString * const YGVideoPostStoreCommentsKey = @"com.yaga.videopoststore.comments";
static NSString * const YGVideoPostStoreLikesKey = @"com.yaga.videopoststore.likes";
static NSString * const YGVideoPostStoreSeedVersionKey = @"com.yaga.videopoststore.seedVersion";
static NSString * const YGVideoPostStorePostsSignatureKey = @"com.yaga.videopoststore.postsSignature";
static NSInteger const YGVideoPostStoreSeedVersion = 3;

@interface YGVideoPostStore ()

@property (nonatomic, strong) NSUserDefaults *userDefaults;
@property (nonatomic, strong) NSCache<NSString *, UIImage *> *thumbnailCache;

@end

@implementation YGVideoPostStore

+ (instancetype)sharedStore {
    static YGVideoPostStore *store;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        store = [[YGVideoPostStore alloc] initPrivate];
    });
    return store;
}

- (instancetype)init {
    @throw [NSException exceptionWithName:@"YGVideoPostStoreInitError"
                                   reason:@"Use sharedStore instead."
                                 userInfo:nil];
}

- (instancetype)initPrivate {
    self = [super init];
    if (self) {
        _userDefaults = NSUserDefaults.standardUserDefaults;
        _thumbnailCache = [[NSCache alloc] init];
        [self seedPostsIfNeeded];
        [self migrateLocalVideoPathsIfNeeded];
    }
    return self;
}

- (NSArray<NSDictionary *> *)allPosts {
    NSArray *posts = [self.userDefaults arrayForKey:YGVideoPostStorePostsKey];
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

- (NSArray<NSDictionary *> *)postsForSectionTitle:(NSString *)title {
    NSArray<NSDictionary *> *posts = [self allPosts];
    if ([title isEqualToString:@"Newest"]) {
        return [self newestPostsFromPosts:posts];
    }
    if ([title isEqualToString:@"Follow"]) {
        NSArray<NSString *> *followingUserIds = [[YGFollowStore sharedStore] followingUserIdsForCurrentUser];
        if (followingUserIds.count == 0) {
            return @[];
        }

        NSMutableArray<NSDictionary *> *followPosts = [NSMutableArray array];
        for (NSDictionary *post in posts) {
            NSString *userId = [post[@"userId"] isKindOfClass:NSString.class] ? post[@"userId"] : @"";
            if ([followingUserIds containsObject:userId]) {
                [followPosts addObject:post];
            }
        }
        return [followPosts copy];
    }
    return posts;
}

- (NSArray<NSDictionary *> *)newestPostsFromPosts:(NSArray<NSDictionary *> *)posts {
    NSMutableArray<NSDictionary *> *localPosts = [NSMutableArray array];
    NSMutableArray<NSDictionary *> *defaultPosts = [NSMutableArray array];
    for (NSDictionary *post in posts) {
        NSString *postId = [post[@"postId"] isKindOfClass:NSString.class] ? post[@"postId"] : @"";
        if ([postId hasPrefix:@"local_video_"]) {
            [localPosts addObject:post];
        } else {
            [defaultPosts addObject:post];
        }
    }

    NSMutableArray<NSDictionary *> *randomDefaults = [[self shuffledPosts:defaultPosts] mutableCopy];
    if (randomDefaults.count > 2) {
        [randomDefaults removeObjectsInRange:NSMakeRange(2, randomDefaults.count - 2)];
    }

    NSMutableArray<NSDictionary *> *newestPosts = [NSMutableArray arrayWithArray:localPosts];
    [newestPosts addObjectsFromArray:randomDefaults];
    return [newestPosts copy];
}

- (NSArray<NSDictionary *> *)shuffledPosts:(NSArray<NSDictionary *> *)posts {
    NSMutableArray<NSDictionary *> *shuffledPosts = [posts mutableCopy];
    for (NSInteger index = shuffledPosts.count - 1; index > 0; index--) {
        NSInteger swapIndex = arc4random_uniform((uint32_t)(index + 1));
        [shuffledPosts exchangeObjectAtIndex:index withObjectAtIndex:swapIndex];
    }
    return [shuffledPosts copy];
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
            @"source": @"video",
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

    NSArray *storedPosts = [self.userDefaults arrayForKey:YGVideoPostStorePostsKey];
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
        BOOL belongsToPreviousTestProfile = [postUserId isEqualToString:userId] && [originalUserId hasPrefix:@"default_video_"];

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
        [self.userDefaults setObject:[updatedPosts copy] forKey:YGVideoPostStorePostsKey];
        [self.userDefaults synchronize];
    }
}

- (nullable NSDictionary *)addLocalVideoPostWithText:(NSString *)text videoURL:(NSURL *)videoURL {
    if (text.length == 0 || videoURL == nil) {
        return nil;
    }

    NSString *savedVideoPath = [self persistLocalVideoFromURL:videoURL];
    if (savedVideoPath.length == 0) {
        return nil;
    }

    NSDictionary *currentUser = [[YGUserStore sharedStore] currentUser];
    NSString *nickname = [currentUser[@"nickname"] isKindOfClass:NSString.class] ? currentUser[@"nickname"] : @"";
    NSString *avatarName = [currentUser[@"avatarName"] isKindOfClass:NSString.class] ? currentUser[@"avatarName"] : @"";
    NSString *avatarLocalPath = [currentUser[@"avatarLocalPath"] isKindOfClass:NSString.class] ? currentUser[@"avatarLocalPath"] : @"";
    NSString *avatarDataBase64 = [currentUser[@"avatarDataBase64"] isKindOfClass:NSString.class] ? currentUser[@"avatarDataBase64"] : @"";
    NSString *avatarImageName = [currentUser[@"avatarImageName"] isKindOfClass:NSString.class] ? currentUser[@"avatarImageName"] : @"";
    NSString *postId = [@"local_video_" stringByAppendingString:NSUUID.UUID.UUIDString];
    NSDictionary *post = @{
        @"postId": postId,
        @"userId": [[YGUserStore sharedStore] currentUserEmail] ?: @"guest",
        @"userName": nickname.length > 0 ? nickname : @"Yaga User",
        @"avatarName": avatarName.length > 0 ? avatarName : @"headplace",
        @"avatarLocalPath": avatarLocalPath.length > 0 ? avatarLocalPath : @"",
        @"avatarDataBase64": avatarDataBase64.length > 0 ? avatarDataBase64 : @"",
        @"avatarImageName": avatarImageName.length > 0 ? avatarImageName : @"",
        @"videoLocalPath": savedVideoPath,
        @"likeCount": @(0),
        @"text": text,
        @"seedCommentText": @""
    };

    NSArray *storedPosts = [self.userDefaults arrayForKey:YGVideoPostStorePostsKey];
    NSMutableArray *posts = [[storedPosts isKindOfClass:NSArray.class] ? storedPosts : @[] mutableCopy];
    [posts insertObject:post atIndex:0];

    NSMutableDictionary *commentsDatabase = [[self commentsDatabase] mutableCopy];
    commentsDatabase[postId] = @[];
    NSMutableDictionary *likesDatabase = [[self likesDatabase] mutableCopy];
    likesDatabase[postId] = @{@"count": @(0), @"userIds": @[]};

    [self.userDefaults setObject:[posts copy] forKey:YGVideoPostStorePostsKey];
    [self.userDefaults setObject:[commentsDatabase copy] forKey:YGVideoPostStoreCommentsKey];
    [self.userDefaults setObject:[likesDatabase copy] forKey:YGVideoPostStoreLikesKey];
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
    [self.userDefaults setObject:[commentsDatabase copy] forKey:YGVideoPostStoreCommentsKey];
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
    [self.userDefaults setObject:[likesDatabase copy] forKey:YGVideoPostStoreLikesKey];
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

- (nullable UIImage *)imageInVideoResourcesNamed:(NSString *)fileName {
    if (fileName.length == 0) {
        return nil;
    }

    NSString *baseName = fileName.stringByDeletingPathExtension;
    NSString *extension = fileName.pathExtension;
    NSString *path = [[NSBundle mainBundle] pathForResource:baseName ofType:extension inDirectory:@"Videosoureces"];
    if (path.length == 0) {
        path = [[NSBundle mainBundle] pathForResource:baseName ofType:extension];
    }
    UIImage *image = path.length > 0 ? [UIImage imageWithContentsOfFile:path] : nil;
    return image;
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

    UIImage *resourceImage = [self imageInVideoResourcesNamed:post[@"avatarImageName"]];
    if (resourceImage != nil) {
        return resourceImage;
    }

    NSString *avatarName = [post[@"avatarName"] isKindOfClass:NSString.class] ? post[@"avatarName"] : @"";
    return avatarName.length > 0 ? [UIImage imageNamed:avatarName] : nil;
}

- (nullable NSURL *)videoURLInVideoResourcesNamed:(NSString *)fileName {
    if (fileName.length == 0) {
        return nil;
    }

    NSString *baseName = fileName.stringByDeletingPathExtension;
    NSString *extension = fileName.pathExtension;
    NSURL *url = [[NSBundle mainBundle] URLForResource:baseName withExtension:extension subdirectory:@"Videosoureces"];
    if (url == nil) {
        url = [[NSBundle mainBundle] URLForResource:baseName withExtension:extension];
    }
    return url;
}

- (nullable NSURL *)videoURLForPost:(NSDictionary *)post {
    NSString *videoLocalPath = [post[@"videoLocalPath"] isKindOfClass:NSString.class] ? post[@"videoLocalPath"] : @"";
    if (videoLocalPath.length > 0) {
        NSString *absolutePath = [self absolutePathForStoredVideoPath:videoLocalPath];
        if ([NSFileManager.defaultManager fileExistsAtPath:absolutePath]) {
            return [NSURL fileURLWithPath:absolutePath];
        }
    }
    return [self videoURLInVideoResourcesNamed:post[@"videoFileName"]];
}

- (nullable UIImage *)thumbnailImageForVideoNamed:(NSString *)fileName {
    NSURL *videoURL = [self videoURLInVideoResourcesNamed:fileName];
    if (videoURL == nil) {
        return nil;
    }

    UIImage *cachedImage = [self.thumbnailCache objectForKey:fileName];
    if (cachedImage != nil) {
        return cachedImage;
    }

    UIImage *image = [self thumbnailImageForVideoURL:videoURL];
    if (image != nil) {
        [self.thumbnailCache setObject:image forKey:fileName];
    }
    return image;
}

- (nullable UIImage *)thumbnailImageForPost:(NSDictionary *)post {
    NSURL *videoURL = [self videoURLForPost:post];
    if (videoURL == nil) {
        return nil;
    }

    NSString *cacheKey = [post[@"videoLocalPath"] isKindOfClass:NSString.class] ? post[@"videoLocalPath"] : post[@"videoFileName"];
    UIImage *cachedImage = cacheKey.length > 0 ? [self.thumbnailCache objectForKey:cacheKey] : nil;
    if (cachedImage != nil) {
        return cachedImage;
    }

    UIImage *image = [self thumbnailImageForVideoURL:videoURL];
    if (image != nil && cacheKey.length > 0) {
        [self.thumbnailCache setObject:image forKey:cacheKey];
    }
    return image;
}

- (nullable UIImage *)thumbnailImageForVideoURL:(NSURL *)videoURL {
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:videoURL options:nil];
    AVAssetImageGenerator *imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
    imageGenerator.appliesPreferredTrackTransform = YES;
    imageGenerator.maximumSize = CGSizeMake(720.0, 1280.0);
    NSError *error = nil;
    CGImageRef imageRef = [imageGenerator copyCGImageAtTime:CMTimeMakeWithSeconds(0.0, 600)
                                                 actualTime:NULL
                                                      error:&error];
    if (imageRef == nil) {
        imageRef = [imageGenerator copyCGImageAtTime:CMTimeMakeWithSeconds(0.1, 600)
                                          actualTime:NULL
                                               error:&error];
    }
    if (imageRef == nil) {
        return nil;
    }

    UIImage *image = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    return image;
}

- (nullable NSString *)persistLocalVideoFromURL:(NSURL *)sourceURL {
    if (sourceURL == nil) {
        return nil;
    }

    NSString *extension = sourceURL.pathExtension.length > 0 ? sourceURL.pathExtension : @"mov";
    NSString *fileName = [NSString stringWithFormat:@"video_%@.%@", NSUUID.UUID.UUIDString, extension];
    NSString *relativePath = [@"YagaLocalVideos" stringByAppendingPathComponent:fileName];
    NSString *directoryPath = [[self documentsDirectory] stringByAppendingPathComponent:@"YagaLocalVideos"];
    NSFileManager *fileManager = NSFileManager.defaultManager;
    if (![fileManager fileExistsAtPath:directoryPath]) {
        [fileManager createDirectoryAtPath:directoryPath withIntermediateDirectories:YES attributes:nil error:nil];
    }

    NSURL *destinationURL = [NSURL fileURLWithPath:[directoryPath stringByAppendingPathComponent:fileName]];
    [fileManager removeItemAtURL:destinationURL error:nil];
    BOOL didStartAccessing = [sourceURL startAccessingSecurityScopedResource];
    NSError *copyError = nil;
    BOOL success = [fileManager copyItemAtURL:sourceURL toURL:destinationURL error:&copyError];
    if (!success) {
        NSData *videoData = [NSData dataWithContentsOfURL:sourceURL];
        success = videoData.length > 0 && [videoData writeToURL:destinationURL atomically:YES];
    }
    if (didStartAccessing) {
        [sourceURL stopAccessingSecurityScopedResource];
    }
    return success ? relativePath : nil;
}

- (NSString *)absolutePathForStoredVideoPath:(NSString *)storedPath {
    if (storedPath.length == 0) {
        return @"";
    }
    if ([storedPath hasPrefix:@"/"]) {
        NSString *fileName = storedPath.lastPathComponent;
        NSString *recoveredPath = [[self documentsDirectory] stringByAppendingPathComponent:[@"YagaLocalVideos" stringByAppendingPathComponent:fileName]];
        if ([NSFileManager.defaultManager fileExistsAtPath:recoveredPath]) {
            return recoveredPath;
        }
        return storedPath;
    }
    return [[self documentsDirectory] stringByAppendingPathComponent:storedPath];
}

- (NSString *)documentsDirectory {
    return NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject ?: @"";
}

- (void)migrateLocalVideoPathsIfNeeded {
    NSArray *posts = [self.userDefaults arrayForKey:YGVideoPostStorePostsKey];
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
        NSString *videoLocalPath = [post[@"videoLocalPath"] isKindOfClass:NSString.class] ? post[@"videoLocalPath"] : @"";
        NSString *updatedVideoLocalPath = [self migratedRelativeVideoPathFromPath:videoLocalPath];
        if (![updatedVideoLocalPath isEqualToString:videoLocalPath]) {
            updatedPost[@"videoLocalPath"] = updatedVideoLocalPath;
            didChange = YES;
        }
        [updatedPosts addObject:[updatedPost copy]];
    }

    if (didChange) {
        [self.userDefaults setObject:[updatedPosts copy] forKey:YGVideoPostStorePostsKey];
        [self.userDefaults synchronize];
    }
}

- (NSString *)migratedRelativeVideoPathFromPath:(NSString *)path {
    if (path.length == 0 || ![path hasPrefix:@"/"]) {
        return path ?: @"";
    }

    NSString *fileName = path.lastPathComponent;
    NSString *relativePath = [@"YagaLocalVideos" stringByAppendingPathComponent:fileName];
    NSString *currentPath = [[self documentsDirectory] stringByAppendingPathComponent:relativePath];
    if ([NSFileManager.defaultManager fileExistsAtPath:currentPath]) {
        return relativePath;
    }

    if ([NSFileManager.defaultManager fileExistsAtPath:path]) {
        NSData *videoData = [NSData dataWithContentsOfFile:path];
        if (videoData.length > 0 && [videoData writeToFile:currentPath atomically:YES]) {
            return relativePath;
        }
    }
    return path;
}

- (void)seedPostsIfNeeded {
    NSArray<NSDictionary *> *defaultPosts = [self defaultPosts];
    NSString *postsSignature = [self signatureForPosts:defaultPosts];
    NSString *storedSignature = [self.userDefaults stringForKey:YGVideoPostStorePostsSignatureKey];
    NSInteger storedVersion = [self.userDefaults integerForKey:YGVideoPostStoreSeedVersionKey];
    if (storedVersion >= YGVideoPostStoreSeedVersion && [storedSignature isEqualToString:postsSignature]) {
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
        commentsDatabase[postId] = [self commentsByRefreshingSeedComment:seedComment forPost:post existingComments:commentsDatabase[postId]];
        if (![likesDatabase[postId] isKindOfClass:NSDictionary.class]) {
            NSNumber *likeCount = post[@"likeCount"];
            likesDatabase[postId] = @{
                @"count": @([likeCount respondsToSelector:@selector(integerValue)] ? likeCount.integerValue : 0),
                @"userIds": @[]
            };
        }
    }

    NSArray *mergedPosts = [self postsByMergingDefaultPosts:defaultPosts withStoredPosts:[self.userDefaults arrayForKey:YGVideoPostStorePostsKey]];
    [self.userDefaults setObject:mergedPosts forKey:YGVideoPostStorePostsKey];
    [self.userDefaults setObject:[commentsDatabase copy] forKey:YGVideoPostStoreCommentsKey];
    [self.userDefaults setObject:[likesDatabase copy] forKey:YGVideoPostStoreLikesKey];
    [self.userDefaults setInteger:YGVideoPostStoreSeedVersion forKey:YGVideoPostStoreSeedVersionKey];
    [self.userDefaults setObject:postsSignature forKey:YGVideoPostStorePostsSignatureKey];
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

- (NSString *)signatureForPosts:(NSArray<NSDictionary *> *)posts {
    NSData *data = [NSJSONSerialization dataWithJSONObject:posts options:0 error:nil];
    if (data.length == 0) {
        return posts.description;
    }
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] ?: posts.description;
}

- (NSArray *)commentsByRefreshingSeedComment:(NSDictionary *)seedComment
                                     forPost:(NSDictionary *)post
                            existingComments:(NSArray *)existingComments {
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

- (NSDictionary *)commentsDatabase {
    NSDictionary *commentsDatabase = [self.userDefaults dictionaryForKey:YGVideoPostStoreCommentsKey];
    return [commentsDatabase isKindOfClass:NSDictionary.class] ? commentsDatabase : @{};
}

- (NSDictionary *)likesDatabase {
    NSDictionary *likesDatabase = [self.userDefaults dictionaryForKey:YGVideoPostStoreLikesKey];
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
        @"text": text.length > 0 ? text : @"This flow feels so good.",
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
        @"This flow feels so good after a long day.",
        @"Love how peaceful and beginner-friendly this is.",
        @"The pace is perfect. I can actually follow along.",
        @"Adding this to my morning yoga routine.",
        @"This gave me such a calm reset.",
        @"Beautiful practice. The movement feels really natural."
    ];
    return texts[[self stableIndexForString:postId count:texts.count]];
}

- (NSArray<NSDictionary *> *)defaultCommentAuthors {
    return @[
        @{
            @"userId": @"default_video_alonzo",
            @"userName": @"Alonzo",
            @"avatarName": @"headplace",
            @"avatarImageName": @"Alonzo.jpg"
        },
        @{
            @"userId": @"default_video_tomas",
            @"userName": @"Tomas",
            @"avatarName": @"headplace",
            @"avatarImageName": @"Tomas.jpg"
        },
        @{
            @"userId": @"default_video_meredith",
            @"userName": @"Meredith",
            @"avatarName": @"headplace",
            @"avatarImageName": @"Meredith.jpg"
        },
        @{
            @"userId": @"default_video_jane",
            @"userName": @"Jane",
            @"avatarName": @"headplace",
            @"avatarImageName": @"Jane.jpg"
        },
        @{
            @"userId": @"default_video_annie",
            @"userName": @"Annie",
            @"avatarName": @"headplace",
            @"avatarImageName": @"Annie.jpg"
        },
        @{
            @"userId": @"default_video_shelly",
            @"userName": @"Shelly",
            @"avatarName": @"headplace",
            @"avatarImageName": @"Shelly.jpg"
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
            @"postId": @"alonzo",
            @"userId": @"default_video_alonzo",
            @"userName": @"Alonzo",
            @"avatarImageName": @"Alonzo.jpg",
            @"videoFileName": @"AlonzoT161141864.mp4",
            @"likeCount": @(18),
            @"text": @"You don’t have to be the bendiest person to get a good yoga session in."
        },
        @{
            @"postId": @"tomas",
            @"userId": @"default_video_tomas",
            @"userName": @"Tomas",
            @"avatarImageName": @"Tomas.jpg",
            @"videoFileName": @"TomasT161827706.mp4",
            @"likeCount": @(43),
            @"text": @"Yoga vibes"
        },
        @{
            @"postId": @"meredith",
            @"userId": @"default_video_meredith",
            @"userName": @"Meredith",
            @"avatarImageName": @"Meredith.jpg",
            @"videoFileName": @"MeredithT160415325.mp4",
            @"likeCount": @(27),
            @"text": @"Basic yoga. Let's practice together!"
        },
        @{
            @"postId": @"jane",
            @"userId": @"default_video_jane",
            @"userName": @"Jane",
            @"avatarImageName": @"Jane.jpg",
            @"videoFileName": @"JaneT113104.649.mp4",
            @"likeCount": @(64),
            @"text": @"yoga flow for first time on the mat! If you've been meaning to try yoga this year, let this be your sign"
        },
        @{
            @"postId": @"annie",
            @"userId": @"default_video_annie",
            @"userName": @"Annie",
            @"avatarImageName": @"Annie.jpg",
            @"videoFileName": @"AnnieT114105.392.mp4",
            @"likeCount": @(35),
            @"text": @"a simple yoga routine to start your day and gently stretch your body"
        },
        @{
            @"postId": @"shelly",
            @"userId": @"default_video_shelly",
            @"userName": @"Shelly",
            @"avatarImageName": @"Shelly.jpg",
            @"videoFileName": @"ShellyT113853.864.mp4",
            @"likeCount": @(52),
            @"text": @"Perfect for beginner yogis"
        }
    ];
}

@end
