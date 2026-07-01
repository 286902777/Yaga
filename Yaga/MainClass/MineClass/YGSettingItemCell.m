//
//  YGSettingItemCell.m
//  Yaga
//

#import "YGSettingItemCell.h"

@interface YGSettingItemCell ()

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIImageView *arrowImageView;

@end

@implementation YGSettingItemCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setupSubviews];
    }
    return self;
}

- (void)setupSubviews {
    self.backgroundColor = UIColor.clearColor;
    self.contentView.backgroundColor = UIColor.clearColor;
    self.selectionStyle = UITableViewCellSelectionStyleNone;

    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.titleLabel.textColor = UIColor.blackColor;
    self.titleLabel.font = [UIFont systemFontOfSize:16.0 weight:UIFontWeightMedium];

    self.arrowImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"rightarrow"]];
    self.arrowImageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.arrowImageView.contentMode = UIViewContentModeScaleAspectFit;

    [self.contentView addSubview:self.titleLabel];
    [self.contentView addSubview:self.arrowImageView];

    [NSLayoutConstraint activateConstraints:@[
        [self.titleLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:20.0],
        [self.titleLabel.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],

        [self.arrowImageView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-16.0],
        [self.arrowImageView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
        [self.arrowImageView.widthAnchor constraintEqualToConstant:20.0],
        [self.arrowImageView.heightAnchor constraintEqualToConstant:20.0],
    ]];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.contentView.layer.cornerRadius = 0.0;
    self.contentView.layer.masksToBounds = NO;
}

- (void)configureWithTitle:(NSString *)title {
    self.titleLabel.text = title;
}

@end
