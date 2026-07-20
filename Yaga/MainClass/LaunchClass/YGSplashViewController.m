//
//  YGSplashViewController.m
//  Yaga
//

#import "YGSplashViewController.h"
#import "YGAppRouter.h"
#import "YGRootManager.h"
#import "YGWebContainerViewController.h"
#import <Network/Network.h>

@interface YGSplashViewController ()

@property (nonatomic, copy) void (^completion)(void);
@property (nonatomic, strong) UIImageView *backgroundImageView;
@property (nonatomic, strong) NSURLSessionDataTask *networkPermissionTask;
@property (nonatomic, strong) nw_path_monitor_t pathMonitor;
@property (nonatomic, strong) dispatch_queue_t pathMonitorQueue;
@property (nonatomic, assign) BOOL hasStartedNetworkPermissionFlow;
@property (nonatomic, assign) BOOL hasStartedNetworkMonitoring;
@property (nonatomic, assign) BOOL hasStartedAppInfoRequest;

@end

@implementation YGSplashViewController

- (instancetype)initWithCompletion:(void (^)(void))completion {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _completion = [completion copy];
        _pathMonitor = nw_path_monitor_create();
        _pathMonitorQueue = dispatch_queue_create("app.yaga.network-monitor", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (void)dealloc {
    [self.networkPermissionTask cancel];
    if (self.pathMonitor) {
        nw_path_monitor_cancel(self.pathMonitor);
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [YGWebContainerViewController warmUpWebEngine];
    [self setupUI];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self startMonitoringNetwork];
    [self triggerNetworkPermissionThenMonitor];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)setupUI {
    self.view.backgroundColor = UIColor.blackColor;

    [self.view addSubview:self.backgroundImageView];

    [NSLayoutConstraint activateConstraints:@[
        [self.backgroundImageView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.backgroundImageView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.backgroundImageView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.backgroundImageView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
    ]];
}

- (UIImageView *)backgroundImageView {
    if (_backgroundImageView == nil) {
        _backgroundImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"s_icon"]];
        _backgroundImageView.contentMode = UIViewContentModeScaleAspectFill;
        _backgroundImageView.clipsToBounds = YES;
        _backgroundImageView.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _backgroundImageView;
}

- (void)startMonitoringNetwork {
    if (self.hasStartedNetworkMonitoring) {
        return;
    }
    self.hasStartedNetworkMonitoring = YES;

    __weak typeof(self) weakSelf = self;
    nw_path_monitor_set_update_handler(self.pathMonitor, ^(nw_path_t path) {
        if (nw_path_get_status(path) != nw_path_status_satisfied) {
            return;
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) self = weakSelf;
            if (!self) {
                return;
            }
            [self startAppInfoRequest];
        });
    });
    nw_path_monitor_set_queue(self.pathMonitor, self.pathMonitorQueue);
    nw_path_monitor_start(self.pathMonitor);
}

- (void)triggerNetworkPermissionThenMonitor {
    if (self.hasStartedNetworkPermissionFlow) {
        return;
    }
    self.hasStartedNetworkPermissionFlow = YES;

    NSURLComponents *components = [NSURLComponents componentsWithString:@"https://www.google.com/"];
    components.queryItems = @[
        [NSURLQueryItem queryItemWithName:@"network_probe" value:[NSUUID UUID].UUIDString]
    ];

    NSURL *URL = components.URL;
    if (!URL) {
        return;
    }

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL
                                                           cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                                                       timeoutInterval:10.0];
    request.HTTPMethod = @"GET";

    __weak typeof(self) weakSelf = self;
    self.networkPermissionTask = [NSURLSession.sharedSession dataTaskWithRequest:request
                                                               completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) self = weakSelf;
            if (!self) {
                return;
            }
            self.networkPermissionTask = nil;
        });
    }];
    [self.networkPermissionTask resume];
}

- (void)startAppInfoRequest {
    if (self.hasStartedAppInfoRequest) {
        return;
    }

    self.hasStartedAppInfoRequest = YES;
    if (self.pathMonitor) {
        nw_path_monitor_cancel(self.pathMonitor);
        self.pathMonitor = nil;
    }
    [self routeAfterSplash];
}

- (void)routeAfterSplash {
    __weak typeof(self) weakSelf = self;
    [[YGRootManager controlHub] igniteWithReply:^(BOOL success) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) {
            return;
        }

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
