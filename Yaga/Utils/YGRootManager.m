//
//  YGRootManager.m
//
//  Root gateway coordinator.
//

#import "YGRootManager.h"
#import "YGRequestAgent.h"
#import "YGSecretCodec.h"
#import <UIKit/UIKit.h>

static NSString * const YGRootGateEnabledDefaultsKey = @"yaga.isOpenH";
NSString * const YGRootLandingURLDefaultsKey = @"HostUrl";
static NSString * const YGRootLoginModeDefaultsKey = @"yaga.routeLoginFlag";

@interface YGRootManager ()
@end

@implementation YGRootManager

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
    NSString *appVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    if (appVersion.length == 0) {
        appVersion = @"1.1.0";
    }

    NSDictionary<NSString *, NSString *> *headers = [self headerEnvelopeForAppVersion:appVersion];
    NSDictionary<NSString *, id> *parameters = [self gateProbePayload];

    [self sendEndpoint:@"opi/v1/yagao"
                  verb:@"POST"
               payload:parameters
               headers:headers
                finish:^(NSData * _Nullable data, NSError * _Nullable error) {
        if (error || !data) {
            NSLog(@"requestAppInfo failed: %@", error.localizedDescription);
            if (reply) {
                reply(NO);
            }
            return;
        }

        NSString *jsonString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if (jsonString.length > 0) {
            NSLog(@"%@", jsonString);
        }

        NSDictionary *user = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        if (![user isKindOfClass:NSDictionary.class] || error) {
            NSLog(@"%@", error);
            if (reply) {
                reply(NO);
            }
            return;
        }

        NSString *code = [self normalizedStringFromValue:user[@"code"]];
        NSString *result = [self normalizedStringFromValue:user[@"result"]];
        if (![code isEqualToString:@"0000"] || result.length == 0) {
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
            NSLog(@"%@", error);
            if (reply) {
                reply(NO);
            }
            return;
        }

        NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
        [defaults setBool:YES forKey:YGRootGateEnabledDefaultsKey];
        [self stashStringValue:dict[@"openValue"] defaultsKey:YGRootLandingURLDefaultsKey];
        [defaults setInteger:[self integerFromLooseValue:dict[@"loginFlag"]] forKey:YGRootLoginModeDefaultsKey];
        if (reply) {
            reply(YES);
        }
    }];
}

