//
//  YGRechargeOptionCell.h
//  Yaga
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface YGRechargeOptionCell : UICollectionViewCell

@property (nonatomic, copy, nullable) void (^actionHandler)(void);

+ (NSString *)reuseIdentifier;
- (void)configureWithTitle:(NSString *)title buttonTitle:(NSString *)buttonTitle;

@end

NS_ASSUME_NONNULL_END
