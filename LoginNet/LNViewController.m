//
//  LNViewController.m
//  LoginNet
//
//  Created by liu min on 14-3-15.
//  Copyright (c) 2014年 sportsexp. All rights reserved.
//

#import "LNViewController.h"
#import "ASIHTTPRequest.h"
#import "SVProgressHUD.h"
#import "ASIFormDataRequest.h"
#import "SEUtils.h"
#import <SystemConfiguration/CaptiveNetwork.h>
#import <QuartzCore/QuartzCore.h>

#define USER_NAME @"username"
#define USER_PWD @"pwd"
#define NET_NAME @"reagle"

@interface LNViewController ()<ASIHTTPRequestDelegate,UIAlertViewDelegate,UITextFieldDelegate>{
    NSString *wifiSSID;
    CGFloat originalViewY;
    BOOL isOnline;
    BOOL currentSwitchState;
}
@property (weak, nonatomic) IBOutlet UISwitch *openSwitch;
- (IBAction)openSwitchPress:(id)sender;
@property (weak, nonatomic) IBOutlet UITextField *usernameTextField;
@property (weak, nonatomic) IBOutlet UITextField *pwdTextField;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIView *inputBGView;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UILabel *versionLabel;

@end

@implementation LNViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    _inputBGView.layer.cornerRadius = 4.0;
    
    if([SEUtils getUserInfo] != nil){
        NSDictionary *userInfo = [SEUtils getUserInfo];
        _usernameTextField.text = userInfo[USER_NAME]   ;
        _pwdTextField.text = userInfo[USER_PWD];
    }
    
    NSDictionary *appInfoDic = [[NSBundle mainBundle] infoDictionary];
    NSString *appVersion = appInfoDic[@"CFBundleShortVersionString"];
    _versionLabel.text = [NSString stringWithFormat:@"Design by Bill liu(v%@).",appVersion];
}


-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self updateNetInfo];
}


-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    originalViewY = CGRectGetMinY(self.view.frame);
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    [self downViewForEdit];
}


#pragma mark - Custom method
-(void)checkNewVersion{
    //检测版本更新
    [SEUtils getUpdatedVersion:^(NSString *version) {
        NSDictionary *appInfoDic = [[NSBundle mainBundle] infoDictionary];
        NSString *appVersion = appInfoDic[@"CFBundleShortVersionString"];
        float appVersionF = [appVersion floatValue];
        float updatedVersionF = [version floatValue];
        if(updatedVersionF > appVersionF){
            NSString *message = [NSString stringWithFormat:@"You can install a new version(%@)",version];
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Tips"
                                                                message:message
                                                               delegate:self
                                                      cancelButtonTitle:@"Cancel"
                                                      otherButtonTitles:@"Yes", nil];
            alertView.tag = 202;
            [alertView show];
        }
    }];
}


-(void)updateNetInfo{
    NSString *ssid = [self fetchSSIDInfo];
    if(ssid != nil){
        wifiSSID = ssid;
        _statusLabel.text = wifiSSID;
        
        if([ssid isEqualToString:NET_NAME]){
            [self checkOnline];
        }else{
            [_openSwitch setOn:NO animated:YES];
        }
    }else{
        [_openSwitch setOn:NO animated:YES];
        _statusLabel.text = @"Please connect to WiFi";
    }
    
    currentSwitchState = _openSwitch.isOn;
}



-(void)checkOnline{
    isOnline = NO;
    [SVProgressHUD showWithStatus:@"正在加载."];
    NSURL *url = [NSURL URLWithString:@"http://www.baidu.com"];
    ASIHTTPRequest *httpReqeust = [ASIHTTPRequest requestWithURL:url];
    httpReqeust.delegate = self;
    httpReqeust.tag = 302;
    [httpReqeust startAsynchronous];
}



-(void)downViewForEdit{
    if([_usernameTextField isFirstResponder]){
        [_usernameTextField resignFirstResponder];
    }
    
    if([_pwdTextField isFirstResponder]){
        [_pwdTextField resignFirstResponder];
    }
    
    if(CGRectGetMinY(self.view.frame) != originalViewY){
        [UIView animateWithDuration:0.2 animations:^{
            [self.view setFrame:CGRectMake(0, originalViewY, CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame))];
        }];
    }
}


-(void)upViewForEnterWithView:(UIView *)textField{
    CGPoint btnPoint = CGPointMake(0, CGRectGetMaxY(textField.frame));
    CGPoint point = [textField convertPoint:btnPoint toView:self.view];
    CGFloat maxY = point.y;
    CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
    
    if(screenHeight - maxY < 256){
        CGFloat minY = screenHeight - maxY - 256;
        [UIView animateWithDuration:0.2 animations:^{
            [self.view setFrame:CGRectMake(0, originalViewY + minY, CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame))];
        }];
    }
}



-(void)checkWiFi{
    if(wifiSSID != nil && [wifiSSID isEqualToString:NET_NAME]){
        [self sendLoginHttpRequest];
    }else{
        NSString *message = [NSString stringWithFormat:@"请连接 %@ Wi-Fi.",NET_NAME];
        [SVProgressHUD showErrorWithStatus:message];
        [_openSwitch setOn:NO animated:YES];
    }
    
    currentSwitchState = _openSwitch.isOn;
}




