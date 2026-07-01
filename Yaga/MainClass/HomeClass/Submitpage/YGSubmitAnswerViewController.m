//
//  YGSubmitAnswerViewController.m
//  Yaga
//

#import "YGSubmitAnswerViewController.h"

@interface YGSubmitAnswerViewController ()

@property (nonatomic, copy) NSString *question;
@property (nonatomic, strong) UIImageView *avatarImageView;
@property (nonatomic, strong) UIView *bubbleView;
@property (nonatomic, strong) UILabel *answerLabel;

@end

@implementation YGSubmitAnswerViewController

- (instancetype)initWithQuestion:(NSString *)question {
    self = [super init];
    if (self) {
        _question = [question copy];
    }
    return self; 
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = UIColor.whiteColor;
    [self setupSubviews];
}

- (void)setupSubviews {
    self.avatarImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"yagaanwser"]];
    self.avatarImageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.avatarImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.avatarImageView.backgroundColor = UIColor.whiteColor;
    self.avatarImageView.layer.cornerRadius = 18.0;
    self.avatarImageView.clipsToBounds = YES;
    [self.view addSubview:self.avatarImageView];

    self.bubbleView = [[UIView alloc] init];
    self.bubbleView.translatesAutoresizingMaskIntoConstraints = NO;
    self.bubbleView.backgroundColor = UIColor.whiteColor;
    self.bubbleView.layer.cornerRadius = 11.0;
    self.bubbleView.clipsToBounds = YES;
    [self.view addSubview:self.bubbleView];

    self.answerLabel = [[UILabel alloc] init];
    self.answerLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.answerLabel.text = [self randomAnswerText];
    self.answerLabel.textColor = UIColor.blackColor;
    self.answerLabel.font = [UIFont systemFontOfSize:12.0 weight:UIFontWeightRegular];
    self.answerLabel.numberOfLines = 0;
    [self.bubbleView addSubview:self.answerLabel];

    [NSLayoutConstraint activateConstraints:@[
        [self.avatarImageView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:16.0],
        [self.avatarImageView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:26.0],
        [self.avatarImageView.widthAnchor constraintEqualToConstant:36.0],
        [self.avatarImageView.heightAnchor constraintEqualToConstant:36.0],

        [self.bubbleView.leadingAnchor constraintEqualToAnchor:self.avatarImageView.trailingAnchor constant:5.0],
        [self.bubbleView.topAnchor constraintEqualToAnchor:self.avatarImageView.topAnchor constant:1.0],
        [self.bubbleView.trailingAnchor constraintLessThanOrEqualToAnchor:self.view.trailingAnchor constant:-30.0],
        [self.bubbleView.heightAnchor constraintGreaterThanOrEqualToConstant:44.0],

        [self.answerLabel.topAnchor constraintEqualToAnchor:self.bubbleView.topAnchor constant:9.0],
        [self.answerLabel.leadingAnchor constraintEqualToAnchor:self.bubbleView.leadingAnchor constant:10.0],
        [self.answerLabel.trailingAnchor constraintEqualToAnchor:self.bubbleView.trailingAnchor constant:-10.0],
        [self.answerLabel.bottomAnchor constraintEqualToAnchor:self.bubbleView.bottomAnchor constant:-9.0]
    ]];
}

- (NSString *)randomAnswerText {
    NSArray<NSString *> *answers = @[
        @"Good morning, welcome to Yaga. A bright and beautiful day is beginning.",
        @"May your day be filled with calm energy, kind moments, and gentle progress.",
        @"Hi, welcome to Yaga. I hope your practice feels light, joyful, and peaceful today.",
        @"A new day is here. Keep your heart open, stay curious, and take good care of yourself.",
        @"Start slowly, breathe deeply, and let today bring you something warm and wonderful."
    ];
    NSUInteger index = arc4random_uniform((uint32_t)answers.count);
    return answers[index];
}

@end
