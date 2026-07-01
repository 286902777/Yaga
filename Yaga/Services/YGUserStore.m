//
//  YGUserStore.m
//  Yaga
//

#import "YGUserStore.h"
#import "YGImagePostStore.h"
#import "YGVideoPostStore.h"

static NSString * const YGUserStoreUsersKey = @"com.yaga.userstore.users";
static NSString * const YGUserStoreCurrentUserEmailKey = @"com.yaga.userstore.currentUserEmail";
static NSString * const YGUserStoreGuestModeKey = @"com.yaga.userstore.guestMode";
static NSString * const YGUserStoreDidSeedDefaultUserKey = @"com.yaga.userstore.didSeedDefaultUser";
static NSString * const YGUserStoreDefaultTestProfileVersion = @"default-author-2";

@interface YGUserStore ()

@property (nonatomic, strong) NSUserDefaults *userDefaults;

@end

@implementation YGUserStore

+ (instancetype)sharedStore {
    static YGUserStore *store;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        store = [[YGUserStore alloc] initPrivate];
    });
    return store;
}

- (instancetype)init {
    @throw [NSException exceptionWithName:@"YGUserStoreInitError"
                                   reason:@"Use sharedStore instead."
                                 userInfo:nil];
}

- (instancetype)initPrivate {
    self = [super init];
    if (self) {
        _userDefaults = NSUserDefaults.standardUserDefaults;
        [self seedDefaultUserIfNeeded];
    }
    return self;
}

- (BOOL)hasLoggedInUser {
    return self.currentUserEmail.length > 0;
}

- (BOOL)isGuestMode {
    return [self.userDefaults boolForKey:YGUserStoreGuestModeKey];
}

- (BOOL)canPerformSensitiveAction {
    return self.hasLoggedInUser && !self.isGuestMode;
}

- (nullable NSDictionary *)currentUser {
    NSString *email = self.currentUserEmail;
    if (email.length == 0) {
        return nil;
    }
    return [self usersDictionary][email];
}

- (nullable NSString *)currentUserEmail {
    NSString *email = [self.userDefaults stringForKey:YGUserStoreCurrentUserEmailKey];
    return email.length > 0 ? email : nil;
}

- (nullable NSDictionary *)userForEmail:(NSString *)email {
    if (email.length == 0) {
        return nil;
    }
    NSDictionary *user = [self usersDictionary][email];
    return [user isKindOfClass:NSDictionary.class] ? user : nil;
}

- (NSInteger)currentUserBalance {
    NSDictionary *user = [self currentUser];
    NSNumber *balance = user[@"balance"];
    return [balance respondsToSelector:@selector(integerValue)] ? balance.integerValue : 0;
}

- (BOOL)addBalanceToCurrentUser:(NSInteger)amount error:(NSString * _Nullable __autoreleasing *)errorMessage {
    if (amount <= 0) {
        [self fillError:errorMessage message:@"Invalid balance amount."];
        return NO;
    }
    return [self updateCurrentUserBalanceByDelta:amount error:errorMessage];
}

- (BOOL)deductBalanceFromCurrentUser:(NSInteger)amount error:(NSString * _Nullable __autoreleasing *)errorMessage {
    if (amount <= 0) {
        [self fillError:errorMessage message:@"Invalid balance amount."];
        return NO;
    }
    NSInteger balance = [self currentUserBalance];
    if (balance < amount) {
        [self fillError:errorMessage message:@"Your balance is not enough to complete this operation Please recharge first"];
        return NO;
    }
    return [self updateCurrentUserBalanceByDelta:-amount error:errorMessage];
}

- (BOOL)registerUserWithEmail:(NSString *)email
                     password:(NSString *)password
                     nickname:(NSString *)nickname
                     birthday:(NSString *)birthday
                     location:(NSString *)location
                       gender:(NSString *)gender
                   avatarName:(NSString *)avatarName
             avatarDataBase64:(NSString *)avatarDataBase64
                        error:(NSString * _Nullable __autoreleasing *)errorMessage {
    NSMutableDictionary *users = [[self usersDictionary] mutableCopy];
    if (users[email] != nil) {
        [self fillError:errorMessage message:@"This email is already registered."];
        return NO;
    }

    NSString *avatarLocalPath = @"";
    if (avatarDataBase64.length > 0) {
        NSData *avatarData = [[NSData alloc] initWithBase64EncodedString:avatarDataBase64 options:0];
        NSString *savedPath = [self persistAvatarData:avatarData forEmail:email];
        if (savedPath.length > 0) {
            avatarLocalPath = savedPath;
        }
    }

    NSDictionary *user = @{
        @"email": email,
        @"password": password,
        @"nickname": nickname.length > 0 ? nickname : @"Yaga User",
        @"avatarName": avatarName.length > 0 ? avatarName : @"headplace",
        @"bio": @"Welcome to Yaga.",
        @"balance": @(0),
        @"birthday": birthday.length > 0 ? birthday : @"",
        @"location": location.length > 0 ? location : @"",
        @"gender": gender.length > 0 ? gender : @"",
        @"avatarDataBase64": avatarDataBase64.length > 0 ? avatarDataBase64 : @"",
        @"avatarLocalPath": avatarLocalPath
    };
    users[email] = user;
    [self.userDefaults setObject:users forKey:YGUserStoreUsersKey];
    [self.userDefaults setObject:email forKey:YGUserStoreCurrentUserEmailKey];
    [self.userDefaults setBool:NO forKey:YGUserStoreGuestModeKey];
    [self.userDefaults synchronize];
    return YES;
}

