//
//  YGWebContainerViewController.m
//  Yaga
//
//  Objective-C web container controller.
//

#import "YGWebContainerViewController.h"
#import "YGRootManager.h"
#import "YGSecretCodec.h"
#import "YGHUDHelper.h"
#import "AppDelegate.h"
#import <StoreKit/StoreKit.h>
#import <WebKit/WebKit.h>

static NSInteger const YGWebContainerTextMaskSeed = 37;
static NSInteger const YGWebContainerTextMaskStep = 11;
static WKWebView *YGWebContainerWarmWebView = nil;

@interface YGWebContainerWeakScriptMessageHandler : NSObject <WKScriptMessageHandler>

@property (nonatomic, weak, nullable) id<WKScriptMessageHandler> delegate;

- (instancetype)initWithDelegate:(id<WKScriptMessageHandler>)delegate;

@end

@interface YGWebContainerViewController () <WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler, UIGestureRecognizerDelegate, SKProductsRequestDelegate, SKPaymentTransactionObserver>

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
@property (nonatomic, assign) BOOL hasRetriedWebContentTermination;
@property (nonatomic, strong, nullable) SKProductsRequest *productsRequest;
@property (nonatomic, strong, nullable) SKProduct *purchaseProduct;
@property (nonatomic, assign) BOOL hasRegisteredPaymentObserver;

+ (WKProcessPool *)sharedProcessPool;

@end

@implementation YGWebContainerViewController

+ (void)warmUpWebEngine {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
        configuration.processPool = [self sharedProcessPool];
        configuration.websiteDataStore = WKWebsiteDataStore.defaultDataStore;
        YGWebContainerWarmWebView = [[WKWebView alloc] initWithFrame:CGRectMake(0.0, 0.0, 1.0, 1.0) configuration:configuration];
        [YGWebContainerWarmWebView loadHTMLString:@"<html><body></body></html>" baseURL:nil];
    });
}

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
    [self.productsRequest cancel];
    self.productsRequest.delegate = nil;
    if (self.hasRegisteredPaymentObserver) {
        [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
    }

    WKUserContentController *userContentController = self.webView.configuration.userContentController;
    [userContentController removeScriptMessageHandlerForName:@"rechargePay"];
    [userContentController removeScriptMessageHandlerForName:@"Close"];
    [userContentController removeScriptMessageHandlerForName:@"openBrowser"];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self registerPaymentObserverIfNeeded];
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
        UIImage *image = [UIImage imageNamed:@"aassdfsd"];
        
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
        configuration.processPool = [self.class sharedProcessPool];
        configuration.websiteDataStore = WKWebsiteDataStore.defaultDataStore;
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

+ (WKProcessPool *)sharedProcessPool {
    static WKProcessPool *processPool = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        processPool = [[WKProcessPool alloc] init];
    });
    return processPool;
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
        NSLog(@"H5 URL is nil.");
        [self reportInitialLoadIfNeededWithSuccess:NO];
        return;
    }

    NSLog(@"Loading H5 URL: %@", URL.absoluteString);
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    [self.webView loadRequest:request];
}

- (nullable NSURL *)makeH5URL {
    NSString *URLString = self.h5Url ?: [self assembledGatewayURLString];
    if (URLString.length == 0) {
        return nil;
    }
    return [NSURL URLWithString:URLString];
}

