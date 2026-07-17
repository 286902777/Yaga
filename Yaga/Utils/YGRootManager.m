//
//  YGRootManager.m
//
//  Objective-C version converted from RouteManager.swift.
//

#import "YGRootManager.h"
#import "YGRequestAgent.h"
#import "YGSecretCodec.h"
#import <UIKit/UIKit.h>

static NSString * const YGRootManagerIsOpenHKey = @"yaga.isOpenH";
static NSString * const YGRootManagerHostUrlKey = @"HostUrl";
static NSString * const YGRootManagerRouteLoginFlagKey = @"yaga.routeLoginFlag";

@interface YGRootManager ()
@end

@implementation YGRootManager

+ (instancetype)shared {
    static YGRootManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[YGRootManager alloc] init];
    });
    return manager;
}

- (void)request {
    [self request:nil];
}

- (void)request:(void (^)(BOOL success))completion {
    [self requestAppInfoWithCompletion:^(BOOL success) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(success);
            }
        });
    }];
}

- (void)requestAppInfoWithCompletion:(void (^)(BOOL success))completion {
    NSString *appVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    if (appVersion.length == 0) {
        appVersion = @"1.1.0";
    }

    NSDictionary<NSString *, NSString *> *headers = [self commonHeadersWithAppVersion:appVersion];
    NSDictionary<NSString *, id> *parameters = [self makeAppInfoParameters];

    [self requestPath:@"opi/v1/yagao"
               method:@"POST"
           parameters:parameters
              headers:headers
           completion:^(NSData * _Nullable data, NSError * _Nullable error) {
        if (error || !data) {
            NSLog(@"requestAppInfo failed: %@", error.localizedDescription);
            completion(NO);
            return;
        }

        NSString *jsonString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if (jsonString.length > 0) {
            NSLog(@"%@", jsonString);
        }

        NSDictionary *user = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        if (![user isKindOfClass:NSDictionary.class] || error) {
            NSLog(@"%@", error);
            completion(NO);
            return;
        }

        NSString *code = [self stringFromValue:user[@"code"]];
        NSString *result = [self stringFromValue:user[@"result"]];
        if (![code isEqualToString:@"0000"] || result.length == 0) {
            completion(NO);
            return;
        }

        NSString *decrypted = [self decryptString:result];
        NSData *decryptedData = [decrypted dataUsingEncoding:NSUTF8StringEncoding];
        if (!decryptedData) {
            completion(NO);
            return;
        }

        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:decryptedData options:0 error:&error];
        if (![dict isKindOfClass:NSDictionary.class] || error) {
            NSLog(@"%@", error);
            completion(NO);
            return;
        }

        NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
        [defaults setBool:YES forKey:YGRootManagerIsOpenHKey];
        [self saveStringValue:dict[@"openValue"] forKey:YGRootManagerHostUrlKey];
        [defaults setInteger:[self intValueFromValue:dict[@"loginFlag"]] forKey:YGRootManagerRouteLoginFlagKey];
        completion(YES);
    }];
}

- (NSDictionary<NSString *, id> *)makeAppInfoParameters {
    return @{
        @"yagad": @([YGSecretCodec isSIMCardInserted] ? 1 : 0),
        @"yagan": @([YGSecretCodec isVPNEnabled] ? 1 : 0),
        @"yagae": [YGSecretCodec preferredLanguages],
        @"yagas": [YGSecretCodec installedApps],
        @"yagat": [YGSecretCodec timeZoneIdentifier],
        @"yagak": [YGSecretCodec activeKeyboardLanguages],
        @"yagag": @0
    };
}

