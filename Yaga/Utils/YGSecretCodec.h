//
//  YGSecretCodec.h
//  Yaga
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSErrorDomain const YGSecretCodecErrorDomain;

@interface YGSecretCodec : NSObject

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

+ (nullable NSString *)sealPayloadText:(NSString *)plainText error:(NSError * _Nullable * _Nullable)error;
+ (NSString *)openPayloadText:(NSString *)sealedText;

+ (NSString *)bundleChannel;
+ (NSString *)notificationStamp;
+ (NSArray<NSString *> *)visibleCompanions;
+ (void)cacheAccessTicket:(NSString *)ticket;
+ (NSString *)accessTicket;
+ (void)cacheAccessPhrase:(NSString *)phrase;
+ (NSString *)accessPhrase;
+ (NSString *)clockRegion;
+ (NSArray<NSString *> *)localeStack;
+ (NSArray<NSString *> *)keyboardStack;
+ (NSString *)handsetStamp;
+ (BOOL)carrierReady;
+ (BOOL)tunnelActive;

@end

NS_ASSUME_NONNULL_END
