//
//  YGReportViewController.m
//  Yaga
//

#import "YGReportViewController.h"
#import "YGKeyboardHandler.h"
#import "YGHUDHelper.h"

@interface YGReportViewController () <UITextViewDelegate>

@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) NSMutableArray<UIButton *> *reasonButtons;
@property (nonatomic, strong) UITextView *otherTextView;
@property (nonatomic, strong) UILabel *placeholderLabel;
@property (nonatomic, strong) UIButton *submitButton;
@property (nonatomic, strong) NSLayoutConstraint *contentTopConstraint;
@property (nonatomic, strong) NSLayoutConstraint *submitButtonBottomConstraint;
@property (nonatomic, strong) YGKeyboardHandler *keyboardHandler;
@property (nonatomic, assign) NSInteger selectedReasonIndex;

@end

@implementation YGReportViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = UIColor.whiteColor;
    self.selectedReasonIndex = 0;
    [self yg_setNavigationTitle:@"Report"];
    [self setupContent];
    [self setupKeyboardHandler];
}

- (void)setupContent {
    NSArray<NSString *> *reasons = @[
        @"Pornographic and vulgar",
        @"False information",
        @"Verbal attack",
        @"Violent terror",
        @"Copyright infringement",
        @"Frequent harassment"
    ];
    self.reasonButtons = [NSMutableArray arrayWithCapacity:reasons.count];

    self.contentView = [[UIView alloc] init];
    self.contentView.translatesAutoresizingMaskIntoConstraints = NO;
    self.contentView.backgroundColor = UIColor.clearColor;
    [self.view addSubview:self.contentView];

    UIStackView *reasonsStackView = [[UIStackView alloc] init];
    reasonsStackView.translatesAutoresizingMaskIntoConstraints = NO;
    reasonsStackView.axis = UILayoutConstraintAxisVertical;
    reasonsStackView.spacing = 8.0;
    reasonsStackView.distribution = UIStackViewDistributionFillEqually;
    [self.contentView addSubview:reasonsStackView];

    for (NSInteger index = 0; index < reasons.count; index++) {
        UIButton *button = [self reasonButtonWithTitle:reasons[index] index:index];
        [self.reasonButtons addObject:button];
        [reasonsStackView addArrangedSubview:button];
    }

    UILabel *otherLabel = [[UILabel alloc] init];
    otherLabel.translatesAutoresizingMaskIntoConstraints = NO;
    otherLabel.text = @"Other:";
    otherLabel.textColor = UIColor.blackColor;
    otherLabel.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightBold];
    [self.contentView addSubview:otherLabel];

    self.otherTextView = [[UITextView alloc] init];
    self.otherTextView.translatesAutoresizingMaskIntoConstraints = NO;
    self.otherTextView.backgroundColor = UIColor.whiteColor;
    self.otherTextView.textColor = UIColor.blackColor;
    self.otherTextView.font = [UIFont systemFontOfSize:13.0 weight:UIFontWeightRegular];
    self.otherTextView.delegate = self;
    self.otherTextView.layer.cornerRadius = 16.0;
    self.otherTextView.clipsToBounds = YES;
    self.otherTextView.textContainerInset = UIEdgeInsetsMake(16.0, 16.0, 16.0, 16.0);
    self.otherTextView.textContainer.lineFragmentPadding = 0.0;
    [self.contentView addSubview:self.otherTextView];

    self.placeholderLabel = [[UILabel alloc] init];
    self.placeholderLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.placeholderLabel.text = @"Write down other reasons...";
    self.placeholderLabel.textColor = [self colorWithHexString:@"#C4C4C4"];
    self.placeholderLabel.font = [UIFont systemFontOfSize:12.0 weight:UIFontWeightRegular];
    [self.otherTextView addSubview:self.placeholderLabel];

    self.submitButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.submitButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.submitButton.backgroundColor = [self colorWithHexString:@"#B829FF"];
    self.submitButton.layer.cornerRadius = 30.0;
    self.submitButton.clipsToBounds = YES;
    [self.submitButton setTitle:@"Submit" forState:UIControlStateNormal];
    [self.submitButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    self.submitButton.titleLabel.font = [UIFont systemFontOfSize:16.0 weight:UIFontWeightBold];
    [self.submitButton addTarget:self action:@selector(submitButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.submitButton];

    [self updateReasonButtonStates];
    self.contentTopConstraint = [self.contentView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:20.0];
    self.submitButtonBottomConstraint = [self.submitButton.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-25.0];

    [NSLayoutConstraint activateConstraints:@[
        self.contentTopConstraint,
        [self.contentView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.contentView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.contentView.bottomAnchor constraintEqualToAnchor:self.otherTextView.bottomAnchor],

        [reasonsStackView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],
        [reasonsStackView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:14.0],
        [reasonsStackView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-14.0],
        [reasonsStackView.heightAnchor constraintEqualToConstant:304.0],

        [otherLabel.topAnchor constraintEqualToAnchor:reasonsStackView.bottomAnchor constant:20.0],
        [otherLabel.leadingAnchor constraintEqualToAnchor:reasonsStackView.leadingAnchor],
        [otherLabel.trailingAnchor constraintLessThanOrEqualToAnchor:reasonsStackView.trailingAnchor],

        [self.otherTextView.topAnchor constraintEqualToAnchor:otherLabel.bottomAnchor constant:8.0],
        [self.otherTextView.leadingAnchor constraintEqualToAnchor:reasonsStackView.leadingAnchor],
        [self.otherTextView.trailingAnchor constraintEqualToAnchor:reasonsStackView.trailingAnchor],
        [self.otherTextView.heightAnchor constraintEqualToConstant:116.0],

        [self.placeholderLabel.topAnchor constraintEqualToAnchor:self.otherTextView.topAnchor constant:16.0],
        [self.placeholderLabel.leadingAnchor constraintEqualToAnchor:self.otherTextView.leadingAnchor constant:16.0],
        [self.placeholderLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.otherTextView.trailingAnchor constant:-16.0],

        [self.submitButton.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:14.0],
        [self.submitButton.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-14.0],
        self.submitButtonBottomConstraint,
        [self.submitButton.heightAnchor constraintEqualToConstant:60.0]
    ]];
}

- (UIButton *)reasonButtonWithTitle:(NSString *)title index:(NSInteger)index {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    button.tag = index;
    button.layer.cornerRadius = 22.0;
    button.clipsToBounds = YES;
    [button setTitle:title forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightRegular];
    [button addTarget:self action:@selector(reasonButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (void)reasonButtonTapped:(UIButton *)sender {
    self.selectedReasonIndex = sender.tag;
    [self updateReasonButtonStates];
}

- (void)submitButtonTapped {
    [self.view endEditing:YES];

    NSString *reasonText = [self trimmedText:self.otherTextView.text];
    if (self.selectedReasonIndex == NSNotFound) {
        [YGHUDHelper showCenterText:@"Please select a reason." inView:self.view];
        return;
    }
    if (reasonText.length == 0) {
        [YGHUDHelper showCenterText:@"Please enter content." inView:self.view];
        return;
    }

    self.submitButton.enabled = NO;
    [YGHUDHelper showLoadingAddedTo:self.view text:@"Submitting..."];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [YGHUDHelper hideLoadingForView:self.view];
        [YGHUDHelper showCenterText:@"Submit successful." inView:self.view];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.navigationController popViewControllerAnimated:YES];
        });
    });
}

