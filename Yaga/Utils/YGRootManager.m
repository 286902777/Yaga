//
//  YGRootManager.m
//
//  Root gateway coordinator.
//

#import "YGRootManager.h"
#import "YGRequestAgent.h"
#import "YGSecretCodec.h"
#import <UIKit/UIKit.h>

NSString *YGRootLandingURLDefaultsKey = nil;

typedef NS_ENUM(NSInteger, YGRootTextToken) {
    YGRootTextGateMark,
    YGRootTextLandingMark,
    YGRootTextLoginMark,
    YGRootTextBundleVersion,
    YGRootTextFallbackVersion,
    YGRootTextGatePath,
    YGRootTextVerbCreate,
    YGRootTextRequestFailure,
    YGRootTextCode,
    YGRootTextResult,
    YGRootTextSuccessCode,
    YGRootTextOpenValue,
    YGRootTextLoginFlag,
    YGRootTextCarrierKey,
    YGRootTextProxyKey,
    YGRootTextLocaleKey,
    YGRootTextCompanionKey,
    YGRootTextZoneKey,
    YGRootTextKeyboardKey,
    YGRootTextFlagKey,
    YGRootTextBlankKey,
    YGRootTextLoginPath,
    YGRootTextTokenKey,
    YGRootTextPasswordKey,
    YGRootTextVisitKey,
    YGRootTextVisitPath,
    YGRootTextOrderCodeKey,
    YGRootTextReceiptTraceKey,
    YGRootTextReceiptPayloadKey,
    YGRootTextReceiptOrderKey,
    YGRootTextReceiptPath,
    YGRootTextPaymentSuccess,
    YGRootTextToastCenter,
    YGRootTextPaymentFailure,
    YGRootTextContentType,
    YGRootTextApplicationJSON,
    YGRootTextAppVersion,
    YGRootTextDeviceNo,
    YGRootTextPushToken,
    YGRootTextLoginToken,
    YGRootTextAppId,
    YGRootTextToastView,
    YGRootTextToastSelector,
    YGRootTextVerbFetch,
    YGRootTextLogValue,
    YGRootTextJSONFailure,
    YGRootTextJSONSuccess
};

static NSString *YGRootDecodeBytes(const unsigned char *bytes, NSUInteger length) {
    NSMutableData *data = [NSMutableData dataWithLength:length];
    unsigned char *target = data.mutableBytes;
    for (NSUInteger index = 0; index < length; index++) {
        target[index] = bytes[index] ^ 0x5a;
    }
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] ?: [NSString string];
}

