//
//  YGDirectLoginViewController.m
//  Yaga
//

#import "YGDirectLoginViewController.h"
#import "YGAppRouter.h"
#import "YGRootManager.h"
#import "YGSignInViewController.h"
#import "YGWebViewController.h"
#import "YGPopupAlertView.h"
#import "YGHUDHelper.h"

static NSString * const YGDirectLoginDidCallGotoLoginKey = @"yaga.directLogin.didCallGotoLogin";

@interface YGDirectLoginViewController () <UITextViewDelegate>

@property (nonatomic, strong) UIButton *agreementCheckButton;
@property (nonatomic, assign) BOOL agreementSelected;

@end

@implementation YGDirectLoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = UIColor.whiteColor;
    self.title = @"";
    self.agreementSelected = YES;
    [self setupSubviews];
}

- (void)setupSubviews {
    UIImageView *logoImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"logo"]];
    logoImageView.translatesAutoresizingMaskIntoConstraints = NO;
    logoImageView.contentMode = UIViewContentModeScaleAspectFit;

    UIButton *loginButton = [UIButton buttonWithType:UIButtonTypeSystem];
    loginButton.translatesAutoresizingMaskIntoConstraints = NO;
    [loginButton setTitle:@"Login by email" forState:UIControlStateNormal];
    [loginButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    loginButton.titleLabel.font = [UIFont systemFontOfSize:18.0 weight:UIFontWeightSemibold];
    loginButton.backgroundColor = [self colorWithHexString:@"#B829FF"];
    loginButton.layer.cornerRadius = 30.0;
    loginButton.clipsToBounds = YES;
    [loginButton addTarget:self action:@selector(loginButtonTapped) forControlEvents:UIControlEventTouchUpInside];

    UITextView *agreementTextView = [self textViewWithAttributedText:[self agreementAttributedText]];
    agreementTextView.textAlignment = NSTextAlignmentLeft;

    self.agreementCheckButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.agreementCheckButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.agreementCheckButton.layer.cornerRadius = 8.0;
    self.agreementCheckButton.layer.borderWidth = 1.5;
    self.agreementCheckButton.layer.borderColor = [self colorWithHexString:@"#808080"].CGColor;
    self.agreementCheckButton.titleLabel.font = [UIFont systemFontOfSize:12.0 weight:UIFontWeightBold];
    [self.agreementCheckButton addTarget:self action:@selector(agreementCheckButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self updateAgreementCheckButton];

    [self.view addSubview:logoImageView];
    [self.view addSubview:loginButton];
    [self.view addSubview:self.agreementCheckButton];
    [self.view addSubview:agreementTextView];

    [NSLayoutConstraint activateConstraints:@[
        [logoImageView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [logoImageView.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor constant:-120.0],
        [logoImageView.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.view.leadingAnchor constant:40.0],
        [logoImageView.trailingAnchor constraintLessThanOrEqualToAnchor:self.view.trailingAnchor constant:-40.0],

        [loginButton.topAnchor constraintEqualToAnchor:logoImageView.bottomAnchor constant:62.0],
        [loginButton.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:32.0],
        [loginButton.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-32.0],
        [loginButton.heightAnchor constraintEqualToConstant:60.0],

        [self.agreementCheckButton.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:32.0],
        [self.agreementCheckButton.centerYAnchor constraintEqualToAnchor:agreementTextView.centerYAnchor],
        [self.agreementCheckButton.widthAnchor constraintEqualToConstant:16.0],
        [self.agreementCheckButton.heightAnchor constraintEqualToConstant:16.0],

        [agreementTextView.leadingAnchor constraintEqualToAnchor:self.agreementCheckButton.trailingAnchor constant:8.0],
        [agreementTextView.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.view.leadingAnchor constant:24.0],
        [agreementTextView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-16.0],
        [agreementTextView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-30.0]
    ]];
}

- (UITextView *)textViewWithAttributedText:(NSAttributedString *)attributedText {
    UITextView *textView = [[UITextView alloc] init];
    textView.translatesAutoresizingMaskIntoConstraints = NO;
    textView.delegate = self;
    textView.attributedText = attributedText;
    textView.backgroundColor = UIColor.clearColor;
    textView.textContainerInset = UIEdgeInsetsZero;
    textView.textContainer.lineFragmentPadding = 0.0;
    textView.scrollEnabled = NO;
    textView.editable = NO;
    textView.selectable = YES;
    textView.textAlignment = NSTextAlignmentCenter;
    textView.linkTextAttributes = @{};
    return textView;
}

- (NSAttributedString *)agreementAttributedText {
    NSString *text = @"Agree with User Agreement and Privacy Policy";
    NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:text];
    NSDictionary *baseAttributes = @{
        NSFontAttributeName: [UIFont systemFontOfSize:14.0],
        NSForegroundColorAttributeName: [self colorWithHexString:@"#808080"]
    };
    [attributedText addAttributes:baseAttributes range:NSMakeRange(0, text.length)];

    NSRange userAgreementRange = [text rangeOfString:@"User Agreement"];
    NSRange privacyPolicyRange = [text rangeOfString:@"Privacy Policy"];
    NSDictionary *linkAttributes = @{
        NSForegroundColorAttributeName: [self colorWithHexString:@"#000000"],
        NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle)
    };
    [attributedText addAttributes:linkAttributes range:userAgreementRange];
    [attributedText addAttributes:linkAttributes range:privacyPolicyRange];
    [attributedText addAttribute:NSLinkAttributeName value:@"action://user-agreement" range:userAgreementRange];
    [attributedText addAttribute:NSLinkAttributeName value:@"action://privacy-policy" range:privacyPolicyRange];

    return attributedText;
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
    if (![self validateAgreementSelected]) {
        return;
    }

    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    if (![defaults boolForKey:YGDirectLoginDidCallGotoLoginKey]) {
        [defaults setBool:YES forKey:YGDirectLoginDidCallGotoLoginKey];
        [[YGRootManager shared] gotoLoginWithCompletion:^(BOOL success) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (success) {
                    [YGAppRouter switchToWebContainerInterface];
                } else {
                    [YGHUDHelper showCenterText:@"Login failed. Please try again." inView:self.navigationController.view ?: self.view];
                }
            });
        }];
        return;
    }

    [self.navigationController pushViewController:[[YGSignInViewController alloc] init] animated:YES];
}

