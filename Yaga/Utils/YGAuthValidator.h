//
//  YGAuthValidator.h
//  Yaga
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface YGAuthValidator : NSObject

+ (BOOL)isValidEmail:(NSString *)email;
+ (BOOL)isValidPassword:(NSString *)password;

@end

NS_ASSUME_NONNULL_END
