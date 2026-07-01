//
//  YGSubmitViewController.m
//  Yaga
//

#import "YGSubmitViewController.h"
#import "YGPopupAlertView.h"
#import "YGRechargeViewController.h"
#import "YGSubmitAnswerViewController.h"
#import "YGHUDHelper.h"
#import "YGKeyboardHandler.h"
#import "YGUserStore.h"
#import "YGAppRouter.h"

static NSInteger const YGSubmitCost = 200;

@interface YGSubmitViewController () <UITextViewDelegate>

@property (nonatomic, strong) UIButton *rightIconButton;
@property (nonatomic, strong) UIImageView *topImageView;
@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, strong) UILabel *placeholderLabel;
@property (nonatomic, strong) UIButton *submitButton;
@property (nonatomic, strong) UIImageView *submitDiamondImageView;
@property (nonatomic, strong) NSLayoutConstraint *submitButtonBottomConstraint;
@property (nonatomic, strong) YGKeyboardHandler *keyboardHandler;

@end

@implementation YGSubmitViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = UIColor.whiteColor;
    [self setupSubviews];
    [self setupKeyboardHandler];
}

- (void)setupSubviews {
//    self.rightIconButton = [UIButton buttonWithType:UIButtonTypeCustom];
//    self.rightIconButton.translatesAutoresizingMaskIntoConstraints = NO;
//    self.rightIconButton.backgroundColor = UIColor.clearColor;
//    self.rightIconButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
//    [self.rightIconButton setImage:[UIImage imageNamed:@"suright"] forState:UIControlStateNormal];
//    [self.rightIconButton.widthAnchor constraintEqualToConstant:40.0].active = YES;
//    [self.rightIconButton.heightAnchor constraintEqualToConstant:40.0].active = YES;
//    [self yg_setRightView:self.rightIconButton];

    self.topImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"sutop"]];
    self.topImageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.topImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.topImageView.clipsToBounds = YES;
    [self.view addSubview:self.topImageView];

    self.textView = [[UITextView alloc] init];
    self.textView.translatesAutoresizingMaskIntoConstraints = NO;
    self.textView.backgroundColor = UIColor.whiteColor;
    self.textView.textColor = UIColor.blackColor;
    self.textView.font = [UIFont systemFontOfSize:16.0];
    self.textView.layer.cornerRadius = 20.0;
    self.textView.clipsToBounds = YES;
    self.textView.textContainerInset = UIEdgeInsetsMake(16.0, 14.0, 16.0, 14.0);
    self.textView.delegate = self;
    [self.view addSubview:self.textView];

    self.placeholderLabel = [[UILabel alloc] init];
    self.placeholderLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.placeholderLabel.text = @"Please enter";
    self.placeholderLabel.textColor = [UIColor colorWithWhite:0.62 alpha:1.0];
    self.placeholderLabel.font = [UIFont systemFontOfSize:16.0];
    [self.textView addSubview:self.placeholderLabel];

    self.submitButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.submitButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.submitButton setTitle:@"Submit" forState:UIControlStateNormal];
    [self.submitButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    self.submitButton.titleLabel.font = [UIFont systemFontOfSize:18.0 weight:UIFontWeightSemibold];
    self.submitButton.backgroundColor = [self colorWithHexString:@"#B829FF"];
    self.submitButton.layer.cornerRadius = 28.0;
    self.submitButton.clipsToBounds = YES;
    [self.submitButton addTarget:self action:@selector(submitButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.submitButton];

    self.submitDiamondImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"dediamond"]];
    self.submitDiamondImageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.submitDiamondImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.submitDiamondImageView.userInteractionEnabled = NO;
    [self.view addSubview:self.submitDiamondImageView];
    [self.view bringSubviewToFront:self.submitDiamondImageView];
    self.submitButtonBottomConstraint = [self.submitButton.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-20.0];

    [NSLayoutConstraint activateConstraints:@[
        [self.topImageView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:20.0],
        [self.topImageView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20.0],
        [self.topImageView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20.0],
        [self.topImageView.heightAnchor constraintEqualToAnchor:self.topImageView.widthAnchor multiplier:145.0 / 335.0],

        [self.textView.topAnchor constraintEqualToAnchor:self.topImageView.bottomAnchor constant:20.0],
        [self.textView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20.0],
        [self.textView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20.0],
        [self.textView.heightAnchor constraintEqualToAnchor:self.textView.widthAnchor multiplier:197.0 / 335.0],

        [self.placeholderLabel.topAnchor constraintEqualToAnchor:self.textView.topAnchor constant:16.0],
        [self.placeholderLabel.leadingAnchor constraintEqualToAnchor:self.textView.leadingAnchor constant:19.0],
        [self.placeholderLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.textView.trailingAnchor constant:-16.0],

        [self.submitButton.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20.0],
        [self.submitButton.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20.0],
        self.submitButtonBottomConstraint,
        [self.submitButton.heightAnchor constraintEqualToConstant:56.0],

        [self.submitDiamondImageView.topAnchor constraintEqualToAnchor:self.submitButton.topAnchor constant:-14.0],
        [self.submitDiamondImageView.trailingAnchor constraintEqualToAnchor:self.submitButton.trailingAnchor constant:-36.0],
        [self.submitDiamondImageView.widthAnchor constraintEqualToConstant:74.0],
        [self.submitDiamondImageView.heightAnchor constraintEqualToConstant:28.0]
    ]];
}

