//
//  YGImagePostStore.h
//  Yaga
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface YGImagePostStore : NSObject

+ (instancetype)sharedStore;

- (NSArray<NSDictionary *> *)allPosts;
- (NSArray<NSDictionary *> *)postsForUserId:(NSString *)userId;
- (NSArray<NSDictionary *> *)defaultAuthorProfiles;
- (void)applyDefaultTestUserProfile:(NSDictionary *)profile toUserId:(NSString *)userId;
- (nullable NSDictionary *)addLocalImagePostWithText:(NSString *)text images:(NSArray<UIImage *> *)images;
- (NSArray<NSDictionary *> *)commentsForPostId:(NSString *)postId;
- (void)addComment:(NSDictionary *)comment toPostId:(NSString *)postId;
- (NSInteger)likeCountForPostId:(NSString *)postId;
- (BOOL)isCurrentUserLikedPostId:(NSString *)postId;
- (NSInteger)toggleLikeForPostId:(NSString *)postId;
- (BOOL)hasCurrentUserCommentedPostId:(NSString *)postId;
- (nullable UIImage *)imageInPostResourcesNamed:(NSString *)fileName;
- (nullable UIImage *)imageForPostImageName:(NSString *)imageName;
- (nullable UIImage *)avatarImageForPost:(NSDictionary *)post;

@end

NS_ASSUME_NONNULL_END
