//
//  YGWebContainerViewController.h
//  Yaga
//
//  Objective-C web container controller.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^YGWebContainerCloseHandler)(void);
typedef void (^YGWebContainerInitialLoadHandler)(BOOL success);

@interface YGWebContainerViewController : UIViewController

@property (nonatomic, copy, nullable) YGWebContainerCloseHandler onClose;
@property (nonatomic, copy, nullable) YGWebContainerInitialLoadHandler onInitialLoadFinished;

+ (void)warmUpWebEngine;

- (instancetype)initWithH5Url:(nullable NSString *)h5Url NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)coder NS_DESIGNATED_INITIALIZER;

- (void)reload;
- (void)reloadWithH5Url:(nullable NSString *)h5Url;

@end

NS_ASSUME_NONNULL_END
