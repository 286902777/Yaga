//
//  YGIAPManager.m
//  Yaga
//

#import "YGIAPManager.h"
#import <StoreKit/StoreKit.h>

@interface YGIAPManager () <SKProductsRequestDelegate, SKPaymentTransactionObserver>

@property (nonatomic, strong) SKProductsRequest *productsRequest;
@property (nonatomic, copy) NSString *currentProductIdentifier;
@property (nonatomic, copy) YGIAPPurchaseCompletion currentCompletion;

@end

@implementation YGIAPManager

+ (instancetype)sharedManager {
    static YGIAPManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[YGIAPManager alloc] initPrivate];
    });
    return manager;
}

- (instancetype)init {
    @throw [NSException exceptionWithName:@"YGIAPManagerInitError"
                                   reason:@"Use sharedManager instead."
                                 userInfo:nil];
}

- (instancetype)initPrivate {
    self = [super init];
    if (self) {
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    }
    return self;
}

- (void)purchaseProductWithIdentifier:(NSString *)productIdentifier completion:(YGIAPPurchaseCompletion)completion {
    if (productIdentifier.length == 0) {
        if (completion) {
            completion(NO, @"Product identifier is empty.");
        }
        return;
    }

    if (![SKPaymentQueue canMakePayments]) {
        if (completion) {
            completion(NO, @"In-App Purchase is unavailable.");
        }
        return;
    }

    if (self.currentCompletion != nil) {
        if (completion) {
            completion(NO, @"A purchase is already in progress.");
        }
        return;
    }

    self.currentProductIdentifier = productIdentifier;
    self.currentCompletion = completion;
    self.productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithObject:productIdentifier]];
    self.productsRequest.delegate = self;
    [self.productsRequest start];
}

#pragma mark - SKProductsRequestDelegate

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    SKProduct *product = response.products.firstObject;
    if (product == nil) {
        [self finishWithSuccess:NO message:@"Product is unavailable."];
        return;
    }

    SKPayment *payment = [SKPayment paymentWithProduct:product];
    [[SKPaymentQueue defaultQueue] addPayment:payment];
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error {
    [self finishWithSuccess:NO message:error.localizedDescription ?: @"Unable to request product."];
}

#pragma mark - SKPaymentTransactionObserver

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray<SKPaymentTransaction *> *)transactions {
    for (SKPaymentTransaction *transaction in transactions) {
        switch (transaction.transactionState) {
            case SKPaymentTransactionStatePurchased:
                [self handlePurchasedTransaction:transaction];
                break;
            case SKPaymentTransactionStateFailed:
                [self handleFailedTransaction:transaction];
                break;
            case SKPaymentTransactionStateRestored:
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                break;
            case SKPaymentTransactionStatePurchasing:
            case SKPaymentTransactionStateDeferred:
                break;
        }
    }
}

- (void)handlePurchasedTransaction:(SKPaymentTransaction *)transaction {
    BOOL receiptValid = [self verifyReceiptForTransaction:transaction];
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
    if (!receiptValid) {
        [self finishWithSuccess:NO message:@"Purchase verification failed."];
        return;
    }
    [self finishWithSuccess:YES message:nil];
}

- (void)handleFailedTransaction:(SKPaymentTransaction *)transaction {
    NSError *error = transaction.error;
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
    if (error.code == SKErrorPaymentCancelled) {
        [self finishWithSuccess:NO message:@"Purchase cancelled."];
        return;
    }
    [self finishWithSuccess:NO message:error.localizedDescription ?: @"Purchase failed."];
}

- (BOOL)verifyReceiptForTransaction:(SKPaymentTransaction *)transaction {
    NSString *verifyURLString = @"xxx_receipt_verify_url";
    NSString *sharedSecret = @"xxx_shared_secret";
    NSString *bundleIdentifier = @"xxx_bundle_identifier";
    NSString *transactionIdentifier = transaction.transactionIdentifier ?: @"xxx_transaction_id";
    NSURL *receiptURL = NSBundle.mainBundle.appStoreReceiptURL;
    NSData *receiptData = [NSData dataWithContentsOfURL:receiptURL];
    NSString *receiptBase64 = [receiptData base64EncodedStringWithOptions:0] ?: @"xxx_receipt_data";

    (void)verifyURLString;
    (void)sharedSecret;
    (void)bundleIdentifier;
    (void)transactionIdentifier;
    (void)receiptBase64;

    // Replace the xxx values above and perform your server-side receipt validation here.
    return YES;
}

- (void)finishWithSuccess:(BOOL)success message:(nullable NSString *)message {
    YGIAPPurchaseCompletion completion = self.currentCompletion;
    self.currentCompletion = nil;
    self.currentProductIdentifier = nil;
    self.productsRequest.delegate = nil;
    self.productsRequest = nil;

    dispatch_async(dispatch_get_main_queue(), ^{
        if (completion) {
            completion(success, message);
        }
    });
}

@end
