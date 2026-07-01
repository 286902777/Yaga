//
//  YGPopupAlertView.m
//  Yaga
//

#import "YGPopupAlertView.h"

@interface YGPopupAlertView ()

@property (nonatomic, copy) NSString *iconName;
@property (nonatomic, copy) NSString *message;
@property (nonatomic, copy) NSString *leftButtonTitle;
@property (nonatomic, copy) NSString *rightButtonTitle;
@property (nonatomic, strong) UIView *overlayView;
@property (nonatomic, strong) UIImageView *backgroundImageView;
@property (nonatomic, strong) UIImageView *iconImageView;
@property (nonatomic, strong) UILabel *messageLabel;
@property (nonatomic, strong) UIButton *leftButton;
@property (nonatomic, strong) UIButton *rightButton;
@property (nonatomic, copy) void (^rightButtonHandler)(void);

@end

@implementation YGPopupAlertView

+ (void)showInView:(UIView *)view
          iconName:(NSString *)iconName
           message:(NSString *)message
   leftButtonTitle:(NSString *)leftButtonTitle
  rightButtonTitle:(NSString *)rightButtonTitle {
    [self showInView:view
            iconName:iconName
             message:message
     leftButtonTitle:leftButtonTitle
    rightButtonTitle:rightButtonTitle
  rightButtonHandler:nil];
}

+ (void)showInView:(UIView *)view
          iconName:(NSString *)iconName
           message:(NSString *)message
   leftButtonTitle:(NSString *)leftButtonTitle
  rightButtonTitle:(NSString *)rightButtonTitle
rightButtonHandler:(void (^)(void))rightButtonHandler {
    YGPopupAlertView *popupView = [[YGPopupAlertView alloc] initWithIconName:iconName
                                                                     message:message
                                                             leftButtonTitle:leftButtonTitle
                                                            rightButtonTitle:rightButtonTitle];
    popupView.rightButtonHandler = rightButtonHandler;
    popupView.frame = view.bounds;
    popupView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [view addSubview:popupView];
}

- (instancetype)initWithIconName:(NSString *)iconName
                         message:(NSString *)message
                 leftButtonTitle:(NSString *)leftButtonTitle
                rightButtonTitle:(NSString *)rightButtonTitle {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        _iconName = [iconName copy];
        _message = [message copy];
        _leftButtonTitle = [leftButtonTitle copy];
        _rightButtonTitle = [rightButtonTitle copy];
        [self setupSubviews];
    }
    return self;
}

