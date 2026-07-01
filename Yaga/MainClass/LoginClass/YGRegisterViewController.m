//
//  YGRegisterViewController.m
//  Yaga
//

#import "YGRegisterViewController.h"
#import "YGAuthValidator.h"
#import "YGHUDHelper.h"
#import "YGRegisterProfileViewController.h"

@interface YGRegisterViewController () <UITextFieldDelegate>

@property (nonatomic, strong) UITextField *emailField;
@property (nonatomic, strong) UITextField *passwordField;
@property (nonatomic, strong) UITextField *confirmPasswordField;

@end

@implementation YGRegisterViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"Sign up";
    self.view.backgroundColor = UIColor.whiteColor;
    [self setupSubviews];
}

- (void)setupSubviews {
    UILabel *emailLabel = [self fieldTitleLabelWithText:@"Email"];
    UILabel *passwordLabel = [self fieldTitleLabelWithText:@"Password"];
    UILabel *confirmPasswordLabel = [self fieldTitleLabelWithText:@"Confirm password"];

    self.emailField = [self textFieldWithPlaceholder:@"Email"];
    self.emailField.keyboardType = UIKeyboardTypeEmailAddress;
    self.emailField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.passwordField = [self secureTextFieldWithPlaceholder:@"Password"];
    self.confirmPasswordField = [self secureTextFieldWithPlaceholder:@"Confirm password"];

    UIButton *registerButton = [self primaryButtonWithTitle:@"Sign up" action:@selector(registerButtonTapped)];

    [self.view addSubview:emailLabel];
    [self.view addSubview:self.emailField];
    [self.view addSubview:passwordLabel];
    [self.view addSubview:self.passwordField];
    [self.view addSubview:confirmPasswordLabel];
    [self.view addSubview:self.confirmPasswordField];
    [self.view addSubview:registerButton];

    [NSLayoutConstraint activateConstraints:@[
        [emailLabel.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:72.0],
        [emailLabel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:32.0],
        [emailLabel.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-32.0],

        [self.emailField.topAnchor constraintEqualToAnchor:emailLabel.bottomAnchor constant:12.0],
        [self.emailField.leadingAnchor constraintEqualToAnchor:emailLabel.leadingAnchor],
        [self.emailField.trailingAnchor constraintEqualToAnchor:emailLabel.trailingAnchor],
        [self.emailField.heightAnchor constraintEqualToConstant:44.0],

        [passwordLabel.topAnchor constraintEqualToAnchor:self.emailField.bottomAnchor constant:24.0],
        [passwordLabel.leadingAnchor constraintEqualToAnchor:self.emailField.leadingAnchor],
        [passwordLabel.trailingAnchor constraintEqualToAnchor:self.emailField.trailingAnchor],

        [self.passwordField.topAnchor constraintEqualToAnchor:passwordLabel.bottomAnchor constant:12.0],
        [self.passwordField.leadingAnchor constraintEqualToAnchor:self.emailField.leadingAnchor],
        [self.passwordField.trailingAnchor constraintEqualToAnchor:self.emailField.trailingAnchor],
        [self.passwordField.heightAnchor constraintEqualToConstant:44.0],

        [confirmPasswordLabel.topAnchor constraintEqualToAnchor:self.passwordField.bottomAnchor constant:24.0],
        [confirmPasswordLabel.leadingAnchor constraintEqualToAnchor:self.passwordField.leadingAnchor],
        [confirmPasswordLabel.trailingAnchor constraintEqualToAnchor:self.passwordField.trailingAnchor],

        [self.confirmPasswordField.topAnchor constraintEqualToAnchor:confirmPasswordLabel.bottomAnchor constant:12.0],
        [self.confirmPasswordField.leadingAnchor constraintEqualToAnchor:self.passwordField.leadingAnchor],
        [self.confirmPasswordField.trailingAnchor constraintEqualToAnchor:self.passwordField.trailingAnchor],
        [self.confirmPasswordField.heightAnchor constraintEqualToConstant:44.0],

        [registerButton.topAnchor constraintEqualToAnchor:self.confirmPasswordField.bottomAnchor constant:60.0],
        [registerButton.leadingAnchor constraintEqualToAnchor:self.confirmPasswordField.leadingAnchor],
        [registerButton.trailingAnchor constraintEqualToAnchor:self.confirmPasswordField.trailingAnchor],
        [registerButton.heightAnchor constraintEqualToConstant:56.0],
    ]];
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
    textField.autocorrectionType = UITextAutocorrectionTypeNo;
    textField.clearButtonMode = UITextFieldViewModeWhileEditing;
    textField.delegate = self;
    [textField.heightAnchor constraintEqualToConstant:44.0].active = YES;
    return textField;
}

- (UITextField *)secureTextFieldWithPlaceholder:(NSString *)placeholder {
    UITextField *textField = [self textFieldWithPlaceholder:placeholder];
    textField.secureTextEntry = YES;
    return textField;
}

- (UILabel *)fieldTitleLabelWithText:(NSString *)text {
    UILabel *label = [[UILabel alloc] init];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.text = text;
    label.textColor = UIColor.blackColor;
    label.font = [UIFont systemFontOfSize:16.0 weight:UIFontWeightMedium];
    return label;
}

- (UIButton *)primaryButtonWithTitle:(NSString *)title action:(SEL)action {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:18.0 weight:UIFontWeightSemibold];
    button.backgroundColor = [UIColor colorWithRed:0.72 green:0.16 blue:1.0 alpha:1.0];
    button.layer.cornerRadius = 28.0;
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    [button.heightAnchor constraintEqualToConstant:56.0].active = YES;
    return button;
}

- (void)registerButtonTapped {
    [self.view endEditing:YES];

    NSString *email = [self trimmedString:self.emailField.text];
    NSString *password = self.passwordField.text ?: @"";
    NSString *confirmPassword = self.confirmPasswordField.text ?: @"";

    if (![YGAuthValidator isValidEmail:email]) {
        [YGHUDHelper showText:@"Please enter a valid email." inView:self.view];
        return;
    }
    if (![YGAuthValidator isValidPassword:password]) {
        [YGHUDHelper showText:@"Password must be at least 6 characters." inView:self.view];
        return;
    }
    if (![password isEqualToString:confirmPassword]) {
        [YGHUDHelper showText:@"Passwords do not match." inView:self.view];
        return;
    }

    YGRegisterProfileViewController *controller = [[YGRegisterProfileViewController alloc] initWithEmail:email password:password];
    [self.navigationController pushViewController:controller animated:YES];
}

- (NSString *)trimmedString:(NSString *)text {
    return [text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.emailField) {
        [self.passwordField becomeFirstResponder];
    } else if (textField == self.passwordField) {
        [self.confirmPasswordField becomeFirstResponder];
    } else {
        [textField resignFirstResponder];
        [self registerButtonTapped];
    }
    return YES;
}

@end
