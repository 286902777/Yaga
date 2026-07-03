//
//  YGSettingViewController.m
//  Yaga
//

#import "YGSettingViewController.h"
#import "YGAppRouter.h"
#import "YGHUDHelper.h"
#import "YGUserStore.h"
#import "YGSettingItemCell.h"
#import "YGBlacklistViewController.h"
#import "YGPopupAlertView.h"
#import "YGWebViewController.h"

@interface YGSettingViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray<NSString *> *items;
@property (nonatomic, strong) UIButton *logoutButton;
@property (nonatomic, strong) UIButton *deleteButton;
@property (nonatomic, strong) CAGradientLayer *deleteGradientLayer;

@end

@implementation YGSettingViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"Setting";
    self.view.backgroundColor = UIColor.whiteColor;
    self.items = @[@"Blacklist", @"User Agreement", @"Privacy Agreement"];
    [self setupSubviews];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

    self.deleteGradientLayer.frame = self.deleteButton.bounds;
    self.deleteGradientLayer.cornerRadius = self.deleteButton.layer.cornerRadius;
}

- (void)setupSubviews {
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.backgroundColor = UIColor.clearColor;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.showsVerticalScrollIndicator = NO;
    self.tableView.contentInset = UIEdgeInsetsMake(16.0, 0.0, 16.0, 0.0);
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.rowHeight = 64.0;
    [self.tableView registerClass:YGSettingItemCell.class forCellReuseIdentifier:@"YGSettingItemCell"];
    [self.view addSubview:self.tableView];

    self.logoutButton = [self solidButtonWithTitle:@"Log out"
                                            action:@selector(logoutButtonTapped)
                                         hexColor:@"#B829FF"];
    self.deleteButton = [self gradientButtonWithTitle:@"Delete account"
                                               action:@selector(deleteAccountButtonTapped)
                                        gradientLayer:&_deleteGradientLayer];
    [self.view addSubview:self.logoutButton];
    [self.view addSubview:self.deleteButton];

    [NSLayoutConstraint activateConstraints:@[
        [self.logoutButton.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:24.0],
        [self.logoutButton.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-24.0],
        [self.logoutButton.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-25.0],
        [self.logoutButton.heightAnchor constraintEqualToConstant:60.0],

        [self.deleteButton.leadingAnchor constraintEqualToAnchor:self.logoutButton.leadingAnchor],
        [self.deleteButton.trailingAnchor constraintEqualToAnchor:self.logoutButton.trailingAnchor],
        [self.deleteButton.bottomAnchor constraintEqualToAnchor:self.logoutButton.topAnchor constant:-15.0],
        [self.deleteButton.heightAnchor constraintEqualToConstant:60.0],

        [self.tableView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:8.0],
        [self.tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16.0],
        [self.tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-16.0],
        [self.tableView.bottomAnchor constraintEqualToAnchor:self.deleteButton.topAnchor constant:-20.0],
    ]];
}

- (UIButton *)gradientButtonWithTitle:(NSString *)title
                               action:(SEL)action
                        gradientLayer:(CAGradientLayer * __strong *)gradientLayerPointer {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:18.0 weight:UIFontWeightSemibold];
    button.layer.cornerRadius = 30.0;
    button.clipsToBounds = YES;
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];

    CAGradientLayer *gradientLayer = [CAGradientLayer layer];
    gradientLayer.colors = @[
        (__bridge id)[self colorWithHexString:@"#B829FF"].CGColor,
        (__bridge id)[self colorWithHexString:@"#FC2087"].CGColor,
        (__bridge id)[self colorWithHexString:@"#FFA787"].CGColor
    ];
    gradientLayer.startPoint = CGPointMake(0.0, 0.5);
    gradientLayer.endPoint = CGPointMake(1.0, 0.5);
    gradientLayer.locations = @[@0.0, @0.5, @1.0];
    [button.layer insertSublayer:gradientLayer atIndex:0];
    if (gradientLayerPointer != NULL) {
        *gradientLayerPointer = gradientLayer;
    }

    return button;
}

