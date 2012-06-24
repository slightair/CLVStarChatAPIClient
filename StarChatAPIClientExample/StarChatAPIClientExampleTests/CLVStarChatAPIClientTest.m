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
    [client setAuthorizationHeaderWithUsername:@"foo" password:@"bar"];
    
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
    [client setAuthorizationHeaderWithUsername:@"foo" password:@"bar"];
    
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
    NSString *jsonString = @"[{\"name\":\"はひふへほ\",\"privacy\":\"public\",\"user_num\":2},{\"name\":\"Lobby\",\"privacy\":\"public\",\"user_num\":3,\"topic\":{\"id\":6,\"created_at\":1339939789,\"user_name\":\"foo\",\"channel_name\":\"Lobby\",\"body\":\"nice topic\"}},{\"name\":\"test\",\"privacy\":\"private\",\"user_num\":2,\"topic\":{\"id\":4,\"created_at\":1339832042,\"user_name\":\"hoge\",\"channel_name\":\"test\",\"body\":\"topic topic\"}}]";
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    [[[[self.stubServer stub] forPath:@"/users/foo/channels"] andJSONResponse:jsonData] andStatusCode:200];
    
    CLVStarChatAPIClient *client = [[CLVStarChatAPIClient alloc] initWithBaseURL:self.stubServerBaseURL];
    [client setAuthorizationHeaderWithUsername:@"foo" password:@"bar"];
    
    [self prepare];
    
    [client subscribedChannels:^(NSArray *channels){
        for (id channel in channels) {
            GHAssertTrue([channel isKindOfClass:[CLVStarChatChannelInfo class]], @"'channel' should be instance of CLVStarChatChannnelInfo.");
        }
        
        GHAssertEquals([channels count], 3U, @"channels should have 3 elements");
        
        GHAssertEqualStrings([[channels objectAtIndex:0] name], @"はひふへほ", @"channel.name should equal to 'はひふへほ'");
        GHAssertEqualStrings([[channels objectAtIndex:1] name], @"Lobby", @"channel.name should equal to 'Lobby'");
        GHAssertEqualStrings([[channels objectAtIndex:2] name], @"test", @"channel.name should equal to 'test'");
        
        [self notify:kGHUnitWaitStatusSuccess];
    }
                       failure:^(NSError *error){
                           [self notify:kGHUnitWaitStatusFailure];
                       }];
    
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:5.0f];
}

// GET /channels/channel_name
- (void)testChannelInfoForName
{
    NSString *jsonString = @"{\"name\":\"はひふへほ\",\"privacy\":\"public\",\"user_num\":3,\"topic\":{\"id\":6,\"created_at\":1339939789,\"user_name\":\"foo\",\"channel_name\":\"はひふへほ\",\"body\":\"nice topic\"}}";
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    [[[[self.stubServer stub] forPath:@"/channels/はひふへほ"] andJSONResponse:jsonData] andStatusCode:200];
    
    CLVStarChatAPIClient *client = [[CLVStarChatAPIClient alloc] initWithBaseURL:self.stubServerBaseURL];
    [client setAuthorizationHeaderWithUsername:@"foo" password:@"bar"];
    
    [self prepare];
    
    [client channelInfoForName:@"はひふへほ"
                    completion:^(CLVStarChatChannelInfo *channelInfo){
                        GHAssertEqualStrings(channelInfo.name, @"はひふへほ", @"channel.name should equal to 'はひふへほ'");
                        GHAssertEqualStrings(channelInfo.privacy, @"public", @"channel.privacy should equal to 'public'");
                        GHAssertEquals(channelInfo.numUsers, 3, @"channel.numUsers should equal to '3'");
                        
                        [self notify:kGHUnitWaitStatusSuccess];
                    }
                       failure:^(NSError *error){
                           [self notify:kGHUnitWaitStatusFailure];
                       }];
    
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:5.0f];
}

// PUT /channels/channel_name
- (void)testUpdateChannelInfo
{
    GHFail(@"write test code.");
}

