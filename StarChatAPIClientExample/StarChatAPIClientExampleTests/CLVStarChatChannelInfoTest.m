//
//  CLVStarChatChannelInfoTest.m
//  StarChatAPIClientExample
//
//  Created by slightair on 12/06/17.
//  Copyright (c) 2012 slightair. All rights reserved.
//

#import "CLVStarChatChannelInfoTest.h"
#import "CLVStarChatChannelInfo.h"
#import "CLVStarChatTopicInfo.h"
#import "SBJson.h"

@implementation CLVStarChatChannelInfoTest

- (void)testInitWithDictionary
{
    NSString *channelInfoJSON = @"{\"name\":\"Lobby\",\"privacy\":\"public\",\"user_num\":3,\"topic\":{\"id\":6,\"created_at\":1339939789,\"user_name\":\"foo\",\"channel_name\":\"Lobby\",\"body\":\"nice topic\"}}";
    NSDictionary *channelInfoDict = [channelInfoJSON JSONValue];
    
    CLVStarChatChannelInfo *channelInfo = [CLVStarChatChannelInfo channelInfoWithDictionary:channelInfoDict];
    
    NSString *expectName = @"Lobby";
    NSString *expectPrivacy = @"public";
    NSInteger expectNumUsers = 3;
    NSInteger expectTopicId = 6;
    NSString *expectTopicChannelName = @"Lobby";
    NSString *expectTopicBody = @"nice topic";
    NSDate *expectTopicCreatedAt = [NSDate dateWithTimeIntervalSince1970:1339939789];
    NSString *expectTopicUserlName = @"foo";
    
    GHAssertEqualStrings(channelInfo.name, expectName, @"channelInfo.name should equal to %@", expectName);
    GHAssertEqualStrings(channelInfo.privacy, expectPrivacy, @"channelInfo.privacy should equal to %@", expectPrivacy);
    GHAssertEquals(channelInfo.numUsers, expectNumUsers, @"channelInfo.numUsers should equal to %d", expectNumUsers);
    
    CLVStarChatTopicInfo *topicInfo = channelInfo.topic;
    GHAssertEquals(topicInfo.topicId, expectTopicId, @"topicInfo.topicId should equal to %d", expectTopicId);
    GHAssertEqualStrings(topicInfo.channelName, expectTopicChannelName, @"topicInfo.channelName should equal to %@", expectTopicChannelName);
    GHAssertEqualStrings(topicInfo.body, expectTopicBody, @"topicInfo.body should equal to %@", expectTopicBody);
    GHAssertEqualObjects(topicInfo.createdAt, expectTopicCreatedAt, @"topicInfo.createdAt should equal to %@", expectTopicCreatedAt);
    GHAssertEqualStrings(topicInfo.userName, expectTopicUserlName, @"topicInfo.userName should equal to %@", expectTopicUserlName);
}

@end
