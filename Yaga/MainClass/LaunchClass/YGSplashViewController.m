//
//  YGSplashViewController.m
//  Yaga
//

#import "YGSplashViewController.h"
#import "YGAppRouter.h"
#import "YGRootManager.h"

@interface YGSplashViewController ()

@property (nonatomic, copy) void (^completion)(void);
@property (nonatomic, assign) BOOL didFinishSplash;

@end

@implementation YGSplashViewController

- (instancetype)initWithCompletion:(void (^)(void))completion {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _completion = [completion copy];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = UIColor.whiteColor;
    
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[self splashImage]];
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    imageView.clipsToBounds = YES;
    imageView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:imageView];
    
    [NSLayoutConstraint activateConstraints:@[
        [imageView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [imageView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [imageView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [imageView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
    ]];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (self.didFinishSplash) {
        return;
    }
    self.didFinishSplash = YES;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self routeAfterSplash];
    });
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (UIImage *)splashImage {
    UIImage *image = [UIImage imageNamed:@"s_icon"];
    if (image == nil) {
        image = [UIImage imageNamed:@"s_icon.png"];
    }
    return image;
}

- (void)routeAfterSplash {
    [[YGRootManager shared] request:^(BOOL success) {
        if (success) {
            [YGAppRouter switchToDirectLoginInterface];
            return;
        }

        if (self.completion) {
            self.completion();
        }
    }];
}

@end