- (nullable NSString *)assembledGatewayURLString {
    NSString *token = [YGSecretCodec accessTicket];
    NSString *baseURLString = [NSUserDefaults.standardUserDefaults stringForKey:YGRootLandingURLDefaultsKey];
    if (baseURLString.length == 0 || token.length == 0) {
        return nil;
    }

    long long timestamp = (long long)(NSDate.date.timeIntervalSince1970 * 1000.0);
    NSDictionary<NSString *, id> *openParams = @{
        @"token": token,
        @"timestamp": @(timestamp)
    };

    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:openParams options:0 error:nil];
    if (jsonData.length == 0) {
        return nil;
    }

    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    if (jsonString.length == 0) {
        return nil;
    }

    NSString *encryptedParams = [YGSecretCodec sealPayloadText:jsonString error:nil];
    if (encryptedParams.length == 0) {
        return nil;
    }

    return [NSString stringWithFormat:@"%@?openParams=%@&appId=%@", baseURLString, encryptedParams, [YGSecretCodec bundleChannel]];
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

    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) {
            return;
        }
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
        [self prepareWebViewForClose];
        self.onClose();
        return;
    }
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey: @"yaga.directLogin.didCallGotoLogin"];
    [self prepareWebViewForClose];
    if (self.navigationController != nil) {
        [self.navigationController popViewControllerAnimated:YES];
        return;
    }

    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)prepareWebViewForClose {
    [self.webView stopLoading];
    self.webView.navigationDelegate = nil;
    self.webView.UIDelegate = nil;
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
    id<UIApplicationDelegate> delegate = UIApplication.sharedApplication.delegate;
    if (![delegate isKindOfClass:AppDelegate.class]) {
        return;
    }

    [(AppDelegate *)delegate registerRemoteNotificationsIfNeeded];
}

- (void)reportOpenWebTime:(NSInteger)loadingTime {
    id routeManager = [self sharedInstanceForClassName:@"YGRootManager"];
    SEL selector = NSSelectorFromString(@"markWebVisitAt:");
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

    SEL controlHubSelector = NSSelectorFromString(@"controlHub");
    if ([cls respondsToSelector:controlHubSelector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        return [cls performSelector:controlHubSelector];
#pragma clang diagnostic pop
    }

    return nil;
}

#pragma mark - Purchase

- (void)requestPay {
    if (self.isPurchasing) {
        return;
    }

    if (self.batchNo.length == 0) {
        [self showToast:@"Product identifier is empty."];
        return;
    }

    if (![SKPaymentQueue canMakePayments]) {
        [self showToast:@"In-App Purchase is unavailable."];
        return;
    }

    self.isPurchasing = YES;
    self.view.userInteractionEnabled = NO;
    [self setLoadingVisible:YES];

    [self.productsRequest cancel];
    self.productsRequest.delegate = nil;
    self.purchaseProduct = nil;

    self.productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithObject:self.batchNo]];
    self.productsRequest.delegate = self;
    [self.productsRequest start];
}

- (void)registerPaymentObserverIfNeeded {
    if (self.hasRegisteredPaymentObserver) {
        return;
    }

    self.hasRegisteredPaymentObserver = YES;
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
}

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    if (![NSThread isMainThread]) {
        __weak typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf productsRequest:request didReceiveResponse:response];
        });
        return;
    }

    self.productsRequest.delegate = nil;
    self.productsRequest = nil;

    SKProduct *product = response.products.firstObject;
    if (product == nil) {
        [self resetPurchasingState];
        [self showToast:@"Product is unavailable."];
        return;
    }

    self.purchaseProduct = product;
    SKMutablePayment *payment = [SKMutablePayment paymentWithProduct:product];
    payment.applicationUsername = self.orderCode ?: @"";
    [[SKPaymentQueue defaultQueue] addPayment:payment];
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error {
    if (![NSThread isMainThread]) {
        __weak typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf request:request didFailWithError:error];
        });
        return;
    }

    if (request == self.productsRequest) {
        self.productsRequest.delegate = nil;
        self.productsRequest = nil;
    }

    [self resetPurchasingState];
    [self showToast:error.localizedDescription ?: @"Unable to request product."];
}

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray<SKPaymentTransaction *> *)transactions {
    if (![NSThread isMainThread]) {
        __weak typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf paymentQueue:queue updatedTransactions:transactions];
        });
        return;
    }

    for (SKPaymentTransaction *transaction in transactions) {
        switch (transaction.transactionState) {
            case SKPaymentTransactionStatePurchased:
                [self handlePurchasedTransaction:transaction];
                break;
            case SKPaymentTransactionStateFailed:
                [self handleFailedTransaction:transaction];
                break;
            case SKPaymentTransactionStateRestored:
                [queue finishTransaction:transaction];
                break;
            case SKPaymentTransactionStatePurchasing:
            case SKPaymentTransactionStateDeferred:
                break;
        }
    }
}

