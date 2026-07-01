//
//  YGStaticTextViewController.m
//  Yaga
//

#import "YGStaticTextViewController.h"

@interface YGStaticTextViewController ()

@property (nonatomic, copy) NSString *displayTitle;
@property (nonatomic, copy) NSString *contentText;

@end

@implementation YGStaticTextViewController

- (instancetype)initWithTitle:(NSString *)title contentText:(NSString *)contentText {
    self = [super init];
    if (self) {
        _displayTitle = [title copy];
        _contentText = [contentText copy];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = self.displayTitle;
    self.view.backgroundColor = UIColor.whiteColor;

    UITextView *textView = [[UITextView alloc] init];
    textView.translatesAutoresizingMaskIntoConstraints = NO;
    textView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.90];
    textView.layer.cornerRadius = 24.0;
    textView.textContainerInset = UIEdgeInsetsMake(20.0, 18.0, 20.0, 18.0);
    textView.editable = NO;
    textView.textColor = UIColor.blackColor;
    textView.font = [UIFont systemFontOfSize:16.0];
    textView.text = self.contentText;
    [self.view addSubview:textView];

    [NSLayoutConstraint activateConstraints:@[
        [textView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:20.0],
        [textView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20.0],
        [textView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20.0],
        [textView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-20.0],
    ]];
}

@end
