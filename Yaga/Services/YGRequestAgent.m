//
//  YGRequestAgent.m
//  Yaga
//

#import "YGRequestAgent.h"
#import "../Utils/YGSecretCodec.h"

NSErrorDomain const YGRequestAgentErrorDomain = @"app.yaga.request-agent";

static NSString * const YGRequestAgentRemoteMessageKey = @"message";
static NSString * const YGRequestAgentRemoteErrorKey = @"error";
static NSTimeInterval const YGRequestAgentTimeout = 30.0;

static NSString *YGWireVerbToken(YGWireVerb verb) {
    switch (verb) {
        case YGWireVerbFetch:
            return @"GET";
        case YGWireVerbCreate:
            return @"POST";
        case YGWireVerbReplace:
            return @"PUT";
        case YGWireVerbRevise:
            return @"PATCH";
        case YGWireVerbRemove:
            return @"DELETE";
    }
}

@interface YGRequestAgent ()

@property (nonatomic, strong) NSURLSession *client;
@property (nonatomic, strong) NSOperationQueue *callbackQueue;

@end

@implementation YGRequestAgent

+ (YGRequestAgent *)sharedAgent {
    static YGRequestAgent *agent;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        agent = [[YGRequestAgent alloc] initWithClient:NSURLSession.sharedSession
                                         callbackQueue:NSOperationQueue.mainQueue];
    });
    return agent;
}

- (instancetype)initWithClient:(NSURLSession *)client
                 callbackQueue:(NSOperationQueue *)callbackQueue {
    self = [super init];
    if (self) {
        _client = client ?: NSURLSession.sharedSession;
        _callbackQueue = callbackQueue ?: NSOperationQueue.mainQueue;
    }
    return self;
}

- (NSURL *)rootAddress {
    return [NSURL URLWithString:@"https://opi.i32823wk.link/"];
}

- (nullable NSURLSessionDataTask *)loadEndpoint:(NSString *)endpoint
                                          query:(nullable NSDictionary<NSString *,id> *)query
                                   headerFields:(nullable NSDictionary<NSString *,NSString *> *)headerFields
                                         finish:(YGRequestAgentCompletion)finish {
    return [self sendEndpoint:endpoint
                         verb:YGWireVerbFetch
                         body:query
                 headerFields:headerFields
                       finish:finish];
}

- (nullable NSURLSessionDataTask *)uploadEndpoint:(NSString *)endpoint
                                            body:(nullable NSDictionary<NSString *,id> *)body
                                    headerFields:(nullable NSDictionary<NSString *,NSString *> *)headerFields
                                          finish:(YGRequestAgentCompletion)finish {
    return [self sendEndpoint:endpoint
                         verb:YGWireVerbCreate
                         body:body
                 headerFields:headerFields
                       finish:finish];
}

- (nullable NSURLSessionDataTask *)sendEndpoint:(NSString *)endpoint
                                           verb:(YGWireVerb)verb
                                           body:(nullable NSDictionary<NSString *,id> *)body
                                   headerFields:(nullable NSDictionary<NSString *,NSString *> *)headerFields
                                         finish:(YGRequestAgentCompletion)finish {
    NSError *buildError = nil;
    NSURLRequest *preparedRequest = [self requestForEndpoint:endpoint
                                                        verb:verb
                                                        body:body
                                                headerFields:headerFields
                                                       error:&buildError];
    if (preparedRequest == nil) {
        [self notifyObject:nil error:buildError finish:finish];
        return nil;
    }

    NSURLSessionDataTask *task = [self.client dataTaskWithRequest:preparedRequest
                                                completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        [self receiveJSONObjectWithData:data response:response error:error finish:finish];
    }];
    [task resume];
    return task;
}

- (nullable NSURLSessionDataTask *)sendRawEndpoint:(NSString *)endpoint
                                              verb:(YGWireVerb)verb
                                              body:(nullable NSDictionary<NSString *,id> *)body
                                      headerFields:(nullable NSDictionary<NSString *,NSString *> *)headerFields
                                            finish:(YGRequestAgentDataCompletion)finish {
    NSError *buildError = nil;
    NSURLRequest *preparedRequest = [self requestForEndpoint:endpoint
                                                        verb:verb
                                                        body:body
                                                headerFields:headerFields
                                                       error:&buildError];
    if (preparedRequest == nil) {
        [self logRawEndpoint:endpoint response:nil data:nil error:buildError];
        [self notifyData:nil error:buildError finish:finish];
        return nil;
    }

    NSURLSessionDataTask *task = [self.client dataTaskWithRequest:preparedRequest
                                                completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSError *resultError = nil;
        NSData *validData = [self verifiedPayload:data response:response error:error resultError:&resultError];
        [self logRawEndpoint:endpoint response:response data:validData ?: data error:resultError ?: error];
        [self notifyData:validData error:resultError finish:finish];
    }];
    [task resume];
    return task;
}