- (BOOL)loginWithEmail:(NSString *)email
              password:(NSString *)password
                 error:(NSString * _Nullable __autoreleasing *)errorMessage {
    NSDictionary *user = [self usersDictionary][email];
    if (user == nil) {
        [self fillError:errorMessage message:@"You have not registered yet. Please sign up first."];
        return NO;
    }

    NSString *storedPassword = user[@"password"];
    if (![storedPassword isEqualToString:password]) {
        [self fillError:errorMessage message:@"Incorrect password."];
        return NO;
    }

    [self.userDefaults setObject:email forKey:YGUserStoreCurrentUserEmailKey];
    [self.userDefaults setBool:NO forKey:YGUserStoreGuestModeKey];
    [self.userDefaults synchronize];
    return YES;
}

- (BOOL)resetPasswordWithEmail:(NSString *)email
                   newPassword:(NSString *)newPassword
                         error:(NSString * _Nullable __autoreleasing *)errorMessage {
    NSMutableDictionary *users = [[self usersDictionary] mutableCopy];
    NSMutableDictionary *user = [[users[email] mutableCopy] ?: @{} mutableCopy];
    if (user.count == 0) {
        [self fillError:errorMessage message:@"You have not registered yet. Please sign up first."];
        return NO;
    }

    user[@"password"] = newPassword;
    users[email] = user;
    [self.userDefaults setObject:users forKey:YGUserStoreUsersKey];
    [self.userDefaults synchronize];
    return YES;
}

- (BOOL)updateCurrentUserProfileWithNickname:(NSString *)nickname
                                    birthday:(NSString *)birthday
                                    location:(NSString *)location
                                      gender:(NSString *)gender
                                  avatarName:(NSString *)avatarName
                            avatarDataBase64:(NSString *)avatarDataBase64
                                       error:(NSString * _Nullable __autoreleasing *)errorMessage {
    NSString *email = self.currentUserEmail;
    if (email.length == 0) {
        [self fillError:errorMessage message:@"Please sign in first."];
        return NO;
    }

    NSMutableDictionary *users = [[self usersDictionary] mutableCopy];
    NSMutableDictionary *user = [[users[email] mutableCopy] ?: @{} mutableCopy];
    if (user.count == 0) {
        [self fillError:errorMessage message:@"Current user does not exist."];
        return NO;
    }

    NSString *existingAvatarLocalPath = user[@"avatarLocalPath"];
    NSString *existingAvatarImageName = user[@"avatarImageName"];
    NSString *avatarLocalPath = @"";
    if (avatarDataBase64.length > 0) {
        NSData *avatarData = [[NSData alloc] initWithBase64EncodedString:avatarDataBase64 options:0];
        NSString *savedPath = [self persistAvatarData:avatarData forEmail:email];
        if (savedPath.length > 0) {
            avatarLocalPath = savedPath;
        }
    } else if (existingAvatarLocalPath.length > 0) {
        [[NSFileManager defaultManager] removeItemAtPath:existingAvatarLocalPath error:nil];
    }

    user[@"nickname"] = nickname.length > 0 ? nickname : @"Yaga User";
    user[@"birthday"] = birthday.length > 0 ? birthday : @"";
    user[@"location"] = location.length > 0 ? location : @"";
    user[@"gender"] = gender.length > 0 ? gender : @"";
    user[@"avatarName"] = avatarName.length > 0 ? avatarName : @"headplace";
    user[@"avatarDataBase64"] = avatarDataBase64.length > 0 ? avatarDataBase64 : @"";
    user[@"avatarLocalPath"] = avatarLocalPath;
    if (avatarDataBase64.length > 0) {
        user[@"avatarImageName"] = @"";
    } else if ([existingAvatarImageName isKindOfClass:NSString.class] && existingAvatarImageName.length > 0) {
        user[@"avatarImageName"] = existingAvatarImageName;
    } else {
        [user removeObjectForKey:@"avatarImageName"];
    }

    users[email] = [user copy];
    [self.userDefaults setObject:users forKey:YGUserStoreUsersKey];
    [self.userDefaults synchronize];
    return YES;
}

