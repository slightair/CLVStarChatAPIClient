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
    
    __block CLVStarChatUserInfo *userInfo = nil;
    [client userInfoForName:@"michael"
                 completion:^(CLVStarChatUserInfo *info){
                     userInfo = info;
                     [self notify:kGHUnitWaitStatusSuccess];
                 }
                    failure:^(NSError *error){
                           [self notify:kGHUnitWaitStatusFailure];
                    }];
    
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:5.0f];
    
    NSString *expectName = @"michael";
    NSString *expectNick = @"MJ";
    NSArray *expectKeywords = [NSArray arrayWithObjects:@"michael", @"Michael", @"FYI", nil];
    
    GHAssertEqualStrings(userInfo.name, expectName, @"userInfo.name should equal to %@", expectName);
    GHAssertEqualStrings(userInfo.nick, expectNick, @"userInfo.nick should equal to %@", expectNick);
    GHAssertEqualObjects(userInfo.keywords, expectKeywords, @"userInfo.keywords should equal to %@", expectKeywords);
}

// PUT /users/user_name
- (void)testUpdateUserInfo
{
    __block NSString *postBodyString = nil;
    [[[[self.stubServer stub] forPath:@"/users/foo" HTTPMethod:@"PUT"] andCheckPostBody:^(NSData *postBody){
        postBodyString = [[NSString alloc] initWithData:postBody encoding:NSUTF8StringEncoding];
    }] andStatusCode:200];
    
    CLVStarChatAPIClient *client = [[CLVStarChatAPIClient alloc] initWithBaseURL:self.stubServerBaseURL];
    [client setAuthorizationHeaderWithUsername:@"foo" password:@"bar"];
    
    [self prepare];
    
    [client updateUserInfoWithNick:@"hogenick"
                          keywords:[NSArray arrayWithObjects:@"hoge", @"fuga", @"piyo", @"はひふへほ", nil]
                        completion:^{
                            [self notify:kGHUnitWaitStatusSuccess];
                        }
                           failure:^(NSError *error){
                               [self notify:kGHUnitWaitStatusFailure];
                           }];
    
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:5.0f];
    
    NSArray *params = [postBodyString componentsSeparatedByString:@"&"];
    
    GHAssertEquals([params count], 5U, @"params should have 5 objects");
    
    NSUInteger score = 0;
    for (NSString *param in params) {
        if ([param isEqualToString:@"keywords[]=hoge"] ||
            [param isEqualToString:@"keywords[]=fuga"] ||
            [param isEqualToString:@"keywords[]=piyo"] ||
            [param isEqualToString:@"keywords[]=%E3%81%AF%E3%81%B2%E3%81%B5%E3%81%B8%E3%81%BB"] ||
            [param isEqualToString:@"nick=hogenick"]) {
            score++;
        }
    }
    GHAssertEquals(score, 5U, @"post body should have specified keywords and nick.");
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
    
    __block NSArray *subscribedChannels = nil;
    [client subscribedChannels:^(NSArray *channels){
        subscribedChannels = channels;
        [self notify:kGHUnitWaitStatusSuccess];
    }
                       failure:^(NSError *error){
                           [self notify:kGHUnitWaitStatusFailure];
                       }];
    
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:5.0f];
    
    for (id channel in subscribedChannels) {
        GHAssertTrue([channel isKindOfClass:[CLVStarChatChannelInfo class]], @"'channel' should be instance of CLVStarChatChannnelInfo.");
    }
    
    GHAssertEquals([subscribedChannels count], 3U, @"channels should have 3 elements");
    
    GHAssertEqualStrings([[subscribedChannels objectAtIndex:0] name], @"はひふへほ", @"channel.name should equal to 'はひふへほ'");
    GHAssertEqualStrings([[subscribedChannels objectAtIndex:1] name], @"Lobby", @"channel.name should equal to 'Lobby'");
    GHAssertEqualStrings([[subscribedChannels objectAtIndex:2] name], @"test", @"channel.name should equal to 'test'");
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
    
    __block CLVStarChatChannelInfo *channelInfo = nil;
    [client channelInfoForName:@"はひふへほ"
                    completion:^(CLVStarChatChannelInfo *info){
                        channelInfo = info;
                        [self notify:kGHUnitWaitStatusSuccess];
                    }
                       failure:^(NSError *error){
                           [self notify:kGHUnitWaitStatusFailure];
                       }];
    
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:5.0f];
    
    GHAssertEqualStrings(channelInfo.name, @"はひふへほ", @"channel.name should equal to 'はひふへほ'");
    GHAssertEqualStrings(channelInfo.privacy, @"public", @"channel.privacy should equal to 'public'");
    GHAssertEquals(channelInfo.numUsers, 3, @"channel.numUsers should equal to '3'");
}

