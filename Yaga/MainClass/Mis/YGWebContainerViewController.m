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
#include <stdarg.h>

static NSInteger const YGWebContainerTextMaskSeed = 37;
static NSInteger const YGWebContainerTextMaskStep = 11;
static WKWebView *YGWebContainerWarmWebView = nil;

static NSString *YGWebContainerDecodedText(const UInt8 *bytes, NSUInteger length) {
    NSMutableData *data = [NSMutableData dataWithLength:length];
    UInt8 *decoded = data.mutableBytes;
    for (NSUInteger index = 0; index < length; index += 1) {
        NSInteger shift = YGWebContainerTextMaskSeed + (NSInteger)index * YGWebContainerTextMaskStep;
        decoded[index] = (UInt8)((NSInteger)bytes[index] - shift);
    }
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] ?: @"";
}

static void YGWebContainerLog(NSString *format, ...) {
    va_list arguments;
    va_start(arguments, format);
    NSLogv(format, arguments);
    va_end(arguments);
}

#define YGWebText(...) YGWebContainerDecodedText((const UInt8[]){__VA_ARGS__}, sizeof((const UInt8[]){__VA_ARGS__}))

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


@end

@implementation YGWebContainerViewController

+ (void)warmUpWebEngine {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
        configuration.websiteDataStore = WKWebsiteDataStore.nonPersistentDataStore;
        YGWebContainerWarmWebView = [[WKWebView alloc] initWithFrame:CGRectMake(0.0, 0.0, 1.0, 1.0) configuration:configuration];
        [YGWebContainerWarmWebView loadHTMLString:YGWebText(97, 152, 175, 179, 189, 154, 163, 212, 236, 236, 12, 220, 229, 227, 33, 57, 57, 89, 41, 50, 48, 116, 139, 143, 153, 118) baseURL:nil];
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
    [userContentController removeScriptMessageHandlerForName:YGWebText(151, 149, 158, 174, 178, 206, 206, 215, 205, 233, 12)];
    [userContentController removeScriptMessageHandlerForName:YGWebText(104, 156, 170, 185, 182)];
    [userContentController removeScriptMessageHandlerForName:YGWebText(148, 160, 160, 180, 147, 206, 214, 233, 240, 237, 5)];
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
        UIImage *image = [UIImage imageNamed:YGWebText(134, 145, 174, 185, 181, 194, 218, 214)];
        
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
        configuration.websiteDataStore = WKWebsiteDataStore.nonPersistentDataStore;
        WKUserContentController *userContentController = [[WKUserContentController alloc] init];
        [userContentController addScriptMessageHandler:[[YGWebContainerWeakScriptMessageHandler alloc] initWithDelegate:self] name:YGWebText(151, 149, 158, 174, 178, 206, 206, 215, 205, 233, 12)];
        [userContentController addScriptMessageHandler:[[YGWebContainerWeakScriptMessageHandler alloc] initWithDelegate:self] name:YGWebText(104, 156, 170, 185, 182)];
        [userContentController addScriptMessageHandler:[[YGWebContainerWeakScriptMessageHandler alloc] initWithDelegate:self] name:YGWebText(148, 160, 160, 180, 147, 206, 214, 233, 240, 237, 5)];
        configuration.userContentController = userContentController;
        configuration.allowsInlineMediaPlayback = YES;
        configuration.mediaTypesRequiringUserActionForPlayback = WKAudiovisualMediaTypeAll;

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
        YGWebContainerLog(YGWebText(109, 101, 91, 155, 163, 168, 135, 219, 240, 168, 1, 7, 21, 226));
        [self reportInitialLoadIfNeededWithSuccess:NO];
        return;
    }

    YGWebContainerLog(YGWebText(113, 159, 156, 170, 186, 202, 206, 146, 197, 189, 179, 243, 251, 0, 249, 234, 250, 32), URL.absoluteString);
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
        YGWebText(153, 159, 166, 171, 191): token,
        YGWebText(153, 153, 168, 171, 196, 208, 200, 223, 237): @(timestamp)
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

    return [NSString stringWithFormat:YGWebText(74, 112, 122, 181, 193, 193, 213, 194, 222, 250, 244, 11, 28, 241, 228, 10, 251, 65, 91, 102, 74, 112, 84, 71, 109), baseURLString, encryptedParams, [YGSecretCodec bundleChannel]];
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
    NSString *state = success ? YGWebText(152, 165, 158, 169, 182, 207, 218) : YGWebText(139, 145, 164, 178, 182, 192);
    NSString *escapedURLString = [self javaScriptEscapedString:URL.absoluteString ?: @""];
    NSString *javaScript = [[YGWebText(156, 153, 169, 170, 192, 211, 149, 214, 230, 251, 3, 255, 29, 23, 39, 15, 75, 69, 89, 106, 41, 122, 124, 153, 77, 123, 184, 193, 205, 211, 220, 191, 251, 245, 9, 26, 217, 227, 53, 51, 81, 81, 105, 99, 88, 132, 132, 152, 136, 180, 172, 202, 198, 147, 163, 162, 8) stringByAppendingString:[NSString stringWithFormat:YGWebText(137, 149, 175, 167, 186, 200, 161, 146, 248, 168, 6, 18, 10, 40, 36, 4, 245, 7, 16, 54, 40, 56, 55, 151, 159, 164, 125, 110, 128, 137, 175, 161, 165, 13), state, escapedURLString]] stringByAppendingString:YGWebText(162, 89, 100, 129)];

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
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:YGWebText(158, 145, 162, 167, 127, 192, 208, 228, 226, 235, 7, 234, 24, 27, 40, 56, 3, 68, 84, 90, 68, 109, 131, 142, 116, 167, 183, 189, 165, 211, 214, 227, 243)];
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
    [self clearWebViewDataStore:self.webView.configuration.websiteDataStore];
    [self clearWebViewDataStore:WKWebsiteDataStore.defaultDataStore];
}

