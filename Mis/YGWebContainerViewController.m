//
//  YGWebContainerViewController.m
//  Yaga
//
//  Objective-C web container controller.
//

#import "YGWebContainerViewController.h"
#import <WebKit/WebKit.h>

static NSString * const YGWebContainerUserDefaultsHostUrlKey = @"HostUrl";
static NSInteger const YGWebContainerTextMaskSeed = 37;
static NSInteger const YGWebContainerTextMaskStep = 11;

@interface YGWebContainerWeakScriptMessageHandler : NSObject <WKScriptMessageHandler>

@property (nonatomic, weak, nullable) id<WKScriptMessageHandler> delegate;

- (instancetype)initWithDelegate:(id<WKScriptMessageHandler>)delegate;

@end

@interface YGWebContainerViewController () <WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler, UIGestureRecognizerDelegate>

@property (nonatomic, copy, nullable) NSString *h5Url;
@property (nonatomic, strong) UIImageView *backgroundImageView;
@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, strong) UIScreenEdgePanGestureRecognizer *edgeBackGestureRecognizer;
@property (nonatomic, strong, nullable) NSDate *loadingStartTime;
@property (nonatomic, copy) NSString *batchNo;
@property (nonatomic, copy) NSString *orderCode;
@property (nonatomic, assign) BOOL isPurchasing;
@property (nonatomic, assign) BOOL hasReportedInitialLoad;
@property (nonatomic, assign) BOOL hasProtectedScreen;

@end

@implementation YGWebContainerViewController

- (instancetype)init {
    return [self initWithH5Url:nil];
}

- (instancetype)initWithH5Url:(nullable NSString *)h5Url {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _h5Url = [h5Url copy];
        _batchNo = @"";
        _orderCode = @"";
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        _batchNo = @"";
        _orderCode = @"";
    }
    return self;
}

- (void)dealloc {
    WKUserContentController *userContentController = self.webView.configuration.userContentController;
    [userContentController removeScriptMessageHandlerForName:@"rechargePay"];
    [userContentController removeScriptMessageHandlerForName:@"Close"];
    [userContentController removeScriptMessageHandlerForName:@"openBrowser"];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
    [self loadH5];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self protectScreenIfNeeded];
    [self requestPushAuthorizationIfNeeded];
}

#pragma mark - Public

- (void)reload {
    [self reloadWithH5Url:nil];
}

- (void)reloadWithH5Url:(nullable NSString *)h5Url {
    if (h5Url.length > 0) {
        self.h5Url = h5Url;
    }
    [self loadH5];
}

#pragma mark - Setup

- (void)setupUI {
    self.view.backgroundColor = [UIColor colorWithRed:15.0 / 255.0 green:14.0 / 255.0 blue:44.0 / 255.0 alpha:1.0];

    [self.view addSubview:self.backgroundImageView];
    [self.view addSubview:self.webView];

    [NSLayoutConstraint activateConstraints:@[
        [self.backgroundImageView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.backgroundImageView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.backgroundImageView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.backgroundImageView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],

        [self.webView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.webView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.webView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.webView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
    ]];

    [self.view addGestureRecognizer:self.edgeBackGestureRecognizer];
}

- (UIImageView *)backgroundImageView {
    if (_backgroundImageView == nil) {
        UIImage *image = [UIImage imageNamed:@"rawVibeExchange"];
        if (image == nil) {
            image = [UIImage imageNamed:@"sfasdfass"];
        }

        _backgroundImageView = [[UIImageView alloc] initWithImage:image];
        _backgroundImageView.translatesAutoresizingMaskIntoConstraints = NO;
        _backgroundImageView.contentMode = UIViewContentModeScaleAspectFill;
        _backgroundImageView.clipsToBounds = YES;
        _backgroundImageView.hidden = YES;
    }
    return _backgroundImageView;
}

- (WKWebView *)webView {
    if (_webView == nil) {
        WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
        WKUserContentController *userContentController = [[WKUserContentController alloc] init];
        [userContentController addScriptMessageHandler:[[YGWebContainerWeakScriptMessageHandler alloc] initWithDelegate:self] name:@"rechargePay"];
        [userContentController addScriptMessageHandler:[[YGWebContainerWeakScriptMessageHandler alloc] initWithDelegate:self] name:@"Close"];
        [userContentController addScriptMessageHandler:[[YGWebContainerWeakScriptMessageHandler alloc] initWithDelegate:self] name:@"openBrowser"];
        configuration.userContentController = userContentController;
        configuration.allowsInlineMediaPlayback = YES;
        if (@available(iOS 10.0, *)) {
            configuration.mediaTypesRequiringUserActionForPlayback = WKAudiovisualMediaTypeNone;
        } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
            configuration.requiresUserActionForMediaPlayback = NO;
#pragma clang diagnostic pop
        }

        _webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:configuration];
        _webView.translatesAutoresizingMaskIntoConstraints = NO;
        _webView.navigationDelegate = self;
        _webView.UIDelegate = self;
        _webView.opaque = NO;
        _webView.backgroundColor = UIColor.clearColor;
        _webView.scrollView.backgroundColor = UIColor.clearColor;
        if (@available(iOS 11.0, *)) {
            _webView.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
        _webView.scrollView.contentInset = UIEdgeInsetsZero;
        _webView.scrollView.scrollIndicatorInsets = UIEdgeInsetsZero;
    }
    return _webView;
}

