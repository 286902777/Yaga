//
//  YGDirectLoginViewController.m
//  Yaga
//

#import "YGDirectLoginViewController.h"
#import "YGAppRouter.h"
#import "YGRootManager.h"
#import "YGSignInViewController.h"
#import "YGHUDHelper.h"
#import "YGSecretCodec.h"

static NSString * const YGDirectLoginDidCallGotoLoginKey = @"yaga.directLogin.didCallGotoLogin";

@interface YGDirectLoginViewController ()
@end

@implementation YGDirectLoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = UIColor.whiteColor;
    self.title = @"";
    [self setupSubviews];
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    if ([defaults boolForKey:YGDirectLoginDidCallGotoLoginKey]) {
        NSString * t = [YGSecretCodec accessTicket];
        NSString * p = [YGSecretCodec accessPhrase];
        if (t.length > 0 && p.length > 0) {
            UIView *loadingView = self.view.window ?: self.navigationController.view ?: self.view;
            [YGHUDHelper showLoadingAddedTo:loadingView text:@"Loading..."];
            __weak typeof(self) weakSelf = self;
            [YGAppRouter switchToWebContainerInterfaceWithInitialLoadHandler:^(BOOL loadSuccess) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    __strong typeof(weakSelf) self = weakSelf;
                    [YGHUDHelper hideLoadingForView:loadingView];
                    if (!self) {
                        return;
                    }
                    if (!loadSuccess) {
                        [YGHUDHelper showCenterText:@"Load failed. Please try again." inView:self.navigationController.view ?: self.view];
                    }
                });
            }];
        }
    }
}

- (void)setupSubviews {
    UIImageView *logoImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"logo"]];
    logoImageView.translatesAutoresizingMaskIntoConstraints = NO;
    logoImageView.contentMode = UIViewContentModeScaleAspectFit;

    UIButton *loginButton = [UIButton buttonWithType:UIButtonTypeSystem];
    loginButton.translatesAutoresizingMaskIntoConstraints = NO;
    [loginButton setTitle:@"Login" forState:UIControlStateNormal];
    [loginButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    loginButton.titleLabel.font = [UIFont systemFontOfSize:18.0 weight:UIFontWeightSemibold];
    loginButton.backgroundColor = [self colorWithHexString:@"#B829FF"];
    loginButton.layer.cornerRadius = 30.0;
    loginButton.clipsToBounds = YES;
    [loginButton addTarget:self action:@selector(loginButtonTapped) forControlEvents:UIControlEventTouchUpInside];

    [self.view addSubview:logoImageView];
    [self.view addSubview:loginButton];

    [NSLayoutConstraint activateConstraints:@[
        [logoImageView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [logoImageView.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor constant:-120.0],
        [logoImageView.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.view.leadingAnchor constant:40.0],
        [logoImageView.trailingAnchor constraintLessThanOrEqualToAnchor:self.view.trailingAnchor constant:-40.0],

        [loginButton.topAnchor constraintEqualToAnchor:logoImageView.bottomAnchor constant:62.0],
        [loginButton.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:32.0],
        [loginButton.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-32.0],
        [loginButton.heightAnchor constraintEqualToConstant:60.0]
    ]];
}

- (UIColor *)colorWithHexString:(NSString *)hexString {
    NSString *value = [[hexString stringByReplacingOccurrencesOfString:@"#" withString:@""] uppercaseString];
    if (value.length != 6) {
        return UIColor.clearColor;
    }

    unsigned int red = 0;
    unsigned int green = 0;
    unsigned int blue = 0;
    [[NSScanner scannerWithString:[value substringWithRange:NSMakeRange(0, 2)]] scanHexInt:&red];
    [[NSScanner scannerWithString:[value substringWithRange:NSMakeRange(2, 2)]] scanHexInt:&green];
    [[NSScanner scannerWithString:[value substringWithRange:NSMakeRange(4, 2)]] scanHexInt:&blue];

    return [UIColor colorWithRed:red / 255.0 green:green / 255.0 blue:blue / 255.0 alpha:1.0];
}

- (void)loginButtonTapped {
    UIView *loadingView = self.view.window ?: self.navigationController.view ?: self.view;
    [YGHUDHelper showLoadingAddedTo:loadingView text:@"Loading..."];

    __weak typeof(self) weakSelf = self;
    [[YGRootManager controlHub] bindGuestSessionWithReply:^(BOOL success) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) self = weakSelf;
            if (!self) {
                [YGHUDHelper hideLoadingForView:loadingView];
                return;
            }

            if (success) {
                [YGAppRouter switchToWebContainerInterfaceWithInitialLoadHandler:^(BOOL loadSuccess) {
                    __strong typeof(weakSelf) self = weakSelf;
                    [YGHUDHelper hideLoadingForView:loadingView];
                    if (!self) {
                        return;
                    }
                    if (!loadSuccess) {
                        [YGHUDHelper showCenterText:@"Load failed. Please try again." inView:self.navigationController.view ?: self.view];
                    }
                }];
            } else {
                [YGHUDHelper hideLoadingForView:loadingView];
                [YGHUDHelper showCenterText:@"Login failed. Please try again." inView:self.navigationController.view ?: self.view];
            }
        });
    }];
}

@end
