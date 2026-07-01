//
//  YGRechargeOptionCell.m
//  Yaga
//

#import "YGRechargeOptionCell.h"

@interface YGRechargeGradientView : UIView

@end

@implementation YGRechargeGradientView

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    if (CGRectIsEmpty(rect)) {
        return;
    }

    CGContextRef context = UIGraphicsGetCurrentContext();
    if (context == NULL) {
        return;
    }

    CGContextSaveGState(context);
    UIBezierPath *clipPath = [UIBezierPath bezierPathWithRoundedRect:self.bounds cornerRadius:CGRectGetHeight(self.bounds) / 2.0];
    [clipPath addClip];

    NSArray *colors = @[
        (__bridge id)[UIColor colorWithRed:184.0 / 255.0 green:41.0 / 255.0 blue:255.0 / 255.0 alpha:1.0].CGColor,
        (__bridge id)[UIColor colorWithRed:252.0 / 255.0 green:32.0 / 255.0 blue:135.0 / 255.0 alpha:1.0].CGColor,
        (__bridge id)[UIColor colorWithRed:255.0 / 255.0 green:167.0 / 255.0 blue:135.0 / 255.0 alpha:1.0].CGColor
    ];
    CGFloat locations[] = {0.0, 0.5, 1.0};
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)colors, locations);
    CGContextDrawLinearGradient(context,
                                gradient,
                                CGPointMake(0.0, CGRectGetMidY(self.bounds)),
                                CGPointMake(CGRectGetWidth(self.bounds), CGRectGetMidY(self.bounds)),
                                0);
    CGGradientRelease(gradient);
    CGColorSpaceRelease(colorSpace);
    CGContextRestoreGState(context);
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self setNeedsDisplay];
}

@end

@interface YGRechargeOptionCell ()

@property (nonatomic, strong) UIImageView *diamondImageView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) YGRechargeGradientView *actionBackgroundView;
@property (nonatomic, strong) UIButton *actionButton;

@end

@implementation YGRechargeOptionCell

+ (NSString *)reuseIdentifier {
    return @"YGRechargeOptionCell";
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupViews];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
}

- (void)setupViews {
    self.contentView.backgroundColor = UIColor.whiteColor;
    self.contentView.layer.cornerRadius = 20.0;
    self.contentView.clipsToBounds = YES;

    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.titleLabel.textColor = UIColor.blackColor;
    self.titleLabel.font = [UIFont systemFontOfSize:18.0 weight:UIFontWeightHeavy];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.contentView addSubview:self.titleLabel];

    self.diamondImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"diamond"]];
    self.diamondImageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.diamondImageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.contentView addSubview:self.diamondImageView];

    self.actionBackgroundView = [[YGRechargeGradientView alloc] init];
    self.actionBackgroundView.translatesAutoresizingMaskIntoConstraints = NO;
    self.actionBackgroundView.backgroundColor = [self colorWithHexString:@"#B829FF"];
    self.actionBackgroundView.layer.cornerRadius = 16.0;
    self.actionBackgroundView.clipsToBounds = YES;
    self.actionBackgroundView.userInteractionEnabled = NO;
    [self.contentView addSubview:self.actionBackgroundView];

    self.actionButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.actionButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.actionButton.backgroundColor = UIColor.clearColor;
    [self.actionButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    self.actionButton.titleLabel.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightBold];
    self.actionButton.layer.cornerRadius = 16.0;
    self.actionButton.layer.masksToBounds = YES;
    [self.actionButton addTarget:self action:@selector(actionButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.actionButton];

    [NSLayoutConstraint activateConstraints:@[
        [self.titleLabel.centerXAnchor constraintEqualToAnchor:self.contentView.centerXAnchor],
        [self.titleLabel.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
        [self.titleLabel.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.contentView.leadingAnchor constant:12.0],
        [self.titleLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.contentView.trailingAnchor constant:-12.0],

        [self.diamondImageView.centerXAnchor constraintEqualToAnchor:self.contentView.centerXAnchor],
        [self.diamondImageView.centerYAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:32.0],
        [self.diamondImageView.widthAnchor constraintEqualToConstant:36.0],
        [self.diamondImageView.heightAnchor constraintEqualToConstant:36.0],

        [self.actionBackgroundView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:30.0],
        [self.actionBackgroundView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-30.0],
        [self.actionBackgroundView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-8.0],
        [self.actionBackgroundView.heightAnchor constraintEqualToConstant:32.0],

        [self.actionButton.topAnchor constraintEqualToAnchor:self.actionBackgroundView.topAnchor],
        [self.actionButton.leadingAnchor constraintEqualToAnchor:self.actionBackgroundView.leadingAnchor],
        [self.actionButton.trailingAnchor constraintEqualToAnchor:self.actionBackgroundView.trailingAnchor],
        [self.actionButton.bottomAnchor constraintEqualToAnchor:self.actionBackgroundView.bottomAnchor]
    ]];
}

- (void)configureWithTitle:(NSString *)title buttonTitle:(NSString *)buttonTitle {
    self.titleLabel.text = title;
    [self.actionButton setTitle:buttonTitle forState:UIControlStateNormal];
    [self setNeedsLayout];
}

- (void)actionButtonTapped {
    if (self.actionHandler) {
        self.actionHandler();
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
