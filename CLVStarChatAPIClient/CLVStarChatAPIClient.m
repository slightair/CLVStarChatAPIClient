//
//  CLVStarChatAPIClient.m
//  StarChatAPIClient
//
//  Created by slightair on 12/06/12.
//  Copyright (c) 2012 slightair. All rights reserved.
//

#import "CLVStarChatAPIClient.h"

#define kClientBufferSize 2048
#define kReconnectThreshold 90

NSString *URLEncode(NSString *string);

// CFNetwork CFReadStreamClientCallBack
void readHttpStreamCallBack(CFReadStreamRef stream, CFStreamEventType eventType, void *clientCallBackInfo);

@interface CLVStarChatAPIClient ()

- (BOOL)checkStatusCode:(NSInteger)statusCode;
- (void)messagesForPath:(NSString *)path
             completion:(void (^)(NSArray *messages))completion
                failure:(CLVStarChatAPIBasicFailureBlock)failure;
- (NSArray *)messagesForPath:(NSString *)path error:(NSError **)error;
- (void)releaseReadStream;
- (void)connectUserStreamAPI;
- (void)stopKeepConnectionTimer;
- (void)checkPacketInterval;

@property (nonatomic, strong, readwrite) NSString *userName;
@property (nonatomic, assign, readwrite) CLVStarChatUserStreamConnectionStatus connectionStatus;
@property (nonatomic, strong) SBJsonStreamParserAdapter *streamParserAdapter;
@property (nonatomic, strong) SBJsonStreamParser *streamParser;
@property (nonatomic, strong) NSTimer *keepConnectionTimer;
@property (nonatomic, assign) CFReadStreamRef readStreamRef;
@property (nonatomic, assign) time_t lastPacketReceivedAt;
@property (nonatomic, assign) AFNetworkReachabilityStatus reachabilityStatus;

// AFHTTPClient
@property (readwrite, nonatomic, retain) NSMutableDictionary *defaultHeaders;

@end

@implementation CLVStarChatAPIClient

@synthesize delegate = _delegate;
@synthesize userName = _userName;
@synthesize connectionStatus = _connectionStatus;
@synthesize isAutoConnect = _isAutoConnect;
@synthesize streamParserAdapter = _streamParserAdapter;
@synthesize streamParser = _streamParser;
@synthesize keepConnectionTimer = _keepConnectionTimer;
@synthesize readStreamRef = _readStreamRef;
@synthesize lastPacketReceivedAt = _lastPacketReceivedAt;
@synthesize reachabilityStatus = _reachabilityStatus;

// AFHTTPClient
@synthesize defaultHeaders = _defaultHeaders;

- (void)setAuthorizationHeaderWithUsername:(NSString *)username password:(NSString *)password
{
    self.userName = username;
    [super setAuthorizationHeaderWithUsername:username password:password];
}

- (id)initWithBaseURL:(NSURL *)url
{
    self = [super initWithBaseURL:url];
    if (self) {
        SBJsonStreamParserAdapter *adapter = [[SBJsonStreamParserAdapter alloc] init];
        adapter.delegate = self;
        
        SBJsonStreamParser *parser = [[SBJsonStreamParser alloc] init];
        parser.delegate = adapter;
        parser.supportMultipleDocuments = YES;
        
        self.streamParserAdapter = adapter;
        self.streamParser = parser;
        self.connectionStatus = CLVStarChatUserStreamConnectionStatusNone;
        self.isAutoConnect = NO;
        self.reachabilityStatus = AFNetworkReachabilityStatusUnknown;
        
        __unsafe_unretained CLVStarChatAPIClient *client = self;
        self.reachabilityStatusChangeBlock = ^(AFNetworkReachabilityStatus status){
            if (self.reachabilityStatus == status) {
                return;
            }
            self.reachabilityStatus = status;
            
            if (!client.isAutoConnect) {
                return;
            }
            
            if (!client.userName) {
                return;
            }
            
            if (status != AFNetworkReachabilityStatusNotReachable) {
                [client startUserStreamConnection];
                if ([client.delegate respondsToSelector:@selector(userStreamClientDidAutoConnect:)]) {
                    [client.delegate userStreamClientDidAutoConnect:client];
                }
            }
        };
    }
    return self;
}

