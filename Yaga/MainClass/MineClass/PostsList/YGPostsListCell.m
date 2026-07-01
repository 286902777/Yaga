//
//  YGPostsListCell.m
//  Yaga
//

#import "YGPostsListCell.h"
#import "YGImagePostStore.h"
#import "YGVideoPostStore.h"

@interface YGPostsListCell ()

@property (nonatomic, strong) UIImageView *avatarImageView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UIImageView *moreImageView;
@property (nonatomic, strong) UILabel *descriptionLabel;
@property (nonatomic, strong) UIImageView *contentImageView;
@property (nonatomic, strong) UIImageView *playImageView;

@end

@implementation YGPostsListCell

+ (NSString *)reuseIdentifier {
    return NSStringFromClass(self);
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
    self.avatarImageView.image = nil;
    self.nameLabel.text = nil;
    self.descriptionLabel.text = nil;
    self.contentImageView.image = nil;
    self.playImageView.hidden = YES;
    self.moreTapHandler = nil;
    [self setMoreHidden:NO];
}

- (void)setupViews {
    self.contentView.backgroundColor = UIColor.whiteColor;
    self.contentView.layer.cornerRadius = 20.0;
    self.contentView.clipsToBounds = YES;

    self.avatarImageView = [[UIImageView alloc] init];
    self.avatarImageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.avatarImageView.backgroundColor = UIColor.whiteColor;
    self.avatarImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.avatarImageView.clipsToBounds = YES;
    self.avatarImageView.layer.cornerRadius = 20.0;
    [self.contentView addSubview:self.avatarImageView];

    self.nameLabel = [[UILabel alloc] init];
    self.nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.nameLabel.textColor = UIColor.blackColor;
    self.nameLabel.font = [UIFont boldSystemFontOfSize:16.0];
    [self.contentView addSubview:self.nameLabel];

    self.moreImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"listmore"]];
    self.moreImageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.moreImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.moreImageView.userInteractionEnabled = YES;
    [self.moreImageView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(moreImageTapped)]];
    [self.contentView addSubview:self.moreImageView];

    self.descriptionLabel = [[UILabel alloc] init];
    self.descriptionLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.descriptionLabel.textColor = [self colorWithHexString:@"#808080"];
    self.descriptionLabel.font = [UIFont systemFontOfSize:12.0 weight:UIFontWeightRegular];
    self.descriptionLabel.numberOfLines = 2;
    self.descriptionLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    [self.contentView addSubview:self.descriptionLabel];

    self.contentImageView = [[UIImageView alloc] init];
    self.contentImageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.contentImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.contentImageView.clipsToBounds = YES;
    self.contentImageView.layer.cornerRadius = 20.0;
    [self.contentView addSubview:self.contentImageView];

    self.playImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"playimage"]];
    self.playImageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.playImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.playImageView.hidden = YES;
    [self.contentImageView addSubview:self.playImageView];

    [NSLayoutConstraint activateConstraints:@[
        [self.avatarImageView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:15.0],
        [self.avatarImageView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:15.0],
        [self.avatarImageView.widthAnchor constraintEqualToConstant:40.0],
        [self.avatarImageView.heightAnchor constraintEqualToConstant:40.0],

        [self.nameLabel.leadingAnchor constraintEqualToAnchor:self.avatarImageView.trailingAnchor constant:10.0],
        [self.nameLabel.centerYAnchor constraintEqualToAnchor:self.avatarImageView.centerYAnchor],
        [self.nameLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.moreImageView.leadingAnchor constant:-10.0],

        [self.moreImageView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-15.0],
        [self.moreImageView.centerYAnchor constraintEqualToAnchor:self.avatarImageView.centerYAnchor],
        [self.moreImageView.widthAnchor constraintEqualToConstant:24.0],
        [self.moreImageView.heightAnchor constraintEqualToConstant:24.0],

        [self.descriptionLabel.topAnchor constraintEqualToAnchor:self.avatarImageView.bottomAnchor constant:20.0],
        [self.descriptionLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:15.0],
        [self.descriptionLabel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-15.0],

        [self.contentImageView.topAnchor constraintEqualToAnchor:self.descriptionLabel.bottomAnchor constant:15.0],
        [self.contentImageView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:15.0],
        [self.contentImageView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-15.0],
        [self.contentImageView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-10.0],

        [self.playImageView.centerXAnchor constraintEqualToAnchor:self.contentImageView.centerXAnchor],
        [self.playImageView.centerYAnchor constraintEqualToAnchor:self.contentImageView.centerYAnchor],
        [self.playImageView.widthAnchor constraintEqualToConstant:44.0],
        [self.playImageView.heightAnchor constraintEqualToConstant:44.0]
    ]];
}

- (void)moreImageTapped {
    if (self.moreTapHandler != nil) {
        self.moreTapHandler();
    }
}

- (void)setMoreHidden:(BOOL)hidden {
    self.moreImageView.hidden = hidden;
    self.moreImageView.userInteractionEnabled = !hidden;
    if (hidden) {
        self.moreTapHandler = nil;
    }
}

- (void)configureWithAvatarName:(NSString *)avatarName
                       userName:(NSString *)userName
                descriptionText:(NSString *)descriptionText
               contentImageName:(NSString *)contentImageName {
    self.avatarImageView.image = [UIImage imageNamed:avatarName];
    self.nameLabel.text = userName;
    self.descriptionLabel.text = descriptionText;
    self.contentImageView.image = [UIImage imageNamed:contentImageName];
    self.playImageView.hidden = YES;
}

- (void)configureWithImagePost:(NSDictionary *)post {
    UIImage *avatarImage = [[YGImagePostStore sharedStore] avatarImageForPost:post];
    if (avatarImage == nil) {
        avatarImage = [[YGVideoPostStore sharedStore] avatarImageForPost:post];
    }
    self.avatarImageView.image = avatarImage ?: [UIImage imageNamed:@"headplace"];
    self.nameLabel.text = post[@"userName"];
    self.descriptionLabel.text = post[@"descriptionText"] ?: post[@"text"];
    UIImage *contentImage = [post[@"previewImage"] isKindOfClass:UIImage.class] ? post[@"previewImage"] : nil;
    if (contentImage == nil) {
        contentImage = [[YGImagePostStore sharedStore] imageForPostImageName:post[@"contentImageName"]];
    }
    self.contentImageView.image = contentImage ?: [UIImage imageNamed:@"personplace"];
    self.playImageView.hidden = YES;
}

- (void)configureWithVideoPost:(NSDictionary *)post {
    UIImage *avatarImage = [[YGVideoPostStore sharedStore] avatarImageForPost:post];
    if (avatarImage == nil) {
        avatarImage = [[YGImagePostStore sharedStore] avatarImageForPost:post];
    }
    self.avatarImageView.image = avatarImage ?: [UIImage imageNamed:@"headplace"];
    self.nameLabel.text = post[@"userName"];
    self.descriptionLabel.text = post[@"text"] ?: post[@"descriptionText"];

    UIImage *contentImage = [post[@"previewImage"] isKindOfClass:UIImage.class] ? post[@"previewImage"] : nil;
    if (contentImage == nil) {
        contentImage = [[YGVideoPostStore sharedStore] thumbnailImageForPost:post];
    }
    self.contentImageView.image = contentImage ?: [UIImage imageNamed:@"personplace"];
    self.playImageView.hidden = NO;
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
