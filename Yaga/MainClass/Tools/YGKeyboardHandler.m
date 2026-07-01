//
//  YGKeyboardHandler.m
//  Yaga
//

#import "YGKeyboardHandler.h"

@interface YGKeyboardHandler ()

@property (nonatomic, weak) UIView *view;
@property (nonatomic, copy) YGKeyboardHandlerBlock changeHandler;

@end

@implementation YGKeyboardHandler

- (instancetype)initWithView:(UIView *)view
               changeHandler:(YGKeyboardHandlerBlock)changeHandler {
    self = [super init];
    if (self) {
        _view = view;
        _changeHandler = [changeHandler copy];
        [self registerKeyboardNotifications];
    }
    return self;
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)registerKeyboardNotifications {
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(keyboardWillChangeFrame:)
                                               name:UIKeyboardWillChangeFrameNotification
                                             object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(keyboardWillHide:)
                                               name:UIKeyboardWillHideNotification
                                             object:nil];
}

- (void)keyboardWillChangeFrame:(NSNotification *)notification {
    UIView *view = self.view;
    if (view == nil) {
        return;
    }

    CGRect keyboardEndFrame = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect convertedFrame = [view convertRect:keyboardEndFrame fromView:nil];
    CGFloat keyboardHeight = MAX(0.0, CGRectGetMaxY(view.bounds) - CGRectGetMinY(convertedFrame));
    [self notifyChangeWithKeyboardHeight:keyboardHeight notification:notification];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    [self notifyChangeWithKeyboardHeight:0.0 notification:notification];
}

- (void)notifyChangeWithKeyboardHeight:(CGFloat)keyboardHeight notification:(NSNotification *)notification {
    if (self.changeHandler == nil) {
        return;
    }

    NSTimeInterval duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    if (duration <= 0.0) {
        duration = 0.25;
    }
    UIViewAnimationCurve curve = [notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue];
    UIViewAnimationOptions options = (UIViewAnimationOptions)(curve << 16);
    self.changeHandler(keyboardHeight, duration, options);
}

@end
