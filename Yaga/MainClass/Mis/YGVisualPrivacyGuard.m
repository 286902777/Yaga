//
//  YGVisualPrivacyGuard.m
//  Yaga
//

#import "YGVisualPrivacyGuard.h"
#import <QuartzCore/QuartzCore.h>

static NSTimeInterval const YGVisualPrivacyGuardDelay = 1.0;
static NSInteger const YGVisualPrivacyGuardSecureTextFieldTag = 54321;

@interface YGPrivacyLayerContext : NSObject

@property (nonatomic, weak) UIView *view;
@property (nonatomic, weak) CALayer *originalSuperlayer;
@property (nonatomic, assign) NSUInteger originalLayerIndex;
@property (nonatomic, strong) UITextField *secureTextField;
@property (nonatomic, copy) NSArray<NSLayoutConstraint *> *constraints;

- (instancetype)initWithView:(UIView *)view
          originalSuperlayer:(CALayer *)originalSuperlayer
          originalLayerIndex:(NSUInteger)originalLayerIndex
             secureTextField:(UITextField *)secureTextField
                 constraints:(NSArray<NSLayoutConstraint *> *)constraints;
- (void)restore;

@end

@interface UIView (YGVisualPrivacyGuard)

- (nullable YGPrivacyLayerContext *)yg_installVisualPrivacyGuard;
- (void)yg_removeVisualPrivacyGuard;

@end

@interface YGVisualPrivacyGuard ()

@property (nonatomic, strong, nullable) UIVisualEffectView *blurView;
@property (nonatomic, assign) BOOL observingScreenCapture;
@property (nonatomic, strong) NSMutableDictionary<NSValue *, dispatch_block_t> *pendingProtections;
@property (nonatomic, strong) NSMutableDictionary<NSValue *, YGPrivacyLayerContext *> *protectionContexts;

@end

@implementation YGVisualPrivacyGuard

+ (instancetype)shared {
    static YGVisualPrivacyGuard *guard;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        guard = [[YGVisualPrivacyGuard alloc] initPrivate];
    });
    return guard;
}

- (instancetype)init {
    @throw [NSException exceptionWithName:@"YGVisualPrivacyGuardInitError"
                                   reason:@"Use shared instead."
                                 userInfo:nil];
}

- (instancetype)initPrivate {
    self = [super init];
    if (self) {
        _pendingProtections = [NSMutableDictionary dictionary];
        _protectionContexts = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)dealloc {
    if (_observingScreenCapture) {
        [UIScreen.mainScreen removeObserver:self forKeyPath:@"captured"];
    }
}

- (void)protectWindow:(UIWindow *)window {
    for (UIView *view in window.subviews) {
        [self protectView:view];
    }
}

- (void)protectView:(UIView *)view {
    NSValue *identifier = [NSValue valueWithNonretainedObject:view];
    dispatch_block_t previousWork = self.pendingProtections[identifier];
    if (previousWork != nil) {
        dispatch_block_cancel(previousWork);
    }

    __weak typeof(self) weakSelf = self;
    __weak typeof(view) weakView = view;
    dispatch_block_t workItem = dispatch_block_create(0, ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        __strong typeof(weakView) strongView = weakView;
        if (strongSelf == nil || strongView == nil) {
            return;
        }

        [strongSelf.pendingProtections removeObjectForKey:identifier];
        if (strongSelf.protectionContexts[identifier] != nil) {
            return;
        }

        YGPrivacyLayerContext *context = [strongView yg_installVisualPrivacyGuard];
        if (context != nil) {
            strongSelf.protectionContexts[identifier] = context;
        }
    });

    self.pendingProtections[identifier] = workItem;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(YGVisualPrivacyGuardDelay * NSEC_PER_SEC)),
                   dispatch_get_main_queue(),
                   workItem);
}

- (void)protectFromScreenRecording {
    if (!self.observingScreenCapture) {
        [UIScreen.mainScreen addObserver:self
                              forKeyPath:@"captured"
                                 options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                                 context:nil];
        self.observingScreenCapture = YES;
        return;
    }

    [self updateRecordingShieldForScreen:UIScreen.mainScreen];
}

- (void)removeProtectionFromView:(UIView *)view {
    NSValue *identifier = [NSValue valueWithNonretainedObject:view];
    dispatch_block_t workItem = self.pendingProtections[identifier];
    if (workItem != nil) {
        dispatch_block_cancel(workItem);
        [self.pendingProtections removeObjectForKey:identifier];
    }

    YGPrivacyLayerContext *context = self.protectionContexts[identifier];
    if (context != nil) {
        [self.protectionContexts removeObjectForKey:identifier];
        [context restore];
    } else {
        [view yg_removeVisualPrivacyGuard];
    }

    if (self.observingScreenCapture) {
        [UIScreen.mainScreen removeObserver:self forKeyPath:@"captured"];
        self.observingScreenCapture = NO;
    }
    [self hideRecordingShield];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey,id> *)change
                       context:(void *)context {
    if ([keyPath isEqualToString:@"captured"] && [object isKindOfClass:UIScreen.class]) {
        UIScreen *screen = (UIScreen *)object;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateRecordingShieldForScreen:screen];
        });
        return;
    }

    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (void)updateRecordingShieldForScreen:(UIScreen *)screen {
    if (screen.isCaptured) {
        [self showRecordingShield];
    } else {
        [self hideRecordingShield];
    }
}