// GET /users/user_name
- (void)userInfoForName:(NSString *)userName
             completion:(void (^)(CLVStarChatUserInfo *userInfo))completion
                failure:(CLVStarChatAPIBasicFailureBlock)failure
{
    NSMutableURLRequest *request = [self requestWithMethod:@"GET"
                                                      path:[NSString stringWithFormat:@"/users/%@", userName]
                                                parameters:nil];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request
        success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON){
            CLVStarChatUserInfo *userInfo = [CLVStarChatUserInfo userInfoWithDictionary:JSON];
            completion(userInfo);
        }
        failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON){
            failure(error);
        }];
    [operation start];
}

- (CLVStarChatUserInfo *)userInfoForName:(NSString *)userName
                                   error:(NSError **)error
{
    NSMutableURLRequest *request = [self requestWithMethod:@"GET"
                                                      path:[NSString stringWithFormat:@"/users/%@", userName]
                                                parameters:nil];
    
    NSError *localError = nil;
    NSURLResponse *response = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&localError];
    
    if (localError) {
        if (error) {
            *error = localError;
        }
        return nil;
    }
    
    NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
    if (![self checkStatusCode:statusCode]) {
        if (error) {
            *error = [NSError errorWithDomain:CLVStarChatAPIErrorDomain
                                         code:NSURLErrorBadServerResponse
                                     userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"Unexpected HTTP status code %d", statusCode]
                                                                          forKey:NSLocalizedDescriptionKey]];
        }
        return nil;
    }
    
    NSString *JSONString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    return [CLVStarChatUserInfo userInfoWithDictionary:[JSONString JSONValue]];
}

// PUT /users/user_name
- (void)updateUserInfoWithNick:(NSString *)nick
                      keywords:(NSArray *)keywords
                    completion:(CLVStarChatAPIBasicSuccessBlock)completion
                       failure:(CLVStarChatAPIBasicFailureBlock)failure
{
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                                nick, @"nick",
                                keywords, @"keywords",
                                nil];
    
    NSMutableURLRequest *request = [self requestWithMethod:@"PUT"
                                                      path:[NSString stringWithFormat:@"/users/%@", self.userName]
                                                parameters:parameters];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject){
        completion();
    }
                                     failure:^(AFHTTPRequestOperation *operation, NSError *error){
                                         failure(error);
                                     }];
    [operation start];
}

- (BOOL)updateUserInfoWithNick:(NSString *)nick
                      keywords:(NSArray *)keywords
                         error:(NSError **)error
{
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                                nick, @"nick",
                                keywords, @"keywords",
                                nil];
    
    NSMutableURLRequest *request = [self requestWithMethod:@"PUT"
                                                      path:[NSString stringWithFormat:@"/users/%@", self.userName]
                                                parameters:parameters];
    
    NSError *localError = nil;
    NSURLResponse *response = nil;
    [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&localError];
    
    if (localError) {
        if (error) {
            *error = localError;
        }
        return NO;
    }
    
    NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
    if (![self checkStatusCode:statusCode]) {
        if (error) {
            *error = [NSError errorWithDomain:CLVStarChatAPIErrorDomain
                                         code:NSURLErrorBadServerResponse
                                     userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"Unexpected HTTP status code %d", statusCode]
                                                                          forKey:NSLocalizedDescriptionKey]];
        }
        return NO;
    }
    
    return YES;
}

// GET /users/user_name/ping
- (void)sendPing:(CLVStarChatAPIBasicSuccessBlock)completion
         failure:(CLVStarChatAPIBasicFailureBlock)failure
{
    NSMutableURLRequest *request = [self requestWithMethod:@"GET"
                                                      path:[NSString stringWithFormat:@"/users/%@/ping", self.userName]
                                                parameters:nil];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request
        success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON){
            if (![[JSON objectForKey:@"result"] isEqualToString:@"pong"]) {
                NSError *error = [NSError errorWithDomain:CLVStarChatAPIErrorDomain code:CLVStarChatAPIErrorUnknown userInfo:JSON];
                failure(error);
            }
            completion();
        }
        failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON){
            failure(error);
        }];
    [operation start];
}