// GET /channels/channel_name/users
- (void)testUsersForChannel
{
    NSString *jsonString = @"[{\"name\":\"hoge\",\"nick\":\"hoge\"},{\"name\":\"foo\",\"nick\":\"foo\",\"keywords\":[\"nununu\"]}]";
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    [[[[self.stubServer stub] forPath:@"/channels/はひふへほ/users"] andJSONResponse:jsonData] andStatusCode:200];
    
    CLVStarChatAPIClient *client = [[CLVStarChatAPIClient alloc] initWithBaseURL:self.stubServerBaseURL];
    [client setAuthorizationHeaderWithUsername:@"foo" password:@"bar"];
    
    [self prepare];
    
    [client usersForChannel:@"はひふへほ"
                 completion:^(NSArray *users){
                     for (id user in users) {
                         GHAssertTrue([user isKindOfClass:[CLVStarChatUserInfo class]], @"'user' should be instance of CLVStarChatUserInfo.");
                     }
                     
                     GHAssertEquals([users count], 2U, @"users should have 2 elements");
                     
                     GHAssertEqualStrings([[users objectAtIndex:0] name], @"hoge", @"user.name should equal to 'hoge'");
                     GHAssertEqualStrings([[users objectAtIndex:1] name], @"foo", @"user.name should equal to 'foo'");
                     
                     [self notify:kGHUnitWaitStatusSuccess];
                 }
                    failure:^(NSError *error){
                        [self notify:kGHUnitWaitStatusFailure];
                    }];
    
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:5.0f];
}

// GET /channels/channel_name/messages/recent
- (void)testRecentMessagesForChannel
{
    NSString *jsonString = @"[{\"id\":461,\"user_name\":\"foo\",\"body\":\"あいうえお\",\"created_at\":1340372159,\"channel_name\":\"てすと\",\"notice\":false},{\"id\":462,\"user_name\":\"foo\",\"body\":\"かきくけこ\",\"created_at\":1340372162,\"channel_name\":\"てすと\",\"notice\":false},{\"id\":463,\"user_name\":\"foo\",\"body\":\"さしすせそ\",\"created_at\":1340372165,\"channel_name\":\"てすと\",\"notice\":false},{\"id\":464,\"user_name\":\"foo\",\"body\":\"ニャーン\",\"created_at\":1340372169,\"channel_name\":\"てすと\",\"notice\":false},{\"id\":465,\"user_name\":\"foo\",\"body\":\"ひろし\",\"created_at\":1340372199,\"channel_name\":\"てすと\",\"notice\":true}]";
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    [[[[self.stubServer stub] forPath:@"/channels/てすと/messages/recent"] andJSONResponse:jsonData] andStatusCode:200];
    
    CLVStarChatAPIClient *client = [[CLVStarChatAPIClient alloc] initWithBaseURL:self.stubServerBaseURL];
    [client setAuthorizationHeaderWithUsername:@"foo" password:@"bar"];
    
    [self prepare];
    
    [client recentMessagesForChannel:@"てすと"
                 completion:^(NSArray *messages){
                     for (id message in messages) {
                         GHAssertTrue([message isKindOfClass:[CLVStarChatMessageInfo class]], @"'message' should be instance of CLVStarChatMessageInfo.");
                     }
                     
                     GHAssertEquals([messages count], 5U, @"messages should have 5 elements");
                     
                     GHAssertEqualStrings([[messages objectAtIndex:0] body], @"あいうえお", @"message.body should equal to 'あいうえお'");
                     GHAssertEqualStrings([[messages objectAtIndex:1] body], @"かきくけこ", @"message.body should equal to 'かきくけこ'");
                     GHAssertEqualStrings([[messages objectAtIndex:2] body], @"さしすせそ", @"message.body should equal to 'さしすせそ'");
                     GHAssertEqualStrings([[messages objectAtIndex:3] body], @"ニャーン", @"message.body should equal to 'ニャーン'");
                     GHAssertEqualStrings([[messages objectAtIndex:4] body], @"ひろし", @"message.body should equal to 'ひろし'");
                     GHAssertEquals([[messages objectAtIndex:0] isNotice], NO, @"message.isNotice should equal to 'foo'");
                     GHAssertEquals([[messages objectAtIndex:4] isNotice], YES, @"message.isNotice should equal to 'foo'");
                     
                     [self notify:kGHUnitWaitStatusSuccess];
                 }
                    failure:^(NSError *error){
                        [self notify:kGHUnitWaitStatusFailure];
                    }];
    
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:5.0f];
}

