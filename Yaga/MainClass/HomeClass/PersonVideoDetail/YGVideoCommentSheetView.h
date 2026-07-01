//
//  YGVideoCommentSheetView.h
//  Yaga
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface YGVideoCommentSheetView : UIView

+ (void)showInView:(UIView *)view submitHandler:(nullable void (^)(void))submitHandler;
+ (void)showInView:(UIView *)view commentCount:(NSInteger)commentCount submitHandler:(nullable void (^)(void))submitHandler;
+ (void)showInView:(UIView *)view
      commentCount:(NSInteger)commentCount
          comments:(nullable NSArray<NSDictionary *> *)comments
     submitHandler:(nullable void (^)(NSDictionary *comment))submitHandler;
+ (void)showInView:(UIView *)view
      commentCount:(NSInteger)commentCount
          comments:(nullable NSArray<NSDictionary *> *)comments
     submitHandler:(nullable void (^)(NSDictionary *comment))submitHandler
      blockHandler:(nullable void (^)(NSDictionary *comment))blockHandler;

@end

NS_ASSUME_NONNULL_END
