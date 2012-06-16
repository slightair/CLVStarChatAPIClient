//
//  CLVStarChatMessageInfo.h
//  StarChatAPIClient
//
//  Created by slightair on 12/06/16.
//  Copyright (c) 2012 slightair. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CLVStarChatMessageInfo : NSObject

@property (nonatomic) NSInteger messageId;
@property (nonatomic, strong) NSString *userName;
@property (nonatomic, strong) NSString *body;
@property (nonatomic) NSInteger createdAt;
@property (nonatomic, strong) NSString *channelName;
@property (nonatomic) BOOL isNotice;

@end
