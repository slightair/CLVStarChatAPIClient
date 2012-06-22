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
- (void)updateUserInfo:(NSArray *)keywords
            completion:(CLVStarChatAPIBasicSuccessBlock)completion
               failure:(CLVStarChatAPIBasicFailureBlock)failure
{
#warning - not implemented.
    
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
- (void)updateChannelInfo:(NSString *)topic
               completion:(CLVStarChatAPIBasicSuccessBlock)completion
                  failure:(CLVStarChatAPIBasicFailureBlock)failure
{
#warning - not implemented.
    
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
    NSMutableURLRequest *request = [self requestWithMethod:@"GET"
                                                      path:[NSString stringWithFormat:@"/channels/%@/messages/recent", URLEncode(channelName)]
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

// GET /channels/channel_name/messages/by_time_span/start_time,end_time
- (void)messagesForChannel:(NSString *)channelName
                 startTime:(NSInteger)startTime
                   endTime:(NSInteger)endTime
                completion:(void (^)(NSArray *messages))completion
                   failure:(CLVStarChatAPIBasicFailureBlock)failure
{
#warning - not implemented.
    
}

// POST /channels/channel_name/messages
- (void)postMessage:(NSString *)message
            channel:(NSString *)channelName
             notice:(BOOL)isNotice
         completion:(CLVStarChatAPIBasicSuccessBlock)completion
            failure:(CLVStarChatAPIBasicFailureBlock)failure
{
#warning - not implemented.
    
}

// PUT /subscribings?user_name=user_name;channel_name=channel_name
- (void)subscribeChannel:(NSString *)channelName
              completion:(CLVStarChatAPIBasicSuccessBlock)completion
                 failure:(CLVStarChatAPIBasicFailureBlock)failure
{
#warning - not implemented.
    
}

// DELETE /subscribings?user_name=user_name;channel_name=channel_name
- (void)leaveChannel:(NSString *)channelName
          completion:(CLVStarChatAPIBasicSuccessBlock)completion
             failure:(CLVStarChatAPIBasicFailureBlock)failure
{
#warning - not implemented.
    
}

@end

NSString *URLEncode(NSString *string) {
    CFStringRef encodedString = CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (__bridge CFStringRef)string, NULL, CFSTR (";,/?:@&=+$#"), kCFStringEncodingUTF8);
    
    return (__bridge NSString *)encodedString;
}