- (NSDictionary<NSString *, id> *)gateProbePayload {
    return @{
        @"yagad": @([YGSecretCodec carrierReady] ? 1 : 0),
        @"yagan": @([YGSecretCodec tunnelActive] ? 1 : 0),
        @"yagae": [YGSecretCodec localeStack],
        @"yagas": [YGSecretCodec visibleCompanions],
        @"yagat": [YGSecretCodec clockRegion],
        @"yagak": [YGSecretCodec keyboardStack],
        @"yagag": @1
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
    NSString *appVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    if (appVersion.length == 0) {
        appVersion = @"1.1.0";
    }

    NSDictionary<NSString *, NSString *> *headers = [self headerEnvelopeForAppVersion:appVersion];
    NSDictionary<NSString *, id> *parameters = @{
        @"yagaa": @"",
        @"yagad": [YGSecretCodec accessPhrase],
        @"yagan": [YGSecretCodec handsetStamp]
    };

    [self sendEndpoint:@"opi/v1/yagal"
                  verb:@"POST"
               payload:parameters
               headers:headers
                finish:^(NSData * _Nullable data, NSError * _Nullable error) {
        if (error || !data) {
            NSLog(@"requestAppInfo failed: %@", error.localizedDescription);
            if (reply) {
                reply(NO);
            }
            return;
        }

        NSDictionary *user = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        if (![user isKindOfClass:NSDictionary.class] || error) {
            NSLog(@"JSON fail: %@", error.localizedDescription);
            if (reply) {
                reply(NO);
            }
            return;
        }

        NSString *code = [self normalizedStringFromValue:user[@"code"]];
        NSString *result = [self normalizedStringFromValue:user[@"result"]];
        if (![code isEqualToString:@"0000"] || result.length == 0) {
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
            NSLog(@"%@", error);
            if (reply) {
                reply(NO);
            }
            return;
        }

        NSLog(@"%@", dict);
        NSString *token = [self normalizedStringFromValue:dict[@"token"]];
        if (token.length > 0) {
            [YGSecretCodec cacheAccessTicket:token];
        }

        NSString *password = [self normalizedStringFromValue:dict[@"password"]];
        if (password.length > 0) {
            [YGSecretCodec cacheAccessPhrase:password];
        }
        if (reply) {
            reply(YES);
        }
    }];
}

- (void)markWebVisitAt:(NSString *)timestamp {
    NSString *appVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    if (appVersion.length == 0) {
        appVersion = @"1.1.0";
    }

    NSDictionary<NSString *, NSString *> *headers = [self headerEnvelopeForAppVersion:appVersion];
    NSDictionary<NSString *, id> *parameters = @{@"yagao": timestamp ?: @""};

    [self sendEndpoint:@"opi/v1/yagat"
                  verb:@"POST"
               payload:parameters
               headers:headers
                finish:^(NSData * _Nullable data, NSError * _Nullable error) {
        if (error || !data) {
            NSLog(@"requestAppInfo failed: %@", error.localizedDescription);
            return;
        }

        NSDictionary *user = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        if (![user isKindOfClass:NSDictionary.class] || error) {
            NSLog(@"JSON fail: %@", error.localizedDescription);
            return;
        }

        NSLog(@"JSON success: %@", [self normalizedStringFromValue:user[@"code"]]);
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
    NSString *appVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    if (appVersion.length == 0) {
        appVersion = @"1.1.0";
    }

    NSDictionary<NSString *, NSString *> *headers = [self headerEnvelopeForAppVersion:appVersion];
    NSDictionary<NSString *, id> *orderDict = @{@"orderCode": orderTag ?: @""};
    NSData *orderData = [NSJSONSerialization dataWithJSONObject:orderDict options:0 error:nil];
    NSString *jsonOrder = [[NSString alloc] initWithData:orderData encoding:NSUTF8StringEncoding];
    if (jsonOrder.length == 0) {
        return;
    }

    NSDictionary<NSString *, id> *parameters = @{
        @"yagat": trace ?: @"",
        @"yagap": receipt ?: @"",
        @"yagac": jsonOrder
    };

    __weak typeof(self) weakSelf = self;
    [self sendEndpoint:@"opi/v1/yagap"
                  verb:@"POST"
               payload:parameters
               headers:headers
                finish:^(NSData * _Nullable data, NSError * _Nullable error) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) {
            return;
        }

        if (error || !data) {
            NSLog(@"requestAppInfo failed: %@", error.localizedDescription);
            [self presentReceiptRejectedToast];
            return;
        }

        NSString *rawString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] ?: @"";
        NSLog(@"%@", [self unsealText:rawString]);

        NSDictionary *user = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        if (![user isKindOfClass:NSDictionary.class] || error) {
            NSLog(@"JSON fail: %@", error.localizedDescription);
            [self presentReceiptRejectedToast];
            return;
        }

        NSString *code = [self normalizedStringFromValue:user[@"code"]];
        NSLog(@"JSON success: %@", code);
        if ([code isEqualToString:@"0000"]) {
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
        [self raiseToastWithMessage:@"Payment Success." inView:view placement:@"center"];
    });
}

- (void)presentReceiptRejectedToast {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *view = [self foregroundWindow];
        if (!view) {
            return;
        }
        [self raiseToastWithMessage:@"Payment failed." inView:view placement:@"center"];
    });
}

#pragma mark - Helpers

- (NSDictionary<NSString *, NSString *> *)headerEnvelopeForAppVersion:(NSString *)appVersion {
    NSMutableDictionary<NSString *, NSString *> *headers = [@{
        @"Content-Type": @"application/json",
        @"appVersion": appVersion,
        @"deviceNo": [YGSecretCodec handsetStamp],
        @"pushToken": [YGSecretCodec notificationStamp],
        @"loginToken": [YGSecretCodec accessTicket]
    } mutableCopy];

    NSString *appId = [YGSecretCodec bundleChannel];
    if (appId.length > 0) {
        headers[@"appId"] = appId;
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
    Class toastClass = NSClassFromString(@"ToastView");
    SEL selector = NSSelectorFromString(@"showWithMessage:in:position:");
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
    YGWireVerb verb = [[verbName uppercaseString] isEqualToString:@"GET"] ? YGWireVerbFetch : YGWireVerbCreate;
    [YGRequestAgent.sharedAgent sendRawEndpoint:endpoint
                                           verb:verb
                                           body:payload
                                   headerFields:headers
                                         finish:finish];
}

@end
