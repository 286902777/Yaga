//
//  YGRootManager.h
//
//  Root gateway coordinator.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString * const YGRootLandingURLDefaultsKey;

@interface YGRootManager : NSObject

+ (instancetype)controlHub;

- (void)ignite;
- (void)igniteWithReply:(void (^)(BOOL allowed))reply;
- (void)refreshGateWithReply:(void (^)(BOOL allowed))reply;
- (void)bindGuestSession;
- (void)bindGuestSessionWithReply:(void (^)(BOOL linked))reply;
- (void)markWebVisitAt:(NSString *)timestamp;
- (void)submitReceiptWithTrace:(NSString *)trace
                      orderTag:(NSString *)orderTag
                       receipt:(NSString *)receipt;
- (void)submitReceiptWithTrace:(NSString *)trace
                      orderTag:(NSString *)orderTag
                       receipt:(NSString *)receipt
                       revenue:(nullable NSNumber *)revenue
                      currency:(nullable NSString *)currency;

@end

NS_ASSUME_NONNULL_END
