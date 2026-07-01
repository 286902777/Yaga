//
//  YGVideoPostStore.h
//  Yaga
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface YGVideoPostStore : NSObject

+ (instancetype)sharedStore;

- (NSArray<NSDictionary *> *)allPosts;
- (NSArray<NSDictionary *> *)postsForSectionTitle:(NSString *)title;
- (NSArray<NSDictionary *> *)postsForUserId:(NSString *)userId;
- (NSArray<NSDictionary *> *)defaultAuthorProfiles;
- (void)applyDefaultTestUserProfile:(NSDictionary *)profile toUserId:(NSString *)userId;
- (nullable NSDictionary *)addLocalVideoPostWithText:(NSString *)text videoURL:(NSURL *)videoURL;
- (NSArray<NSDictionary *> *)commentsForPostId:(NSString *)postId;
- (void)addComment:(NSDictionary *)comment toPostId:(NSString *)postId;
- (NSInteger)likeCountForPostId:(NSString *)postId;
- (BOOL)isCurrentUserLikedPostId:(NSString *)postId;
- (NSInteger)toggleLikeForPostId:(NSString *)postId;
- (BOOL)hasCurrentUserCommentedPostId:(NSString *)postId;
- (nullable UIImage *)imageInVideoResourcesNamed:(NSString *)fileName;
- (nullable UIImage *)avatarImageForPost:(NSDictionary *)post;
- (nullable UIImage *)thumbnailImageForVideoNamed:(NSString *)fileName;
- (nullable UIImage *)thumbnailImageForPost:(NSDictionary *)post;
- (nullable NSURL *)videoURLInVideoResourcesNamed:(NSString *)fileName;
- (nullable NSURL *)videoURLForPost:(NSDictionary *)post;

@end

NS_ASSUME_NONNULL_END