- (void)clearWebViewDataStore:(WKWebsiteDataStore *)dataStore {
    NSSet<NSString *> *dataTypes = [WKWebsiteDataStore allWebsiteDataTypes];
    NSDate *fromDate = [NSDate dateWithTimeIntervalSince1970:0];
    [dataStore removeDataOfTypes:dataTypes modifiedSince:fromDate completionHandler:^{}];
}

#pragma mark - Native Services

- (void)protectScreenIfNeeded {
    if (self.hasProtectedScreen) {
        return;
    }

    self.hasProtectedScreen = YES;
    id screenShield = [self sharedInstanceForClassName:YGWebText(126, 119, 145, 175, 196, 209, 200, 222, 205, 250, 252, 20, 10, 23, 56, 17, 74, 65, 93, 90)];
    [self invokeSelector:NSSelectorFromString(YGWebText(149, 162, 170, 186, 182, 191, 219, 184, 239, 247, 0, 241, 12, 38, 36, 47, 67, 50, 80, 89, 112, 126, 123, 139, 155, 159)) onTarget:screenShield object:nil];
    [self invokeSelector:NSSelectorFromString(YGWebText(149, 162, 170, 186, 182, 191, 219, 200, 230, 237, 10, 216)) onTarget:screenShield object:self.view];
}

- (void)requestPushAuthorizationIfNeeded {
    id<UIApplicationDelegate> delegate = UIApplication.sharedApplication.delegate;
    if (![delegate isKindOfClass:AppDelegate.class]) {
        return;
    }

    [(AppDelegate *)delegate registerRemoteNotificationsIfNeeded];
}

