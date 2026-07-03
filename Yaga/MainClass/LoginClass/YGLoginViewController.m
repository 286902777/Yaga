//
//  YGLoginViewController.m
//  Yaga
//

#import "YGLoginViewController.h"
#import "YGRegisterViewController.h"
#import "YGSignInViewController.h"
#import "YGWebViewController.h"
#import "YGAppRouter.h"
#import "YGPopupAlertView.h"
#import "YGUserStore.h"
#import "YGEULAAlertView.h"
#include <stdlib.h>

static NSString * const YGLoginEULAAgreedKey = @"com.yaga.login.eulaAgreed";

@interface YGLoginViewController () <UITextViewDelegate>

@property (nonatomic, strong) UIButton *registerButton;
@property (nonatomic, strong) CAGradientLayer *registerGradientLayer;
@property (nonatomic, strong) UIButton *agreementCheckButton;
@property (nonatomic, assign) BOOL agreementSelected;
@property (nonatomic, assign) BOOL eulaShowing;

@end

@implementation YGLoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = UIColor.whiteColor;
    self.title = @"";
    [self setupSubviews];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self showEULAIfNeeded];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    self.registerGradientLayer.frame = self.registerButton.bounds;
    self.registerGradientLayer.cornerRadius = self.registerButton.layer.cornerRadius;
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
    
    self.registerButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.registerButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.registerButton setTitle:@"I'm new" forState:UIControlStateNormal];
    [self.registerButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    self.registerButton.titleLabel.font = [UIFont systemFontOfSize:18.0 weight:UIFontWeightSemibold];
    self.registerButton.layer.cornerRadius = 30.0;
    self.registerButton.clipsToBounds = YES;
    [self.registerButton addTarget:self action:@selector(guestLoginTapped) forControlEvents:UIControlEventTouchUpInside];
    
    self.registerGradientLayer = [CAGradientLayer layer];
    self.registerGradientLayer.colors = @[
        (__bridge id)[self colorWithHexString:@"#B829FF"].CGColor,
        (__bridge id)[self colorWithHexString:@"#FC2087"].CGColor,
        (__bridge id)[self colorWithHexString:@"#FFA787"].CGColor
    ];
    self.registerGradientLayer.startPoint = CGPointMake(0.0, 0.5);
    self.registerGradientLayer.endPoint = CGPointMake(1.0, 0.5);
    self.registerGradientLayer.locations = @[@0.0, @0.5, @1.0];
    [self.registerButton.layer insertSublayer:self.registerGradientLayer atIndex:0];
    
    [self.view addSubview:logoImageView];
    [self.view addSubview:loginButton];
    [self.view addSubview:self.registerButton];
    
    UITextView *signUpTextView = [self textViewWithAttributedText:[self signUpAttributedText]];
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
    
    [self.view addSubview:signUpTextView];
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
        
        [self.registerButton.topAnchor constraintEqualToAnchor:loginButton.bottomAnchor constant:15.0],
        [self.registerButton.leadingAnchor constraintEqualToAnchor:loginButton.leadingAnchor],
        [self.registerButton.trailingAnchor constraintEqualToAnchor:loginButton.trailingAnchor],
        [self.registerButton.heightAnchor constraintEqualToConstant:60.0],
        
        [signUpTextView.topAnchor constraintEqualToAnchor:self.registerButton.bottomAnchor constant:20.0],
        [signUpTextView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [signUpTextView.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.view.leadingAnchor constant:24.0],
        [signUpTextView.trailingAnchor constraintLessThanOrEqualToAnchor:self.view.trailingAnchor constant:-24.0],
        
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

- (NSAttributedString *)signUpAttributedText {
    NSString *text = @"Don't have an account? Sign up";
    NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:text];
    NSDictionary *baseAttributes = @{
        NSFontAttributeName: [UIFont systemFontOfSize:14.0],
        NSForegroundColorAttributeName: [self colorWithHexString:@"#808080"]
    };
    [attributedText addAttributes:baseAttributes range:NSMakeRange(0, text.length)];
    
    NSRange signUpRange = [text rangeOfString:@"Sign up"];
    [attributedText addAttributes:@{
        NSForegroundColorAttributeName: [self colorWithHexString:@"#000000"],
        NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle),
        NSLinkAttributeName: @"action://signup"
    } range:signUpRange];
    
    return attributedText;
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
    [self.navigationController pushViewController:[[YGSignInViewController alloc] init] animated:YES];
}

