//
//  YGForgotPasswordViewController.m
//  Yaga
//

#import "YGForgotPasswordViewController.h"
#import "YGAuthValidator.h"
#import "YGHUDHelper.h"
#import "YGUserStore.h"

@interface YGForgotPasswordViewController () <UITextFieldDelegate>

@property (nonatomic, strong) UITextField *emailField;
@property (nonatomic, strong) UITextField *passwordField;
@property (nonatomic, strong) UITextField *confirmPasswordField;

@end

@implementation YGForgotPasswordViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"Forget password";
    self.view.backgroundColor = UIColor.whiteColor;
    [self setupSubviews];
}

- (void)setupSubviews {
    UIStackView *stackView = [[UIStackView alloc] init];
    stackView.translatesAutoresizingMaskIntoConstraints = NO;
    stackView.axis = UILayoutConstraintAxisVertical;
    stackView.spacing = 16.0;
    [self.view addSubview:stackView];

    UILabel *emailLabel = [self fieldTitleLabelWithText:@"Email"];
    UILabel *passwordLabel = [self fieldTitleLabelWithText:@"Password"];
    UILabel *confirmPasswordLabel = [self fieldTitleLabelWithText:@"Confirm password"];

    self.emailField = [self textFieldWithPlaceholder:@"Email"];
    self.emailField.keyboardType = UIKeyboardTypeEmailAddress;
    self.emailField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.passwordField = [self secureTextFieldWithPlaceholder:@"Password"];
    self.confirmPasswordField = [self secureTextFieldWithPlaceholder:@"Enter the password again"];

    UIButton *resetButton = [self primaryButtonWithTitle:@"Save" action:@selector(resetButtonTapped)];

    [stackView addArrangedSubview:emailLabel];
    [stackView addArrangedSubview:self.emailField];
    [stackView addArrangedSubview:passwordLabel];
    [stackView addArrangedSubview:self.passwordField];
    [stackView addArrangedSubview:confirmPasswordLabel];
    [stackView addArrangedSubview:self.confirmPasswordField];
    [stackView addArrangedSubview:resetButton];

    [NSLayoutConstraint activateConstraints:@[
        [stackView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:72.0],
        [stackView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:24.0],
        [stackView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-24.0],
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

- (void)resetButtonTapped {
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

    [YGHUDHelper showLoadingAddedTo:self.view text:@"Updating password..."];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSString *errorMessage = nil;
        BOOL success = [[YGUserStore sharedStore] resetPasswordWithEmail:email
                                                             newPassword:password
                                                                   error:&errorMessage];
        [YGHUDHelper hideLoadingForView:self.view];
        if (!success) {
            [YGHUDHelper showText:errorMessage ?: @"Unable to reset password." inView:self.view];
            return;
        }
        [YGHUDHelper showText:@"Password updated." inView:self.view];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.navigationController popViewControllerAnimated:YES];
        });
    });
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
        [self resetButtonTapped];
    }
    return YES;
}

@end