- (void)reportOpenWebTime:(NSInteger)loadingTime {
    id routeManager = [self sharedInstanceForClassName:YGWebText(126, 119, 141, 181, 192, 208, 180, 211, 235, 233, 250, 3, 27)];
    SEL selector = NSSelectorFromString(YGWebText(146, 145, 173, 177, 168, 193, 201, 200, 230, 251, 252, 18, 234, 40, 249));
    NSString *timeString = [NSString stringWithFormat:YGWebText(74, 156, 159), (long)loadingTime];
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

    SEL sharedSelector = NSSelectorFromString(YGWebText(152, 152, 156, 184, 182, 192));
    if ([cls respondsToSelector:sharedSelector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        return [cls performSelector:sharedSelector];
#pragma clang diagnostic pop
    }

    SEL sharedManagerSelector = NSSelectorFromString(YGWebText(152, 152, 156, 184, 182, 192, 180, 211, 235, 233, 250, 3, 27));
    if ([cls respondsToSelector:sharedManagerSelector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        return [cls performSelector:sharedManagerSelector];
#pragma clang diagnostic pop
    }

    SEL controlHubSelector = NSSelectorFromString(YGWebText(136, 159, 169, 186, 195, 203, 211, 186, 242, 234));
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
        [self showToast:YGWebText(117, 162, 170, 170, 198, 191, 219, 146, 230, 236, 248, 12, 29, 29, 37, 51, 58, 82, 11, 95, 116, 44, 124, 143, 157, 172, 188, 124)];
        return;
    }

    if (![SKPaymentQueue canMakePayments]) {
        [self showToast:YGWebText(110, 158, 104, 135, 193, 204, 135, 194, 242, 250, 246, 6, 10, 39, 36, 234, 62, 83, 11, 107, 111, 109, 141, 131, 150, 164, 164, 176, 197, 201, 157)];
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
        [self showToast:YGWebText(117, 162, 170, 170, 198, 191, 219, 146, 230, 251, 179, 19, 23, 21, 53, 43, 62, 76, 76, 88, 109, 113, 69)];
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
    [self showToast:error.localizedDescription ?: YGWebText(122, 158, 156, 168, 189, 193, 135, 230, 236, 168, 5, 3, 26, 41, 36, 61, 73, 0, 91, 104, 112, 112, 140, 133, 161, 102)];
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
        [self showToast:YGWebText(117, 165, 173, 169, 185, 189, 218, 215, 157, 235, 244, 12, 12, 25, 43, 54, 58, 68, 25)];
        return;
    }

    [self showToast:error.localizedDescription ?: YGWebText(117, 165, 173, 169, 185, 189, 218, 215, 157, 238, 244, 7, 21, 25, 35, 248)];
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

    id walletService = [self sharedInstanceForClassName:YGWebText(124, 145, 167, 178, 182, 208, 183, 211, 246, 245, 248, 12, 29, 7, 36, 60, 75, 73, 78, 91)];
    SEL selector = NSSelectorFromString(YGWebText(141, 145, 169, 170, 189, 193, 185, 215, 224, 240, 244, 16, 16, 25, 2, 43, 65, 76, 77, 87, 100, 119, 110, 139, 161, 160, 133, 175, 205, 199, 215, 200, 244, 202, 10, 24, 21, 33, 57, 21, 76, 76, 88, 56, 123, 121, 130, 143, 158, 176, 191, 144, 211, 209, 237, 231, 251, 13, 8, 232, 28, 57, 65, 76, 74, 94, 94, 127, 75));
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
        [YGHUDHelper showLoadingAddedTo:self.view text:YGWebText(117, 165, 173, 169, 185, 189, 218, 219, 235, 239, 193, 204, 215)];
        return;
    }

    [YGHUDHelper hideLoadingForView:self.view];
}