// PUT /channels/channel_name
- (void)testUpdateChannelInfo
{
    __block NSString *postBodyString = nil;
    [[[[self.stubServer stub] forPath:@"/channels/てすと" HTTPMethod:@"PUT"] andCheckPostBody:^(NSData *postBody){
        postBodyString = [[NSString alloc] initWithData:postBody encoding:NSUTF8StringEncoding];
    }] andStatusCode:200];
    
    CLVStarChatAPIClient *client = [[CLVStarChatAPIClient alloc] initWithBaseURL:self.stubServerBaseURL];
    [client setAuthorizationHeaderWithUsername:@"foo" password:@"bar"];
    
    [self prepare];
    
    [client updateChannelInfo:@"てすと"
                        topic:@"はひふへほ"
                      private:NO
                   completion:^{
                       [self notify:kGHUnitWaitStatusSuccess];
                   }
                      failure:^(NSError *error){
                          [self notify:kGHUnitWaitStatusFailure];
                      }];
    
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:5.0f];
    
    NSArray *params = [postBodyString componentsSeparatedByString:@"&"];
    
    GHAssertEquals([params count], 2U, @"params should have 2 objects");
    
    NSUInteger score = 0;
    for (NSString *param in params) {
        if ([param isEqualToString:@"topic[body]=%E3%81%AF%E3%81%B2%E3%81%B5%E3%81%B8%E3%81%BB"] ||
            [param isEqualToString:@"privacy=public"]) {
            score++;
        }
    }
    GHAssertEquals(score, 2U, @"post body should have specified topic and privacy.");
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
    
    __block NSArray *hahihuhehoUsers = nil;
    [client usersForChannel:@"はひふへほ"
                 completion:^(NSArray *users){
                     hahihuhehoUsers = users;
                     [self notify:kGHUnitWaitStatusSuccess];
                 }
                    failure:^(NSError *error){
                        [self notify:kGHUnitWaitStatusFailure];
                    }];
    
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:5.0f];
    
    for (id user in hahihuhehoUsers) {
        GHAssertTrue([user isKindOfClass:[CLVStarChatUserInfo class]], @"'user' should be instance of CLVStarChatUserInfo.");
    }
    
    GHAssertEquals([hahihuhehoUsers count], 2U, @"users should have 2 elements");
    
    GHAssertEqualStrings([[hahihuhehoUsers objectAtIndex:0] name], @"hoge", @"user.name should equal to 'hoge'");
    GHAssertEqualStrings([[hahihuhehoUsers objectAtIndex:1] name], @"foo", @"user.name should equal to 'foo'");
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
    
    __block NSArray *testMessages = nil;
    [client recentMessagesForChannel:@"てすと"
                 completion:^(NSArray *messages){
                     testMessages = messages;
                     [self notify:kGHUnitWaitStatusSuccess];
                 }
                    failure:^(NSError *error){
                        [self notify:kGHUnitWaitStatusFailure];
                    }];
    
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:5.0f];
    
    for (id message in testMessages) {
        GHAssertTrue([message isKindOfClass:[CLVStarChatMessageInfo class]], @"'message' should be instance of CLVStarChatMessageInfo.");
    }
    
    GHAssertEquals([testMessages count], 5U, @"messages should have 5 elements");
    
    GHAssertEqualStrings([[testMessages objectAtIndex:0] body], @"あいうえお", @"message.body should equal to 'あいうえお'");
    GHAssertEqualStrings([[testMessages objectAtIndex:1] body], @"かきくけこ", @"message.body should equal to 'かきくけこ'");
    GHAssertEqualStrings([[testMessages objectAtIndex:2] body], @"さしすせそ", @"message.body should equal to 'さしすせそ'");
    GHAssertEqualStrings([[testMessages objectAtIndex:3] body], @"ニャーン", @"message.body should equal to 'ニャーン'");
    GHAssertEqualStrings([[testMessages objectAtIndex:4] body], @"ひろし", @"message.body should equal to 'ひろし'");
    GHAssertEquals([[testMessages objectAtIndex:0] isNotice], NO, @"message.isNotice should equal to 'foo'");
    GHAssertEquals([[testMessages objectAtIndex:4] isNotice], YES, @"message.isNotice should equal to 'foo'");
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
    
    __block NSArray *testMessages = nil;
    [client messagesForChannel:@"てすと"
                     startTime:10000
                       endTime:10100
                    completion:^(NSArray *messages){
                        testMessages = messages;
                        [self notify:kGHUnitWaitStatusSuccess];
                    }
                       failure:^(NSError *error){
                           [self notify:kGHUnitWaitStatusFailure];
                       }];
    
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:5.0f];
    
    for (id message in testMessages) {
        GHAssertTrue([message isKindOfClass:[CLVStarChatMessageInfo class]], @"'message' should be instance of CLVStarChatMessageInfo.");
    }
    
    GHAssertEquals([testMessages count], 5U, @"messages should have 5 elements");
    
    GHAssertEqualStrings([[testMessages objectAtIndex:0] body], @"あいうえお", @"message.body should equal to 'あいうえお'");
    GHAssertEqualStrings([[testMessages objectAtIndex:1] body], @"かきくけこ", @"message.body should equal to 'かきくけこ'");
    GHAssertEqualStrings([[testMessages objectAtIndex:2] body], @"さしすせそ", @"message.body should equal to 'さしすせそ'");
    GHAssertEqualStrings([[testMessages objectAtIndex:3] body], @"ニャーン", @"message.body should equal to 'ニャーン'");
    GHAssertEqualStrings([[testMessages objectAtIndex:4] body], @"ひろし", @"message.body should equal to 'ひろし'");
    GHAssertEquals([[testMessages objectAtIndex:0] isNotice], NO, @"message.isNotice should equal to 'foo'");
    GHAssertEquals([[testMessages objectAtIndex:4] isNotice], YES, @"message.isNotice should equal to 'foo'");
}

