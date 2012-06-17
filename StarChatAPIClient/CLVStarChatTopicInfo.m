//
//  CLVStarChatTopicInfo.m
//  StarChatAPIClient
//
//  Created by slightair on 12/06/16.
//  Copyright (c) 2012 slightair. All rights reserved.
//

#import "CLVStarChatTopicInfo.h"

@interface CLVStarChatTopicInfo ()

@property (nonatomic, readwrite) NSInteger topicId;
@property (nonatomic, readwrite, strong) NSString *channelName;
@property (nonatomic, readwrite, strong) NSString *body;
@property (nonatomic, readwrite, strong) NSDate *createdAt;
@property (nonatomic, readwrite, strong) NSString *userName;

@end

@implementation CLVStarChatTopicInfo

@synthesize topicId = _topicId;
@synthesize channelName = _channelName;
@synthesize body = _body;
@synthesize createdAt = _createdAt;
@synthesize userName = _userName;

+ (id)topicInfoWithDictionary:(NSDictionary *)dictionary
{
    return [[[self class] alloc] initWithDictionary:dictionary];
}

- (id)initWithDictionary:(NSDictionary *)dictionary
{
    self = [super init];
    if (self) {
        
    }
    return self;
}

@end