- (void)showToast:(NSString *)message {
    Class toastViewClass = NSClassFromString(YGWebText(121, 159, 156, 185, 197, 178, 208, 215, 244));
    SEL selector = NSSelectorFromString(YGWebText(152, 152, 170, 189, 158, 193, 218, 229, 222, 239, 248, 216, 18, 34, 249, 58, 68, 83, 84, 106, 106, 123, 133, 92, 145, 173, 181, 175, 205, 205, 222, 232, 191));
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

    YGWebContainerLog(YGWebText(145, 159, 156, 170, 165, 197, 212, 215, 183, 168, 184, 10, 13, 212, 44, 61), (long)loadingTime);
    [self reportInitialLoadIfNeededWithSuccess:YES];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:YGWebText(158, 145, 162, 167, 127, 192, 208, 228, 226, 235, 7, 234, 24, 27, 40, 56, 3, 68, 84, 90, 68, 109, 131, 142, 116, 167, 183, 189, 165, 211, 214, 227, 243)];
    [self reportOpenWebTime:loadingTime];
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    YGWebContainerLog(YGWebText(109, 101, 91, 178, 192, 189, 203, 146, 227, 233, 252, 10, 14, 24, 249, 234, 250, 32), error.localizedDescription);
    [self showToast:error.localizedDescription ?: YGWebText(113, 159, 156, 170, 113, 194, 200, 219, 233, 237, 247, 204)];
    [self reportInitialLoadIfNeededWithSuccess:NO];
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    YGWebContainerLog(YGWebText(109, 101, 91, 182, 195, 203, 221, 219, 240, 241, 2, 12, 10, 32, 223, 54, 68, 65, 79, 22, 103, 109, 128, 142, 146, 156, 125, 110, 126, 164), error.localizedDescription);
    [self showToast:error.localizedDescription ?: YGWebText(113, 159, 156, 170, 113, 194, 200, 219, 233, 237, 247, 204)];
    [self reportInitialLoadIfNeededWithSuccess:NO];
}

- (void)webViewWebContentProcessDidTerminate:(WKWebView *)webView {
    YGWebContainerLog(YGWebText(109, 101, 91, 157, 182, 190, 170, 225, 235, 252, 248, 12, 29, 212, 47, 60, 68, 67, 80, 105, 116, 44, 139, 135, 159, 165, 172, 188, 186, 216, 212, 222, 179));
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

    NSSet<NSString *> *allowedSchemes = [NSSet setWithObjects:
                                         YGWebText(141, 164, 175, 182),
                                         YGWebText(141, 164, 175, 182, 196),
                                         YGWebText(139, 153, 167, 171),
                                         YGWebText(134, 146, 170, 187, 197),
                                         nil];
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
    if ([message.name isEqualToString:YGWebText(151, 149, 158, 174, 178, 206, 206, 215, 205, 233, 12)] && [message.body isKindOfClass:NSDictionary.class]) {
        NSDictionary *body = (NSDictionary *)message.body;
        NSString *batchNoKey = YGWebText(135, 145, 175, 169, 185, 170, 214);
        NSString *orderCodeKey = YGWebText(148, 162, 159, 171, 195, 159, 214, 214, 226);
        NSString *batchNo = [body[batchNoKey] isKindOfClass:NSString.class] ? body[batchNoKey] : @"";
        NSString *orderCode = [body[orderCodeKey] isKindOfClass:NSString.class] ? body[orderCodeKey] : @"";
        self.batchNo = batchNo;
        self.orderCode = orderCode;
        [self requestPay];
        return;
    }

    if ([message.name isEqualToString:YGWebText(104, 156, 170, 185, 182)]) {
        [self closeController];
        return;
    }

    if ([message.name isEqualToString:YGWebText(148, 160, 160, 180, 147, 206, 214, 233, 240, 237, 5)] && [message.body isKindOfClass:NSDictionary.class]) {
        NSDictionary *body = (NSDictionary *)message.body;
        NSString *URLKey = YGWebText(154, 162, 167);
        NSString *URLString = [body[URLKey] isKindOfClass:NSString.class] ? body[URLKey] : nil;
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
    return YGWebText(142, 164, 168, 185, 126, 189, 215, 226, 240);
}

- (NSString *)hyAppStoreHost {
    return YGWebText(134, 160, 171, 185, 127, 189, 215, 226, 233, 237, 193, 1, 24, 33);
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
