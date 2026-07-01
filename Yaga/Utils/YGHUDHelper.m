//
//  YGHUDHelper.m
//  Yaga
//

#import "YGHUDHelper.h"
#import "MBProgressHUD.h"

@implementation YGHUDHelper

+ (MBProgressHUD *)showLoadingAddedTo:(UIView *)view text:(nullable NSString *)text {
    [MBProgressHUD hideHUDForView:view animated:NO];
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:view animated:YES];
    hud.label.text = text;
    hud.removeFromSuperViewOnHide = YES;
    return hud;
}

+ (void)hideLoadingForView:(UIView *)view {
    [MBProgressHUD hideHUDForView:view animated:YES];
}

+ (void)showText:(NSString *)text inView:(UIView *)view {
    [MBProgressHUD hideHUDForView:view animated:NO];
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:view animated:YES];
    hud.mode = MBProgressHUDModeText;
    hud.label.text = text;
    hud.margin = 14.0;
    hud.offset = CGPointMake(0.0, MBProgressMaxOffset);
    hud.removeFromSuperViewOnHide = YES;
    [hud hideAnimated:YES afterDelay:1.4];
}

+ (void)showCenterText:(NSString *)text inView:(UIView *)view {
    [MBProgressHUD hideHUDForView:view animated:NO];
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:view animated:YES];
    hud.mode = MBProgressHUDModeText;
    hud.label.text = text;
    hud.label.numberOfLines = 0;
    hud.margin = 16.0;
    hud.removeFromSuperViewOnHide = YES;
    [hud hideAnimated:YES afterDelay:1.6];
}

@end
