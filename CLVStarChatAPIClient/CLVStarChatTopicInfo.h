//
//  CLVStarChatTopicInfo.h
//  StarChatAPIClient
//
//  Created by slightair on 12/06/16.
//  Copyright (c) 2012 slightair. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CLVStarChatTopicInfo : NSObject

+ (id)topicInfoWithDictionary:(NSDictionary *)dictionary;
- (id)initWithDictionary:(NSDictionary *)dictionary;

@property (nonatomic, readonly) NSInteger topicId;
@property (nonatomic, readonly, strong) NSString *channelName;
@property (nonatomic, readonly, strong) NSString *body;
@property (nonatomic, readonly, strong) NSDate *createdAt;
@property (nonatomic, readonly, strong) NSString *userName;

@end
