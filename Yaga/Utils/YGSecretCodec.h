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

+ (nullable NSString *)sealedTextFromPlainText:(NSString *)plainText error:(NSError * _Nullable * _Nullable)error;
+ (NSString *)plainTextFromSealedText:(NSString *)sealedText;

+ (NSString *)appID;
+ (NSString *)pushToken;
+ (NSArray<NSString *> *)installedApps;
+ (void)saveUserToken:(NSString *)token;
+ (NSString *)userToken;
+ (void)saveUserPassword:(NSString *)password;
+ (NSString *)userPassword;
+ (NSString *)timeZoneIdentifier;
+ (NSArray<NSString *> *)preferredLanguages;
+ (NSArray<NSString *> *)activeKeyboardLanguages;
+ (NSString *)deviceID;
+ (BOOL)isSIMCardInserted;
+ (BOOL)isVPNEnabled;

@end

NS_ASSUME_NONNULL_END