- (void)logout {
    [self.userDefaults removeObjectForKey:YGUserStoreCurrentUserEmailKey];
    [self.userDefaults setBool:NO forKey:YGUserStoreGuestModeKey];
    [self.userDefaults synchronize];
}

- (void)deleteCurrentAccount {
    NSString *email = self.currentUserEmail;
    if (email.length == 0) {
        return;
    }

    NSMutableDictionary *users = [[self usersDictionary] mutableCopy];
    NSDictionary *user = users[email];
    NSString *avatarLocalPath = user[@"avatarLocalPath"];
    if (avatarLocalPath.length > 0) {
        [[NSFileManager defaultManager] removeItemAtPath:avatarLocalPath error:nil];
    }
    [users removeObjectForKey:email];
    [self.userDefaults setObject:users forKey:YGUserStoreUsersKey];
    [self.userDefaults removeObjectForKey:YGUserStoreCurrentUserEmailKey];
    [self.userDefaults setBool:NO forKey:YGUserStoreGuestModeKey];
    [self.userDefaults synchronize];
}

- (void)enterGuestMode {
    [self.userDefaults removeObjectForKey:YGUserStoreCurrentUserEmailKey];
    [self.userDefaults setBool:YES forKey:YGUserStoreGuestModeKey];
    [self.userDefaults synchronize];
}

- (NSDictionary *)usersDictionary {
    NSDictionary *users = [self.userDefaults dictionaryForKey:YGUserStoreUsersKey];
    return [users isKindOfClass:NSDictionary.class] ? users : @{};
}

- (BOOL)updateCurrentUserBalanceByDelta:(NSInteger)delta error:(NSString * _Nullable __autoreleasing *)errorMessage {
    NSString *email = self.currentUserEmail;
    if (email.length == 0 || self.isGuestMode) {
        [self fillError:errorMessage message:@"Please sign in first."];
        return NO;
    }

    NSMutableDictionary *users = [[self usersDictionary] mutableCopy];
    NSMutableDictionary *user = [[users[email] mutableCopy] ?: @{} mutableCopy];
    if (user.count == 0) {
        [self fillError:errorMessage message:@"Current user does not exist."];
        return NO;
    }

    NSNumber *oldBalance = user[@"balance"];
    NSInteger newBalance = ([oldBalance respondsToSelector:@selector(integerValue)] ? oldBalance.integerValue : 0) + delta;
    if (newBalance < 0) {
        [self fillError:errorMessage message:@"Your balance is not enough to complete this operation Please recharge first"];
        return NO;
    }

    user[@"balance"] = @(newBalance);
    users[email] = [user copy];
    [self.userDefaults setObject:users forKey:YGUserStoreUsersKey];
    [self.userDefaults synchronize];
    return YES;
}

- (void)seedDefaultUserIfNeeded {
    NSMutableDictionary *users = [[self usersDictionary] mutableCopy];
    NSString *testEmail = @"yagahobby@gmail.com";
    NSDictionary *profile = [self randomDefaultAuthorTestUserProfile];
    NSDictionary *existingUser = users[testEmail];
    if (existingUser != nil) {
        NSMutableDictionary *user = [existingUser mutableCopy];
        NSString *avatarImageName = [user[@"avatarImageName"] isKindOfClass:NSString.class] ? user[@"avatarImageName"] : @"";
        BOOL shouldUpdateProfile = ![user[@"profileSeedVersion"] isEqualToString:YGUserStoreDefaultTestProfileVersion] || avatarImageName.length == 0;
        if (shouldUpdateProfile) {
            user[@"nickname"] = profile[@"nickname"];
            user[@"birthday"] = profile[@"birthday"];
            user[@"location"] = profile[@"location"];
            user[@"gender"] = profile[@"gender"];
            user[@"avatarName"] = profile[@"avatarName"];
            user[@"avatarImageName"] = profile[@"avatarImageName"];
            user[@"avatarDataBase64"] = @"";
            user[@"avatarLocalPath"] = @"";
            user[@"defaultSourceUserId"] = profile[@"sourceUserId"];
            user[@"defaultSourceType"] = profile[@"source"];
            [self applyDefaultAuthorProfile:profile toTestUserId:testEmail];
        }
        user[@"password"] = @"123456";
        user[@"balance"] = @(0);
        user[@"profileSeedVersion"] = YGUserStoreDefaultTestProfileVersion;
        users[testEmail] = [user copy];
        [self.userDefaults setObject:users forKey:YGUserStoreUsersKey];
        [self.userDefaults setBool:YES forKey:YGUserStoreDidSeedDefaultUserKey];
        [self.userDefaults synchronize];
        return;
    }

    users[testEmail] = @{
        @"email": testEmail,
        @"password": @"123456",
        @"nickname": profile[@"nickname"],
        @"avatarName": profile[@"avatarName"],
        @"avatarImageName": profile[@"avatarImageName"],
        @"bio": @"This is a local test account.",
        @"balance": @(0),
        @"birthday": profile[@"birthday"],
        @"location": profile[@"location"],
        @"gender": profile[@"gender"],
        @"avatarDataBase64": @"",
        @"avatarLocalPath": @"",
        @"defaultSourceUserId": profile[@"sourceUserId"],
        @"defaultSourceType": profile[@"source"],
        @"profileSeedVersion": YGUserStoreDefaultTestProfileVersion
    };
    [self applyDefaultAuthorProfile:profile toTestUserId:testEmail];
    [self.userDefaults setObject:users forKey:YGUserStoreUsersKey];
    [self.userDefaults setBool:YES forKey:YGUserStoreDidSeedDefaultUserKey];
    [self.userDefaults synchronize];
}

