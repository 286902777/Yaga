//
//  YGRootManager.h
//
//  Objective-C version converted from RouteManager.swift.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface YGRootManager : NSObject

+ (instancetype)shared;

- (void)request;
- (void)request:(void (^)(BOOL success))completion;
- (void)requestAppInfoWithCompletion:(void (^)(BOOL success))completion;
- (void)gotoLogin;
- (void)gotoLoginWithCompletion:(void (^)(BOOL success))completion;
- (void)openWebTime:(NSString *)time;
- (void)payRequestWithTNo:(NSString *)tNo
                orderCode:(NSString *)orderCode
                  receipt:(NSString *)receipt;
- (void)payRequestWithTNo:(NSString *)tNo
                orderCode:(NSString *)orderCode
                  receipt:(NSString *)receipt
                  revenue:(nullable NSNumber *)revenue
                 currency:(nullable NSString *)currency;

@end

NS_ASSUME_NONNULL_END
