//
//  YGEULAAlertView.m
//  Yaga
//

#import "YGEULAAlertView.h"

@interface YGEULAAlertView ()

@property (nonatomic, copy) NSString *message;
@property (nonatomic, copy) void (^cancelHandler)(void);
@property (nonatomic, copy) void (^agreeHandler)(void);
@property (nonatomic, strong) UIView *panelView;

@end

@implementation YGEULAAlertView

+ (void)showInView:(UIView *)view
           message:(NSString *)message
     cancelHandler:(void (^)(void))cancelHandler
      agreeHandler:(void (^)(void))agreeHandler {
    if (view == nil) {
        return;
    }

    YGEULAAlertView *alertView = [[YGEULAAlertView alloc] initWithMessage:message
                                                            cancelHandler:cancelHandler
                                                             agreeHandler:agreeHandler];
    alertView.translatesAutoresizingMaskIntoConstraints = NO;
    [view addSubview:alertView];
    [NSLayoutConstraint activateConstraints:@[
        [alertView.topAnchor constraintEqualToAnchor:view.topAnchor],
        [alertView.leadingAnchor constraintEqualToAnchor:view.leadingAnchor],
        [alertView.trailingAnchor constraintEqualToAnchor:view.trailingAnchor],
        [alertView.bottomAnchor constraintEqualToAnchor:view.bottomAnchor]
    ]];
    [alertView animateIn];
}

- (instancetype)initWithMessage:(NSString *)message
                  cancelHandler:(void (^)(void))cancelHandler
                   agreeHandler:(void (^)(void))agreeHandler {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        _message = [message copy];
        _cancelHandler = [cancelHandler copy];
        _agreeHandler = [agreeHandler copy];
        [self setupViews];
    }
    return self;
}

- (void)setupViews {
    self.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.58];

    self.panelView = [[UIView alloc] init];
    self.panelView.translatesAutoresizingMaskIntoConstraints = NO;
    self.panelView.backgroundColor = UIColor.whiteColor;
    self.panelView.layer.cornerRadius = 24.0;
    if (@available(iOS 11.0, *)) {
        self.panelView.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
    }
    self.panelView.clipsToBounds = YES;
    [self addSubview:self.panelView];

    UITextView *textView = [[UITextView alloc] init];
    textView.translatesAutoresizingMaskIntoConstraints = NO;
    textView.text = self.message;
    textView.textColor = [self colorWithHexString:@"#666666"];
    textView.font = [UIFont systemFontOfSize:13.0 weight:UIFontWeightRegular];
    textView.backgroundColor = UIColor.clearColor;
    textView.editable = NO;
    textView.selectable = NO;
    textView.showsVerticalScrollIndicator = NO;
    textView.textContainerInset = UIEdgeInsetsZero;
    textView.textContainer.lineFragmentPadding = 0.0;
    [self.panelView addSubview:textView];

    UIButton *cancelButton = [self buttonWithTitle:@"Cancel"
                                   backgroundColor:[self colorWithHexString:@"#F7F7F7"]
                                         textColor:[self colorWithHexString:@"#808080"]];
    [cancelButton addTarget:self action:@selector(cancelButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.panelView addSubview:cancelButton];

    UIButton *agreeButton = [self buttonWithTitle:@"Agree"
                                  backgroundColor:[self colorWithHexString:@"#C719F3"]
                                        textColor:UIColor.whiteColor];
    [agreeButton addTarget:self action:@selector(agreeButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.panelView addSubview:agreeButton];

    [NSLayoutConstraint activateConstraints:@[
        [self.panelView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [self.panelView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [self.panelView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
        [self.panelView.heightAnchor constraintEqualToAnchor:self.heightAnchor multiplier:0.62],

        [textView.topAnchor constraintEqualToAnchor:self.panelView.topAnchor constant:62.0],
        [textView.leadingAnchor constraintEqualToAnchor:self.panelView.leadingAnchor constant:28.0],
        [textView.trailingAnchor constraintEqualToAnchor:self.panelView.trailingAnchor constant:-28.0],
        [textView.bottomAnchor constraintEqualToAnchor:cancelButton.topAnchor constant:-18.0],

        [cancelButton.leadingAnchor constraintEqualToAnchor:self.panelView.leadingAnchor constant:28.0],
        [cancelButton.bottomAnchor constraintEqualToAnchor:self.panelView.safeAreaLayoutGuide.bottomAnchor constant:-18.0],
        [cancelButton.heightAnchor constraintEqualToConstant:52.0],

        [agreeButton.leadingAnchor constraintEqualToAnchor:cancelButton.trailingAnchor constant:12.0],
        [agreeButton.trailingAnchor constraintEqualToAnchor:self.panelView.trailingAnchor constant:-28.0],
        [agreeButton.centerYAnchor constraintEqualToAnchor:cancelButton.centerYAnchor],
        [agreeButton.widthAnchor constraintEqualToAnchor:cancelButton.widthAnchor],
        [agreeButton.heightAnchor constraintEqualToAnchor:cancelButton.heightAnchor]
    ]];
}

- (UIButton *)buttonWithTitle:(NSString *)title backgroundColor:(UIColor *)backgroundColor textColor:(UIColor *)textColor {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    button.backgroundColor = backgroundColor;
    button.layer.cornerRadius = 26.0;
    button.clipsToBounds = YES;
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:textColor forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightBold];
    return button;
}

- (void)animateIn {
    self.alpha = 0.0;
    self.panelView.transform = CGAffineTransformMakeTranslation(0.0, 220.0);
    [UIView animateWithDuration:0.25 animations:^{
        self.alpha = 1.0;
        self.panelView.transform = CGAffineTransformIdentity;
    }];
}

- (void)dismissWithCompletion:(void (^)(void))completion {
    [UIView animateWithDuration:0.2 animations:^{
        self.alpha = 0.0;
        self.panelView.transform = CGAffineTransformMakeTranslation(0.0, 220.0);
    } completion:^(__unused BOOL finished) {
        [self removeFromSuperview];
        if (completion != nil) {
            completion();
        }
    }];
}

- (void)cancelButtonTapped {
    [self dismissWithCompletion:self.cancelHandler];
}

- (void)agreeButtonTapped {
    [self dismissWithCompletion:self.agreeHandler];
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

@end
