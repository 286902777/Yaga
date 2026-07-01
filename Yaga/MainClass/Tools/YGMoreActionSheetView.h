//
//  YGMoreActionSheetView.h
//  Yaga
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface YGMoreActionSheetView : UIView

+ (void)showInView:(UIView *)view
     reportHandler:(nullable void (^)(void))reportHandler
      blockHandler:(nullable void (^)(void))blockHandler;

@end

NS_ASSUME_NONNULL_END
