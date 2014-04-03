//
//  LNAppDelegate.h
//  LoginNet
//
//  Created by liu min on 14-3-15.
//  Copyright (c) 2014年 sportsexp. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LNViewController.h"

@interface LNAppDelegate : UIResponder <UIApplicationDelegate>{
    LNViewController *lnVC;
    BOOL isEnterBG;
}

@property (strong, nonatomic) UIWindow *window;

@end