- (UIScreenEdgePanGestureRecognizer *)edgeBackGestureRecognizer {
    if (_edgeBackGestureRecognizer == nil) {
        _edgeBackGestureRecognizer = [[UIScreenEdgePanGestureRecognizer alloc] initWithTarget:self action:@selector(handleEdgeBackGesture:)];
        _edgeBackGestureRecognizer.edges = UIRectEdgeLeft;
        _edgeBackGestureRecognizer.delegate = self;
    }
    return _edgeBackGestureRecognizer;
}

#pragma mark - Loading

- (void)loadH5 {
    NSURL *URL = [self makeH5URL];
    if (URL == nil) {
        [self reportInitialLoadIfNeededWithSuccess:NO];
        return;
    }

    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    [self.webView loadRequest:request];
}

- (nullable NSURL *)makeH5URL {
    NSString *URLString = self.h5Url;
    if (URLString.length == 0) {
        URLString = [NSUserDefaults.standardUserDefaults stringForKey:YGWebContainerUserDefaultsHostUrlKey];
    }
    if (URLString.length == 0) {
        return nil;
    }
    return [NSURL URLWithString:URLString];
}

- (void)reportInitialLoadIfNeededWithSuccess:(BOOL)success {
    self.backgroundImageView.hidden = NO;
    if (self.hasReportedInitialLoad) {
        return;
    }

    self.hasReportedInitialLoad = YES;
    if (self.onInitialLoadFinished) {
        self.onInitialLoadFinished(success);
    }
}

- (void)notifyNativeOpenStateWithSuccess:(BOOL)success URL:(NSURL *)URL {
    NSString *state = success ? @"success" : @"failed";
    NSString *escapedURLString = [self javaScriptEscapedString:URL.absoluteString ?: @""];
    NSString *javaScript = [NSString stringWithFormat:
                            @"window.dispatchEvent(new CustomEvent('nativeOpenState', {"
                            @"detail: { state: '%@', url: '%@' }"
                            @"}));",
                            state,
                            escapedURLString];

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.webView evaluateJavaScript:javaScript completionHandler:nil];
    });
}