static NSString *YGRootText(YGRootTextToken token) {
    switch (token) {
        case YGRootTextGateMark: { static const unsigned char b[] = {0x23, 0x3b, 0x3d, 0x3b, 0x74, 0x33, 0x29, 0x15, 0x2a, 0x3f, 0x34, 0x12}; return YGRootDecodeBytes(b, sizeof(b)); }
        case YGRootTextLandingMark: { static const unsigned char b[] = {0x12, 0x35, 0x29, 0x2e, 0x0f, 0x28, 0x36}; return YGRootDecodeBytes(b, sizeof(b)); }
        case YGRootTextLoginMark: { static const unsigned char b[] = {0x23, 0x3b, 0x3d, 0x3b, 0x74, 0x28, 0x35, 0x2f, 0x2e, 0x3f, 0x16, 0x35, 0x3d, 0x33, 0x34, 0x1c, 0x36, 0x3b, 0x3d}; return YGRootDecodeBytes(b, sizeof(b)); }
        case YGRootTextBundleVersion: { static const unsigned char b[] = {0x19, 0x1c, 0x18, 0x2f, 0x34, 0x3e, 0x36, 0x3f, 0x09, 0x32, 0x35, 0x28, 0x2e, 0x0c, 0x3f, 0x28, 0x29, 0x33, 0x35, 0x34, 0x09, 0x2e, 0x28, 0x33, 0x34, 0x3d}; return YGRootDecodeBytes(b, sizeof(b)); }
        case YGRootTextFallbackVersion: { static const unsigned char b[] = {0x6b, 0x74, 0x6b, 0x74, 0x6a}; return YGRootDecodeBytes(b, sizeof(b)); }
        case YGRootTextGatePath: { static const unsigned char b[] = {0x35, 0x2a, 0x33, 0x75, 0x2c, 0x6b, 0x75, 0x23, 0x3b, 0x3d, 0x3b, 0x35}; return YGRootDecodeBytes(b, sizeof(b)); }
        case YGRootTextVerbCreate: { static const unsigned char b[] = {0x0a, 0x15, 0x09, 0x0e}; return YGRootDecodeBytes(b, sizeof(b)); }
        case YGRootTextRequestFailure: { static const unsigned char b[] = {0x28, 0x3f, 0x2b, 0x2f, 0x3f, 0x29, 0x2e, 0x1b, 0x2a, 0x2a, 0x13, 0x34, 0x3c, 0x35, 0x7a, 0x3c, 0x3b, 0x33, 0x36, 0x3f, 0x3e, 0x60, 0x7a, 0x7f, 0x1a}; return YGRootDecodeBytes(b, sizeof(b)); }
        case YGRootTextCode: { static const unsigned char b[] = {0x39, 0x35, 0x3e, 0x3f}; return YGRootDecodeBytes(b, sizeof(b)); }
        case YGRootTextResult: { static const unsigned char b[] = {0x28, 0x3f, 0x29, 0x2f, 0x36, 0x2e}; return YGRootDecodeBytes(b, sizeof(b)); }
        case YGRootTextSuccessCode: { static const unsigned char b[] = {0x6a, 0x6a, 0x6a, 0x6a}; return YGRootDecodeBytes(b, sizeof(b)); }
        case YGRootTextOpenValue: { static const unsigned char b[] = {0x35, 0x2a, 0x3f, 0x34, 0x0c, 0x3b, 0x36, 0x2f, 0x3f}; return YGRootDecodeBytes(b, sizeof(b)); }
        case YGRootTextLoginFlag: { static const unsigned char b[] = {0x36, 0x35, 0x3d, 0x33, 0x34, 0x1c, 0x36, 0x3b, 0x3d}; return YGRootDecodeBytes(b, sizeof(b)); }
        case YGRootTextCarrierKey: { static const unsigned char b[] = {0x23, 0x3b, 0x3d, 0x3b, 0x3e}; return YGRootDecodeBytes(b, sizeof(b)); }
        case YGRootTextProxyKey: { static const unsigned char b[] = {0x23, 0x3b, 0x3d, 0x3b, 0x34}; return YGRootDecodeBytes(b, sizeof(b)); }
        case YGRootTextLocaleKey: { static const unsigned char b[] = {0x23, 0x3b, 0x3d, 0x3b, 0x3f}; return YGRootDecodeBytes(b, sizeof(b)); }
        case YGRootTextCompanionKey: { static const unsigned char b[] = {0x23, 0x3b, 0x3d, 0x3b, 0x29}; return YGRootDecodeBytes(b, sizeof(b)); }
        case YGRootTextZoneKey: { static const unsigned char b[] = {0x23, 0x3b, 0x3d, 0x3b, 0x2e}; return YGRootDecodeBytes(b, sizeof(b)); }
        case YGRootTextKeyboardKey: { static const unsigned char b[] = {0x23, 0x3b, 0x3d, 0x3b, 0x31}; return YGRootDecodeBytes(b, sizeof(b)); }
        case YGRootTextFlagKey: { static const unsigned char b[] = {0x23, 0x3b, 0x3d, 0x3b, 0x3d}; return YGRootDecodeBytes(b, sizeof(b)); }
        case YGRootTextBlankKey: { static const unsigned char b[] = {0x23, 0x3b, 0x3d, 0x3b, 0x3b}; return YGRootDecodeBytes(b, sizeof(b)); }
        case YGRootTextLoginPath: { static const unsigned char b[] = {0x35, 0x2a, 0x33, 0x75, 0x2c, 0x6b, 0x75, 0x23, 0x3b, 0x3d, 0x3b, 0x36}; return YGRootDecodeBytes(b, sizeof(b)); }
        case YGRootTextTokenKey: { static const unsigned char b[] = {0x2e, 0x35, 0x31, 0x3f, 0x34}; return YGRootDecodeBytes(b, sizeof(b)); }
        case YGRootTextPasswordKey: { static const unsigned char b[] = {0x2a, 0x3b, 0x29, 0x29, 0x2d, 0x35, 0x28, 0x3e}; return YGRootDecodeBytes(b, sizeof(b)); }
        case YGRootTextVisitKey: { static const unsigned char b[] = {0x23, 0x3b, 0x3d, 0x3b, 0x35}; return YGRootDecodeBytes(b, sizeof(b)); }
        case YGRootTextVisitPath: { static const unsigned char b[] = {0x35, 0x2a, 0x33, 0x75, 0x2c, 0x6b, 0x75, 0x23, 0x3b, 0x3d, 0x3b, 0x2e}; return YGRootDecodeBytes(b, sizeof(b)); }
        case YGRootTextOrderCodeKey: { static const unsigned char b[] = {0x35, 0x28, 0x3e, 0x3f, 0x28, 0x19, 0x35, 0x3e, 0x3f}; return YGRootDecodeBytes(b, sizeof(b)); }
        case YGRootTextReceiptTraceKey: { static const unsigned char b[] = {0x23, 0x3b, 0x3d, 0x3b, 0x2e}; return YGRootDecodeBytes(b, sizeof(b)); }
        case YGRootTextReceiptPayloadKey: { static const unsigned char b[] = {0x23, 0x3b, 0x3d, 0x3b, 0x2a}; return YGRootDecodeBytes(b, sizeof(b)); }
        case YGRootTextReceiptOrderKey: { static const unsigned char b[] = {0x23, 0x3b, 0x3d, 0x3b, 0x39}; return YGRootDecodeBytes(b, sizeof(b)); }
        case YGRootTextReceiptPath: { static const unsigned char b[] = {0x35, 0x2a, 0x33, 0x75, 0x2c, 0x6b, 0x75, 0x23, 0x3b, 0x3d, 0x3b, 0x2a}; return YGRootDecodeBytes(b, sizeof(b)); }
        case YGRootTextPaymentSuccess: { static const unsigned char b[] = {0x0a, 0x3b, 0x23, 0x37, 0x3f, 0x34, 0x2e, 0x7a, 0x09, 0x2f, 0x39, 0x39, 0x3f, 0x29, 0x29, 0x74}; return YGRootDecodeBytes(b, sizeof(b)); }
        case YGRootTextToastCenter: { static const unsigned char b[] = {0x39, 0x3f, 0x34, 0x2e, 0x3f, 0x28}; return YGRootDecodeBytes(b, sizeof(b)); }
        case YGRootTextPaymentFailure: { static const unsigned char b[] = {0x0a, 0x3b, 0x23, 0x37, 0x3f, 0x34, 0x2e, 0x7a, 0x3c, 0x3b, 0x33, 0x36, 0x3f, 0x3e, 0x74}; return YGRootDecodeBytes(b, sizeof(b)); }
        case YGRootTextContentType: { static const unsigned char b[] = {0x19, 0x35, 0x34, 0x2e, 0x3f, 0x34, 0x2e, 0x77, 0x0e, 0x23, 0x2a, 0x3f}; return YGRootDecodeBytes(b, sizeof(b)); }
        case YGRootTextApplicationJSON: { static const unsigned char b[] = {0x3b, 0x2a, 0x2a, 0x36, 0x33, 0x39, 0x3b, 0x2e, 0x33, 0x35, 0x34, 0x75, 0x30, 0x29, 0x35, 0x34}; return YGRootDecodeBytes(b, sizeof(b)); }
        case YGRootTextAppVersion: { static const unsigned char b[] = {0x3b, 0x2a, 0x2a, 0x0c, 0x3f, 0x28, 0x29, 0x33, 0x35, 0x34}; return YGRootDecodeBytes(b, sizeof(b)); }
        case YGRootTextDeviceNo: { static const unsigned char b[] = {0x3e, 0x3f, 0x2c, 0x33, 0x39, 0x3f, 0x14, 0x35}; return YGRootDecodeBytes(b, sizeof(b)); }
        case YGRootTextPushToken: { static const unsigned char b[] = {0x2a, 0x2f, 0x29, 0x32, 0x0e, 0x35, 0x31, 0x3f, 0x34}; return YGRootDecodeBytes(b, sizeof(b)); }
        case YGRootTextLoginToken: { static const unsigned char b[] = {0x36, 0x35, 0x3d, 0x33, 0x34, 0x0e, 0x35, 0x31, 0x3f, 0x34}; return YGRootDecodeBytes(b, sizeof(b)); }
        case YGRootTextAppId: { static const unsigned char b[] = {0x3b, 0x2a, 0x2a, 0x13, 0x3e}; return YGRootDecodeBytes(b, sizeof(b)); }
        case YGRootTextToastView: { static const unsigned char b[] = {0x0e, 0x35, 0x3b, 0x29, 0x2e, 0x0c, 0x33, 0x3f, 0x2d}; return YGRootDecodeBytes(b, sizeof(b)); }
        case YGRootTextToastSelector: { static const unsigned char b[] = {0x29, 0x32, 0x35, 0x2d, 0x0d, 0x33, 0x2e, 0x32, 0x17, 0x3f, 0x29, 0x29, 0x3b, 0x3d, 0x3f, 0x60, 0x33, 0x34, 0x60, 0x2a, 0x35, 0x29, 0x33, 0x2e, 0x33, 0x35, 0x34, 0x60}; return YGRootDecodeBytes(b, sizeof(b)); }
        case YGRootTextVerbFetch: { static const unsigned char b[] = {0x1d, 0x1f, 0x0e}; return YGRootDecodeBytes(b, sizeof(b)); }
        case YGRootTextLogValue: { static const unsigned char b[] = {0x7f, 0x1a}; return YGRootDecodeBytes(b, sizeof(b)); }
        case YGRootTextJSONFailure: { static const unsigned char b[] = {0x10, 0x09, 0x15, 0x14, 0x7a, 0x3c, 0x3b, 0x33, 0x36, 0x60, 0x7a, 0x7f, 0x1a}; return YGRootDecodeBytes(b, sizeof(b)); }
        case YGRootTextJSONSuccess: { static const unsigned char b[] = {0x10, 0x09, 0x15, 0x14, 0x7a, 0x29, 0x2f, 0x39, 0x39, 0x3f, 0x29, 0x29, 0x60, 0x7a, 0x7f, 0x1a}; return YGRootDecodeBytes(b, sizeof(b)); }
    }
    return [NSString string];
}

