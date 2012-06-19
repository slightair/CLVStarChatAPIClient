//
//  CLVStarChatUserInfo.m
//  StarChatAPIClient
//
//  Created by slightair on 12/06/16.
//  Copyright (c) 2012 slightair. All rights reserved.
//

#import "CLVStarChatUserInfo.h"

@interface CLVStarChatUserInfo ()

@property (nonatomic, readwrite, strong) NSString *name;
@property (nonatomic, readwrite, strong) NSString *nick;
@property (nonatomic, readwrite, strong) NSArray *keywords;

@end

@implementation CLVStarChatUserInfo

@synthesize name = _name;
@synthesize nick = _nick;
@synthesize keywords = _keywords;

+ (id)userInfoWithDictionary:(NSDictionary *)dictionary
{
    return [[[self class] alloc] initWithDictionary:dictionary];
}

- (id)initWithDictionary:(NSDictionary *)dictionary
{
    self = [super init];
    if (self) {
        self.name = [dictionary objectForKey:@"name"];
        self.nick = [dictionary objectForKey:@"nick"];
        self.keywords = [dictionary objectForKey:@"keywords"];
    }
    return self;
}

@end
