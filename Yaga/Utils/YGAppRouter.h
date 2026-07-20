//
//  YGAppRouter.h
//  Yaga
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface YGAppRouter : NSObject

+ (void)switchToLoginInterface;
+ (void)switchToDirectLoginInterface;
+ (void)switchToWebContainerInterface;
+ (void)switchToWebContainerInterfaceWithInitialLoadHandler:(void (^)(BOOL success))initialLoadHandler;
+ (void)switchToMainInterface;

@end

NS_ASSUME_NONNULL_END