// POST /channels/channel_name/messages
- (void)testPostMessage_channel_notice_temporaryNick
{
    __block NSString *postBodyString = nil;
    [[[[self.stubServer stub] forPath:@"/channels/てすと/messages" HTTPMethod:@"POST"] andCheckPostBody:^(NSData *postBody){
        postBodyString = [[NSString alloc] initWithData:postBody encoding:NSUTF8StringEncoding];
    }] andStatusCode:200];
    
    CLVStarChatAPIClient *client = [[CLVStarChatAPIClient alloc] initWithBaseURL:self.stubServerBaseURL];
    [client setAuthorizationHeaderWithUsername:@"foo" password:@"bar"];
    
    [self prepare];
    
    [client postMessage:@"こんにちは"
                channel:@"てすと"
                 notice:NO
          temporaryNick:@"はひふへほ"
             completion:^{
                 [self notify:kGHUnitWaitStatusSuccess];
             }
                failure:^(NSError *error){
                    [self notify:kGHUnitWaitStatusFailure];
                }];
    
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:5.0f];
    
    NSArray *params = [postBodyString componentsSeparatedByString:@"&"];
    
    GHAssertEquals([params count], 3U, @"params should have 3 objects");
    
    NSUInteger score = 0;
    for (NSString *param in params) {
        if ([param isEqualToString:@"body=%E3%81%93%E3%82%93%E3%81%AB%E3%81%A1%E3%81%AF"] ||
            [param isEqualToString:@"notice=false"] ||
            [param isEqualToString:@"temporary_nick=%E3%81%AF%E3%81%B2%E3%81%B5%E3%81%B8%E3%81%BB"]) {
            score++;
        }
    }
    GHAssertEquals(score, 3U, @"post body should have specified body, notice and temporary_nick.");
}

#warning - skip test
// PUT /subscribings?user_name=user_name;channel_name=channel_name
- (void)_testSubscribeChannel
{
    [[[self.stubServer stub] forPath:@"/subscribings?user_name=foo&channel_name=%E3%81%A6%E3%81%99%E3%81%A8" HTTPMethod:@"PUT"] andStatusCode:200];
    
    CLVStarChatAPIClient *client = [[CLVStarChatAPIClient alloc] initWithBaseURL:self.stubServerBaseURL];
    [client setAuthorizationHeaderWithUsername:@"foo" password:@"bar"];
    
    [self prepare];
    
    [client subscribeChannel:@"てすと"
                  completion:^{
                      [self notify:kGHUnitWaitStatusSuccess];
                  }
                     failure:^(NSError *error){
                         [self notify:kGHUnitWaitStatusFailure];
                     }];
    
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:5.0f];
}

#warning - skip test
// DELETE /subscribings?user_name=user_name;channel_name=channel_name
- (void)_testLeaveChannel
{
    [[[self.stubServer stub] forPath:@"/subscribings?user_name=foo&channel_name=%E3%81%A6%E3%81%99%E3%81%A8" HTTPMethod:@"DELETE"] andStatusCode:200];
    
    CLVStarChatAPIClient *client = [[CLVStarChatAPIClient alloc] initWithBaseURL:self.stubServerBaseURL];
    [client setAuthorizationHeaderWithUsername:@"foo" password:@"bar"];
    
    [self prepare];
    
    [client leaveChannel:@"てすと"
                  completion:^{
                      [self notify:kGHUnitWaitStatusSuccess];
                  }
                     failure:^(NSError *error){
                         [self notify:kGHUnitWaitStatusFailure];
                     }];
    
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:5.0f];
}

@end