- (BOOL)sendPing:(NSError **)error
{
    NSMutableURLRequest *request = [self requestWithMethod:@"GET"
                                                      path:[NSString stringWithFormat:@"/users/%@/ping", self.userName]
                                                parameters:nil];
    
    NSError *localError = nil;
    NSURLResponse *response = nil;
    [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&localError];
    
    if (localError) {
        if (error) {
            *error = localError;
        }
        return NO;
    }
    
    NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
    if (![self checkStatusCode:statusCode]) {
        if (error) {
            *error = [NSError errorWithDomain:CLVStarChatAPIErrorDomain
                                         code:NSURLErrorBadServerResponse
                                     userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"Unexpected HTTP status code %d", statusCode]
                                                                          forKey:NSLocalizedDescriptionKey]];
        }
        return NO;
    }
    
    return YES;
}

// GET /users/user_name/channels
- (void)subscribedChannels:(void (^)(NSArray *channels))completion
                   failure:(CLVStarChatAPIBasicFailureBlock)failure
{
    NSMutableURLRequest *request = [self requestWithMethod:@"GET"
                                                      path:[NSString stringWithFormat:@"/users/%@/channels", self.userName]
                                                parameters:nil];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request
        success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON){
            if (![JSON isKindOfClass:[NSArray class]]) {
                NSError *error = [NSError errorWithDomain:CLVStarChatAPIErrorDomain code:CLVStarChatAPIErrorUnexpectedResponse userInfo:JSON];
                failure(error);
            }
            
            NSMutableArray *channels = [NSMutableArray array];
            for (NSDictionary *channelInfo in JSON) {
                @autoreleasepool {
                    [channels addObject:[CLVStarChatChannelInfo channelInfoWithDictionary:channelInfo]];
                }
            }
            
            completion([NSArray arrayWithArray:channels]);
        }
        failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON){
            failure(error);
        }];
    [operation start];
}

- (NSArray *)subscribedChannels:(NSError **)error
{
    NSMutableURLRequest *request = [self requestWithMethod:@"GET"
                                                      path:[NSString stringWithFormat:@"/users/%@/channels", self.userName]
                                                parameters:nil];
    
    NSError *localError = nil;
    NSURLResponse *response = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&localError];
    
    if (localError) {
        if (error) {
            *error = localError;
        }
        return nil;
    }
    
    NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
    if (![self checkStatusCode:statusCode]) {
        if (error) {
            *error = [NSError errorWithDomain:CLVStarChatAPIErrorDomain
                                         code:NSURLErrorBadServerResponse
                                     userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"Unexpected HTTP status code %d", statusCode]
                                                                          forKey:NSLocalizedDescriptionKey]];
        }
        return nil;
    }
    
    NSString *JSONString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    NSMutableArray *channels = [NSMutableArray array];
    for (NSDictionary *channelInfo in [JSONString JSONValue]) {
        @autoreleasepool {
            [channels addObject:[CLVStarChatChannelInfo channelInfoWithDictionary:channelInfo]];
        }
    }
    
    return [NSArray arrayWithArray:channels];
}

// GET /channels/channel_name
- (void)channelInfoForName:(NSString *)channelName
                completion:(void (^)(CLVStarChatChannelInfo *channelInfo))completion
                   failure:(CLVStarChatAPIBasicFailureBlock)failure
{
    NSMutableURLRequest *request = [self requestWithMethod:@"GET"
                                                      path:[NSString stringWithFormat:@"/channels/%@", URLEncode(channelName)]
                                                parameters:nil];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request
        success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON){
            CLVStarChatChannelInfo *channelInfo = [CLVStarChatChannelInfo channelInfoWithDictionary:JSON];
            completion(channelInfo);
        }
        failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON){
            failure(error);
        }];
    [operation start];
}

- (CLVStarChatChannelInfo *)channelInfoForName:(NSString *)channelName error:(NSError **)error
{
    NSMutableURLRequest *request = [self requestWithMethod:@"GET"
                                                      path:[NSString stringWithFormat:@"/channels/%@", URLEncode(channelName)]
                                                parameters:nil];
    
    NSError *localError = nil;
    NSURLResponse *response = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&localError];
    
    if (localError) {
        if (error) {
            *error = localError;
        }
        return nil;
    }
    
    NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
    if (![self checkStatusCode:statusCode]) {
        if (error) {
            *error = [NSError errorWithDomain:CLVStarChatAPIErrorDomain
                                         code:NSURLErrorBadServerResponse
                                     userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"Unexpected HTTP status code %d", statusCode]
                                                                          forKey:NSLocalizedDescriptionKey]];
        }
        return nil;
    }
    
    NSString *JSONString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    return [CLVStarChatChannelInfo channelInfoWithDictionary:[JSONString JSONValue]];
}

