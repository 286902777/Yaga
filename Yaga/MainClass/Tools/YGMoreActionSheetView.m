//
//  YGMoreActionSheetView.m
//  Yaga
//

#import "YGMoreActionSheetView.h"

@interface YGMoreActionSheetView ()

@property (nonatomic, strong) UIView *overlayView;
@property (nonatomic, strong) UIStackView *buttonStackView;
@property (nonatomic, copy) void (^reportHandler)(void);
@property (nonatomic, copy) void (^blockHandler)(void);

@end

@implementation YGMoreActionSheetView

+ (void)showInView:(UIView *)view
     reportHandler:(void (^)(void))reportHandler
      blockHandler:(void (^)(void))blockHandler {
    YGMoreActionSheetView *sheetView = [[YGMoreActionSheetView alloc] initWithReportHandler:reportHandler blockHandler:blockHandler];
    sheetView.frame = view.bounds;
    sheetView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [view addSubview:sheetView];
}

- (instancetype)initWithReportHandler:(void (^)(void))reportHandler blockHandler:(void (^)(void))blockHandler {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        _reportHandler = [reportHandler copy];
        _blockHandler = [blockHandler copy];
        [self setupSubviews];
    }
    return self;
}

- (void)setupSubviews {
    self.backgroundColor = UIColor.clearColor;

    self.overlayView = [[UIView alloc] init];
    self.overlayView.translatesAutoresizingMaskIntoConstraints = NO;
    self.overlayView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.55];
    [self addSubview:self.overlayView];

    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(cancelButtonTapped)];
    [self.overlayView addGestureRecognizer:tapGesture];

    self.buttonStackView = [[UIStackView alloc] init];
    self.buttonStackView.translatesAutoresizingMaskIntoConstraints = NO;
    self.buttonStackView.axis = UILayoutConstraintAxisVertical;
    self.buttonStackView.spacing = 12.0;
    self.buttonStackView.distribution = UIStackViewDistributionFillEqually;
    [self addSubview:self.buttonStackView];

    UIButton *reportButton = [self actionButtonWithTitle:@"Report"
                                         backgroundColor:UIColor.whiteColor
                                               textColor:UIColor.blackColor
                                                  action:@selector(reportButtonTapped)];
    UIButton *blockButton = [self actionButtonWithTitle:@"Block"
                                       backgroundColor:UIColor.whiteColor
                                             textColor:UIColor.blackColor
                                                action:@selector(blockButtonTapped)];
    UIButton *cancelButton = [self actionButtonWithTitle:@"Cancel"
                                        backgroundColor:[self colorWithHexString:@"#B829FF"]
                                              textColor:UIColor.whiteColor
                                                 action:@selector(cancelButtonTapped)];
    [self.buttonStackView addArrangedSubview:reportButton];
    [self.buttonStackView addArrangedSubview:blockButton];
    [self.buttonStackView addArrangedSubview:cancelButton];

    [NSLayoutConstraint activateConstraints:@[
        [self.overlayView.topAnchor constraintEqualToAnchor:self.topAnchor],
        [self.overlayView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [self.overlayView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [self.overlayView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],

        [self.buttonStackView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:24.0],
        [self.buttonStackView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-24.0],
        [self.buttonStackView.bottomAnchor constraintEqualToAnchor:self.safeAreaLayoutGuide.bottomAnchor constant:-28.0],
        [self.buttonStackView.heightAnchor constraintEqualToConstant:204.0]
    ]];
}

- (UIButton *)actionButtonWithTitle:(NSString *)title
                    backgroundColor:(UIColor *)backgroundColor
                          textColor:(UIColor *)textColor
                             action:(SEL)action {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    button.backgroundColor = backgroundColor;
    button.layer.cornerRadius = 30.0;
    button.clipsToBounds = YES;
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:textColor forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:16.0 weight:UIFontWeightBold];
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (void)reportButtonTapped {
    void (^handler)(void) = self.reportHandler;
    [self removeFromSuperview];
    if (handler != nil) {
        handler();
    }
}

- (void)blockButtonTapped {
    void (^handler)(void) = self.blockHandler;
    [self removeFromSuperview];
    if (handler != nil) {
        handler();
    }
}

- (void)cancelButtonTapped {
    [self removeFromSuperview];
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