- (void)agreementCheckButtonTapped {
    self.agreementSelected = !self.agreementSelected;
    [self updateAgreementCheckButton];
}

- (void)updateAgreementCheckButton {
    UIColor *selectedColor = [self colorWithHexString:@"#B829FF"];
    UIColor *normalColor = [self colorWithHexString:@"#808080"];
    self.agreementCheckButton.backgroundColor = self.agreementSelected ? selectedColor : UIColor.clearColor;
    self.agreementCheckButton.layer.borderColor = (self.agreementSelected ? selectedColor : normalColor).CGColor;
    [self.agreementCheckButton setTitle:self.agreementSelected ? @"✓" : @"" forState:UIControlStateNormal];
    [self.agreementCheckButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
}

- (BOOL)validateAgreementSelected {
    if (self.agreementSelected) {
        return YES;
    }

    UIView *targetView = self.navigationController.view ?: self.view;
    [YGPopupAlertView showInView:targetView
                        iconName:@"hint.png"
                         message:@"Please agree to the User Agreement\nand Privacy Policy first."
                 leftButtonTitle:@"Cancel"
                rightButtonTitle:@"OK"];
    return NO;
}

- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange interaction:(UITextItemInteraction)interaction {
    NSString *action = URL.absoluteString;
    if ([action isEqualToString:@"action://user-agreement"]) {
        [self userAgreementTapped];
        return NO;
    }

    if ([action isEqualToString:@"action://privacy-policy"]) {
        [self privacyPolicyTapped];
        return NO;
    }

    return YES;
}

- (void)userAgreementTapped {
    YGWebViewController *controller = [[YGWebViewController alloc] initWithTitle:@"User Agreement"
                                                                       URLString:@"https://app.i32823wk.link/users"];
    [self.navigationController pushViewController:controller animated:YES];
}

- (void)privacyPolicyTapped {
    YGWebViewController *controller = [[YGWebViewController alloc] initWithTitle:@"Privacy Agreement"
                                                                       URLString:@"https://app.i32823wk.link/privacy"];
    [self.navigationController pushViewController:controller animated:YES];
}

@end