// PUT /channels/channel_name
- (void)updateChannelInfo:(NSString *)channelName
                    topic:(NSString *)topic
                  private:(BOOL)isPrivate
               completion:(CLVStarChatAPIBasicSuccessBlock)completion
                  failure:(CLVStarChatAPIBasicFailureBlock)failure;
{
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                                topic, @"topic[body]",
                                (isPrivate ? @"private" : @"public"), @"privacy",
                                nil];
    
    NSMutableURLRequest *request = [self requestWithMethod:@"PUT"
                                                      path:[NSString stringWithFormat:@"/channels/%@", URLEncode(channelName)]
                                                parameters:parameters];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject){
        completion();
    }
                                     failure:^(AFHTTPRequestOperation *operation, NSError *error){
                                         failure(error);
                                     }];
    [operation start];
}

- (BOOL)updateChannelInfo:(NSString *)channelName
                    topic:(NSString *)topic
                  private:(BOOL)isPrivate
                    error:(NSError **)error
{
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                                topic, @"topic[body]",
                                (isPrivate ? @"private" : @"public"), @"privacy",
                                nil];
    
    NSMutableURLRequest *request = [self requestWithMethod:@"PUT"
                                                      path:[NSString stringWithFormat:@"/channels/%@", URLEncode(channelName)]
                                                parameters:parameters];
    
    NSError *localError = nil;
    NSURLResponse *response = nil;
    [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&localError];
    
    if (localError) {
        if (error) {
            *error = localError;
        }
        return NO;
    }
    
    NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
    if (![self checkStatusCode:statusCode]) {
        if (error) {
            *error = [NSError errorWithDomain:CLVStarChatAPIErrorDomain
                                         code:NSURLErrorBadServerResponse
                                     userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"Unexpected HTTP status code %d", statusCode]
                                                                          forKey:NSLocalizedDescriptionKey]];
        }
        return NO;
    }
    
    return YES;
}

// GET /channels/channel_name/users
- (void)usersForChannel:(NSString *)channelName
             completion:(void (^)(NSArray *users))completion
                failure:(CLVStarChatAPIBasicFailureBlock)failure;
{
    NSMutableURLRequest *request = [self requestWithMethod:@"GET"
                                                      path:[NSString stringWithFormat:@"/channels/%@/users", URLEncode(channelName)]
                                                parameters:nil];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request
        success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON){
            if (![JSON isKindOfClass:[NSArray class]]) {
                NSError *error = [NSError errorWithDomain:CLVStarChatAPIErrorDomain code:CLVStarChatAPIErrorUnexpectedResponse userInfo:JSON];
                failure(error);
            }
            
            NSMutableArray *users = [NSMutableArray array];
            for (NSDictionary *userInfo in JSON) {
                @autoreleasepool {
                    [users addObject:[CLVStarChatUserInfo userInfoWithDictionary:userInfo]];
                }
            }
            
            completion([NSArray arrayWithArray:users]);
        }
        failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON){
            failure(error);
        }];
    [operation start];
}

- (NSArray *)usersForChannel:(NSString *)channelName
                       error:(NSError **)error
{
    NSMutableURLRequest *request = [self requestWithMethod:@"GET"
                                                      path:[NSString stringWithFormat:@"/channels/%@/users", URLEncode(channelName)]
                                                parameters:nil];
    
    NSError *localError = nil;
    NSURLResponse *response = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&localError];
    
    if (localError) {
        if (error) {
            *error = localError;
        }
        return nil;
    }
    
    NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
    if (![self checkStatusCode:statusCode]) {
        if (error) {
            *error = [NSError errorWithDomain:CLVStarChatAPIErrorDomain
                                         code:NSURLErrorBadServerResponse
                                     userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"Unexpected HTTP status code %d", statusCode]
                                                                          forKey:NSLocalizedDescriptionKey]];
        }
        return nil;
    }
    
    NSString *JSONString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    NSMutableArray *users = [NSMutableArray array];
    for (NSDictionary *userInfo in [JSONString JSONValue]) {
        @autoreleasepool {
            [users addObject:[CLVStarChatUserInfo userInfoWithDictionary:userInfo]];
        }
    }
    
    return [NSArray arrayWithArray:users];
}

