//
//  YGSecretCodec.m
//  Yaga
//

#import "YGSecretCodec.h"
#import <CFNetwork/CFNetwork.h>
#import <CommonCrypto/CommonCryptor.h>
#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <Security/Security.h>
#import <UIKit/UIKit.h>

NSErrorDomain const YGSecretCodecErrorDomain = @"app.yaga.secret-codec";

static NSString * const YGSecretCodecKeyText = @"518486he8pzgbjsk";
static NSString * const YGSecretCodecVectorText = @"614436p28qzhkjsl";
static NSString * const YGSecretCodecAppID = @"44332211";
//static NSString * const YGSecretCodecKeyText = @"j18m7ps7l6l8qwct";
//static NSString * const YGSecretCodecVectorText = @"tia0xlho5k5udd1u";
//static NSString * const YGSecretCodecAppID = @"33061668";
static NSString * const YGSecretCodecDeviceIDKey = @"yaga.deviceID";
static NSString * const YGSecretCodecUserTokenKey = @"yaga.userToken";
static NSString * const YGSecretCodecUserPassKey = @"yaga.userPass";
static NSString * const YGSecretCodecPushTokenKey = @"yaga.pushToken";

@interface YGKeychainDeviceStore : NSObject

- (nullable NSString *)loadStringForKey:(NSString *)key;
- (BOOL)saveString:(NSString *)value key:(NSString *)key;

@end

@implementation YGSecretCodec

+ (nullable NSString *)sealedTextFromPlainText:(NSString *)plainText error:(NSError * _Nullable __autoreleasing *)error {
    NSData *plainData = [plainText dataUsingEncoding:NSUTF8StringEncoding];
    NSData *keyData = [YGSecretCodecKeyText dataUsingEncoding:NSUTF8StringEncoding];
    NSData *vectorData = [YGSecretCodecVectorText dataUsingEncoding:NSUTF8StringEncoding];

    NSData *cipherData = [self runCipherWithOperation:kCCEncrypt
                                                 data:plainData
                                                  key:keyData
                                               vector:vectorData
                                                error:error];
    return cipherData != nil ? [self hexTextFromData:cipherData] : nil;
}

+ (NSString *)plainTextFromSealedText:(NSString *)sealedText {
    NSData *cipherData = [self dataFromHexText:sealedText];
    if (cipherData.length == 0) {
        return @"";
    }

    NSData *keyData = [YGSecretCodecKeyText dataUsingEncoding:NSUTF8StringEncoding];
    NSData *vectorData = [YGSecretCodecVectorText dataUsingEncoding:NSUTF8StringEncoding];
    NSData *plainData = [self runCipherWithOperation:kCCDecrypt
                                                data:cipherData
                                                 key:keyData
                                              vector:vectorData
                                               error:nil];
    if (plainData.length == 0) {
        return @"";
    }

    return [[NSString alloc] initWithData:plainData encoding:NSUTF8StringEncoding] ?: @"";
}

+ (nullable NSData *)runCipherWithOperation:(CCOperation)operation
                                       data:(NSData *)data
                                        key:(NSData *)key
                                     vector:(NSData *)vector
                                      error:(NSError * _Nullable __autoreleasing *)error {
    size_t outputLength = 0;
    NSMutableData *outputData = [NSMutableData dataWithLength:data.length + kCCBlockSizeAES128];

    CCCryptorStatus status = CCCrypt(operation,
                                     kCCAlgorithmAES,
                                     kCCOptionPKCS7Padding,
                                     key.bytes,
                                     key.length,
                                     vector.bytes,
                                     data.bytes,
                                     data.length,
                                     outputData.mutableBytes,
                                     outputData.length,
                                     &outputLength);
    if (status != kCCSuccess) {
        if (error != NULL) {
            *error = [NSError errorWithDomain:YGSecretCodecErrorDomain
                                         code:status
                                     userInfo:@{NSLocalizedDescriptionKey: @"AES operation failed."}];
        }
        return nil;
    }

    outputData.length = outputLength;
    return [outputData copy];
}