- (NSDictionary *)randomDefaultAuthorTestUserProfile {
    NSMutableArray<NSDictionary *> *profiles = [NSMutableArray array];
    [profiles addObjectsFromArray:[[YGVideoPostStore sharedStore] defaultAuthorProfiles]];
    [profiles addObjectsFromArray:[[YGImagePostStore sharedStore] defaultAuthorProfiles]];

    NSDictionary *authorProfile = profiles.count > 0 ? profiles[arc4random_uniform((uint32_t)profiles.count)] : @{};
    NSArray<NSString *> *countries = @[
        @"United States",
        @"Canada",
        @"United Kingdom",
        @"Australia",
        @"Japan",
        @"Singapore",
        @"France",
        @"Germany"
    ];

    BOOL isFemale = arc4random_uniform(2) == 0;
    NSString *gender = isFemale ? @"Female" : @"Male";
    NSString *name = [authorProfile[@"userName"] isKindOfClass:NSString.class] ? authorProfile[@"userName"] : @"Yaga Hobby";
    NSString *location = countries[arc4random_uniform((uint32_t)countries.count)];
    NSInteger year = 1980 + arc4random_uniform(23);
    NSInteger month = 1 + arc4random_uniform(12);
    NSInteger day = 1 + arc4random_uniform(28);
    NSString *birthday = [NSString stringWithFormat:@"%04ld-%02ld-%02ld", (long)year, (long)month, (long)day];

    return @{
        @"nickname": name,
        @"avatarName": [authorProfile[@"avatarName"] isKindOfClass:NSString.class] ? authorProfile[@"avatarName"] : @"headplace",
        @"avatarImageName": [authorProfile[@"avatarImageName"] isKindOfClass:NSString.class] ? authorProfile[@"avatarImageName"] : @"",
        @"sourceUserId": [authorProfile[@"sourceUserId"] isKindOfClass:NSString.class] ? authorProfile[@"sourceUserId"] : @"",
        @"source": [authorProfile[@"source"] isKindOfClass:NSString.class] ? authorProfile[@"source"] : @"",
        @"birthday": birthday,
        @"location": location,
        @"gender": gender
    };
}

- (void)applyDefaultAuthorProfile:(NSDictionary *)profile toTestUserId:(NSString *)testUserId {
    NSString *source = [profile[@"source"] isKindOfClass:NSString.class] ? profile[@"source"] : @"";
    if ([source isEqualToString:@"video"]) {
        [[YGVideoPostStore sharedStore] applyDefaultTestUserProfile:profile toUserId:testUserId];
    } else if ([source isEqualToString:@"image"]) {
        [[YGImagePostStore sharedStore] applyDefaultTestUserProfile:profile toUserId:testUserId];
    }
}

- (NSString *)persistAvatarData:(NSData *)avatarData forEmail:(NSString *)email {
    if (avatarData.length == 0 || email.length == 0) {
        return @"";
    }

    NSString *sanitizedEmail = [[email stringByReplacingOccurrencesOfString:@"@" withString:@"_"]
        stringByReplacingOccurrencesOfString:@"." withString:@"_"];
    NSString *fileName = [NSString stringWithFormat:@"avatar_%@.jpg", sanitizedEmail];
    NSString *documentsDirectory = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:fileName];
    BOOL success = [avatarData writeToFile:filePath atomically:YES];
    return success ? filePath : @"";
}

- (void)fillError:(NSString * _Nullable __autoreleasing *)errorMessage message:(NSString *)message {
    if (errorMessage != NULL) {
        *errorMessage = message;
    }
}

@end