// GET /channels/channel_name/messages/recent
- (void)recentMessagesForChannel:(NSString *)channelName
                      completion:(void (^)(NSArray *messages))completion
                         failure:(CLVStarChatAPIBasicFailureBlock)failure
{
    [self messagesForPath:[NSString stringWithFormat:@"/channels/%@/messages/recent", URLEncode(channelName)]
               completion:completion
                  failure:failure];
}

- (NSArray *)recentMessagesForChannel:(NSString *)channelName
                                error:(NSError **)error
{
    return [self messagesForPath:[NSString stringWithFormat:@"/channels/%@/messages/recent", URLEncode(channelName)]
                           error:error];
}

// GET /channels/channel_name/messages/by_time_span/start_time,end_time
- (void)messagesForChannel:(NSString *)channelName
                 startTime:(NSInteger)startTime
                   endTime:(NSInteger)endTime
                completion:(void (^)(NSArray *messages))completion
                   failure:(CLVStarChatAPIBasicFailureBlock)failure
{
    [self messagesForPath:[NSString stringWithFormat:@"/channels/%@/messages/by_time_span/%ld,%ld", URLEncode(channelName), startTime, endTime]
               completion:completion
                  failure:failure];
}

- (NSArray *)messagesForChannel:(NSString *)channelName
                      startTime:(NSInteger)startTime
                        endTime:(NSInteger)endTime
                          error:(NSError **)error
{
    return [self messagesForPath:[NSString stringWithFormat:@"/channels/%@/messages/by_time_span/%ld,%ld", URLEncode(channelName), startTime, endTime]
                           error:error];
}

// POST /channels/channel_name/messages
- (void)postMessage:(NSString *)message
            channel:(NSString *)channelName
             notice:(BOOL)isNotice
      temporaryNick:(NSString *)temporaryNick
         completion:(CLVStarChatAPIBasicSuccessBlock)completion
            failure:(CLVStarChatAPIBasicFailureBlock)failure
{
    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                message, @"body",
                                (isNotice ? @"true" : @"false"), @"notice",
                                nil];
    
    if (temporaryNick && [temporaryNick isKindOfClass:[NSString class]]) {
        [parameters setObject:temporaryNick forKey:@"temporary_nick"];
    }
    
    NSMutableURLRequest *request = [self requestWithMethod:@"POST"
                                                      path:[NSString stringWithFormat:@"/channels/%@/messages", URLEncode(channelName)]
                                                parameters:parameters];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject){
        completion();
    }
                                     failure:^(AFHTTPRequestOperation *operation, NSError *error){
                                         failure(error);
                                     }];
    [operation start];
}

- (BOOL)postMessage:(NSString *)message
            channel:(NSString *)channelName
             notice:(BOOL)isNotice
      temporaryNick:(NSString *)temporaryNick
              error:(NSError **)error
{
    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                       message, @"body",
                                       (isNotice ? @"true" : @"false"), @"notice",
                                       nil];
    
    if (temporaryNick && [temporaryNick isKindOfClass:[NSString class]]) {
        [parameters setObject:temporaryNick forKey:@"temporary_nick"];
    }
    
    NSMutableURLRequest *request = [self requestWithMethod:@"POST"
                                                      path:[NSString stringWithFormat:@"/channels/%@/messages", URLEncode(channelName)]
                                                parameters:parameters];
    
    NSError *localError = nil;
    NSURLResponse *response = nil;
    [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&localError];
    
    if (localError) {
        if (error) {
            *error = localError;
        }
        return NO;
    }
    
    NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
    if (![self checkStatusCode:statusCode]) {
        if (error) {
            *error = [NSError errorWithDomain:CLVStarChatAPIErrorDomain
                                         code:NSURLErrorBadServerResponse
                                     userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"Unexpected HTTP status code %d", statusCode]
                                                                          forKey:NSLocalizedDescriptionKey]];
        }
        return NO;
    }
    
    return YES;
}

