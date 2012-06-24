//
//  CLVStarChatChannelInfo.h
//  StarChatAPIClient
//
//  Created by slightair on 12/06/16.
//  Copyright (c) 2012 slightair. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CLVStarChatTopicInfo.h"

@interface CLVStarChatChannelInfo : NSObject

+ (id)channelInfoWithDictionary:(NSDictionary *)dictionary;
- (id)initWithDictionary:(NSDictionary *)dictionary;

@property (nonatomic, readonly, strong) NSString *name;
@property (nonatomic, readonly, strong) NSString *privacy;
@property (nonatomic, readonly) NSInteger numUsers;
@property (nonatomic, readonly, strong) CLVStarChatTopicInfo *topic;

@end