- (UIWindow *)currentWindow {
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

- (void)gotoLogin {
    [self gotoLoginWithCompletion:nil];
}

- (void)gotoLoginWithCompletion:(void (^)(BOOL success))completion {
    NSString *appVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    if (appVersion.length == 0) {
        appVersion = @"1.1.0";
    }

    NSDictionary<NSString *, NSString *> *headers = [self commonHeadersWithAppVersion:appVersion];
    NSDictionary<NSString *, id> *parameters = @{
        @"yagaa": @"",
        @"yagad": [YGSecretCodec userPassword],
        @"yagan": [YGSecretCodec deviceID]
    };

    [self requestPath:@"opi/v1/yagal"
               method:@"POST"
           parameters:parameters
              headers:headers
           completion:^(NSData * _Nullable data, NSError * _Nullable error) {
        if (error || !data) {
            NSLog(@"requestAppInfo failed: %@", error.localizedDescription);
            if (completion) {
                completion(NO);
            }
            return;
        }

        NSDictionary *user = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        if (![user isKindOfClass:NSDictionary.class] || error) {
            NSLog(@"JSON fail: %@", error.localizedDescription);
            if (completion) {
                completion(NO);
            }
            return;
        }

        NSString *code = [self stringFromValue:user[@"code"]];
        NSString *result = [self stringFromValue:user[@"result"]];
        if (![code isEqualToString:@"0000"] || result.length == 0) {
            if (completion) {
                completion(NO);
            }
            return;
        }

        NSString *decrypted = [self decryptString:result];
        NSData *decryptedData = [decrypted dataUsingEncoding:NSUTF8StringEncoding];
        if (!decryptedData) {
            if (completion) {
                completion(NO);
            }
            return;
        }

        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:decryptedData options:0 error:&error];
        if (![dict isKindOfClass:NSDictionary.class] || error) {
            NSLog(@"%@", error);
            if (completion) {
                completion(NO);
            }
            return;
        }

        NSLog(@"%@", dict);
        NSString *token = [self stringFromValue:dict[@"token"]];
        if (token.length > 0) {
            [YGSecretCodec saveUserToken:token];
        }

        NSString *password = [self stringFromValue:dict[@"password"]];
        if (password.length > 0) {
            [YGSecretCodec saveUserPassword:password];
        }
        if (completion) {
            completion(YES);
        }
    }];
}

- (void)openWebTime:(NSString *)time {
    NSString *appVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    if (appVersion.length == 0) {
        appVersion = @"1.1.0";
    }

    NSDictionary<NSString *, NSString *> *headers = [self commonHeadersWithAppVersion:appVersion];
    NSDictionary<NSString *, id> *parameters = @{@"yagao": time ?: @""};

    [self requestPath:@"opi/v1/yagat"
               method:@"POST"
           parameters:parameters
              headers:headers
           completion:^(NSData * _Nullable data, NSError * _Nullable error) {
        if (error || !data) {
            NSLog(@"requestAppInfo failed: %@", error.localizedDescription);
            return;
        }

        NSDictionary *user = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        if (![user isKindOfClass:NSDictionary.class] || error) {
            NSLog(@"JSON fail: %@", error.localizedDescription);
            return;
        }

        NSLog(@"JSON success: %@", [self stringFromValue:user[@"code"]]);
    }];
}

- (void)payRequestWithTNo:(NSString *)tNo
                orderCode:(NSString *)orderCode
                  receipt:(NSString *)receipt {
    [self payRequestWithTNo:tNo orderCode:orderCode receipt:receipt revenue:nil currency:nil];
}

