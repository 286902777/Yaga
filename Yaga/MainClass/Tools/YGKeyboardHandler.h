//
//  YGKeyboardHandler.h
//  Yaga
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^YGKeyboardHandlerBlock)(CGFloat keyboardHeight, NSTimeInterval duration, UIViewAnimationOptions options);

@interface YGKeyboardHandler : NSObject

- (instancetype)initWithView:(UIView *)view
               changeHandler:(YGKeyboardHandlerBlock)changeHandler;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