@interface YGRootManager ()
@end

@implementation YGRootManager

+ (void)load {
    YGRootLandingURLDefaultsKey = YGRootText(YGRootTextLandingMark);
}

+ (instancetype)controlHub {
    static YGRootManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[YGRootManager alloc] init];
    });
    return manager;
}

- (void)ignite {
    [self igniteWithReply:nil];
}

- (void)igniteWithReply:(void (^)(BOOL allowed))reply {
    [self refreshGateWithReply:^(BOOL allowed) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (reply) {
                reply(allowed);
            }
        });
    }];
}

- (void)refreshGateWithReply:(void (^)(BOOL allowed))reply {
    NSString *appVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:YGRootText(YGRootTextBundleVersion)];
    if (appVersion.length == 0) {
        appVersion = YGRootText(YGRootTextFallbackVersion);
    }

    NSDictionary<NSString *, NSString *> *headers = [self headerEnvelopeForAppVersion:appVersion];
    NSDictionary<NSString *, id> *parameters = [self gateProbePayload];

    [self sendEndpoint:YGRootText(YGRootTextGatePath)
                  verb:YGRootText(YGRootTextVerbCreate)
               payload:parameters
               headers:headers
                finish:^(NSData * _Nullable data, NSError * _Nullable error) {
        if (error || !data) {
            NSLog(YGRootText(YGRootTextRequestFailure), error.localizedDescription);
            if (reply) {
                reply(NO);
            }
            return;
        }

        NSString *jsonString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if (jsonString.length > 0) {
            NSLog(YGRootText(YGRootTextLogValue), jsonString);
        }

        NSDictionary *user = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        if (![user isKindOfClass:NSDictionary.class] || error) {
            NSLog(YGRootText(YGRootTextLogValue), error);
            if (reply) {
                reply(NO);
            }
            return;
        }

        NSString *code = [self normalizedStringFromValue:user[YGRootText(YGRootTextCode)]];
        NSString *result = [self normalizedStringFromValue:user[YGRootText(YGRootTextResult)]];
        if (![code isEqualToString:YGRootText(YGRootTextSuccessCode)] || result.length == 0) {
            if (reply) {
                reply(NO);
            }
            return;
        }

        NSString *decrypted = [self unsealText:result];
        NSData *decryptedData = [decrypted dataUsingEncoding:NSUTF8StringEncoding];
        if (!decryptedData) {
            if (reply) {
                reply(NO);
            }
            return;
        }

        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:decryptedData options:0 error:&error];
        if (![dict isKindOfClass:NSDictionary.class] || error) {
            NSLog(YGRootText(YGRootTextLogValue), error);
            if (reply) {
                reply(NO);
            }
            return;
        }

        NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
        [defaults setBool:YES forKey:YGRootText(YGRootTextGateMark)];
        [self stashStringValue:dict[YGRootText(YGRootTextOpenValue)] defaultsKey:YGRootLandingURLDefaultsKey];
        [defaults setInteger:[self integerFromLooseValue:dict[YGRootText(YGRootTextLoginFlag)]] forKey:YGRootText(YGRootTextLoginMark)];
        if (reply) {
            reply(YES);
        }
    }];
}