- (NSString *)javaScriptEscapedString:(NSString *)string {
    NSString *escaped = [string stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"];
    escaped = [escaped stringByReplacingOccurrencesOfString:@"'" withString:@"\\'"];
    escaped = [escaped stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"];
    escaped = [escaped stringByReplacingOccurrencesOfString:@"\r" withString:@"\\r"];
    return escaped;
}

#pragma mark - Navigation

- (void)handleEdgeBackGesture:(UIScreenEdgePanGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.state != UIGestureRecognizerStateRecognized) {
        return;
    }
    [self goBack];
}

- (void)goBack {
    if (self.webView.canGoBack) {
        [self.webView goBack];
    }
}

- (void)closeController {
    if (self.onClose) {
        self.onClose();
        return;
    }

    if (self.navigationController != nil) {
        [self.navigationController popViewControllerAnimated:YES];
        return;
    }

    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Native Services

- (void)protectScreenIfNeeded {
    if (self.hasProtectedScreen) {
        return;
    }

    self.hasProtectedScreen = YES;
    id screenShield = [self sharedInstanceForClassName:@"YGVisualPrivacyGuard"];
    [self invokeSelector:NSSelectorFromString(@"protectFromScreenRecording") onTarget:screenShield object:nil];
    [self invokeSelector:NSSelectorFromString(@"protectView:") onTarget:screenShield object:self.view];
}

- (void)requestPushAuthorizationIfNeeded {
    id pushService = [self sharedInstanceForClassName:@"PushNotificationService"];
    [self invokeSelector:NSSelectorFromString(@"requestAuthorizationIfNeeded") onTarget:pushService object:nil];
}

- (void)reportOpenWebTime:(NSInteger)loadingTime {
    id routeManager = [self sharedInstanceForClassName:@"RouteManager"];
    SEL selector = NSSelectorFromString(@"openWebTime:");
    NSString *timeString = [NSString stringWithFormat:@"%ld", (long)loadingTime];
    [self invokeSelector:selector onTarget:routeManager object:timeString];
}

- (void)invokeSelector:(SEL)selector onTarget:(id)target object:(nullable id)object {
    if (target == nil || selector == NULL || ![target respondsToSelector:selector]) {
        return;
    }

    NSMethodSignature *signature = [target methodSignatureForSelector:selector];
    if (signature == nil) {
        return;
    }

    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    invocation.target = target;
    invocation.selector = selector;
    if (object != nil && signature.numberOfArguments > 2) {
        [invocation setArgument:&object atIndex:2];
    }
    [invocation invoke];
}

- (nullable id)sharedInstanceForClassName:(NSString *)className {
    Class cls = NSClassFromString(className);
    if (cls == Nil) {
        return nil;
    }

    SEL sharedSelector = NSSelectorFromString(@"shared");
    if ([cls respondsToSelector:sharedSelector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        return [cls performSelector:sharedSelector];
#pragma clang diagnostic pop
    }

    SEL sharedManagerSelector = NSSelectorFromString(@"sharedManager");
    if ([cls respondsToSelector:sharedManagerSelector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        return [cls performSelector:sharedManagerSelector];
#pragma clang diagnostic pop
    }

    return nil;
}

#pragma mark - Purchase

- (void)requestPay {
    if (self.isPurchasing) {
        return;
    }

    self.isPurchasing = YES;
    self.view.userInteractionEnabled = NO;
    [self setLoadingVisible:YES];

    [self performRuntimePurchaseIfAvailableWithCompletion:^(BOOL handled, BOOL success) {
        if (!handled) {
            [self resetPurchasingState];
            [self showToast:@"Purchase fail."];
            return;
        }

        if (!success) {
            [self resetPurchasingState];
        }
    }];
}

- (void)performRuntimePurchaseIfAvailableWithCompletion:(void (^)(BOOL handled, BOOL success))completion {
    if (self.batchNo.length == 0) {
        completion(NO, NO);
        return;
    }

    id iapManager = [self sharedInstanceForClassName:@"YGIAPManager"];
    SEL selector = NSSelectorFromString(@"purchaseProductWithIdentifier:completion:");
    if (![iapManager respondsToSelector:selector]) {
        completion(NO, NO);
        return;
    }

    __weak typeof(self) weakSelf = self;
    void (^purchaseCompletion)(BOOL, NSString *) = [^(BOOL success, NSString *message) {
        __strong typeof(weakSelf) self = weakSelf;
        if (self == nil) {
            completion(YES, success);
            return;
        }

        [self resetPurchasingState];
        if (!success) {
            [self showToast:message.length > 0 ? message : @"Purchase fail."];
        }
        completion(YES, success);
    } copy];

    NSMethodSignature *signature = [iapManager methodSignatureForSelector:selector];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    invocation.target = iapManager;
    invocation.selector = selector;
    NSString *productIdentifier = self.batchNo;
    [invocation setArgument:&productIdentifier atIndex:2];
    [invocation setArgument:&purchaseCompletion atIndex:3];
    [invocation invoke];
}

- (void)finishPurchasingWithTransactionId:(NSString *)transactionId
                                  receipt:(NSString *)receipt
                                  revenue:(nullable NSNumber *)revenue
                                 currency:(nullable NSString *)currency {
    [self resetPurchasingState];

    id walletService = [self sharedInstanceForClassName:@"WalletPaymentService"];
    SEL selector = NSSelectorFromString(@"handleRechargeCallbackWithBatchNo:orderCode:receipt:revenue:currency:");
    if ([walletService respondsToSelector:selector]) {
        NSMethodSignature *signature = [walletService methodSignatureForSelector:selector];
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
        invocation.target = walletService;
        invocation.selector = selector;
        NSString *orderCode = self.orderCode ?: @"";
        [invocation setArgument:&transactionId atIndex:2];
        [invocation setArgument:&orderCode atIndex:3];
        [invocation setArgument:&receipt atIndex:4];
        [invocation setArgument:&revenue atIndex:5];
        [invocation setArgument:&currency atIndex:6];
        [invocation invoke];
    }
}

- (void)resetPurchasingState {
    self.isPurchasing = NO;
    self.view.userInteractionEnabled = YES;
    [self setLoadingVisible:NO];
}

- (void)setLoadingVisible:(BOOL)visible {
    Class loadingViewClass = NSClassFromString(@"LoadingView");
    if (visible) {
        SEL selector = NSSelectorFromString(@"showIn:message:duration:");
        if ([loadingViewClass respondsToSelector:selector]) {
            NSString *message = @"Loading...";
            NSTimeInterval duration = 60.0;
            NSMethodSignature *signature = [loadingViewClass methodSignatureForSelector:selector];
            NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
            invocation.target = loadingViewClass;
            invocation.selector = selector;
            UIView *view = self.view;
            [invocation setArgument:&view atIndex:2];
            [invocation setArgument:&message atIndex:3];
            [invocation setArgument:&duration atIndex:4];
            [invocation invoke];
        }
        return;
    }

    SEL selector = NSSelectorFromString(@"hideCurrent");
    [self invokeSelector:selector onTarget:loadingViewClass object:nil];
}

- (void)showToast:(NSString *)message {
    Class toastViewClass = NSClassFromString(@"ToastView");
    SEL selector = NSSelectorFromString(@"showMessage:in:position:duration:");
    if ([toastViewClass respondsToSelector:selector]) {
        NSInteger position = 1;
        NSTimeInterval duration = 1.8;
        NSMethodSignature *signature = [toastViewClass methodSignatureForSelector:selector];
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
        invocation.target = toastViewClass;
        invocation.selector = selector;
        UIView *view = self.view;
        [invocation setArgument:&message atIndex:2];
        [invocation setArgument:&view atIndex:3];
        [invocation setArgument:&position atIndex:4];
        [invocation setArgument:&duration atIndex:5];
        [invocation invoke];
        return;
    }

    NSLog(@"%@", message);
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    self.loadingStartTime = [NSDate date];
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    NSInteger loadingTime = 0;
    if (self.loadingStartTime != nil) {
        loadingTime = (NSInteger)([[NSDate date] timeIntervalSinceDate:self.loadingStartTime] * 1000.0);
    }

    NSLog(@"loadTime: %ld ms", (long)loadingTime);
    [self reportInitialLoadIfNeededWithSuccess:YES];
    [self reportOpenWebTime:loadingTime];
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    NSLog(@"H5 load failed: %@", error.localizedDescription);
    [self reportInitialLoadIfNeededWithSuccess:NO];
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    NSLog(@"H5 provisional load failed: %@", error.localizedDescription);
    [self reportInitialLoadIfNeededWithSuccess:NO];
}

- (void)webView:(WKWebView *)webView
decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction
decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    NSURL *URL = navigationAction.request.URL;
    NSString *scheme = URL.scheme.lowercaseString;
    if (URL == nil || scheme.length == 0) {
        decisionHandler(WKNavigationActionPolicyAllow);
        return;
    }

    NSSet<NSString *> *allowedSchemes = [NSSet setWithObjects:@"http", @"https", @"file", @"about", nil];
    if (![allowedSchemes containsObject:scheme]) {
        [UIApplication.sharedApplication openURL:URL options:@{} completionHandler:^(BOOL success) {
            [self notifyNativeOpenStateWithSuccess:success URL:URL];
        }];
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }

    decisionHandler(WKNavigationActionPolicyAllow);
}

#pragma mark - WKUIDelegate

- (nullable WKWebView *)webView:(WKWebView *)webView
 createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration
            forNavigationAction:(WKNavigationAction *)navigationAction
                 windowFeatures:(WKWindowFeatures *)windowFeatures {
    NSURL *URL = navigationAction.request.URL;
    if (URL == nil) {
        return nil;
    }

    NSString *URLString = URL.absoluteString.lowercaseString;
    if ([URL.scheme isEqualToString:[self hyAppStoreScheme]] || [URLString containsString:[self hyAppStoreHost]]) {
        [UIApplication.sharedApplication openURL:URL options:@{} completionHandler:nil];
        return nil;
    }

    [webView loadRequest:[NSURLRequest requestWithURL:URL]];
    return nil;
}

- (void)webView:(WKWebView *)webView
requestMediaCapturePermissionForOrigin:(WKSecurityOrigin *)origin
initiatedByFrame:(WKFrameInfo *)frame
           type:(WKMediaCaptureType)type
decisionHandler:(void (^)(WKPermissionDecision decision))decisionHandler API_AVAILABLE(ios(15.0)) {
    decisionHandler(WKPermissionDecisionGrant);
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer == self.edgeBackGestureRecognizer) {
        return self.webView.canGoBack || self.navigationController != nil || self.presentingViewController != nil;
    }

    return YES;
}

#pragma mark - WKScriptMessageHandler

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    if ([message.name isEqualToString:@"rechargePay"] && [message.body isKindOfClass:NSDictionary.class]) {
        NSDictionary *body = (NSDictionary *)message.body;
        NSString *batchNo = [body[@"batchNo"] isKindOfClass:NSString.class] ? body[@"batchNo"] : @"";
        NSString *orderCode = [body[@"orderCode"] isKindOfClass:NSString.class] ? body[@"orderCode"] : @"";
        self.batchNo = batchNo;
        self.orderCode = orderCode;
        [self requestPay];
        return;
    }

    if ([message.name isEqualToString:@"Close"]) {
        [self closeController];
        return;
    }

    if ([message.name isEqualToString:@"openBrowser"] && [message.body isKindOfClass:NSDictionary.class]) {
        NSDictionary *body = (NSDictionary *)message.body;
        NSString *URLString = [body[@"url"] isKindOfClass:NSString.class] ? body[@"url"] : nil;
        NSURL *URL = [NSURL URLWithString:URLString ?: @""];
        if (URL != nil) {
            [UIApplication.sharedApplication openURL:URL options:@{} completionHandler:^(BOOL success) {
                [self notifyNativeOpenStateWithSuccess:success URL:URL];
            }];
        }
    }
}

#pragma mark - Obfuscated Web Target

- (NSString *)hyAppStoreScheme {
    UInt8 bytes[] = {142, 164, 168, 185, 126, 189, 215, 226, 240};
    return [self decodeShiftedBytes:bytes length:sizeof(bytes)];
}

- (NSString *)hyAppStoreHost {
    UInt8 bytes[] = {134, 160, 171, 185, 127, 189, 215, 226, 233, 237, 193, 1, 24, 33};
    return [self decodeShiftedBytes:bytes length:sizeof(bytes)];
}

- (NSString *)decodeShiftedBytes:(const UInt8 *)bytes length:(NSUInteger)length {
    NSMutableData *data = [NSMutableData dataWithLength:length];
    UInt8 *decoded = data.mutableBytes;
    for (NSUInteger index = 0; index < length; index += 1) {
        NSInteger shift = YGWebContainerTextMaskSeed + (NSInteger)index * YGWebContainerTextMaskStep;
        decoded[index] = (UInt8)((NSInteger)bytes[index] - shift);
    }
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] ?: @"";
}

@end

@implementation YGWebContainerWeakScriptMessageHandler

- (instancetype)initWithDelegate:(id<WKScriptMessageHandler>)delegate {
    self = [super init];
    if (self) {
        _delegate = delegate;
    }
    return self;
}

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    [self.delegate userContentController:userContentController didReceiveScriptMessage:message];
}

@end
