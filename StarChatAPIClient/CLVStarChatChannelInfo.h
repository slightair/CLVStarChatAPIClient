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

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *privacy;
@property (nonatomic) NSInteger numUsers;
@property (nonatomic, strong) CLVStarChatTopicInfo *topic;

@end