- (void)updateReasonButtonStates {
    for (UIButton *button in self.reasonButtons) {
        BOOL selected = button.tag == self.selectedReasonIndex;
        button.backgroundColor = selected ? [self colorWithHexString:@"#B829FF"] : UIColor.whiteColor;
        [button setTitleColor:selected ? UIColor.whiteColor : UIColor.blackColor forState:UIControlStateNormal];
    }
}

- (void)textViewDidChange:(UITextView *)textView {
    self.placeholderLabel.hidden = textView.text.length > 0;
}

- (NSString *)trimmedText:(NSString *)text {
    return [text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet] ?: @"";
}

- (void)setupKeyboardHandler {
    __weak typeof(self) weakSelf = self;
    self.keyboardHandler = [[YGKeyboardHandler alloc] initWithView:self.view changeHandler:^(CGFloat keyboardHeight, NSTimeInterval duration, UIViewAnimationOptions options) {
        [weakSelf updateLayoutForKeyboardHeight:keyboardHeight duration:duration options:options];
    }];
}

- (void)updateLayoutForKeyboardHeight:(CGFloat)keyboardHeight duration:(NSTimeInterval)duration options:(UIViewAnimationOptions)options {
    CGFloat safeAreaBottom = self.view.safeAreaInsets.bottom;
    self.submitButtonBottomConstraint.constant = keyboardHeight > 0.0 ? -(keyboardHeight - safeAreaBottom + 12.0) : -25.0;

    CGFloat contentOffset = 0.0;
    if (keyboardHeight > 0.0) {
        [self.view layoutIfNeeded];
        CGRect textViewFrame = [self.otherTextView convertRect:self.otherTextView.bounds toView:self.view];
        CGFloat keyboardTop = CGRectGetHeight(self.view.bounds) - keyboardHeight;
        CGFloat submitTop = keyboardTop - 12.0 - 60.0 - 12.0;
        CGFloat overflow = CGRectGetMaxY(textViewFrame) - submitTop;
        contentOffset = overflow > 0.0 ? -(overflow + 10.0) : 0.0;
    }
    self.contentTopConstraint.constant = 20.0 + contentOffset;

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
