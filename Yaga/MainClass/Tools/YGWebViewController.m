//
//  YGWebViewController.m
//  Yaga
//

#import "YGWebViewController.h"
#import "YGHUDHelper.h"
#import <WebKit/WebKit.h>

@interface YGWebViewController () <WKNavigationDelegate>

@property (nonatomic, copy) NSString *URLString;
@property (nonatomic, strong) WKWebView *webView;

@end

@implementation YGWebViewController

- (instancetype)initWithTitle:(NSString *)title URLString:(NSString *)URLString {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self.title = title;
        _URLString = [URLString copy];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = UIColor.whiteColor;
    [self setupWebView];
    [self loadURL];
}

- (void)setupWebView {
    WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
    self.webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:configuration];
    self.webView.translatesAutoresizingMaskIntoConstraints = NO;
    self.webView.navigationDelegate = self;
    self.webView.opaque = NO;
    self.webView.backgroundColor = UIColor.clearColor;
    self.webView.scrollView.backgroundColor = UIColor.clearColor;
    [self.view addSubview:self.webView];

    [NSLayoutConstraint activateConstraints:@[
        [self.webView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [self.webView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.webView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.webView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor]
    ]];
}

- (void)loadURL {
    NSURL *URL = [NSURL URLWithString:self.URLString];
    if (URL == nil) {
        [YGHUDHelper showCenterText:@"Invalid URL." inView:self.view];
        return;
    }
    NSURLRequest *request = [NSURLRequest requestWithURL:URL cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:20.0];
    [self.webView loadRequest:request];
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    [YGHUDHelper showLoadingAddedTo:self.view text:@"Loading..."];
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    [YGHUDHelper hideLoadingForView:self.view];
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    [self showLoadError:error];
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    [self showLoadError:error];
}

- (void)showLoadError:(NSError *)error {
    [YGHUDHelper hideLoadingForView:self.view];
    [YGHUDHelper showCenterText:error.localizedDescription ?: @"Load failed." inView:self.view];
}

@end