// PUT /subscribings?user_name=user_name;channel_name=channel_name
- (void)subscribeChannel:(NSString *)channelName
              completion:(CLVStarChatAPIBasicSuccessBlock)completion
                 failure:(CLVStarChatAPIBasicFailureBlock)failure
{
    NSString *path = [NSString stringWithFormat:@"/subscribings?user_name=%@&channel_name=%@", self.userName, URLEncode(channelName)];
    NSMutableURLRequest *request = [self requestWithMethod:@"PUT"
                                                      path:path
                                                parameters:nil];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject){
        completion();
    }
                                     failure:^(AFHTTPRequestOperation *operation, NSError *error){
                                         failure(error);
                                     }];
    [operation start];
}

- (BOOL)subscribeChannel:(NSString *)channelName
                   error:(NSError **)error
{
    NSString *path = [NSString stringWithFormat:@"/subscribings?user_name=%@&channel_name=%@", self.userName, URLEncode(channelName)];
    NSMutableURLRequest *request = [self requestWithMethod:@"PUT"
                                                      path:path
                                                parameters:nil];
    
    NSError *localError = nil;
    NSURLResponse *response = nil;
    [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&localError];
    
    if (localError) {
        if (error) {
            *error = localError;
        }
        return NO;
    }
    
    NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
    if (![self checkStatusCode:statusCode]) {
        if (error) {
            *error = [NSError errorWithDomain:CLVStarChatAPIErrorDomain
                                         code:NSURLErrorBadServerResponse
                                     userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"Unexpected HTTP status code %d", statusCode]
                                                                          forKey:NSLocalizedDescriptionKey]];
        }
        return NO;
    }
    
    return YES;
}

// DELETE /subscribings?user_name=user_name;channel_name=channel_name
- (void)leaveChannel:(NSString *)channelName
          completion:(CLVStarChatAPIBasicSuccessBlock)completion
             failure:(CLVStarChatAPIBasicFailureBlock)failure
{
    NSString *path = [NSString stringWithFormat:@"/subscribings?user_name=%@&channel_name=%@", self.userName, URLEncode(channelName)];
    NSMutableURLRequest *request = [self requestWithMethod:@"DELETE"
                                                      path:path
                                                parameters:nil];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject){
        completion();
    }
                                     failure:^(AFHTTPRequestOperation *operation, NSError *error){
                                         failure(error);
                                     }];
    [operation start];
}

- (BOOL)leaveChannel:(NSString *)channelName
               error:(NSError **)error
{
    NSString *path = [NSString stringWithFormat:@"/subscribings?user_name=%@&channel_name=%@", self.userName, URLEncode(channelName)];
    NSMutableURLRequest *request = [self requestWithMethod:@"DELETE"
                                                      path:path
                                                parameters:nil];
    
    NSError *localError = nil;
    NSURLResponse *response = nil;
    [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&localError];
    
    if (localError) {
        if (error) {
            *error = localError;
        }
        return NO;
    }
    
    NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
    if (![self checkStatusCode:statusCode]) {
        if (error) {
            *error = [NSError errorWithDomain:CLVStarChatAPIErrorDomain
                                         code:NSURLErrorBadServerResponse
                                     userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"Unexpected HTTP status code %d", statusCode]
                                                                          forKey:NSLocalizedDescriptionKey]];
        }
        return NO;
    }
    
    return YES;
}

#pragma mark -
#pragma mark UserStream

- (void)startUserStreamConnection
{
    if (self.connectionStatus == CLVStarChatUserStreamConnectionStatusConnecting ||
        self.connectionStatus == CLVStarChatUserStreamConnectionStatusConnected) {
        return;
    }
    
    [self stopKeepConnectionTimer];
    
    [self connectUserStreamAPI];
    self.keepConnectionTimer = [NSTimer scheduledTimerWithTimeInterval:1
                                                                target:self
                                                              selector:@selector(checkPacketInterval)
                                                              userInfo:nil
                                                               repeats:YES];
}

