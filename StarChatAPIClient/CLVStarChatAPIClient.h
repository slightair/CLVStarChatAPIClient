//
//  CLVStarChatAPIClient.h
//  StarChatAPIClient
//
//  Created by slightair on 12/06/12.
//  Copyright (c) 2012 slightair. All rights reserved.
//

#import "AFNetworking.h"
#import "CLVStarChatUserInfo.h"
#import "CLVStarChatChannelInfo.h"
#import "CLVStarChatTopicInfo.h"

@interface CLVStarChatAPIClient : AFHTTPClient

typedef void (^CLVStarChatAPIBasicSuccessBlock)(AFHTTPRequestOperation *operation);
typedef void (^CLVStarChatAPIBasicFailureBlock)(AFHTTPRequestOperation *operation, NSError *error);

// GET /users/user_name
- (void)userInfoForName:(NSString *)userName
             completion:(void (^)(AFHTTPRequestOperation *operation, CLVStarChatUserInfo *userInfo))completion
                failure:(CLVStarChatAPIBasicFailureBlock)failure;

// PUT /users/user_name
- (void)updateUserInfo:(NSArray *)keywords
            completion:(CLVStarChatAPIBasicSuccessBlock)completion
                failure:(CLVStarChatAPIBasicFailureBlock)failure;

// GET /users/user_name/ping
- (void)sendPing:(CLVStarChatAPIBasicSuccessBlock)completion
         failure:(CLVStarChatAPIBasicFailureBlock)failure;

// GET /users/user_name/channels
- (void)subscribedChannels:(void (^)(AFHTTPRequestOperation *operation, NSArray *channels))completion
                   failure:(CLVStarChatAPIBasicFailureBlock)failure;

// GET /channels/channel_name
- (void)channelInfoForName:(NSString *)channelName
                completion:(void (^)(AFHTTPRequestOperation *operation, CLVStarChatChannelInfo *channelInfo))completion
                   failure:(CLVStarChatAPIBasicFailureBlock)failure;

// PUT /channels/channel_name
- (void)updateChannelInfo:(NSString *)topic
               completion:(CLVStarChatAPIBasicSuccessBlock)completion
                  failure:(CLVStarChatAPIBasicFailureBlock)failure;

// GET /channels/channel_name/users
- (void)usersForChannel:(NSString *)channelName
             completion:(void (^)(AFHTTPRequestOperation *operation, NSArray *users))completion
                failure:(CLVStarChatAPIBasicFailureBlock)failure;

// GET /channels/channel_name/messages/recent
- (void)recentMessagesForChannel:(NSString *)channelName
                      completion:(void (^)(AFHTTPRequestOperation *operation, NSArray *messages))completion
                         failure:(CLVStarChatAPIBasicFailureBlock)failure;

// GET /channels/channel_name/messages/by_time_span/start_time,end_time
- (void)messagesForChannel:(NSString *)channelName
                 startTime:(NSInteger)startTime
                   endTime:(NSInteger)endTime
                completion:(void (^)(AFHTTPRequestOperation *operation, NSArray *messages))completion
                   failure:(CLVStarChatAPIBasicFailureBlock)failure;

// POST /channels/channel_name/messages
- (void)postMessage:(NSString *)message
            channel:(NSString *)channelName
             notice:(BOOL)isNotice
         completion:(CLVStarChatAPIBasicSuccessBlock)completion
            failure:(CLVStarChatAPIBasicFailureBlock)failure;

// PUT /subscribings?user_name=user_name;channel_name=channel_name
- (void)subscribeChannel:(NSString *)channelName
              completion:(CLVStarChatAPIBasicSuccessBlock)completion
                 failure:(CLVStarChatAPIBasicFailureBlock)failure;

// DELETE /subscribings?user_name=user_name;channel_name=channel_name
- (void)leaveChannel:(NSString *)channelName
          completion:(CLVStarChatAPIBasicSuccessBlock)completion
             failure:(CLVStarChatAPIBasicFailureBlock)failure;

@end