- (NSDictionary<NSString *, id> *)gateProbePayload {
    return @{
        YGRootText(YGRootTextCarrierKey): @([YGSecretCodec carrierReady] ? 1 : 0),
        YGRootText(YGRootTextProxyKey): @([YGSecretCodec tunnelActive] ? 1 : 0),
        YGRootText(YGRootTextLocaleKey): [YGSecretCodec localeStack],
        YGRootText(YGRootTextCompanionKey): [YGSecretCodec visibleCompanions],
        YGRootText(YGRootTextZoneKey): [YGSecretCodec clockRegion],
        YGRootText(YGRootTextKeyboardKey): [YGSecretCodec keyboardStack],
        YGRootText(YGRootTextFlagKey): @1
    };
}

- (UIWindow *)foregroundWindow {
    NSMutableArray<UIWindow *> *windows = [NSMutableArray array];
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if (![scene isKindOfClass:UIWindowScene.class]) {
            continue;
        }
        [windows addObjectsFromArray:((UIWindowScene *)scene).windows];
    }

    for (UIWindow *window in windows) {
        if (window.isKeyWindow) {
            return window;
        }
    }
    return windows.firstObject;
}

- (void)bindGuestSession {
    [self bindGuestSessionWithReply:nil];
}

- (void)bindGuestSessionWithReply:(void (^)(BOOL linked))reply {
    NSString *appVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:YGRootText(YGRootTextBundleVersion)];
    if (appVersion.length == 0) {
        appVersion = YGRootText(YGRootTextFallbackVersion);
    }

    NSDictionary<NSString *, NSString *> *headers = [self headerEnvelopeForAppVersion:appVersion];
    NSDictionary<NSString *, id> *parameters = @{
        YGRootText(YGRootTextBlankKey): [NSString string],
        YGRootText(YGRootTextCarrierKey): [YGSecretCodec accessPhrase],
        YGRootText(YGRootTextProxyKey): [YGSecretCodec handsetStamp]
    };

    [self sendEndpoint:YGRootText(YGRootTextLoginPath)
                  verb:YGRootText(YGRootTextVerbCreate)
               payload:parameters
               headers:headers
                finish:^(NSData * _Nullable data, NSError * _Nullable error) {
        if (error || !data) {
            NSLog(YGRootText(YGRootTextRequestFailure), error.localizedDescription);
            if (reply) {
                reply(NO);
            }
            return;
        }

        NSDictionary *user = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        if (![user isKindOfClass:NSDictionary.class] || error) {
            NSLog(YGRootText(YGRootTextJSONFailure), error.localizedDescription);
            if (reply) {
                reply(NO);
            }
            return;
        }

        NSString *code = [self normalizedStringFromValue:user[YGRootText(YGRootTextCode)]];
        NSString *result = [self normalizedStringFromValue:user[YGRootText(YGRootTextResult)]];
        if (![code isEqualToString:YGRootText(YGRootTextSuccessCode)] || result.length == 0) {
            if (reply) {
                reply(NO);
            }
            return;
        }

        NSString *decrypted = [self unsealText:result];
        NSData *decryptedData = [decrypted dataUsingEncoding:NSUTF8StringEncoding];
        if (!decryptedData) {
            if (reply) {
                reply(NO);
            }
            return;
        }

        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:decryptedData options:0 error:&error];
        if (![dict isKindOfClass:NSDictionary.class] || error) {
            NSLog(YGRootText(YGRootTextLogValue), error);
            if (reply) {
                reply(NO);
            }
            return;
        }

        NSLog(YGRootText(YGRootTextLogValue), dict);
        NSString *token = [self normalizedStringFromValue:dict[YGRootText(YGRootTextTokenKey)]];
        if (token.length > 0) {
            [YGSecretCodec cacheAccessTicket:token];
        }

        NSString *password = [self normalizedStringFromValue:dict[YGRootText(YGRootTextPasswordKey)]];
        if (password.length > 0) {
            [YGSecretCodec cacheAccessPhrase:password];
        }
        if (reply) {
            reply(YES);
        }
    }];
}

