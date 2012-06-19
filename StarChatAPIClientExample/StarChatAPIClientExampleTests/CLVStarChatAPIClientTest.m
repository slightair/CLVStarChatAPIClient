//
//  CLVStarChatAPIClientTest.m
//  StarChatAPIClientExample
//
//  Created by slightair on 12/06/18.
//  Copyright (c) 2012 slightair. All rights reserved.
//

#define kStubServerPort 12345

#import "CLVStarChatAPIClientTest.h"
#import "CLVStarChatAPIClient.h"
#import "NLTHTTPStubServer.h"

@interface CLVStarChatAPIClientTest ()

@property (nonatomic, strong) NLTHTTPStubServer *stubServer;
@property (nonatomic, strong) NSURL *stubServerBaseURL;

@end

@implementation CLVStarChatAPIClientTest

@synthesize stubServer = _stubServer;
@synthesize stubServerBaseURL = _stubServerBaseURL;

- (void)setUpClass
{
    [NLTHTTPStubServer globalSettings].port = kStubServerPort;
    
    self.stubServer = [NLTHTTPStubServer stubServer];
    [self.stubServer startServer];
    
    self.stubServerBaseURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://localhost:%d", kStubServerPort]];
}

- (void)tearDownClass {
    [self.stubServer stopServer];
}

- (void)setUp {
    [self.stubServer clear];
}

- (void)tearDown {
    if(![self.stubServer isStubEmpty]) {
        GHFail(@"stubs not empty");
    }
}

// GET /users/user_name
- (void)testUserInfoForName
{
    NSString *jsonString = @"{\"name\": \"michael\",  \"nick\": \"MJ\", \"keywords\": [\"michael\", \"Michael\", \"FYI\"]}";
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    [[[[self.stubServer stub] forPath:@"/users/michael"] andJSONResponse:jsonData] andStatusCode:200];
    
    CLVStarChatAPIClient *client = [[CLVStarChatAPIClient alloc] initWithBaseURL:self.stubServerBaseURL];
    
    [self prepare];
    
    [client userInfoForName:@"michael"
                 completion:^(CLVStarChatUserInfo *userInfo){
                     NSString *expectName = @"michael";
                     NSString *expectNick = @"MJ";
                     NSArray *expectKeywords = [NSArray arrayWithObjects:@"michael", @"Michael", @"FYI", nil];
                     
                     GHAssertEqualStrings(userInfo.name, expectName, @"userInfo.name should equal to %@", expectName);
                     GHAssertEqualStrings(userInfo.nick, expectNick, @"userInfo.nick should equal to %@", expectNick);
                     GHAssertEqualObjects(userInfo.keywords, expectKeywords, @"userInfo.keywords should equal to %@", expectKeywords);
                     
                     [self notify:kGHUnitWaitStatusSuccess];
                 }
                    failure:^(NSError *error){
                           [self notify:kGHUnitWaitStatusFailure];
                    }];
    
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:5.0f];
}

// PUT /users/user_name
- (void)testUpdateUserInfo
{
    GHFail(@"write test code.");
}

// GET /users/user_name/ping
- (void)testSendPing
{
    NSString *jsonString = @"{\"result\": \"pong\"}";
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    [[[[self.stubServer stub] forPath:@"/users/foo/ping"] andJSONResponse:jsonData] andStatusCode:200];
    
    CLVStarChatAPIClient *client = [[CLVStarChatAPIClient alloc] initWithBaseURL:self.stubServerBaseURL];
    [client setAuthorizationHeaderWithUsername:@"foo" password:@"br"];
    
    [self prepare];
    
    [client sendPing:^{
        [self notify:kGHUnitWaitStatusSuccess];
    }
             failure:^(NSError *error){
                 [self notify:kGHUnitWaitStatusFailure];
             }];
    
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:5.0f];
}

// GET /users/user_name/channels
- (void)testSubscribedChannels
{
    GHFail(@"write test code.");
}

// GET /channels/channel_name
- (void)testChannelInfoForName
{
    GHFail(@"write test code.");
}

// PUT /channels/channel_name
- (void)testUpdateChannelInfo
{
    GHFail(@"write test code.");
}

// GET /channels/channel_name/users
- (void)testUsersForChannel
{
    GHFail(@"write test code.");
}

// GET /channels/channel_name/messages/recent
- (void)testRecentMessagesForChannel
{
    GHFail(@"write test code.");
}

// GET /channels/channel_name/messages/by_time_span/start_time,end_time
- (void)testMessagesForChannel_startTime_endTime
{
    GHFail(@"write test code.");
}

// POST /channels/channel_name/messages
- (void)testPostMessage_channel_notice
{
    GHFail(@"write test code.");
}

// PUT /subscribings?user_name=user_name;channel_name=channel_name
- (void)subscribeChannel
{
    GHFail(@"write test code.");
}

// DELETE /subscribings?user_name=user_name;channel_name=channel_name
- (void)leaveChannel
{
    GHFail(@"write test code.");
}

@end