- (void)showRecordingShield {
    UIWindow *window = [self keyWindow];
    if (self.blurView != nil || window == nil) {
        return;
    }

    UIVisualEffectView *blurView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleRegular]];
    blurView.userInteractionEnabled = YES;
    blurView.translatesAutoresizingMaskIntoConstraints = NO;
    [window addSubview:blurView];
    [NSLayoutConstraint activateConstraints:@[
        [blurView.leadingAnchor constraintEqualToAnchor:window.leadingAnchor],
        [blurView.trailingAnchor constraintEqualToAnchor:window.trailingAnchor],
        [blurView.topAnchor constraintEqualToAnchor:window.topAnchor],
        [blurView.bottomAnchor constraintEqualToAnchor:window.bottomAnchor]
    ]];
    self.blurView = blurView;
}

- (void)hideRecordingShield {
    [self.blurView removeFromSuperview];
    self.blurView = nil;
}

- (nullable UIWindow *)keyWindow {
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if (![scene isKindOfClass:UIWindowScene.class]) {
            continue;
        }
        UIWindowScene *windowScene = (UIWindowScene *)scene;
        for (UIWindow *window in windowScene.windows) {
            if (window.isKeyWindow) {
                return window;
            }
        }
    }
    return nil;
}

@end

@implementation YGPrivacyLayerContext

- (instancetype)initWithView:(UIView *)view
          originalSuperlayer:(CALayer *)originalSuperlayer
          originalLayerIndex:(NSUInteger)originalLayerIndex
             secureTextField:(UITextField *)secureTextField
                 constraints:(NSArray<NSLayoutConstraint *> *)constraints {
    self = [super init];
    if (self) {
        _view = view;
        _originalSuperlayer = originalSuperlayer;
        _originalLayerIndex = originalLayerIndex;
        _secureTextField = secureTextField;
        _constraints = [constraints copy];
    }
    return self;
}

- (void)restore {
    [NSLayoutConstraint deactivateConstraints:self.constraints];

    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    if (self.view != nil && self.originalSuperlayer != nil) {
        [self.view.layer removeFromSuperlayer];
        NSUInteger layerCount = self.originalSuperlayer.sublayers.count;
        unsigned int restoredIndex = (unsigned int)MIN(self.originalLayerIndex, layerCount);
        [self.originalSuperlayer insertSublayer:self.view.layer atIndex:restoredIndex];
    }
    [self.secureTextField.layer removeFromSuperlayer];
    [CATransaction commit];

    [self.secureTextField removeFromSuperview];
    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
}

@end

@implementation UIView (YGVisualPrivacyGuard)

- (nullable YGPrivacyLayerContext *)yg_installVisualPrivacyGuard {
    if ([self viewWithTag:YGVisualPrivacyGuardSecureTextFieldTag] != nil || self.superview == nil || self.layer.superlayer == nil) {
        return nil;
    }

    CALayer *originalSuperlayer = self.layer.superlayer;
    NSUInteger originalLayerIndex = [originalSuperlayer.sublayers indexOfObjectIdenticalTo:self.layer];
    if (originalLayerIndex == NSNotFound) {
        return nil;
    }

    UITextField *secureTextField = [[UITextField alloc] init];
    secureTextField.tag = YGVisualPrivacyGuardSecureTextFieldTag;
    secureTextField.backgroundColor = UIColor.clearColor;
    secureTextField.userInteractionEnabled = NO;
    secureTextField.secureTextEntry = YES;
    secureTextField.translatesAutoresizingMaskIntoConstraints = NO;
    [self insertSubview:secureTextField atIndex:0];

    CALayer *secureContainer = secureTextField.layer.sublayers.lastObject;
    if (secureContainer == nil) {
        [secureTextField removeFromSuperview];
        return nil;
    }

    NSArray<NSLayoutConstraint *> *constraints = @[
        [secureTextField.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [secureTextField.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [secureTextField.topAnchor constraintEqualToAnchor:self.topAnchor],
        [secureTextField.bottomAnchor constraintEqualToAnchor:self.bottomAnchor]
    ];
    [NSLayoutConstraint activateConstraints:constraints];

    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    [originalSuperlayer addSublayer:secureTextField.layer];
    [secureContainer addSublayer:self.layer];
    [CATransaction commit];

    return [[YGPrivacyLayerContext alloc] initWithView:self
                                    originalSuperlayer:originalSuperlayer
                                    originalLayerIndex:originalLayerIndex
                                       secureTextField:secureTextField
                                           constraints:constraints];
}

- (void)yg_removeVisualPrivacyGuard {
    UITextField *secureTextField = (UITextField *)[self viewWithTag:YGVisualPrivacyGuardSecureTextFieldTag];
    CALayer *originalSuperlayer = secureTextField.layer.superlayer;
    if (![secureTextField isKindOfClass:UITextField.class] || originalSuperlayer == nil) {
        return;
    }

    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    [self.layer removeFromSuperlayer];
    NSUInteger secureLayerIndex = [originalSuperlayer.sublayers indexOfObjectIdenticalTo:secureTextField.layer];
    if (secureLayerIndex != NSNotFound) {
        [originalSuperlayer insertSublayer:self.layer atIndex:(unsigned int)secureLayerIndex];
    } else {
        [originalSuperlayer addSublayer:self.layer];
    }
    [secureTextField.layer removeFromSuperlayer];
    [CATransaction commit];

    [secureTextField removeFromSuperview];
}

@end
