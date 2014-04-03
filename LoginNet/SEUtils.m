//
//  SEUtils.m
//  iGolfton
//
//  Created by JimmyKing on 13-1-9.
//  Copyright (c) 2013年 SportsExp. All rights reserved.
//

#import "SEUtils.h"
#import "ASIHTTPRequest.h"

#define USERINFO @"USERINFO"

@implementation SEUtils
+(void)setUserInfo:(NSDictionary *)dic{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:[NSKeyedArchiver archivedDataWithRootObject:dic] forKey:USERINFO];
    [userDefaults synchronize];
}

+(NSDictionary *)getUserInfo{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSData *userData = [userDefaults objectForKey:USERINFO];
    if(userData == nil){
        return nil;
    }else{
        NSDictionary *userInfo = [[NSKeyedUnarchiver unarchiveObjectWithData:userData] mutableCopy];
        return userInfo;
    }
}


+(void)getUpdatedVersion:(GetUpdatedVersionBlock)block{
    NSURL *url = [NSURL URLWithString:@"http://ios-app.qiniudn.com/iReagle.plist"];
    ASIHTTPRequest *httpRequest = [[ASIHTTPRequest alloc] initWithURL:url];
    
    __block ASIHTTPRequest *pointRequest = httpRequest;
    [httpRequest setCompletionBlock:^{
        NSString *error = nil;
        NSDictionary *plist = [NSPropertyListSerialization propertyListFromData:pointRequest.responseData
                                                               mutabilityOption:NSPropertyListImmutable
                                                                         format:nil
                                                               errorDescription:&error];
        
        NSString *version = plist[@"items"][0][@"metadata"][@"bundle-version"];
        block(version);
    }];
    
    
    [httpRequest setFailedBlock:^{
       NSLog(@"%@", [pointRequest error]);
    }];
    
    [httpRequest startAsynchronous];
}

@end