- (void)stopUserStreamConnection
{
    if (self.connectionStatus != CLVStarChatUserStreamConnectionStatusConnecting &&
        self.connectionStatus != CLVStarChatUserStreamConnectionStatusConnected) {
        return;
    }
    
    [self stopKeepConnectionTimer];
    
    if (self.readStreamRef) {
        CFReadStreamUnscheduleFromRunLoop(self.readStreamRef, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
        CFReadStreamClose(self.readStreamRef);
        [self releaseReadStream];
    }
    
    self.connectionStatus = CLVStarChatUserStreamConnectionStatusDisconnected;
    if ([self.delegate respondsToSelector:@selector(userStreamClientDidDisconnected:)]) {
        [self.delegate userStreamClientDidDisconnected:self];
    }
}

- (void)releaseReadStream
{
    if (self.readStreamRef) {
        CFRelease(self.readStreamRef);
    }
    self.readStreamRef = NULL;
}

- (void)connectUserStreamAPI
{
    if (self.readStreamRef) {
        CFReadStreamUnscheduleFromRunLoop(self.readStreamRef, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
        CFReadStreamClose(self.readStreamRef);
        [self releaseReadStream];
    }
    
    self.connectionStatus = CLVStarChatUserStreamConnectionStatusConnecting;
    if ([self.delegate respondsToSelector:@selector(userStreamClientWillConnect:)]) {
        [self.delegate userStreamClientWillConnect:self];
    }
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"/users/%@/stream", self.userName] relativeToURL:self.baseURL];
    CFURLRef urlRef = CFURLCreateWithString(kCFAllocatorDefault, (__bridge CFStringRef)[url absoluteString], NULL);
    
    CFHTTPMessageRef messageRef = CFHTTPMessageCreateRequest(kCFAllocatorDefault, CFSTR("GET"), urlRef, kCFHTTPVersion1_1);
    for (NSString *headerFieldName in self.defaultHeaders) {
        CFHTTPMessageSetHeaderFieldValue(messageRef, (__bridge CFStringRef)headerFieldName, (__bridge CFStringRef)[self defaultValueForHeader:headerFieldName]);
    }
    CFHTTPMessageSetHeaderFieldValue(messageRef, CFSTR("Accept"), CFSTR("application/json"));
    
    self.readStreamRef = CFReadStreamCreateForHTTPRequest(kCFAllocatorDefault, messageRef);
    CFStreamClientContext contextRef = {0, (__bridge void *)self, NULL, NULL, NULL};
    
    if (CFReadStreamSetClient(self.readStreamRef,
                              (kCFStreamEventOpenCompleted  |
                               kCFStreamEventHasBytesAvailable |
                               kCFStreamEventEndEncountered |
                               kCFStreamEventErrorOccurred),
                              &readHttpStreamCallBack,
                              &contextRef)) {
        CFReadStreamScheduleWithRunLoop(self.readStreamRef, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
    }
    CFReadStreamOpen(self.readStreamRef);
    
    CFRelease(messageRef);
    CFRelease(urlRef);
}

- (void)stopKeepConnectionTimer
{
    if ([self.keepConnectionTimer isValid]) {
        [self.keepConnectionTimer invalidate];
    }
}

- (void)checkPacketInterval
{
    time_t now = time(NULL);
    
    if (now > (self.lastPacketReceivedAt + kReconnectThreshold)) {
        [self connectUserStreamAPI];
    }
}

- (void)dealloc
{
    [self stopKeepConnectionTimer];
    
    if (self.readStreamRef) {
        CFRelease(self.readStreamRef);
    }
}

#pragma mark -
#pragma mark SBJsonStreamParserAdapterDelegate Methods

- (void)parser:(SBJsonStreamParser *)parser foundObject:(NSDictionary *)dict
{
    if ([self.delegate respondsToSelector:@selector(userStreamClient:didReceivedPacket:)]) {
        [self.delegate userStreamClient:self didReceivedPacket:dict];
    }
}

- (void)parser:(SBJsonStreamParser *)parser foundArray:(NSArray *)array
{
}

#pragma mark -
#pragma mark Private Methods

- (void)messagesForPath:(NSString *)path
             completion:(void (^)(NSArray *messages))completion
                failure:(CLVStarChatAPIBasicFailureBlock)failure
{
    NSMutableURLRequest *request = [self requestWithMethod:@"GET"
                                                      path:path
                                                parameters:nil];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request
        success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON){
            if (![JSON isKindOfClass:[NSArray class]]) {
                NSError *error = [NSError errorWithDomain:CLVStarChatAPIErrorDomain code:CLVStarChatAPIErrorUnexpectedResponse userInfo:JSON];
                failure(error);
            }
            
            NSMutableArray *messages = [NSMutableArray array];
            for (NSDictionary *messageInfo in JSON) {
                @autoreleasepool {
                    [messages addObject:[CLVStarChatMessageInfo messageInfoWithDictionary:messageInfo]];
                }
            }
            
            completion([NSArray arrayWithArray:messages]);
        }
        failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON){
            failure(error);
        }];
    [operation start];
}

