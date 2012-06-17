//
//  CLVStarChatMessageInfo.m
//  StarChatAPIClient
//
//  Created by slightair on 12/06/16.
//  Copyright (c) 2012 slightair. All rights reserved.
//

#import "CLVStarChatMessageInfo.h"

@interface CLVStarChatMessageInfo ()

@property (nonatomic, readwrite) NSInteger messageId;
@property (nonatomic, readwrite, strong) NSString *userName;
@property (nonatomic, readwrite, strong) NSString *body;
@property (nonatomic, readwrite, strong) NSDate *createdAt;
@property (nonatomic, readwrite, strong) NSString *channelName;
@property (nonatomic, readwrite) BOOL isNotice;

@end

@implementation CLVStarChatMessageInfo

@synthesize messageId = _messageId;
@synthesize userName = _userName;
@synthesize body = _body;
@synthesize createdAt = _createdAt;
@synthesize channelName = _channelName;
@synthesize isNotice = _isNotice;

+ (id)messageInfoWithDictionary:(NSDictionary *)dictionary
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
