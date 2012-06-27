//
//  CLVStarChatMessageInfoTest.m
//  StarChatAPIClientExample
//
//  Created by slightair on 12/06/18.
//  Copyright (c) 2012 slightair. All rights reserved.
//

#import "CLVStarChatMessageInfoTest.h"
#import "CLVStarChatMessageInfo.h"
#import "SBJson.h"

@implementation CLVStarChatMessageInfoTest

- (void)testInitWithDictionary
{
    NSString *messageInfoJSON = @"{\"id\":350,\"user_name\":\"foo\",\"body\":\"oreo\",\"created_at\":1339430827,\"channel_name\":\"Lobby\",\"notice\":false,\"temporary_nick\":\"fooBot\"}";
    NSDictionary *messageInfoDict = [messageInfoJSON JSONValue];
    
    CLVStarChatMessageInfo *messageInfo = [CLVStarChatMessageInfo messageInfoWithDictionary:messageInfoDict];
    
    NSInteger expectMessageId = 350;
    NSString *expectUserlName = @"foo";
    NSString *expectBody = @"oreo";
    NSDate *expectCreatedAt = [NSDate dateWithTimeIntervalSince1970:1339430827];
    NSString *expectChannelName = @"Lobby";
    BOOL expectNotice = NO;
    NSString *expectTemporaryNick = @"fooBot";
    
    GHAssertEquals(messageInfo.messageId, expectMessageId, @"messageInfo.messageId should equal to %d", expectMessageId);
    GHAssertEqualStrings(messageInfo.userName, expectUserlName, @"messageInfo.userName should equal to %@", expectUserlName);
    GHAssertEqualStrings(messageInfo.body, expectBody, @"messageInfo.body should equal to %@", expectBody);
    GHAssertEqualObjects(messageInfo.createdAt, expectCreatedAt, @"messageInfo.createdAt should equal to %@", expectCreatedAt);
    GHAssertEqualStrings(messageInfo.channelName, expectChannelName, @"messageInfo.channelName should equal to %@", expectChannelName);
    GHAssertEquals(messageInfo.isNotice, expectNotice, @"messageInfo.messageId should equal to %@", expectNotice ? @"YES" : @"NO");
    GHAssertEqualStrings(messageInfo.temporaryNick, expectTemporaryNick, @"messageInfo.temporaryNick should equal to %@", expectTemporaryNick);
}

@end
