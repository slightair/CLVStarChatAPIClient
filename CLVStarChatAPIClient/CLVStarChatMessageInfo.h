//
//  CLVStarChatMessageInfo.h
//  StarChatAPIClient
//
//  Created by slightair on 12/06/16.
//  Copyright (c) 2012 slightair. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CLVStarChatMessageInfo : NSObject

+ (id)messageInfoWithDictionary:(NSDictionary *)dictionary;
- (id)initWithDictionary:(NSDictionary *)dictionary;

@property (nonatomic, readonly) NSInteger messageId;
@property (nonatomic, readonly, strong) NSString *userName;
@property (nonatomic, readonly, strong) NSString *body;
@property (nonatomic, readonly, strong) NSDate *createdAt;
@property (nonatomic, readonly, strong) NSString *channelName;
@property (nonatomic, readonly) BOOL isNotice;

@end