// GET /channels/channel_name/messages/by_time_span/start_time,end_time
- (void)testMessagesForChannel_startTime_endTime
{
    NSString *jsonString = @"[{\"id\":461,\"user_name\":\"foo\",\"body\":\"あいうえお\",\"created_at\":1340372159,\"channel_name\":\"てすと\",\"notice\":false},{\"id\":462,\"user_name\":\"foo\",\"body\":\"かきくけこ\",\"created_at\":1340372162,\"channel_name\":\"てすと\",\"notice\":false},{\"id\":463,\"user_name\":\"foo\",\"body\":\"さしすせそ\",\"created_at\":1340372165,\"channel_name\":\"てすと\",\"notice\":false},{\"id\":464,\"user_name\":\"foo\",\"body\":\"ニャーン\",\"created_at\":1340372169,\"channel_name\":\"てすと\",\"notice\":false},{\"id\":465,\"user_name\":\"foo\",\"body\":\"ひろし\",\"created_at\":1340372199,\"channel_name\":\"てすと\",\"notice\":true}]";
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    [[[[self.stubServer stub] forPath:@"/channels/てすと/messages/by_time_span/10000,10100"] andJSONResponse:jsonData] andStatusCode:200];
    
    CLVStarChatAPIClient *client = [[CLVStarChatAPIClient alloc] initWithBaseURL:self.stubServerBaseURL];
    [client setAuthorizationHeaderWithUsername:@"foo" password:@"bar"];
    
    [self prepare];
    
    [client messagesForChannel:@"てすと"
                     startTime:10000
                       endTime:10100
                    completion:^(NSArray *messages){
                        for (id message in messages) {
                            GHAssertTrue([message isKindOfClass:[CLVStarChatMessageInfo class]], @"'message' should be instance of CLVStarChatMessageInfo.");
                        }
                        
                        GHAssertEquals([messages count], 5U, @"messages should have 5 elements");
                        
                        GHAssertEqualStrings([[messages objectAtIndex:0] body], @"あいうえお", @"message.body should equal to 'あいうえお'");
                        GHAssertEqualStrings([[messages objectAtIndex:1] body], @"かきくけこ", @"message.body should equal to 'かきくけこ'");
                        GHAssertEqualStrings([[messages objectAtIndex:2] body], @"さしすせそ", @"message.body should equal to 'さしすせそ'");
                        GHAssertEqualStrings([[messages objectAtIndex:3] body], @"ニャーン", @"message.body should equal to 'ニャーン'");
                        GHAssertEqualStrings([[messages objectAtIndex:4] body], @"ひろし", @"message.body should equal to 'ひろし'");
                        GHAssertEquals([[messages objectAtIndex:0] isNotice], NO, @"message.isNotice should equal to 'foo'");
                        GHAssertEquals([[messages objectAtIndex:4] isNotice], YES, @"message.isNotice should equal to 'foo'");
                        
                        [self notify:kGHUnitWaitStatusSuccess];
                    }
                       failure:^(NSError *error){
                           [self notify:kGHUnitWaitStatusFailure];
                       }];
    
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:5.0f];
}

// POST /channels/channel_name/messages
- (void)testPostMessage_channel_notice
{
    GHFail(@"write test code.");
}

// PUT /subscribings?user_name=user_name;channel_name=channel_name
- (void)testSubscribeChannel
{
    GHFail(@"write test code.");
}

// DELETE /subscribings?user_name=user_name;channel_name=channel_name
- (void)testLeaveChannel
{
    GHFail(@"write test code.");
}

@end
