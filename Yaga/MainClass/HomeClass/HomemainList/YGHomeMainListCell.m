//
//  YGHomeMainListCell.m
//  Yaga
//

#import "YGHomeMainListCell.h"
#import "YGVideoPostStore.h"

@interface YGHomeMainListCell ()

@property (nonatomic, strong) UIImageView *coverImageView;
@property (nonatomic, strong) UIImageView *playImageView;
@property (nonatomic, strong) UILabel *descriptionLabel;
@property (nonatomic, strong) UIImageView *avatarImageView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UIImageView *moreImageView;

@end

@implementation YGHomeMainListCell

+ (NSString *)reuseIdentifier {
    return @"YGHomeMainListCell";
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupViews];
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.coverImageView.image = nil;
    self.avatarImageView.image = nil;
    self.descriptionLabel.text = nil;
    self.nameLabel.text = nil;
    [self setMoreHidden:NO];
}

- (void)setupViews {
    self.contentView.backgroundColor = UIColor.clearColor;

    self.coverImageView = [[UIImageView alloc] init];
    self.coverImageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.coverImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.coverImageView.clipsToBounds = YES;
    self.coverImageView.layer.cornerRadius = 20.0;
    [self.contentView addSubview:self.coverImageView];

    self.playImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"playimage"]];
    self.playImageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.playImageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.coverImageView addSubview:self.playImageView];

    self.descriptionLabel = [[UILabel alloc] init];
    self.descriptionLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.descriptionLabel.textColor = UIColor.blackColor;
    self.descriptionLabel.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightMedium];
    self.descriptionLabel.numberOfLines = 2;
    self.descriptionLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    [self.contentView addSubview:self.descriptionLabel];

    self.avatarImageView = [[UIImageView alloc] init];
    self.avatarImageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.avatarImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.avatarImageView.clipsToBounds = YES;
    self.avatarImageView.layer.cornerRadius = 12.0;
    [self.contentView addSubview:self.avatarImageView];

    self.nameLabel = [[UILabel alloc] init];
    self.nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.nameLabel.textColor = [UIColor colorWithRed:128.0 / 255.0 green:128.0 / 255.0 blue:128.0 / 255.0 alpha:1.0];
    self.nameLabel.font = [UIFont systemFontOfSize:12.0 weight:UIFontWeightRegular];
    [self.contentView addSubview:self.nameLabel];

    self.moreImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"listmore"]];
    self.moreImageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.moreImageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.contentView addSubview:self.moreImageView];

    [NSLayoutConstraint activateConstraints:@[
        [self.coverImageView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],
        [self.coverImageView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor],
        [self.coverImageView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor],
        [self.coverImageView.heightAnchor constraintEqualToAnchor:self.coverImageView.widthAnchor multiplier:200.0 / 156.0],

        [self.playImageView.centerXAnchor constraintEqualToAnchor:self.coverImageView.centerXAnchor],
        [self.playImageView.centerYAnchor constraintEqualToAnchor:self.coverImageView.centerYAnchor],
        [self.playImageView.widthAnchor constraintEqualToConstant:44.0],
        [self.playImageView.heightAnchor constraintEqualToConstant:44.0],

        [self.descriptionLabel.topAnchor constraintEqualToAnchor:self.coverImageView.bottomAnchor constant:8.0],
        [self.descriptionLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor],
        [self.descriptionLabel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor],
        [self.descriptionLabel.heightAnchor constraintEqualToConstant:38.0],

        [self.avatarImageView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor],
        [self.avatarImageView.topAnchor constraintEqualToAnchor:self.descriptionLabel.bottomAnchor constant:8.0],
        [self.avatarImageView.widthAnchor constraintEqualToConstant:24.0],
        [self.avatarImageView.heightAnchor constraintEqualToConstant:24.0],
        [self.avatarImageView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor],

        [self.nameLabel.leadingAnchor constraintEqualToAnchor:self.avatarImageView.trailingAnchor constant:6.0],
        [self.nameLabel.centerYAnchor constraintEqualToAnchor:self.avatarImageView.centerYAnchor],
        [self.nameLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.moreImageView.leadingAnchor constant:-8.0],

        [self.moreImageView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor],
        [self.moreImageView.centerYAnchor constraintEqualToAnchor:self.avatarImageView.centerYAnchor],
        [self.moreImageView.widthAnchor constraintEqualToConstant:24.0],
        [self.moreImageView.heightAnchor constraintEqualToConstant:24.0]
    ]];
}

- (void)configureWithImageName:(NSString *)imageName
                          text:(NSString *)text
                    avatarName:(NSString *)avatarName
                      userName:(NSString *)userName {
    self.coverImageView.image = [UIImage imageNamed:imageName];
    self.descriptionLabel.text = text;
    self.avatarImageView.image = [UIImage imageNamed:avatarName];
    self.nameLabel.text = userName;
}

- (void)configureWithVideoPost:(NSDictionary *)post {
    UIImage *coverImage = [[YGVideoPostStore sharedStore] thumbnailImageForPost:post];
    self.coverImageView.image = coverImage ?: [UIImage imageNamed:@"personplace"];
    self.descriptionLabel.text = post[@"text"];
    UIImage *avatarImage = [[YGVideoPostStore sharedStore] avatarImageForPost:post];
    self.avatarImageView.image = avatarImage ?: [UIImage imageNamed:@"headplace"];
    self.nameLabel.text = post[@"userName"];
}

- (void)setMoreHidden:(BOOL)hidden {
    self.moreImageView.hidden = hidden;
}

@end