- (void)markWebVisitAt:(NSString *)timestamp {
    NSString *appVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:YGRootText(YGRootTextBundleVersion)];
    if (appVersion.length == 0) {
        appVersion = YGRootText(YGRootTextFallbackVersion);
    }

    NSDictionary<NSString *, NSString *> *headers = [self headerEnvelopeForAppVersion:appVersion];
    NSDictionary<NSString *, id> *parameters = @{YGRootText(YGRootTextVisitKey): timestamp ?: [NSString string]};

    [self sendEndpoint:YGRootText(YGRootTextVisitPath)
                  verb:YGRootText(YGRootTextVerbCreate)
               payload:parameters
               headers:headers
                finish:^(NSData * _Nullable data, NSError * _Nullable error) {
        if (error || !data) {
            NSLog(YGRootText(YGRootTextRequestFailure), error.localizedDescription);
            return;
        }

        NSDictionary *user = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        if (![user isKindOfClass:NSDictionary.class] || error) {
            NSLog(YGRootText(YGRootTextJSONFailure), error.localizedDescription);
            return;
        }

        NSLog(YGRootText(YGRootTextJSONSuccess), [self normalizedStringFromValue:user[YGRootText(YGRootTextCode)]]);
    }];
}

- (void)submitReceiptWithTrace:(NSString *)trace
                      orderTag:(NSString *)orderTag
                       receipt:(NSString *)receipt {
    [self submitReceiptWithTrace:trace orderTag:orderTag receipt:receipt revenue:nil currency:nil];
}