- (void)showEULAIfNeeded {
    if (self.eulaShowing || [NSUserDefaults.standardUserDefaults boolForKey:YGLoginEULAAgreedKey]) {
        return;
    }

    self.eulaShowing = YES;
    __weak typeof(self) weakSelf = self;
    UIView *targetView = self.navigationController.view ?: self.view;
    [YGEULAAlertView showInView:targetView
                        message:[self eulaMessage]
                  cancelHandler:^{
        exit(0);
    } agreeHandler:^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [NSUserDefaults.standardUserDefaults setBool:YES forKey:YGLoginEULAAgreedKey];
        [NSUserDefaults.standardUserDefaults synchronize];
        strongSelf.eulaShowing = NO;
    }];
}

- (NSString *)eulaMessage {
    return @"This End User License Agreement (EULA) governs your use of the Yaga Application (hereinafter referred to as the \"App\"), a yoga video sharing platform. By downloading, accessing or using the App, you agree to be bound by this Agreement. If you do not agree to these terms, you may not use this application.\n"
    "1. Qualifications\n"
    "By using the Yaga App (the \"App\"), you confirm that you are at least 18 years of age. You agree to provide true and accurate age information during registration or use. If you are under the age of 18, you need the express consent of a parent or legal guardian to use the App.\n"
    "2. User Generated Content\n"
    "This app allows users to post and share yoga-related video content.\n"
    "By posting content, you agree to the following terms:\n"
    "Prohibited Content\n"
    "You may not post any content that is offensive, harmful or illegal, including but not limited to:\n"
    "- Hate speech, abuse, harassment or personal attacks targeting other users, yoga instructors, bloggers or related personnel;\n"
    "- Pornographic, explicit or vulgar content;\n"
    "- Content that promotes violence, discrimination, illegal activities or violations of the rights of others;\n"
    "- Any content that disrupts the positive and healthy yoga community atmosphere, violates public order and good customs, or is irrelevant to yoga;\n"
    "- Content that infringes on the intellectual property rights of others.\n"
    "Content Licensing\n"
    "You retain ownership of the content posted, but by posting, you grant Yaga a non-exclusive license to use, distribute, display, and provide yoga-related content recommendations within the App. This license shall remain in effect until you delete the posted content or terminate your account.\n"
    "3. Reporting and Response Mechanism\n"
    "3.1 Your Responsibilities\n"
    "If you become aware of User content that violates this EULA, you agree to report it immediately through Yaga's built-in reporting mechanism.\n"
    "3.2 Our Response\n"
    "We will review the reported content within 24 hours and take appropriate measures based on the severity of the violation, including but not limited to removing the offending content, warning the offending user, restricting the user's posting rights, or banning the offending user. Users who repeatedly violate the rules or commit serious violations may face permanent suspension of their accounts.\n"
    "4. Privacy Policy\n"
    "By using the App, you acknowledge that you have read and understood our [Privacy Policy], which details how we collect, use, store and protect your personal information.\n"
    "5. Termination\n"
    "We may terminate or suspend your access to Yaga at any time for any reason, with or without prior notice. You can also stop using Yaga and delete your account at any time; upon account deletion, your posted content will be removed in a timely manner.\n"
    "6. Modification of the Agreement\n"
    "We may amend this Agreement at any time to adapt to changes in laws and regulations or adjustments to the App’s functions. Changes will be announced in the App, and your continued use of the App after the announcement of the changes means your acceptance of the revised terms. If you do not agree to the revised terms, you should stop using the App immediately.\n"
    "7. Disclaimer\n"
    "Yaga is provided \"AS IS\" without warranties of any kind, express or implied. We do not guarantee that the application will always be interruption-free, error-free or completely secure.\n"
    "8. Limitation of Liability\n"
    "To the fullest extent permitted by law, we are not liable for any direct, indirect, incidental, consequential or special damages caused by your use of Yaga.";
}

- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange interaction:(UITextItemInteraction)interaction {
    NSString *action = URL.absoluteString;
    if ([action isEqualToString:@"action://signup"]) {
        [self signUpTextTapped];
        return NO;
    }
    
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

- (void)guestLoginTapped {
    if (![self validateAgreementSelected]) {
        return;
    }
    [[YGUserStore sharedStore] enterGuestMode];
    [YGAppRouter switchToMainInterface];
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

- (void)signUpTextTapped {
    [self.navigationController pushViewController:[[YGRegisterViewController alloc] init] animated:YES];
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
