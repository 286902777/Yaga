//
//  YGSignInViewController.m
//  Yaga
//

#import "YGSignInViewController.h"
#import "YGAppRouter.h"
#import "YGAuthValidator.h"
#import "YGForgotPasswordViewController.h"
#import "YGHUDHelper.h"
#import "YGUserStore.h"

@interface YGSignInViewController () <UITextFieldDelegate>

@property (nonatomic, strong) UITextField *emailField;
@property (nonatomic, strong) UITextField *passwordField;

@end

@implementation YGSignInViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"Sign in";
    self.view.backgroundColor = UIColor.whiteColor;
    [self setupSubviews];
}

- (void)setupSubviews {
    self.emailField = [self textFieldWithPlaceholder:@"Email"];
    self.emailField.keyboardType = UIKeyboardTypeEmailAddress;
    self.emailField.autocapitalizationType = UITextAutocapitalizationTypeNone;

    self.passwordField = [self textFieldWithPlaceholder:@"Password"];
    self.passwordField.secureTextEntry = YES;

    UIButton *forgotPasswordButton = [UIButton buttonWithType:UIButtonTypeSystem];
    forgotPasswordButton.translatesAutoresizingMaskIntoConstraints = NO;
    [forgotPasswordButton setTitle:@"Forget password?" forState:UIControlStateNormal];
    [forgotPasswordButton setTitleColor:[self colorWithHexString:@"#000000"] forState:UIControlStateNormal];
    forgotPasswordButton.titleLabel.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightMedium];
    [forgotPasswordButton addTarget:self action:@selector(forgotPasswordTapped) forControlEvents:UIControlEventTouchUpInside];

    UIButton *loginButton = [UIButton buttonWithType:UIButtonTypeSystem];
    loginButton.translatesAutoresizingMaskIntoConstraints = NO;
    [loginButton setTitle:@"Login" forState:UIControlStateNormal];
    [loginButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    loginButton.titleLabel.font = [UIFont systemFontOfSize:18.0 weight:UIFontWeightSemibold];
    loginButton.backgroundColor = [self colorWithHexString:@"#B829FF"];
    loginButton.layer.cornerRadius = 30.0;
    loginButton.clipsToBounds = YES;
    [loginButton addTarget:self action:@selector(loginButtonTapped) forControlEvents:UIControlEventTouchUpInside];

    UILabel *emailLabel = [self fieldTitleLabelWithText:@"Email"];
    UILabel *passwordLabel = [self fieldTitleLabelWithText:@"Password"];

    [self.view addSubview:emailLabel];
    [self.view addSubview:self.emailField];
    [self.view addSubview:passwordLabel];
    [self.view addSubview:self.passwordField];
    [self.view addSubview:forgotPasswordButton];
    [self.view addSubview:loginButton];

    [NSLayoutConstraint activateConstraints:@[
        [emailLabel.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:72.0],
        [emailLabel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:32.0],
        [emailLabel.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-32.0],

        [self.emailField.topAnchor constraintEqualToAnchor:emailLabel.bottomAnchor constant:12.0],
        [self.emailField.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:32.0],
        [self.emailField.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-32.0],
        [self.emailField.heightAnchor constraintEqualToConstant:44.0],

        [passwordLabel.topAnchor constraintEqualToAnchor:self.emailField.bottomAnchor constant:24.0],
        [passwordLabel.leadingAnchor constraintEqualToAnchor:self.emailField.leadingAnchor],
        [passwordLabel.trailingAnchor constraintEqualToAnchor:self.emailField.trailingAnchor],

        [self.passwordField.topAnchor constraintEqualToAnchor:passwordLabel.bottomAnchor constant:12.0],
        [self.passwordField.leadingAnchor constraintEqualToAnchor:self.emailField.leadingAnchor],
        [self.passwordField.trailingAnchor constraintEqualToAnchor:self.emailField.trailingAnchor],
        [self.passwordField.heightAnchor constraintEqualToConstant:44.0],

        [forgotPasswordButton.topAnchor constraintEqualToAnchor:self.passwordField.bottomAnchor constant:10.0],
        [forgotPasswordButton.trailingAnchor constraintEqualToAnchor:self.passwordField.trailingAnchor],

        [loginButton.topAnchor constraintEqualToAnchor:self.passwordField.bottomAnchor constant:60.0],
        [loginButton.leadingAnchor constraintEqualToAnchor:self.passwordField.leadingAnchor],
        [loginButton.trailingAnchor constraintEqualToAnchor:self.passwordField.trailingAnchor],
        [loginButton.heightAnchor constraintEqualToConstant:60.0],
    ]];
}

- (UILabel *)fieldTitleLabelWithText:(NSString *)text {
    UILabel *label = [[UILabel alloc] init];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.text = text;
    label.textColor = UIColor.blackColor;
    label.font = [UIFont systemFontOfSize:16.0 weight:UIFontWeightMedium];
    return label;
}

- (UITextField *)textFieldWithPlaceholder:(NSString *)placeholder {
    UITextField *textField = [[UITextField alloc] init];
    textField.translatesAutoresizingMaskIntoConstraints = NO;
    textField.placeholder = placeholder;
    textField.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.92];
    textField.textColor = UIColor.blackColor;
    textField.font = [UIFont systemFontOfSize:16.0];
    textField.layer.cornerRadius = 22.0;
    textField.leftView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 16.0, 44.0)];
    textField.leftViewMode = UITextFieldViewModeAlways;
    textField.clearButtonMode = UITextFieldViewModeWhileEditing;
    textField.autocorrectionType = UITextAutocorrectionTypeNo;
    textField.delegate = self;
    [textField.heightAnchor constraintEqualToConstant:44.0].active = YES;
    return textField;
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
    [self.view endEditing:YES];

    NSString *email = [self trimmedString:self.emailField.text];
    NSString *password = self.passwordField.text ?: @"";
    if (![YGAuthValidator isValidEmail:email]) {
        [YGHUDHelper showText:@"Please enter a valid email." inView:self.view];
        return;
    }
    if (![YGAuthValidator isValidPassword:password]) {
        [YGHUDHelper showText:@"Password must be at least 6 characters." inView:self.view];
        return;
    }

    [YGHUDHelper showLoadingAddedTo:self.view text:@"Signing in..."];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSString *errorMessage = nil;
        BOOL success = [[YGUserStore sharedStore] loginWithEmail:email password:password error:&errorMessage];
        [YGHUDHelper hideLoadingForView:self.view];
        if (!success) {
            [YGHUDHelper showCenterText:errorMessage ?: @"Unable to sign in." inView:self.view];
            return;
        }
        [YGAppRouter switchToMainInterface];
    });
}

- (void)forgotPasswordTapped {
    [self.navigationController pushViewController:[[YGForgotPasswordViewController alloc] init] animated:YES];
}

- (NSString *)trimmedString:(NSString *)text {
    return [text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.emailField) {
        [self.passwordField becomeFirstResponder];
    } else {
        [textField resignFirstResponder];
        [self loginButtonTapped];
    }
    return YES;
}

@end
