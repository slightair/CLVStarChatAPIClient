//
//  CLVStarChatUserInfoTest.m
//  StarChatAPIClientExample
//
//  Created by slightair on 12/06/17.
//  Copyright (c) 2012 slightair. All rights reserved.
//

#import "CLVStarChatUserInfoTest.h"
#import "CLVStarChatUserInfo.h"
#import "SBJson.h"

@implementation CLVStarChatUserInfoTest

- (void)testInitWithDictionary
{
    NSString *userInfoJSON = @"{name: \"michael\",  nick: \"MJ\", keywords: [\"michael\", \"Michael\", \"FYI\"]}";
    NSDictionary *userInfoDict = [userInfoJSON JSONValue];
    
    CLVStarChatUserInfo *userInfo = [CLVStarChatUserInfo userInfoWithDictionary:userInfoDict];
    
    NSString *expectName = @"michael";
    NSString *expectNick = @"MJ";
    NSArray *expectKeywords = [NSArray arrayWithObjects:@"michael", @"Michael", @"FYI", nil];
    
    GHAssertEqualStrings(userInfo.name, expectName, @"userInfo.name should equal to %@", expectName);
    GHAssertEqualStrings(userInfo.nick, expectNick, @"userInfo.nick should equal to %@", expectNick);
    GHAssertEqualObjects(userInfo.keywords, expectKeywords, @"userInfo.keywords should equal to %@", expectKeywords);
}

@end