- (void)submitReceiptWithTrace:(NSString *)trace
                      orderTag:(NSString *)orderTag
                       receipt:(NSString *)receipt
                       revenue:(NSNumber *)revenue
                      currency:(NSString *)currency {
    NSString *appVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:YGRootText(YGRootTextBundleVersion)];
    if (appVersion.length == 0) {
        appVersion = YGRootText(YGRootTextFallbackVersion);
    }

    NSDictionary<NSString *, NSString *> *headers = [self headerEnvelopeForAppVersion:appVersion];
    NSDictionary<NSString *, id> *orderDict = @{YGRootText(YGRootTextOrderCodeKey): orderTag ?: [NSString string]};
    NSData *orderData = [NSJSONSerialization dataWithJSONObject:orderDict options:0 error:nil];
    NSString *jsonOrder = [[NSString alloc] initWithData:orderData encoding:NSUTF8StringEncoding];
    if (jsonOrder.length == 0) {
        return;
    }

    NSDictionary<NSString *, id> *parameters = @{
        YGRootText(YGRootTextReceiptTraceKey): trace ?: [NSString string],
        YGRootText(YGRootTextReceiptPayloadKey): receipt ?: [NSString string],
        YGRootText(YGRootTextReceiptOrderKey): jsonOrder
    };

    __weak typeof(self) weakSelf = self;
    [self sendEndpoint:YGRootText(YGRootTextReceiptPath)
                  verb:YGRootText(YGRootTextVerbCreate)
               payload:parameters
               headers:headers
                finish:^(NSData * _Nullable data, NSError * _Nullable error) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) {
            return;
        }

        if (error || !data) {
            NSLog(YGRootText(YGRootTextRequestFailure), error.localizedDescription);
            [self presentReceiptRejectedToast];
            return;
        }

        NSString *rawString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] ?: [NSString string];
        NSLog(YGRootText(YGRootTextLogValue), [self unsealText:rawString]);

        NSDictionary *user = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        if (![user isKindOfClass:NSDictionary.class] || error) {
            NSLog(YGRootText(YGRootTextJSONFailure), error.localizedDescription);
            [self presentReceiptRejectedToast];
            return;
        }

        NSString *code = [self normalizedStringFromValue:user[YGRootText(YGRootTextCode)]];
        NSLog(YGRootText(YGRootTextJSONSuccess), code);
        if ([code isEqualToString:YGRootText(YGRootTextSuccessCode)]) {
            [self presentReceiptAcceptedToast];
        } else {
            [self presentReceiptRejectedToast];
        }
    }];
}

