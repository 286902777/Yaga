//
//  YGPostsListCell.h
//  Yaga
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface YGPostsListCell : UICollectionViewCell

@property (class, nonatomic, copy, readonly) NSString *reuseIdentifier;
@property (nonatomic, copy, nullable) void (^moreTapHandler)(void);

- (void)configureWithAvatarName:(NSString *)avatarName
                       userName:(NSString *)userName
                descriptionText:(NSString *)descriptionText
               contentImageName:(NSString *)contentImageName;
- (void)configureWithImagePost:(NSDictionary *)post;
- (void)configureWithVideoPost:(NSDictionary *)post;
- (void)setMoreHidden:(BOOL)hidden;

@end

NS_ASSUME_NONNULL_END
