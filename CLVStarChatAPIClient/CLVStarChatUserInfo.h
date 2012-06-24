//
//  CLVStarChatUserInfo.h
//  StarChatAPIClient
//
//  Created by slightair on 12/06/16.
//  Copyright (c) 2012 slightair. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CLVStarChatUserInfo : NSObject

+ (id)userInfoWithDictionary:(NSDictionary *)dictionary;
- (id)initWithDictionary:(NSDictionary *)dictionary;

@property (nonatomic, readonly, strong) NSString *name;
@property (nonatomic, readonly, strong) NSString *nick;
@property (nonatomic, readonly, strong) NSArray *keywords;

@end
