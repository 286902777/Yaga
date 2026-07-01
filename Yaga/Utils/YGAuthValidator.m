//
//  YGAuthValidator.m
//  Yaga
//

#import "YGAuthValidator.h"

@implementation YGAuthValidator

+ (BOOL)isValidEmail:(NSString *)email {
    NSString *pattern = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}";
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", pattern];
    return [predicate evaluateWithObject:email];
}

+ (BOOL)isValidPassword:(NSString *)password {
    return password.length >= 6;
}

@end
