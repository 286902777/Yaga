//
//  AppDelegate.m
//  Yaga
//
//  Created by myfy on 2026/6/24.
//

#import "AppDelegate.h"
#import <UserNotifications/UserNotifications.h>

static NSString * const YGAppDelegatePushTokenDefaultsKey = @"yaga.pushToken";

@interface AppDelegate () <UNUserNotificationCenterDelegate>

@property (nonatomic, assign) BOOL hasRequestedRemoteNotifications;

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    return YES;
}

- (void)registerRemoteNotificationsIfNeeded {
    if (self.hasRequestedRemoteNotifications) {
        return;
    }

    self.hasRequestedRemoteNotifications = YES;
    [self registerRemoteNotificationsForApplication:UIApplication.sharedApplication];
}

- (void)registerRemoteNotificationsForApplication:(UIApplication *)application {
    if (@available(iOS 10.0, *)) {
        UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
        center.delegate = self;
        UNAuthorizationOptions options = UNAuthorizationOptionAlert | UNAuthorizationOptionSound | UNAuthorizationOptionBadge;
        [center requestAuthorizationWithOptions:options completionHandler:^(BOOL granted, NSError * _Nullable error) {
            if (error) {
                NSLog(@"Notification authorization failed: %@", error.localizedDescription);
            }

            if (!granted) {
                return;
            }

            dispatch_async(dispatch_get_main_queue(), ^{
                [application registerForRemoteNotifications];
            });
        }];
        return;
    }

    UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeAlert | UIUserNotificationTypeSound | UIUserNotificationTypeBadge)
                                                                             categories:nil];
    [application registerUserNotificationSettings:settings];
    [application registerForRemoteNotifications];
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    NSString *token = [self hexStringFromDeviceToken:deviceToken];
    if (token.length == 0) {
        return;
    }

    [NSUserDefaults.standardUserDefaults setObject:token forKey:YGAppDelegatePushTokenDefaultsKey];
    [NSUserDefaults.standardUserDefaults synchronize];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    NSLog(@"Remote notification registration failed: %@", error.localizedDescription);
}

- (NSString *)hexStringFromDeviceToken:(NSData *)deviceToken {
    if (deviceToken.length == 0) {
        return @"";
    }

    const unsigned char *bytes = deviceToken.bytes;
    NSMutableString *token = [NSMutableString stringWithCapacity:deviceToken.length * 2];
    for (NSUInteger index = 0; index < deviceToken.length; index++) {
        [token appendFormat:@"%02x", bytes[index]];
    }
    return [token copy];
}

#pragma mark - UNUserNotificationCenterDelegate

- (void)userNotificationCenter:(UNUserNotificationCenter *)center
       willPresentNotification:(UNNotification *)notification
         withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler API_AVAILABLE(ios(10.0)) {
    if (@available(iOS 14.0, *)) {
        completionHandler(UNNotificationPresentationOptionBanner | UNNotificationPresentationOptionList | UNNotificationPresentationOptionSound | UNNotificationPresentationOptionBadge);
    } else {
        completionHandler(UNNotificationPresentationOptionAlert | UNNotificationPresentationOptionSound | UNNotificationPresentationOptionBadge);
    }
}


#pragma mark - UISceneSession lifecycle


- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession options:(UISceneConnectionOptions *)options {
    // Called when a new scene session is being created.
    // Use this method to select a configuration to create the new scene with.
    return [[UISceneConfiguration alloc] initWithName:@"Default Configuration" sessionRole:connectingSceneSession.role];
}


- (void)application:(UIApplication *)application didDiscardSceneSessions:(NSSet<UISceneSession *> *)sceneSessions {
    // Called when the user discards a scene session.
    // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
    // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
}


@end