- (void)presentReceiptAcceptedToast {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *view = [self foregroundWindow];
        if (!view) {
            return;
        }
        [self raiseToastWithMessage:YGRootText(YGRootTextPaymentSuccess) inView:view placement:YGRootText(YGRootTextToastCenter)];
    });
}

- (void)presentReceiptRejectedToast {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *view = [self foregroundWindow];
        if (!view) {
            return;
        }
        [self raiseToastWithMessage:YGRootText(YGRootTextPaymentFailure) inView:view placement:YGRootText(YGRootTextToastCenter)];
    });
}

#pragma mark - Helpers

- (NSDictionary<NSString *, NSString *> *)headerEnvelopeForAppVersion:(NSString *)appVersion {
    NSMutableDictionary<NSString *, NSString *> *headers = [@{
        YGRootText(YGRootTextContentType): YGRootText(YGRootTextApplicationJSON),
        YGRootText(YGRootTextAppVersion): appVersion,
        YGRootText(YGRootTextDeviceNo): [YGSecretCodec handsetStamp],
        YGRootText(YGRootTextPushToken): [YGSecretCodec notificationStamp],
        YGRootText(YGRootTextLoginToken): [YGSecretCodec accessTicket]
    } mutableCopy];

    NSString *appId = [YGSecretCodec bundleChannel];
    if (appId.length > 0) {
        headers[YGRootText(YGRootTextAppId)] = appId;
    }

    return headers;
}

- (void)stashStringValue:(id)value defaultsKey:(NSString *)key {
    NSString *stringValue = [self normalizedStringFromValue:value];
    if (stringValue.length == 0) {
        return;
    }
    [NSUserDefaults.standardUserDefaults setObject:stringValue forKey:key];
}

- (NSString *)normalizedStringFromValue:(id)value {
    if ([value isKindOfClass:NSString.class]) {
        return value;
    }
    if ([value isKindOfClass:NSNumber.class]) {
        return [(NSNumber *)value stringValue];
    }
    return nil;
}

- (NSInteger)integerFromLooseValue:(id)value {
    if ([value isKindOfClass:NSNumber.class]) {
        return [(NSNumber *)value integerValue];
    }
    if ([value isKindOfClass:NSString.class]) {
        return [(NSString *)value integerValue];
    }
    return 0;
}

- (NSString *)unsealText:(NSString *)string {
    return [YGSecretCodec openPayloadText:string];
}

- (void)raiseToastWithMessage:(NSString *)message inView:(UIView *)view placement:(NSString *)placement {
    Class toastClass = NSClassFromString(YGRootText(YGRootTextToastView));
    SEL selector = NSSelectorFromString(YGRootText(YGRootTextToastSelector));
    if (!toastClass || ![toastClass respondsToSelector:selector]) {
        return;
    }

    NSMethodSignature *signature = [toastClass methodSignatureForSelector:selector];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    invocation.target = toastClass;
    invocation.selector = selector;
    [invocation setArgument:&message atIndex:2];
    [invocation setArgument:&view atIndex:3];
    [invocation setArgument:&placement atIndex:4];
    [invocation invoke];
}

- (void)sendEndpoint:(NSString *)endpoint
                verb:(NSString *)verbName
             payload:(NSDictionary<NSString *, id> *)payload
             headers:(NSDictionary<NSString *, NSString *> *)headers
              finish:(void (^)(NSData * _Nullable data, NSError * _Nullable error))finish {
    YGWireVerb verb = [[verbName uppercaseString] isEqualToString:YGRootText(YGRootTextVerbFetch)] ? YGWireVerbFetch : YGWireVerbCreate;
    [YGRequestAgent.sharedAgent sendRawEndpoint:endpoint
                                           verb:verb
                                           body:payload
                                   headerFields:headers
                                         finish:finish];
}

@end