- (nullable NSURL *)addressForEndpoint:(NSString *)endpoint {
    NSString *cleanEndpoint = [endpoint stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (cleanEndpoint.length == 0) {
        return self.rootAddress;
    }

    NSURL *directAddress = [NSURL URLWithString:cleanEndpoint];
    if (directAddress.scheme.length > 0) {
        return directAddress;
    }

    return [NSURL URLWithString:cleanEndpoint relativeToURL:self.rootAddress].absoluteURL;
}

- (nullable NSURLRequest *)requestForEndpoint:(NSString *)endpoint
                                         verb:(YGWireVerb)verb
                                         body:(nullable NSDictionary<NSString *, id> *)body
                                 headerFields:(nullable NSDictionary<NSString *, NSString *> *)headerFields
                                        error:(NSError **)error {
    NSURL *targetAddress = [self addressForEndpoint:endpoint];
    if (targetAddress == nil) {
        [self fillError:error
                   code:YGRequestFaultCodeMalformedAddress
                message:[NSString stringWithFormat:@"Invalid request URL: %@", endpoint ?: @""]];
        return nil;
    }

    NSURL *requestAddress = targetAddress;
    if (verb == YGWireVerbFetch && body.count > 0) {
        NSURLComponents *parts = [NSURLComponents componentsWithURL:targetAddress resolvingAgainstBaseURL:NO];
        if (parts == nil) {
            [self fillError:error
                       code:YGRequestFaultCodeMalformedAddress
                    message:[NSString stringWithFormat:@"Invalid request URL: %@", endpoint ?: @""]];
            return nil;
        }
        NSArray<NSURLQueryItem *> *existingItems = parts.queryItems ?: @[];
        parts.queryItems = [existingItems arrayByAddingObjectsFromArray:[self queryItemsFromFields:body]];
        if (parts.URL == nil) {
            [self fillError:error code:YGRequestFaultCodeBadArgument message:@"Invalid request parameters."];
            return nil;
        }
        requestAddress = parts.URL;
    }

    NSMutableURLRequest *draft = [NSMutableURLRequest requestWithURL:requestAddress];
    draft.HTTPMethod = YGWireVerbToken(verb);
    draft.timeoutInterval = YGRequestAgentTimeout;
    [draft setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [headerFields enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL *stop) {
        [draft setValue:value forHTTPHeaderField:key];
    }];

    if (verb != YGWireVerbFetch && body.count > 0) {
        NSData *packedBody = [self encodedBodyFromFields:body error:error];
        if (packedBody == nil) {
            return nil;
        }
        draft.HTTPBody = packedBody;
    }

    return [draft copy];
}

- (NSArray<NSURLQueryItem *> *)queryItemsFromFields:(NSDictionary<NSString *, id> *)fields {
    NSArray<NSString *> *sortedKeys = [fields.allKeys sortedArrayUsingSelector:@selector(compare:)];
    NSMutableArray<NSURLQueryItem *> *items = [NSMutableArray arrayWithCapacity:sortedKeys.count];
    for (NSString *key in sortedKeys) {
        id value = fields[key];
        [items addObject:[NSURLQueryItem queryItemWithName:key value:[NSString stringWithFormat:@"%@", value]]];
    }
    return [items copy];
}

- (nullable NSData *)encodedBodyFromFields:(NSDictionary<NSString *, id> *)fields error:(NSError **)error {
    if (![NSJSONSerialization isValidJSONObject:fields]) {
        [self fillError:error code:YGRequestFaultCodeBadArgument message:@"Invalid request parameters."];
        return nil;
    }

    if (self.bodyEncoder != nil) {
        return self.bodyEncoder(fields, error);
    }

    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:fields options:0 error:error];
    if (jsonData == nil && error != NULL && *error == nil) {
        [self fillError:error code:YGRequestFaultCodeBadArgument message:@"Invalid request parameters."];
    }
    if (jsonData == nil) {
        return nil;
    }

    NSString *jsonText = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding] ?: @"";
    NSString *sealedText = [YGSecretCodec sealPayloadText:jsonText error:error];
    if (sealedText.length == 0) {
        return nil;
    }
    return [sealedText dataUsingEncoding:NSUTF8StringEncoding];
}

