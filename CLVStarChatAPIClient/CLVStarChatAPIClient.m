//
//  CLVStarChatAPIClient.m
//  StarChatAPIClient
//
//  Created by slightair on 12/06/12.
//  Copyright (c) 2012 slightair. All rights reserved.
//

#import "CLVStarChatAPIClient.h"

NSString *URLEncode(NSString *string);

@interface CLVStarChatAPIClient ()

- (void)messagesForPath:(NSString *)path
             completion:(void (^)(NSArray *messages))completion
                failure:(CLVStarChatAPIBasicFailureBlock)failure;

@property (nonatomic, readwrite, strong) NSString *userName;

@end

@implementation CLVStarChatAPIClient

@synthesize userName = _userName;

- (void)setAuthorizationHeaderWithUsername:(NSString *)username password:(NSString *)password
{
    self.userName = username;
    [super setAuthorizationHeaderWithUsername:username password:password];
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

// GET /channels/channel_name/messages/recent
- (void)recentMessagesForChannel:(NSString *)channelName
                      completion:(void (^)(NSArray *messages))completion
                         failure:(CLVStarChatAPIBasicFailureBlock)failure
{
    [self messagesForPath:[NSString stringWithFormat:@"/channels/%@/messages/recent", URLEncode(channelName)]
               completion:completion
                  failure:failure];
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

@end

NSString *URLEncode(NSString *string) {
    CFStringRef encodedString = CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (__bridge CFStringRef)string, NULL, CFSTR (";,/?:@&=+$#"), kCFStringEncodingUTF8);
    
    return (__bridge NSString *)encodedString;
}