- (NSArray *)messagesForPath:(NSString *)path
                       error:(NSError **)error
{
    NSMutableURLRequest *request = [self requestWithMethod:@"GET"
                                                      path:path
                                                parameters:nil];
    
    NSError *localError = nil;
    NSURLResponse *response = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&localError];
    
    if (localError) {
        if (error) {
            *error = localError;
        }
        return nil;
    }
    
    NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
    if (![self checkStatusCode:statusCode]) {
        if (error) {
            *error = [NSError errorWithDomain:CLVStarChatAPIErrorDomain
                                         code:NSURLErrorBadServerResponse
                                     userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"Unexpected HTTP status code %d", statusCode]
                                                                          forKey:NSLocalizedDescriptionKey]];
        }
        return nil;
    }
    
    NSString *JSONString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    NSMutableArray *messages = [NSMutableArray array];
    for (NSDictionary *messageInfo in [JSONString JSONValue]) {
        @autoreleasepool {
            [messages addObject:[CLVStarChatMessageInfo messageInfoWithDictionary:messageInfo]];
        }
    }
    
    return [NSArray arrayWithArray:messages];
}

- (BOOL)checkStatusCode:(NSInteger)statusCode
{
    if (statusCode < 200 || 300 <= statusCode) {
        return NO;
    }
    return YES;
}

@end

NSString *URLEncode(NSString *string) {
    CFStringRef encodedString = CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (__bridge CFStringRef)string, NULL, CFSTR (";,/?:@&=+$#"), kCFStringEncodingUTF8);
    
    return (__bridge NSString *)encodedString;
}

// CFNetwork CFReadStreamClientCallBack
void readHttpStreamCallBack(CFReadStreamRef stream, CFStreamEventType eventType, void *clientCallBackInfo) {
    CLVStarChatAPIClient *client = (__bridge CLVStarChatAPIClient *)clientCallBackInfo;
    
    switch (eventType) {
        case kCFStreamEventOpenCompleted:
        {
            client.lastPacketReceivedAt = time(NULL);
            client.connectionStatus = CLVStarChatUserStreamConnectionStatusConnected;
            
            if ([client.delegate respondsToSelector:@selector(userStreamClientDidConnected:)]) {
                [client.delegate userStreamClientDidConnected:client];
            }
            
            break;
        }
        case kCFStreamEventHasBytesAvailable:
        {
            UInt8 buffer[kClientBufferSize];
            CFIndex bytesRead = CFReadStreamRead(stream, buffer, sizeof(buffer));
            
            if (bytesRead > 0) {
                client.lastPacketReceivedAt = time(NULL);
                
                NSData *data = [NSData dataWithBytes:buffer length:bytesRead];
                [client.streamParser parse:data];
            }
            
            break;
        }
        case kCFStreamEventEndEncountered:
        {
            client.connectionStatus = CLVStarChatUserStreamConnectionStatusDisconnected;
            if ([client.delegate respondsToSelector:@selector(userStreamClientDidDisconnected:)]) {
                [client.delegate userStreamClientDidDisconnected:client];
            }
            
            CFReadStreamUnscheduleFromRunLoop(stream, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
            CFReadStreamClose(stream);
            [client releaseReadStream];
            [client stopKeepConnectionTimer];
            
            break;
        }
        case kCFStreamEventErrorOccurred:
        {
            CFErrorRef errorRef = CFReadStreamCopyError(stream);
            CFDictionaryRef userInfoRef = CFErrorCopyUserInfo(errorRef);
            NSError *error = [[NSError alloc] initWithDomain:(__bridge NSString *)CFErrorGetDomain(errorRef) code:CFErrorGetCode(errorRef) userInfo:(__bridge NSDictionary *)userInfoRef];
            
            CFRelease(userInfoRef);
            CFRelease(errorRef);
            
            client.connectionStatus = CLVStarChatUserStreamConnectionStatusFailed;
            if ([client.delegate respondsToSelector:@selector(userStreamClient:didFailWithError:)]) {
                [client.delegate userStreamClient:client didFailWithError:error];
            }
            
            CFReadStreamUnscheduleFromRunLoop(stream, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
            CFReadStreamClose(stream);
            [client releaseReadStream];
            [client stopKeepConnectionTimer];
            
            break;
        }
        default: ;
    }
}
