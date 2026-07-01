//
//  YGUserStore.h
//  Yaga
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface YGUserStore : NSObject

+ (instancetype)sharedStore;

- (BOOL)hasLoggedInUser;
- (BOOL)isGuestMode;
- (BOOL)canPerformSensitiveAction;
- (nullable NSDictionary *)currentUser;
- (nullable NSString *)currentUserEmail;
- (nullable NSDictionary *)userForEmail:(NSString *)email;
- (NSInteger)currentUserBalance;
- (BOOL)addBalanceToCurrentUser:(NSInteger)amount error:(NSString * _Nullable * _Nullable)errorMessage;
- (BOOL)deductBalanceFromCurrentUser:(NSInteger)amount error:(NSString * _Nullable * _Nullable)errorMessage;

- (BOOL)registerUserWithEmail:(NSString *)email
                     password:(NSString *)password
                     nickname:(NSString *)nickname
                     birthday:(NSString *)birthday
                     location:(NSString *)location
                       gender:(NSString *)gender
                   avatarName:(NSString *)avatarName
             avatarDataBase64:(NSString *)avatarDataBase64
                        error:(NSString * _Nullable * _Nullable)errorMessage;

- (BOOL)loginWithEmail:(NSString *)email
              password:(NSString *)password
                 error:(NSString * _Nullable * _Nullable)errorMessage;

- (BOOL)resetPasswordWithEmail:(NSString *)email
                   newPassword:(NSString *)newPassword
                         error:(NSString * _Nullable * _Nullable)errorMessage;

- (BOOL)updateCurrentUserProfileWithNickname:(NSString *)nickname
                                    birthday:(NSString *)birthday
                                    location:(NSString *)location
                                      gender:(NSString *)gender
                                  avatarName:(NSString *)avatarName
                            avatarDataBase64:(NSString *)avatarDataBase64
                                       error:(NSString * _Nullable * _Nullable)errorMessage;

- (void)logout;
- (void)deleteCurrentAccount;
- (void)enterGuestMode;

@end

NS_ASSUME_NONNULL_END
