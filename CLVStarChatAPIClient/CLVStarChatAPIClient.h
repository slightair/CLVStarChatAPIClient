//
//  CLVStarChatAPIClient.h
//  StarChatAPIClient
//
//  Created by slightair on 12/06/12.
//  Copyright (c) 2012 slightair. All rights reserved.
//

#define CLVStarChatAPIErrorDomain @"CLVStarChatAPIError"

#import "AFNetworking.h"
#import "CLVStarChatUserInfo.h"
#import "CLVStarChatChannelInfo.h"
#import "CLVStarChatTopicInfo.h"
#import "CLVStarChatMessageInfo.h"
#import "SBJson.h"

#define CLVStarChatAPIClientResponseKey @"CLVStarChatAPIClientResponseKey"

enum CLVStarChatAPIErrors {
    CLVStarChatAPIErrorUnexpectedResponse = 1000,
    CLVStarChatAPIErrorUnknown = -1
};

typedef enum {
    CLVStarChatUserStreamConnectionStatusNone,
    CLVStarChatUserStreamConnectionStatusConnecting,
    CLVStarChatUserStreamConnectionStatusConnected,
    CLVStarChatUserStreamConnectionStatusDisconnected,
    CLVStarChatUserStreamConnectionStatusFailed
} CLVStarChatUserStreamConnectionStatus;

@class CLVStarChatAPIClient;

@protocol CLVStarChatAPIClientDelegate <NSObject>
- (void)userStreamClient:(CLVStarChatAPIClient *)client didReceivedPacket:(NSDictionary *)packet;
@optional
- (void)userStreamClientWillConnect:(CLVStarChatAPIClient *)client;
- (void)userStreamClientDidConnected:(CLVStarChatAPIClient *)client;
- (void)userStreamClientDidDisconnected:(CLVStarChatAPIClient *)client;
- (void)userStreamClient:(CLVStarChatAPIClient *)client didFailWithError:(NSError *)error;
- (void)userStreamClientDidAutoConnect:(CLVStarChatAPIClient *)client;
@end

@interface CLVStarChatAPIClient : AFHTTPClient <SBJsonStreamParserAdapterDelegate>

typedef void (^CLVStarChatAPIBasicSuccessBlock)();
typedef void (^CLVStarChatAPIBasicFailureBlock)(NSError *error);

// GET /users/user_name
- (void)userInfoForName:(NSString *)userName
             completion:(void (^)(CLVStarChatUserInfo *userInfo))completion
                failure:(CLVStarChatAPIBasicFailureBlock)failure;

- (CLVStarChatUserInfo *)userInfoForName:(NSString *)userName
                                   error:(NSError **)error;

// PUT /users/user_name
- (void)updateUserInfoWithNick:(NSString *)nick
                      keywords:(NSArray *)keywords
                    completion:(CLVStarChatAPIBasicSuccessBlock)completion
                       failure:(CLVStarChatAPIBasicFailureBlock)failure;

- (BOOL)updateUserInfoWithNick:(NSString *)nick
                      keywords:(NSArray *)keywords
                         error:(NSError **)error;

// GET /users/user_name/ping
- (void)sendPing:(CLVStarChatAPIBasicSuccessBlock)completion
         failure:(CLVStarChatAPIBasicFailureBlock)failure;

- (BOOL)sendPing:(NSError **)error;

// GET /users/user_name/channels
- (void)subscribedChannels:(void (^)(NSArray *channels))completion
                   failure:(CLVStarChatAPIBasicFailureBlock)failure;

- (NSArray *)subscribedChannels:(NSError **)error;

// GET /channels/channel_name
- (void)channelInfoForName:(NSString *)channelName
                completion:(void (^)(CLVStarChatChannelInfo *channelInfo))completion
                   failure:(CLVStarChatAPIBasicFailureBlock)failure;

- (CLVStarChatChannelInfo *)channelInfoForName:(NSString *)channelName
                                         error:(NSError **)error;

// PUT /channels/channel_name
- (void)updateChannelInfo:(NSString *)channelName
                    topic:(NSString *)topic
                  private:(BOOL)isPrivate
               completion:(CLVStarChatAPIBasicSuccessBlock)completion
                  failure:(CLVStarChatAPIBasicFailureBlock)failure;

- (BOOL)updateChannelInfo:(NSString *)channelName
                    topic:(NSString *)topic
                  private:(BOOL)isPrivate
                    error:(NSError **)error;

// GET /channels/channel_name/users
- (void)usersForChannel:(NSString *)channelName
             completion:(void (^)(NSArray *users))completion
                failure:(CLVStarChatAPIBasicFailureBlock)failure;

- (NSArray *)usersForChannel:(NSString *)channelName
                       error:(NSError **)error;

// GET /channels/channel_name/messages/recent
- (void)recentMessagesForChannel:(NSString *)channelName
                      completion:(void (^)(NSArray *messages))completion
                         failure:(CLVStarChatAPIBasicFailureBlock)failure;

- (NSArray *)recentMessagesForChannel:(NSString *)channelName
                           error:(NSError **)error;

// GET /channels/channel_name/messages/by_time_span/start_time,end_time
- (void)messagesForChannel:(NSString *)channelName
                 startTime:(NSInteger)startTime
                   endTime:(NSInteger)endTime
                completion:(void (^)(NSArray *messages))completion
                   failure:(CLVStarChatAPIBasicFailureBlock)failure;

- (NSArray *)messagesForChannel:(NSString *)channelName
                 startTime:(NSInteger)startTime
                   endTime:(NSInteger)endTime
                     error:(NSError **)error;

// POST /channels/channel_name/messages
- (void)postMessage:(NSString *)message
            channel:(NSString *)channelName
             notice:(BOOL)isNotice
      temporaryNick:(NSString *)temporaryNick
         completion:(CLVStarChatAPIBasicSuccessBlock)completion
            failure:(CLVStarChatAPIBasicFailureBlock)failure;

- (BOOL)postMessage:(NSString *)message
            channel:(NSString *)channelName
             notice:(BOOL)isNotice
      temporaryNick:(NSString *)temporaryNick
              error:(NSError **)error;

// PUT /subscribings?user_name=user_name;channel_name=channel_name
- (void)subscribeChannel:(NSString *)channelName
              completion:(CLVStarChatAPIBasicSuccessBlock)completion
                 failure:(CLVStarChatAPIBasicFailureBlock)failure;

- (BOOL)subscribeChannel:(NSString *)channelName
                   error:(NSError **)error;

// DELETE /subscribings?user_name=user_name;channel_name=channel_name
- (void)leaveChannel:(NSString *)channelName
          completion:(CLVStarChatAPIBasicSuccessBlock)completion
             failure:(CLVStarChatAPIBasicFailureBlock)failure;

- (BOOL)leaveChannel:(NSString *)channelName
               error:(NSError **)error;

// UserStream
- (void)startUserStreamConnection;
- (void)stopUserStreamConnection;

@property (nonatomic, assign) id <CLVStarChatAPIClientDelegate> delegate;
@property (nonatomic, strong, readonly) NSString *userName;
@property (nonatomic, assign, readonly) CLVStarChatUserStreamConnectionStatus connectionStatus;
@property BOOL isAutoConnect;

@end