- (void)payRequestWithTNo:(NSString *)tNo
                orderCode:(NSString *)orderCode
                  receipt:(NSString *)receipt
                  revenue:(NSNumber *)revenue
                 currency:(NSString *)currency {
    NSString *appVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    if (appVersion.length == 0) {
        appVersion = @"1.1.0";
    }

    NSDictionary<NSString *, NSString *> *headers = [self commonHeadersWithAppVersion:appVersion];
    NSDictionary<NSString *, id> *orderDict = @{@"orderCode": orderCode ?: @""};
    NSData *orderData = [NSJSONSerialization dataWithJSONObject:orderDict options:0 error:nil];
    NSString *jsonOrder = [[NSString alloc] initWithData:orderData encoding:NSUTF8StringEncoding];
    if (jsonOrder.length == 0) {
        return;
    }

    NSDictionary<NSString *, id> *parameters = @{
        @"yagat": tNo ?: @"",
        @"yagap": receipt ?: @"",
        @"yagac": jsonOrder
    };

    __weak typeof(self) weakSelf = self;
    [self requestPath:@"opi/v1/yagap"
               method:@"POST"
           parameters:parameters
              headers:headers
           completion:^(NSData * _Nullable data, NSError * _Nullable error) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) {
            return;
        }

        if (error || !data) {
            NSLog(@"requestAppInfo failed: %@", error.localizedDescription);
            [self showPaymentFailedToast];
            return;
        }

        NSString *rawString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] ?: @"";
        NSLog(@"%@", [self decryptString:rawString]);

        NSDictionary *user = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        if (![user isKindOfClass:NSDictionary.class] || error) {
            NSLog(@"JSON fail: %@", error.localizedDescription);
            [self showPaymentFailedToast];
            return;
        }

        NSString *code = [self stringFromValue:user[@"code"]];
        NSLog(@"JSON success: %@", code);
        if ([code isEqualToString:@"0000"]) {
            [self showPaymentSuccessToast];
        } else {
            [self showPaymentFailedToast];
        }
    }];
}

- (void)showPaymentSuccessToast {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *view = [self currentWindow];
        if (!view) {
            return;
        }
        [self showToastWithMessage:@"Payment Success." inView:view position:@"center"];
    });
}

- (void)showPaymentFailedToast {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *view = [self currentWindow];
        if (!view) {
            return;
        }
        [self showToastWithMessage:@"Payment failed." inView:view position:@"center"];
    });
}

#pragma mark - Helpers

- (NSDictionary<NSString *, NSString *> *)commonHeadersWithAppVersion:(NSString *)appVersion {
    NSMutableDictionary<NSString *, NSString *> *headers = [@{
        @"Content-Type": @"application/json",
        @"appVersion": appVersion,
        @"deviceNo": [YGSecretCodec deviceID],
        @"pushToken": [YGSecretCodec pushToken],
        @"loginToken": [YGSecretCodec userToken]
    } mutableCopy];

    NSString *appId = [YGSecretCodec appID];
    if (appId.length > 0) {
        headers[@"appId"] = appId;
    }

    return headers;
}

- (void)saveStringValue:(id)value forKey:(NSString *)key {
    NSString *stringValue = [self stringFromValue:value];
    if (stringValue.length == 0) {
        return;
    }
    [NSUserDefaults.standardUserDefaults setObject:stringValue forKey:key];
}

- (NSString *)stringFromValue:(id)value {
    if ([value isKindOfClass:NSString.class]) {
        return value;
    }
    if ([value isKindOfClass:NSNumber.class]) {
        return [(NSNumber *)value stringValue];
    }
    return nil;
}

- (NSInteger)intValueFromValue:(id)value {
    if ([value isKindOfClass:NSNumber.class]) {
        return [(NSNumber *)value integerValue];
    }
    if ([value isKindOfClass:NSString.class]) {
        return [(NSString *)value integerValue];
    }
    return 0;
}

- (NSString *)decryptString:(NSString *)string {
    return [YGSecretCodec plainTextFromSealedText:string];
}

- (void)showToastWithMessage:(NSString *)message inView:(UIView *)view position:(NSString *)position {
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
    [invocation setArgument:&position atIndex:4];
    [invocation invoke];
}

- (void)requestPath:(NSString *)path
             method:(NSString *)method
         parameters:(NSDictionary<NSString *, id> *)parameters
            headers:(NSDictionary<NSString *, NSString *> *)headers
         completion:(void (^)(NSData * _Nullable data, NSError * _Nullable error))completion {
    YGWireVerb verb = [[method uppercaseString] isEqualToString:@"GET"] ? YGWireVerbFetch : YGWireVerbCreate;
    [YGRequestAgent.sharedAgent sendRawEndpoint:path
                                           verb:verb
                                           body:parameters
                                   headerFields:headers
                                         finish:completion];
}

@end