- (void)setupSubviews {
    self.backgroundColor = UIColor.clearColor;

    self.overlayView = [[UIView alloc] init];
    self.overlayView.translatesAutoresizingMaskIntoConstraints = NO;
    self.overlayView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.45];
    [self addSubview:self.overlayView];

    self.backgroundImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"popupback"]];
    self.backgroundImageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.backgroundImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.backgroundImageView.clipsToBounds = YES;
    self.backgroundImageView.userInteractionEnabled = YES;
    [self addSubview:self.backgroundImageView];

    UIImage *iconImage = [self imageNamed:self.iconName];
    self.iconImageView = [[UIImageView alloc] initWithImage:iconImage];
    self.iconImageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.iconImageView.contentMode = UIViewContentModeScaleAspectFit;
    [self addSubview:self.iconImageView];

    self.messageLabel = [[UILabel alloc] init];
    self.messageLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.messageLabel.text = self.message;
    self.messageLabel.textColor = UIColor.blackColor;
    self.messageLabel.font = [UIFont systemFontOfSize:16.0 weight:UIFontWeightRegular];
    self.messageLabel.textAlignment = NSTextAlignmentCenter;
    self.messageLabel.numberOfLines = 0;
    [self.backgroundImageView addSubview:self.messageLabel];

    self.leftButton = [self actionButtonWithTitle:self.leftButtonTitle selected:NO action:@selector(leftButtonTapped)];
    self.rightButton = [self actionButtonWithTitle:self.rightButtonTitle selected:YES action:@selector(rightButtonTapped)];
    [self.backgroundImageView addSubview:self.leftButton];
    [self.backgroundImageView addSubview:self.rightButton];

    CGFloat iconWidth = iconImage.size.width > 0.0 ? iconImage.size.width : 115.0;
    CGFloat iconHeight = iconImage.size.height > 0.0 ? iconImage.size.height : 115.0;

    [NSLayoutConstraint activateConstraints:@[
        [self.overlayView.topAnchor constraintEqualToAnchor:self.topAnchor],
        [self.overlayView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [self.overlayView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [self.overlayView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],

        [self.backgroundImageView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:30.0],
        [self.backgroundImageView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-30.0],
        [self.backgroundImageView.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
        [self.backgroundImageView.heightAnchor constraintEqualToAnchor:self.backgroundImageView.widthAnchor multiplier:524.0 / 662.0],

        [self.iconImageView.centerXAnchor constraintEqualToAnchor:self.backgroundImageView.centerXAnchor],
        [self.iconImageView.topAnchor constraintEqualToAnchor:self.backgroundImageView.topAnchor constant:-(iconHeight * 2.0 / 5.0) + 10.0],
        [self.iconImageView.widthAnchor constraintEqualToConstant:iconWidth],
        [self.iconImageView.heightAnchor constraintEqualToConstant:iconHeight],

        [self.leftButton.leadingAnchor constraintEqualToAnchor:self.backgroundImageView.leadingAnchor constant:26.0],
        [self.leftButton.bottomAnchor constraintEqualToAnchor:self.backgroundImageView.bottomAnchor constant:-30.0],
        [self.leftButton.heightAnchor constraintEqualToConstant:52.0],
        [self.rightButton.leadingAnchor constraintEqualToAnchor:self.leftButton.trailingAnchor constant:14.0],
        [self.rightButton.trailingAnchor constraintEqualToAnchor:self.backgroundImageView.trailingAnchor constant:-26.0],
        [self.rightButton.bottomAnchor constraintEqualToAnchor:self.leftButton.bottomAnchor],
        [self.rightButton.heightAnchor constraintEqualToAnchor:self.leftButton.heightAnchor],
        [self.rightButton.widthAnchor constraintEqualToAnchor:self.leftButton.widthAnchor],

        [self.messageLabel.leadingAnchor constraintEqualToAnchor:self.backgroundImageView.leadingAnchor constant:36.0],
        [self.messageLabel.trailingAnchor constraintEqualToAnchor:self.backgroundImageView.trailingAnchor constant:-36.0],
        [self.messageLabel.centerYAnchor constraintEqualToAnchor:self.backgroundImageView.centerYAnchor constant:-8.0],
        [self.messageLabel.bottomAnchor constraintLessThanOrEqualToAnchor:self.leftButton.topAnchor constant:-18.0]
    ]];
}

- (UIButton *)actionButtonWithTitle:(NSString *)title selected:(BOOL)selected action:(SEL)action {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:selected ? UIColor.whiteColor : [self colorWithHexString:@"#808080"] forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:16.0 weight:UIFontWeightSemibold];
    button.backgroundColor = selected ? [self colorWithHexString:@"#B829FF"] : [self colorWithHexString:@"#F5F5F5"];
    button.layer.cornerRadius = 26.0;
    button.clipsToBounds = YES;
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (UIImage *)imageNamed:(NSString *)imageName {
    UIImage *image = [UIImage imageNamed:imageName];
    if (image != nil || [imageName.pathExtension.lowercaseString isEqualToString:@"png"]) {
        return image;
    }
    return [UIImage imageNamed:[imageName stringByAppendingString:@".png"]];
}

- (void)leftButtonTapped {
    [self removeFromSuperview];
}

- (void)rightButtonTapped {
    void (^handler)(void) = self.rightButtonHandler;
    [self removeFromSuperview];
    if (handler != nil) {
        handler();
    }
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