- (void)receiveJSONObjectWithData:(nullable NSData *)data
                         response:(nullable NSURLResponse *)response
                            error:(nullable NSError *)error
                           finish:(YGRequestAgentCompletion)finish {
    NSError *resultError = nil;
    NSData *validData = [self verifiedPayload:data response:response error:error resultError:&resultError];
    if (validData == nil) {
        [self notifyObject:nil error:resultError finish:finish];
        return;
    }

    NSError *parseError = nil;
    id object = [NSJSONSerialization JSONObjectWithData:validData options:0 error:&parseError];
    if (object == nil) {
        [self fillError:&parseError code:YGRequestFaultCodeDecodeIssue message:@"Failed to parse the server response."];
        [self notifyObject:nil error:parseError finish:finish];
        return;
    }
    [self notifyObject:object error:nil finish:finish];
}

- (nullable NSData *)verifiedPayload:(nullable NSData *)data
                            response:(nullable NSURLResponse *)response
                               error:(nullable NSError *)error
                         resultError:(NSError **)resultError {
    if (error != nil) {
        [self fillError:resultError code:YGRequestFaultCodeTransport message:error.localizedDescription];
        return nil;
    }

    if (![response isKindOfClass:NSHTTPURLResponse.class]) {
        [self fillError:resultError code:YGRequestFaultCodeNoPayload message:@"The server returned an empty response."];
        return nil;
    }

    NSData *payload = data ?: [NSData data];
    NSInteger statusCode = ((NSHTTPURLResponse *)response).statusCode;
    if (statusCode < 200 || statusCode >= 300) {
        NSString *message = [self remoteMessageFromPayload:payload] ?: [NSString stringWithFormat:@"Request failed with status code %@.", @(statusCode)];
        [self fillError:resultError code:YGRequestFaultCodeRemoteRejected message:message];
        return nil;
    }

    if (payload.length == 0) {
        [self fillError:resultError code:YGRequestFaultCodeNoPayload message:@"The server returned an empty response."];
        return nil;
    }

    return payload;
}

- (void)logRawEndpoint:(NSString *)endpoint
              response:(nullable NSURLResponse *)response
                  data:(nullable NSData *)data
                 error:(nullable NSError *)error {
    NSInteger statusCode = 0;
    if ([response isKindOfClass:NSHTTPURLResponse.class]) {
        statusCode = ((NSHTTPURLResponse *)response).statusCode;
    }

    if (error != nil) {
        NSLog(@"[YGRequestAgent] Raw request failed. endpoint=%@ status=%ld domain=%@ code=%ld message=%@",
              endpoint ?: @"",
              (long)statusCode,
              error.domain,
              (long)error.code,
              error.localizedDescription ?: @"");
        if (data.length > 0) {
            NSString *responseText = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] ?: @"<non-utf8 data>";
            NSLog(@"[YGRequestAgent] Raw failure body. endpoint=%@ length=%lu body=%@",
                  endpoint ?: @"",
                  (unsigned long)data.length,
                  responseText);
        }
        return;
    }

    NSString *responseText = data.length > 0 ? ([[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] ?: @"<non-utf8 data>") : @"";
    NSLog(@"[YGRequestAgent] Raw request succeeded. endpoint=%@ status=%ld length=%lu body=%@",
          endpoint ?: @"",
          (long)statusCode,
          (unsigned long)data.length,
          responseText);
}

- (nullable NSString *)remoteMessageFromPayload:(NSData *)payload {
    if (payload.length == 0) {
        return nil;
    }

    id jsonObject = [NSJSONSerialization JSONObjectWithData:payload options:0 error:nil];
    if ([jsonObject isKindOfClass:NSDictionary.class]) {
        NSDictionary *dictionary = (NSDictionary *)jsonObject;
        NSString *message = dictionary[YGRequestAgentRemoteMessageKey];
        if ([message isKindOfClass:NSString.class] && message.length > 0) {
            return message;
        }
        NSString *remoteError = dictionary[YGRequestAgentRemoteErrorKey];
        if ([remoteError isKindOfClass:NSString.class] && remoteError.length > 0) {
            return remoteError;
        }
    }

    return [[NSString alloc] initWithData:payload encoding:NSUTF8StringEncoding];
}

- (void)notifyObject:(nullable id)object error:(nullable NSError *)error finish:(YGRequestAgentCompletion)finish {
    if (finish == nil) {
        return;
    }
    [self.callbackQueue addOperationWithBlock:^{
        finish(object, error);
    }];
}

- (void)notifyData:(nullable NSData *)data error:(nullable NSError *)error finish:(YGRequestAgentDataCompletion)finish {
    if (finish == nil) {
        return;
    }
    [self.callbackQueue addOperationWithBlock:^{
        finish(data, error);
    }];
}

- (void)fillError:(NSError **)error code:(YGRequestFaultCode)code message:(NSString *)message {
    if (error == NULL) {
        return;
    }
    *error = [NSError errorWithDomain:YGRequestAgentErrorDomain
                                 code:code
                             userInfo:@{NSLocalizedDescriptionKey: message ?: @"Request failed."}];
}

@end
