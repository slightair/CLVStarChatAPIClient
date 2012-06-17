//
//  CLVStarChatTopicInfoTest.m
//  StarChatAPIClientExample
//
//  Created by slightair on 12/06/18.
//  Copyright (c) 2012 slightair. All rights reserved.
//

#import "CLVStarChatTopicInfoTest.h"
#import "CLVStarChatTopicInfo.h"

@implementation CLVStarChatTopicInfoTest

- (void)testInitWithDictionary
{
    NSDictionary *topicInfoDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                     [NSNumber numberWithInteger:6], @"id",
                                     @"Lobby", @"channel_name",
                                     @"nice topic", @"body",
                                     [NSNumber numberWithInteger:1339939789], @"created_at",
                                     @"foo", @"user_name",
                                     nil];
    
    CLVStarChatTopicInfo *topicInfo = [CLVStarChatTopicInfo topicInfoWithDictionary:topicInfoDict];
    
    NSInteger expectTopicId = 6;
    NSString *expectTopicChannelName = @"Lobby";
    NSString *expectTopicBody = @"nice topic";
    NSDate *expectTopicCreatedAt = [NSDate dateWithTimeIntervalSince1970:1339939789];
    NSString *expectTopicUserlName = @"foo";
    
    GHAssertEquals(topicInfo.topicId, expectTopicId, @"topicInfo.topicId should equal to %d", expectTopicId);
    GHAssertEqualStrings(topicInfo.channelName, expectTopicChannelName, @"topicInfo.channelName should equal to %@", expectTopicChannelName);
    GHAssertEqualStrings(topicInfo.body, expectTopicBody, @"topicInfo.body should equal to %@", expectTopicBody);
    GHAssertEqualObjects(topicInfo.createdAt, expectTopicCreatedAt, @"topicInfo.createdAt should equal to %@", expectTopicCreatedAt);
    GHAssertEqualStrings(topicInfo.userName, expectTopicUserlName, @"topicInfo.userName should equal to %@", expectTopicUserlName);
}

@end