- (void)textViewDidChange:(UITextView *)textView {
    self.placeholderLabel.hidden = textView.text.length > 0;
}

- (void)submitButtonTapped {
    [self.view endEditing:YES];
    NSString *content = [self.textView.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (content.length == 0) {
        [YGHUDHelper showCenterText:@"Please enter content." inView:self.view];
        return;
    }

    if (![[YGUserStore sharedStore] canPerformSensitiveAction]) {
        [self presentLoginAlert];
        return;
    }

    if ([[YGUserStore sharedStore] currentUserBalance] < YGSubmitCost) {
        [self showRechargeAlert];
        return;
    }

    NSString *errorMessage = nil;
    BOOL success = [[YGUserStore sharedStore] deductBalanceFromCurrentUser:YGSubmitCost error:&errorMessage];
    if (!success) {
        [YGHUDHelper showCenterText:errorMessage ?: @"Submit failed." inView:self.view];
        return;
    }

    YGSubmitAnswerViewController *viewController = [[YGSubmitAnswerViewController alloc] initWithQuestion:content];
    [self.navigationController pushViewController:viewController animated:YES];
}

- (void)showRechargeAlert {
    UIView *containerView = self.navigationController.view ?: self.view;
    [YGPopupAlertView showInView:containerView
                        iconName:@"diamond"
                         message:@"Your balance is not enough to complete this operation Please recharge first"
                 leftButtonTitle:@"Cancel"
                rightButtonTitle:@"Recharge"
             rightButtonHandler:^{
        YGRechargeViewController *viewController = [[YGRechargeViewController alloc] init];
        [self.navigationController pushViewController:viewController animated:YES];
    }];
}

- (void)presentLoginAlert {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Guest mode"
                                                                             message:@"Please sign in to submit."
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"Confirm" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction * _Nonnull action) {
        [[YGUserStore sharedStore] logout];
        [YGAppRouter switchToLoginInterface];
    }]];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)setupKeyboardHandler {
    __weak typeof(self) weakSelf = self;
    self.keyboardHandler = [[YGKeyboardHandler alloc] initWithView:self.view changeHandler:^(CGFloat keyboardHeight, NSTimeInterval duration, UIViewAnimationOptions options) {
        [weakSelf updateSubmitButtonForKeyboardHeight:keyboardHeight duration:duration options:options];
    }];
}

- (void)updateSubmitButtonForKeyboardHeight:(CGFloat)keyboardHeight duration:(NSTimeInterval)duration options:(UIViewAnimationOptions)options {
    CGFloat safeAreaBottom = self.view.safeAreaInsets.bottom;
    self.submitButtonBottomConstraint.constant = keyboardHeight > 0.0 ? -(keyboardHeight - safeAreaBottom + 12.0) : -20.0;
    [UIView animateWithDuration:duration
                          delay:0.0
                        options:options
                     animations:^{
        [self.view layoutIfNeeded];
    } completion:nil];
}

- (UIColor *)colorWithHexString:(NSString *)hexString {
    NSString *cleanString = [[hexString stringByReplacingOccurrencesOfString:@"#" withString:@""] uppercaseString];
    unsigned int value = 0;
    [[NSScanner scannerWithString:cleanString] scanHexInt:&value];
    return [UIColor colorWithRed:((value >> 16) & 0xFF) / 255.0
                           green:((value >> 8) & 0xFF) / 255.0
                            blue:(value & 0xFF) / 255.0
                           alpha:1.0];
}

@end