-(void)sendLoginHttpRequest{
    [SVProgressHUD showWithStatus:@"正在加载."];
    
    NSString *urlStr = @"http://192.168.10.141/cgi-bin/ace_web_auth.cgi";
    NSURL *url = [NSURL URLWithString:urlStr];
    ASIFormDataRequest *httpRequest = [ASIFormDataRequest requestWithURL:url];
    
    NSDictionary *userinfo = [SEUtils getUserInfo];
    [httpRequest addPostValue:userinfo[USER_NAME] forKey:@"username"];
    [httpRequest addPostValue:userinfo[USER_PWD] forKey:@"userpwd"];
    [httpRequest addPostValue:@"%E7%99%BB+%E5%BD%95" forKey:@"login"];
    [httpRequest addPostValue:@"liumin" forKey:@"orig_referer"];
    httpRequest.tag = 300;
    httpRequest.delegate = self;
    [httpRequest startAsynchronous];
}


-(void)sendLogoutHttpReqeust{
    [SVProgressHUD showWithStatus:@"正在加载."];
    
    NSString *urlStr = @"http://192.168.10.141/cgi-bin/ace_web_auth.cgi?logout";
    NSURL *url = [NSURL URLWithString:urlStr];
    ASIHTTPRequest *httpRequest = [ASIHTTPRequest requestWithURL:url];
    httpRequest.tag = 301;
    httpRequest.delegate = self;
    [httpRequest startAsynchronous];
}



-(NSString *)fetchSSIDInfo{
    NSString *ssid = nil;
    NSArray *wifiArray = (__bridge NSArray *)(CNCopySupportedInterfaces());
    for(NSString *wifiName in wifiArray){
        NSDictionary *info = (__bridge NSDictionary *)(CNCopyCurrentNetworkInfo((__bridge CFStringRef)(wifiName)));
        if(info[@"SSID"]){
            ssid = info[@"SSID"];
        }
    }
    return ssid;
}



#pragma mark - Switch Action
- (IBAction)openSwitchPress:(id)sender {
    UISwitch *swith = (UISwitch*)sender;
    
    if(currentSwitchState != [swith  isOn]){
        if([swith isOn]){
            if(_usernameTextField.text.length <1 || _pwdTextField.text.length <1){
                [SVProgressHUD showErrorWithStatus:@"请输入用户名或密码."];
                [swith setOn:NO animated:YES];
                [swith setEnabled:YES];
            }else{
                NSDictionary *userInform = @{USER_NAME:_usernameTextField.text,USER_PWD:_pwdTextField.text};
                [SEUtils setUserInfo:userInform];
                [self checkWiFi];
            }
            
        }else{
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Tips"
                                                                message:@"Are you sure you want to logout?"
                                                               delegate:self
                                                      cancelButtonTitle:@"Cancel"
                                                      otherButtonTitles:@"Yes", nil];
            alertView.tag = 200;
            [alertView show];
        }
    }
}



#pragma mark - UITextFieldDelegate method
- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField{
    if([_openSwitch isOn]){
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Tips"
                                                            message:@"Account change require to logout."
                                                           delegate:self
                                                  cancelButtonTitle:@"Cancel"
                                                  otherButtonTitles:@"Yes", nil];
        alertView.tag = 201;
        [alertView show];
        return NO;
        
    }else{
        [self upViewForEnterWithView:textField];
        return YES;
    }
}


- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    if(textField.tag == 100){
        [_pwdTextField becomeFirstResponder];
    }else{
        [self downViewForEdit];
        NSDictionary *userInform = @{USER_NAME:_usernameTextField.text,USER_PWD:_pwdTextField.text};
        [SEUtils setUserInfo:userInform];
        [self checkWiFi];
    }
    return YES;
}


#pragma mark - UIAlertViewDelegate method
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if(alertView.tag == 200){
        if(buttonIndex == 1){
            [self sendLogoutHttpReqeust];
        }else{
            [_openSwitch setOn:YES animated:YES];
            currentSwitchState = _openSwitch.isOn;
        }
        
        
    }else if(alertView.tag == 201){
        if(buttonIndex == 1){
            [self sendLogoutHttpReqeust];
        }
        
        
    }else if(alertView.tag == 202){
        if(buttonIndex == 1){
            NSURL *url = [NSURL URLWithString:@"itms-services://?action=download-manifest&url=https://dn-ios-app.qbox.me/iReagle.plist"];
            [[UIApplication sharedApplication] openURL:url];
        }
    }
}



#pragma mark - ASIHTTPReqeustDelegate method
-(void)requestFinished:(ASIHTTPRequest *)request{
    if(request.tag == 300){
        NSString *responseStr = [[NSString alloc] initWithData:[request responseData]
                                                      encoding:NSUTF8StringEncoding];
        int range = (int)[responseStr rangeOfString:@"reason="].length;
        if(range == 0){
            [_openSwitch setOn:YES animated:YES];
            [SVProgressHUD showSuccessWithStatus:@"登陆成功."];
            [self checkNewVersion];
            
        }else{
            [_openSwitch setOn:NO animated:YES];
            [SVProgressHUD showErrorWithStatus:@"账户信息错误."];
        }
        
        
    }else if(request.tag == 301){
        [_openSwitch setOn:NO animated:YES];
        [SVProgressHUD showSuccessWithStatus:@"注销成功."];
        
        
    }else if(request.tag == 302){
        [SVProgressHUD dismiss];
        NSString *responseStr = [[NSString alloc] initWithData:[request responseData]
                                                      encoding:NSUTF8StringEncoding];
        int range = (int)[responseStr rangeOfString:@"192.168.10.141/login.php"].length;
        if(range == 0){
            [_openSwitch setOn:YES animated:YES];
        }else{
            [_openSwitch setOn:NO animated:YES];
        }
    }
    
    currentSwitchState = _openSwitch.isOn;
}


-(void)requestFailed:(ASIHTTPRequest *)request{
    [SVProgressHUD dismiss];
    NSLog(@"error:%@",request.error);
    if(request.tag == 302){
        [_openSwitch setOn:NO animated:YES];
    }
    
    currentSwitchState = _openSwitch.isOn;
}
@end


