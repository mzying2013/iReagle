//
//  SEUtils.h
//  iGolfton
//
//  Created by JimmyKing on 13-1-9.
//  Copyright (c) 2013年 SportsExp. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

typedef void(^GetUpdatedVersionBlock)(NSString *version);

@interface SEUtils : NSObject
+(void)setUserInfo:(NSDictionary *)dic;
+(NSDictionary *)getUserInfo;
+(void)getUpdatedVersion:(GetUpdatedVersionBlock)block;

@end
