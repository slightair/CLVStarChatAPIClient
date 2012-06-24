//
//  CLVStarChatChannelInfo.m
//  StarChatAPIClient
//
//  Created by slightair on 12/06/16.
//  Copyright (c) 2012 slightair. All rights reserved.
//

#import "CLVStarChatChannelInfo.h"

@interface CLVStarChatChannelInfo ()

@property (nonatomic, readwrite, strong) NSString *name;
@property (nonatomic, readwrite, strong) NSString *privacy;
@property (nonatomic, readwrite) NSInteger numUsers;
@property (nonatomic, readwrite, strong) CLVStarChatTopicInfo *topic;

@end

@implementation CLVStarChatChannelInfo

@synthesize name = _name;
@synthesize privacy = _privacy;
@synthesize numUsers = _numUsers;
@synthesize topic = _topic;

+ (id)channelInfoWithDictionary:(NSDictionary *)dictionary
{
    return [[[self class] alloc] initWithDictionary:dictionary];
}

- (id)initWithDictionary:(NSDictionary *)dictionary
{
    self = [super init];
    if (self) {
        self.name = [dictionary objectForKey:@"name"];
        self.privacy = [dictionary objectForKey:@"privacy"];
        self.numUsers = [[dictionary objectForKey:@"user_num"] integerValue];
        self.topic = [CLVStarChatTopicInfo topicInfoWithDictionary:[dictionary objectForKey:@"topic"]];
    }
    return self;
}

@end