- (void)handlePurchasedTransaction:(SKPaymentTransaction *)transaction {
    NSString *transactionId = transaction.transactionIdentifier ?: @"";
    NSString *receipt = [self appStoreReceiptText];
    NSNumber *revenue = self.purchaseProduct.price;
    NSString *currency = [self currencyCodeForProduct:self.purchaseProduct];

    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
    [self finishPurchasingWithTransactionId:transactionId
                                    receipt:receipt
                                    revenue:revenue
                                   currency:currency];
}

- (void)handleFailedTransaction:(SKPaymentTransaction *)transaction {
    NSError *error = transaction.error;
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
    [self resetPurchasingState];
    if (error.code == SKErrorPaymentCancelled) {
        [self showToast:@"Purchase cancelled."];
        return;
    }

    [self showToast:error.localizedDescription ?: @"Purchase failed."];
}

- (NSString *)appStoreReceiptText {
    NSURL *receiptURL = NSBundle.mainBundle.appStoreReceiptURL;
    NSData *receiptData = receiptURL ? [NSData dataWithContentsOfURL:receiptURL] : nil;
    if (receiptData.length == 0) {
        return @"";
    }

    return [receiptData base64EncodedStringWithOptions:0] ?: @"";
}

- (nullable NSString *)currencyCodeForProduct:(nullable SKProduct *)product {
    if (product == nil) {
        return nil;
    }

    return [product.priceLocale objectForKey:NSLocaleCurrencyCode];
}

- (void)finishPurchasingWithTransactionId:(NSString *)transactionId
                                  receipt:(NSString *)receipt
                                  revenue:(nullable NSNumber *)revenue
                                 currency:(nullable NSString *)currency {
    [self resetPurchasingState];
    [[YGRootManager controlHub] submitReceiptWithTrace:transactionId ?: @""
                                             orderTag:self.orderCode ?: @""
                                              receipt:receipt ?: @""
                                              revenue:revenue
                                             currency:currency];

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
    if (visible) {
        [YGHUDHelper showLoadingAddedTo:self.view text:@"Purchasing..."];
        return;
    }

    [YGHUDHelper hideLoadingForView:self.view];
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

    [YGHUDHelper showCenterText:message inView:self.view];
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    self.loadingStartTime = [NSDate date];
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    self.hasRetriedWebContentTermination = NO;

    NSInteger loadingTime = 0;
    if (self.loadingStartTime != nil) {
        loadingTime = (NSInteger)([[NSDate date] timeIntervalSinceDate:self.loadingStartTime] * 1000.0);
    }

    NSLog(@"loadTime: %ld ms", (long)loadingTime);
    [self reportInitialLoadIfNeededWithSuccess:YES];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey: @"yaga.directLogin.didCallGotoLogin"];
    [self reportOpenWebTime:loadingTime];
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    NSLog(@"H5 load failed: %@", error.localizedDescription);
    [self showToast:error.localizedDescription ?: @"Load failed."];
    [self reportInitialLoadIfNeededWithSuccess:NO];
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    NSLog(@"H5 provisional load failed: %@", error.localizedDescription);
    [self showToast:error.localizedDescription ?: @"Load failed."];
    [self reportInitialLoadIfNeededWithSuccess:NO];
}

- (void)webViewWebContentProcessDidTerminate:(WKWebView *)webView {
    NSLog(@"H5 WebContent process terminated.");
    if (self.hasRetriedWebContentTermination) {
        [self reportInitialLoadIfNeededWithSuccess:NO];
        return;
    }

    self.hasRetriedWebContentTermination = YES;
    [webView reload];
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
        __weak typeof(self) weakSelf = self;
        [UIApplication.sharedApplication openURL:URL options:@{} completionHandler:^(BOOL success) {
            __strong typeof(weakSelf) self = weakSelf;
            if (!self) {
                return;
            }
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
            __weak typeof(self) weakSelf = self;
            [UIApplication.sharedApplication openURL:URL options:@{} completionHandler:^(BOOL success) {
                __strong typeof(weakSelf) self = weakSelf;
                if (!self) {
                    return;
                }
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
