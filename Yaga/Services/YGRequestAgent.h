//
//  YGRequestAgent.h
//  Yaga
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, YGWireVerb) {
    YGWireVerbFetch,
    YGWireVerbCreate,
    YGWireVerbReplace,
    YGWireVerbRevise,
    YGWireVerbRemove
};

typedef NS_ENUM(NSInteger, YGRequestFaultCode) {
    YGRequestFaultCodeMalformedAddress = 1001,
    YGRequestFaultCodeNoPayload = 1002,
    YGRequestFaultCodeBadArgument = 1003,
    YGRequestFaultCodeDecodeIssue = 1004,
    YGRequestFaultCodeRemoteRejected = 1005,
    YGRequestFaultCodeTransport = 1006
};

FOUNDATION_EXPORT NSErrorDomain const YGRequestAgentErrorDomain;

typedef void (^YGRequestAgentCompletion)(id _Nullable object, NSError * _Nullable error);
typedef void (^YGRequestAgentDataCompletion)(NSData * _Nullable payload, NSError * _Nullable error);
typedef NSData * _Nullable (^YGRequestAgentBodyEncoder)(NSDictionary<NSString *, id> *fields, NSError * _Nullable * _Nullable error);

@interface YGRequestAgent : NSObject

@property (class, nonatomic, readonly) YGRequestAgent *sharedAgent;

@property (nonatomic, readonly) NSURL *rootAddress;
@property (nonatomic, copy, nullable) YGRequestAgentBodyEncoder bodyEncoder;

- (instancetype)initWithClient:(NSURLSession *)client
                 callbackQueue:(NSOperationQueue *)callbackQueue NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (nullable NSURLSessionDataTask *)loadEndpoint:(NSString *)endpoint
                                          query:(nullable NSDictionary<NSString *, id> *)query
                                   headerFields:(nullable NSDictionary<NSString *, NSString *> *)headerFields
                                         finish:(YGRequestAgentCompletion)finish;

- (nullable NSURLSessionDataTask *)uploadEndpoint:(NSString *)endpoint
                                            body:(nullable NSDictionary<NSString *, id> *)body
                                    headerFields:(nullable NSDictionary<NSString *, NSString *> *)headerFields
                                          finish:(YGRequestAgentCompletion)finish;

- (nullable NSURLSessionDataTask *)sendEndpoint:(NSString *)endpoint
                                           verb:(YGWireVerb)verb
                                           body:(nullable NSDictionary<NSString *, id> *)body
                                   headerFields:(nullable NSDictionary<NSString *, NSString *> *)headerFields
                                         finish:(YGRequestAgentCompletion)finish;

- (nullable NSURLSessionDataTask *)sendRawEndpoint:(NSString *)endpoint
                                              verb:(YGWireVerb)verb
                                              body:(nullable NSDictionary<NSString *, id> *)body
                                      headerFields:(nullable NSDictionary<NSString *, NSString *> *)headerFields
                                            finish:(YGRequestAgentDataCompletion)finish;

@end

NS_ASSUME_NONNULL_END
