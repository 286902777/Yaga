//
//  YGIAPManager.h
//  Yaga
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^YGIAPPurchaseCompletion)(BOOL success, NSString * _Nullable message);

@interface YGIAPManager : NSObject

+ (instancetype)sharedManager;
- (void)purchaseProductWithIdentifier:(NSString *)productIdentifier completion:(YGIAPPurchaseCompletion)completion;

@end

NS_ASSUME_NONNULL_END