+ (NSString *)hexTextFromData:(NSData *)data {
    const unsigned char *bytes = data.bytes;
    NSMutableString *hexText = [NSMutableString stringWithCapacity:data.length * 2];
    for (NSUInteger index = 0; index < data.length; index += 1) {
        [hexText appendFormat:@"%02x", bytes[index]];
    }
    return [hexText copy];
}

+ (NSData *)dataFromHexText:(NSString *)hexText {
    NSMutableData *data = [NSMutableData data];
    NSString *remainingText = [hexText copy] ?: @"";
    while (remainingText.length >= 2) {
        NSString *byteText = [remainingText substringToIndex:2];
        remainingText = [remainingText substringFromIndex:2];

        unsigned int byte = 0;
        NSScanner *scanner = [NSScanner scannerWithString:byteText];
        if ([scanner scanHexInt:&byte]) {
            UInt8 value = (UInt8)(byte & 0xff);
            [data appendBytes:&value length:sizeof(value)];
        }
    }
    return [data copy];
}

+ (NSString *)appID {
    return YGSecretCodecAppID;
}

+ (NSString *)pushToken {
    return [NSUserDefaults.standardUserDefaults stringForKey:YGSecretCodecPushTokenKey] ?: @"";
}

+ (NSArray<NSString *> *)installedApps {
    NSArray<NSDictionary<NSString *, NSString *> *> *appModels = @[
        @{@"name": @"WhatsApp", @"scheme": @"whatsapp"},
        @{@"name": @"Instagram", @"scheme": @"instagram"},
        @{@"name": @"TikTok", @"scheme": @"tiktok"},
        @{@"name": @"GoogleMaps", @"scheme": @"comgooglemaps"},
        @{@"name": @"Twitter", @"scheme": @"tweetie"},
        @{@"name": @"QQ", @"scheme": @"mqq"},
        @{@"name": @"WeChat", @"scheme": @"wechat"},
        @{@"name": @"AliApp", @"scheme": @"alipay"}
    ];

    NSMutableArray<NSString *> *installedApps = [NSMutableArray array];
    for (NSDictionary<NSString *, NSString *> *appModel in appModels) {
        NSString *scheme = appModel[@"scheme"];
        NSURL *URL = [NSURL URLWithString:[NSString stringWithFormat:@"%@://", scheme]];
        if (URL && [UIApplication.sharedApplication canOpenURL:URL]) {
            [installedApps addObject:appModel[@"name"]];
        }
    }
    return [installedApps copy];
}

+ (void)saveUserToken:(NSString *)token {
    [[self keychainStore] saveString:token ?: @"" key:YGSecretCodecUserTokenKey];
}

+ (NSString *)userToken {
    NSString *token = [[self keychainStore] loadStringForKey:YGSecretCodecUserTokenKey];
    return token.length > 0 ? token : @"";
}

+ (void)saveUserPassword:(NSString *)password {
    [[self keychainStore] saveString:password ?: @"" key:YGSecretCodecUserPassKey];
}

+ (NSString *)userPassword {
    NSString *password = [[self keychainStore] loadStringForKey:YGSecretCodecUserPassKey];
    return password.length > 0 ? password : @"";
}

+ (NSString *)timeZoneIdentifier {
    return NSTimeZone.localTimeZone.name ?: @"";
}

+ (NSArray<NSString *> *)preferredLanguages {
    return NSLocale.preferredLanguages ?: @[];
}

+ (NSArray<NSString *> *)activeKeyboardLanguages {
    NSMutableArray<NSString *> *languages = [NSMutableArray array];
    for (UITextInputMode *mode in UITextInputMode.activeInputModes) {
        NSString *language = mode.primaryLanguage;
        if (language.length > 0) {
            [languages addObject:language];
        }
    }
    return [languages copy];
}

+ (NSString *)deviceID {
    YGKeychainDeviceStore *store = [self keychainStore];
    NSString *existingID = [store loadStringForKey:YGSecretCodecDeviceIDKey];
    if (existingID.length > 0) {
        return existingID;
    }

    NSString *identifier = UIDevice.currentDevice.identifierForVendor.UUIDString ?: [NSUUID UUID].UUIDString;
    NSString *deviceID = [identifier stringByAppendingString:YGSecretCodecAppID];
    [store saveString:deviceID key:YGSecretCodecDeviceIDKey];
    return deviceID;
}