- (UIButton *)solidButtonWithTitle:(NSString *)title action:(SEL)action hexColor:(NSString *)hexColor {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:18.0 weight:UIFontWeightSemibold];
    button.backgroundColor = [self colorWithHexString:hexColor];
    button.layer.cornerRadius = 30.0;
    button.clipsToBounds = YES;
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (UIColor *)colorWithHexString:(NSString *)hexString {
    NSString *value = [[hexString stringByReplacingOccurrencesOfString:@"#" withString:@""] uppercaseString];
    unsigned int red = 0;
    unsigned int green = 0;
    unsigned int blue = 0;
    [[NSScanner scannerWithString:[value substringWithRange:NSMakeRange(0, 2)]] scanHexInt:&red];
    [[NSScanner scannerWithString:[value substringWithRange:NSMakeRange(2, 2)]] scanHexInt:&green];
    [[NSScanner scannerWithString:[value substringWithRange:NSMakeRange(4, 2)]] scanHexInt:&blue];
    return [UIColor colorWithRed:red / 255.0 green:green / 255.0 blue:blue / 255.0 alpha:1.0];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.items.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    YGSettingItemCell *cell = [tableView dequeueReusableCellWithIdentifier:@"YGSettingItemCell" forIndexPath:indexPath];
    [cell configureWithTitle:self.items[indexPath.section]];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return section == 0 ? CGFLOAT_MIN : 10.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return CGFLOAT_MIN;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *title = self.items[indexPath.section];
    if ([title isEqualToString:@"Blacklist"]) {
        YGBlacklistViewController *controller = [[YGBlacklistViewController alloc] init];
        [self.navigationController pushViewController:controller animated:YES];
        return;
    }

    if ([title isEqualToString:@"User Agreement"]) {
        YGWebViewController *controller = [[YGWebViewController alloc] initWithTitle:@"User Agreement"
                                                                           URLString:@"https://app.i32823wk.link/users"];
        [self.navigationController pushViewController:controller animated:YES];
        return;
    }

    YGWebViewController *controller = [[YGWebViewController alloc] initWithTitle:@"Privacy Agreement"
                                                                       URLString:@"https://app.i32823wk.link/privacy"];
    [self.navigationController pushViewController:controller animated:YES];
}

- (void)logoutButtonTapped {
    UIView *targetView = self.navigationController.view ?: self.view;
    __weak typeof(self) weakSelf = self;
    [YGPopupAlertView showInView:targetView
                        iconName:@"hint.png"
                         message:@"Are you sure you want to log\nout?"
                 leftButtonTitle:@"Cancel"
                rightButtonTitle:@"Sure"
             rightButtonHandler:^{
        __strong typeof(weakSelf) self = weakSelf;
        if (self == nil) {
            return;
        }
        [YGHUDHelper showLoadingAddedTo:self.view text:@"Logging out..."];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [[YGUserStore sharedStore] logout];
            [YGHUDHelper hideLoadingForView:self.view];
            [YGAppRouter switchToLoginInterface];
        });
    }];
}

- (void)deleteAccountButtonTapped {
    UIView *targetView = self.navigationController.view ?: self.view;
    __weak typeof(self) weakSelf = self;
    [YGPopupAlertView showInView:targetView
                        iconName:@"hint.png"
                         message:@"Are you sure you want to delete\naccount?"
                 leftButtonTitle:@"Cancel"
                rightButtonTitle:@"Sure"
             rightButtonHandler:^{
        __strong typeof(weakSelf) self = weakSelf;
        if (self == nil) {
            return;
        }
        [YGHUDHelper showLoadingAddedTo:self.view text:@"Deleting account..."];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [[YGUserStore sharedStore] deleteCurrentAccount];
            [YGHUDHelper hideLoadingForView:self.view];
            [YGAppRouter switchToLoginInterface];
        });
    }];
}

@end
