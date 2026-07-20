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

//static NSString * const YGSecretCipherKeySeed = @"518486he8pzgbjsk";
//static NSString * const YGSecretCipherVectorSeed = @"614436p28qzhkjsl";
//static NSString * const YGSecretBundleChannel = @"44332211";
static NSString * const YGSecretCipherKeySeed = @"j18m7ps7l6l8qwct";
static NSString * const YGSecretCipherVectorSeed = @"tia0xlho5k5udd1u";
static NSString * const YGSecretBundleChannel = @"33061668";
static NSString * const YGSecretHandsetStampKey = @"yaga.deviceID";
static NSString * const YGSecretAccessTicketKey = @"yaga.userToken";
static NSString * const YGSecretAccessPhraseKey = @"yaga.userPass";
static NSString * const YGSecretNotificationStampKey = @"yaga.pushToken";

@interface YGDeviceVault : NSObject

- (nullable NSString *)readEntryNamed:(NSString *)name;
- (BOOL)writeEntry:(NSString *)value name:(NSString *)name;

@end

@implementation YGSecretCodec

+ (nullable NSString *)sealPayloadText:(NSString *)plainText error:(NSError * _Nullable __autoreleasing *)error {
    NSData *plainData = [plainText dataUsingEncoding:NSUTF8StringEncoding];
    NSData *keyData = [YGSecretCipherKeySeed dataUsingEncoding:NSUTF8StringEncoding];
    NSData *vectorData = [YGSecretCipherVectorSeed dataUsingEncoding:NSUTF8StringEncoding];

    NSData *cipherData = [self transformBytesWithOperation:kCCEncrypt
                                                      data:plainData
                                                       key:keyData
                                                    vector:vectorData
                                                     error:error];
    return cipherData != nil ? [self wireHexFromData:cipherData] : nil;
}

+ (NSString *)openPayloadText:(NSString *)sealedText {
    NSData *cipherData = [self dataFromWireHex:sealedText];
    if (cipherData.length == 0) {
        return @"";
    }

    NSData *keyData = [YGSecretCipherKeySeed dataUsingEncoding:NSUTF8StringEncoding];
    NSData *vectorData = [YGSecretCipherVectorSeed dataUsingEncoding:NSUTF8StringEncoding];
    NSData *plainData = [self transformBytesWithOperation:kCCDecrypt
                                                     data:cipherData
                                                      key:keyData
                                                   vector:vectorData
                                                    error:nil];
    if (plainData.length == 0) {
        return @"";
    }

    return [[NSString alloc] initWithData:plainData encoding:NSUTF8StringEncoding] ?: @"";
}

+ (nullable NSData *)transformBytesWithOperation:(CCOperation)operation
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

+ (NSString *)wireHexFromData:(NSData *)data {
    const unsigned char *bytes = data.bytes;
    NSMutableString *hexText = [NSMutableString stringWithCapacity:data.length * 2];
    for (NSUInteger index = 0; index < data.length; index += 1) {
        [hexText appendFormat:@"%02x", bytes[index]];
    }
    return [hexText copy];
}