+ (BOOL)isSIMCardInserted {
    CTTelephonyNetworkInfo *networkInfo = [[CTTelephonyNetworkInfo alloc] init];
    NSDictionary<NSString *, CTCarrier *> *carriers = networkInfo.serviceSubscriberCellularProviders;
    if (carriers.count == 0) {
        return NO;
    }

    for (CTCarrier *carrier in carriers.allValues) {
        if ([self hasValue:carrier.mobileCountryCode] ||
            [self hasValue:carrier.mobileNetworkCode] ||
            [self hasValue:carrier.isoCountryCode] ||
            [self hasValue:carrier.carrierName]) {
            return YES;
        }
    }
    return NO;
}

+ (BOOL)isVPNEnabled {
    CFDictionaryRef settingsRef = CFNetworkCopySystemProxySettings();
    if (settingsRef == NULL) {
        return NO;
    }

    NSDictionary *settings = CFBridgingRelease(settingsRef);
    NSDictionary *scopedSettings = settings[@"__SCOPED__"];
    if (![scopedSettings isKindOfClass:NSDictionary.class]) {
        return NO;
    }

    NSArray<NSString *> *prefixes = @[@"utun", @"tun", @"tap", @"ppp", @"ipsec"];
    for (NSString *interfaceName in scopedSettings.allKeys) {
        for (NSString *prefix in prefixes) {
            if ([interfaceName hasPrefix:prefix]) {
                return YES;
            }
        }
    }
    return NO;
}

+ (YGKeychainDeviceStore *)keychainStore {
    static YGKeychainDeviceStore *store = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        store = [[YGKeychainDeviceStore alloc] init];
    });
    return store;
}

+ (BOOL)hasValue:(NSString *)value {
    if (value.length == 0) {
        return NO;
    }
    NSString *trimmedValue = [value stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    return trimmedValue.length > 0;
}

@end

@interface YGKeychainDeviceStore ()

@property (nonatomic, copy) NSString *service;

@end

@implementation YGKeychainDeviceStore

- (instancetype)init {
    self = [super init];
    if (self) {
        NSString *bundleID = NSBundle.mainBundle.bundleIdentifier ?: @"yaga";
        _service = [bundleID stringByAppendingString:@".device"];
    }
    return self;
}

- (nullable NSString *)loadStringForKey:(NSString *)key {
    NSMutableDictionary *query = [[self baseQueryForKey:key] mutableCopy];
    query[(__bridge NSString *)kSecReturnData] = @YES;
    query[(__bridge NSString *)kSecMatchLimit] = (__bridge id)kSecMatchLimitOne;

    CFTypeRef item = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &item);
    if (status != errSecSuccess || item == NULL) {
        return nil;
    }

    NSData *data = CFBridgingRelease(item);
    if (![data isKindOfClass:NSData.class]) {
        return nil;
    }
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

- (BOOL)saveString:(NSString *)value key:(NSString *)key {
    NSData *data = [value dataUsingEncoding:NSUTF8StringEncoding];
    if (!data) {
        return NO;
    }

    NSDictionary *query = [self baseQueryForKey:key];
    NSDictionary *attributes = @{(__bridge NSString *)kSecValueData: data};

    OSStatus updateStatus = SecItemUpdate((__bridge CFDictionaryRef)query, (__bridge CFDictionaryRef)attributes);
    if (updateStatus == errSecSuccess) {
        return YES;
    }

    if (updateStatus != errSecItemNotFound) {
        return NO;
    }

    NSMutableDictionary *addQuery = [query mutableCopy];
    addQuery[(__bridge NSString *)kSecValueData] = data;
    return SecItemAdd((__bridge CFDictionaryRef)addQuery, NULL) == errSecSuccess;
}

- (NSDictionary *)baseQueryForKey:(NSString *)key {
    return @{
        (__bridge NSString *)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge NSString *)kSecAttrService: self.service,
        (__bridge NSString *)kSecAttrAccount: key ?: @""
    };
}

@end
