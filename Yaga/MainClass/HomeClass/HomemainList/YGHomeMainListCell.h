//
//  YGHomeMainListCell.h
//  Yaga
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface YGHomeMainListCell : UICollectionViewCell

+ (NSString *)reuseIdentifier;
- (void)configureWithImageName:(NSString *)imageName
                          text:(NSString *)text
                    avatarName:(NSString *)avatarName
                      userName:(NSString *)userName;
- (void)configureWithVideoPost:(NSDictionary *)post;
- (void)setMoreHidden:(BOOL)hidden;

@end

NS_ASSUME_NONNULL_END