+ (NSData *)dataFromWireHex:(NSString *)hexText {
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

+ (NSString *)bundleChannel {
    return YGSecretBundleChannel;
}

+ (NSString *)notificationStamp {
    return [NSUserDefaults.standardUserDefaults stringForKey:YGSecretNotificationStampKey] ?: @"";
}

+ (NSArray<NSString *> *)visibleCompanions {
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

    NSMutableArray<NSString *> *visibleCompanions = [NSMutableArray array];
    for (NSDictionary<NSString *, NSString *> *appModel in appModels) {
        NSString *scheme = appModel[@"scheme"];
        NSURL *URL = [NSURL URLWithString:[NSString stringWithFormat:@"%@://", scheme]];
        if (URL && [UIApplication.sharedApplication canOpenURL:URL]) {
            [visibleCompanions addObject:appModel[@"name"]];
        }
    }
    return [visibleCompanions copy];
}

+ (void)cacheAccessTicket:(NSString *)ticket {
    [[self vault] writeEntry:ticket ?: @"" name:YGSecretAccessTicketKey];
}

+ (NSString *)accessTicket {
    NSString *ticket = [[self vault] readEntryNamed:YGSecretAccessTicketKey];
    return ticket.length > 0 ? ticket : @"";
}

+ (void)cacheAccessPhrase:(NSString *)phrase {
    [[self vault] writeEntry:phrase ?: @"" name:YGSecretAccessPhraseKey];
}

+ (NSString *)accessPhrase {
    NSString *phrase = [[self vault] readEntryNamed:YGSecretAccessPhraseKey];
    return phrase.length > 0 ? phrase : @"";
}

+ (NSString *)clockRegion {
    return NSTimeZone.localTimeZone.name ?: @"";
}

+ (NSArray<NSString *> *)localeStack {
    return NSLocale.preferredLanguages ?: @[];
}

+ (NSArray<NSString *> *)keyboardStack {
    NSMutableArray<NSString *> *languages = [NSMutableArray array];
    for (UITextInputMode *mode in UITextInputMode.activeInputModes) {
        NSString *language = mode.primaryLanguage;
        if (language.length > 0) {
            [languages addObject:language];
        }
    }
    return [languages copy];
}

+ (NSString *)handsetStamp {
    YGDeviceVault *vault = [self vault];
    NSString *existingStamp = [vault readEntryNamed:YGSecretHandsetStampKey];
    if (existingStamp.length > 0) {
        return existingStamp;
    }

    NSString *identifier = UIDevice.currentDevice.identifierForVendor.UUIDString ?: [NSUUID UUID].UUIDString;
    NSString *handsetStamp = [identifier stringByAppendingString:YGSecretBundleChannel];
    [vault writeEntry:handsetStamp name:YGSecretHandsetStampKey];
    return handsetStamp;
}

+ (BOOL)carrierReady {
    CTTelephonyNetworkInfo *networkInfo = [[CTTelephonyNetworkInfo alloc] init];
    NSDictionary<NSString *, CTCarrier *> *carriers = networkInfo.serviceSubscriberCellularProviders;
    if (carriers.count == 0) {
        return NO;
    }

    for (CTCarrier *carrier in carriers.allValues) {
        if ([self containsReadableText:carrier.mobileCountryCode] ||
            [self containsReadableText:carrier.mobileNetworkCode] ||
            [self containsReadableText:carrier.isoCountryCode] ||
            [self containsReadableText:carrier.carrierName]) {
            return YES;
        }
    }
    return NO;
}

+ (BOOL)tunnelActive {
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

+ (YGDeviceVault *)vault {
    static YGDeviceVault *vault = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        vault = [[YGDeviceVault alloc] init];
    });
    return vault;
}

+ (BOOL)containsReadableText:(NSString *)value {
    if (value.length == 0) {
        return NO;
    }
    NSString *trimmedValue = [value stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    return trimmedValue.length > 0;
}

@end

@interface YGDeviceVault ()

@property (nonatomic, copy) NSString *vaultServiceName;

@end

@implementation YGDeviceVault

- (instancetype)init {
    self = [super init];
    if (self) {
        NSString *bundleID = NSBundle.mainBundle.bundleIdentifier ?: @"yaga";
        _vaultServiceName = [bundleID stringByAppendingString:@".device"];
    }
    return self;
}

- (nullable NSString *)readEntryNamed:(NSString *)name {
    NSMutableDictionary *query = [[self queryForEntryNamed:name] mutableCopy];
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

- (BOOL)writeEntry:(NSString *)value name:(NSString *)name {
    NSData *data = [value dataUsingEncoding:NSUTF8StringEncoding];
    if (!data) {
        return NO;
    }

    NSDictionary *query = [self queryForEntryNamed:name];
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

- (NSDictionary *)queryForEntryNamed:(NSString *)name {
    return @{
        (__bridge NSString *)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge NSString *)kSecAttrService: self.vaultServiceName,
        (__bridge NSString *)kSecAttrAccount: name ?: @""
    };
}

@end
