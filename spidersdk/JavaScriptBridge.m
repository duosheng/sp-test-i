//
//  JavaScriptBridge.m
//  dspider
//
//  Created by 杜文 on 16/12/28.
//  Copyright © 2016年 杜文. All rights reserved.
//

#import "JavaScriptBridge.h"
#import <UIKit/UIDevice.h>
#import "JSBUtil.h"
#import "SpiderUtil.h"

@implementation JavaScriptBridge
{
    //Save result
    NSMutableDictionary<NSString*,NSMutableArray<NSString*>*> * datas;
    //Save session cache
    NSMutableDictionary<NSString*,NSString*> * session;
    //JS bridge delegate
    id<JavascriptBridgeDelegate>  jsbDelegate;
    
}

@synthesize webview;

- (instancetype)init:(id<JavascriptBridgeDelegate>)delegate
{
    datas=[[NSMutableDictionary alloc] init];
    session=[[NSMutableDictionary alloc] init];
    jsbDelegate=delegate;
    return self;
}

-(void) clear{
    [datas removeAllObjects];
    [session removeAllObjects];
}

//JavaScript Bridge
-(NSString *) start:(NSDictionary *) args
{
    if([jsbDelegate isStart]){
        NSString * sessionKey=[args valueForKey:@"sessionKey"];
        if([datas valueForKey:sessionKey]==nil){
            [datas setValue:[[NSMutableArray alloc] init] forKey:sessionKey];
        }
    }
    return nil;
}

-(NSString *) set:(NSDictionary *) args
{
    if([jsbDelegate isStart]){
        session[args[@"key"]]=args[@"value"];
        //[session setValue:[args valueForKey:@"value"] forKey:[args valueForKey:@"key"] ];
    }
    return nil;
}

-(NSString *) get:(NSDictionary *) args
{
    if([jsbDelegate isStart]){
        return session[args[@"key"]];
        //return [session valueForKey:[args valueForKey:@"key"]];
    }
    return nil;
}

-(NSString *) save:(NSDictionary *) args
{
    if([jsbDelegate isStart]){
        [jsbDelegate save:args[@"key"] :args[@"value"]];
    }
    return nil;
}

-(NSString *) read:(NSDictionary *) args
{
    if([jsbDelegate isStart]){
        return [jsbDelegate read:args[@"key"]];
    }
    return nil;
}

-(NSString *) showProgressExcept:(NSDictionary *) args
{
    if([jsbDelegate isStart]){
        webview.ExceptUrl=args[@"url"];
    }
    return nil;
}

-(NSString *) getExtraData:(NSDictionary *) args
{
    if([jsbDelegate isStart]){
        UIApplication *app = [UIApplication sharedApplication];
        bool isWifi=false;
        NSArray *children = [[[app valueForKeyPath:@"statusBar"] valueForKeyPath:@"foregroundView"] subviews];
        
        int type = 0;
        for (id child in children) {
            if ([child isKindOfClass:[NSClassFromString(@"UIStatusBarDataNetworkItemView") class]]) {
                type = [[child valueForKeyPath:@"dataNetworkType"] intValue];
            }
        }
        
        NSString *stateString = @"wifi";
        
        switch (type) {
            case 0:
                stateString = @"notReachable";
                break;
                
            case 1:
                stateString = @"2G";
                break;
                
            case 2:
                stateString = @"3G";
                break;
                
            case 3:
                stateString = @"4G";
                break;
                
            case 4:
                stateString = @"LTE";
                break;
                
            case 5:
                isWifi=true;
                stateString = @"wifi";
                break;  
                
            default:  
                break;  
        }
        
        NSDictionary<NSString*,id> *netWork=@{@"isWifi":@(isWifi),
                                              @"subType":@(type),
                                              @"subTypeName":stateString
                                              };
        
        NSDictionary<NSString*,id> *info=@{
                                           @"os":@"ios",
                                           @"osVersion":[[UIDevice currentDevice] systemVersion],
                                           @"sdkVersion":SDK_VERSION,
                                           @"network":netWork
                                           };
        NSString *json= [JSBUtil objToJsonString:info];
        return json;
    }
    return nil;
}

-(NSString *) push:(NSDictionary *) args
{
    if([jsbDelegate isStart]){
        [datas[args[@"sessionKey"]] addObject: args[@"value"]];
    }
    return nil;
}

-(NSString *) setProgress:(NSDictionary *) args
{
    if([jsbDelegate isStart]){
            [jsbDelegate setProgress:[args[@"progress"] intValue]];
    }
    return nil;
}

-(NSString *) setProgressMax:(NSDictionary *) args
{
    if([jsbDelegate isStart]){
            [jsbDelegate setProgressMax:[args[@"progress"] intValue]];
    }
    return nil;
}

-(NSString *) setProgressMsg:(NSDictionary *) args
{
    if([jsbDelegate isStart]){
            [jsbDelegate setProgressMsg:args[@"msg"]];
    }
    return nil;
}

-(NSString *) getArguments:(NSDictionary *) args
{
    NSString * json=webview.Arguments;
    if(!json) json=@"{}";
    return json;
}

-(NSString *) setArguments:(NSDictionary *) args
{
    webview.Arguments= args[@"args"];
    return nil;
}

-(NSString *) setUserAgent:(NSDictionary *) args
{
    [webview  setUserAgent:args[@"ua"]];
    return nil;
}

-(NSString *) autoLoadImg:(bool) load
{
    return nil;
}
//optional
-(NSString *) showProgress:(NSDictionary *) args
{
    if([jsbDelegate isStart]){
        [jsbDelegate showProgress:[args[@"show"] boolValue]];
    }
    return nil;
}

-(NSString *) finish:(NSDictionary *) args
{
    if([jsbDelegate isStart]){
        [jsbDelegate finish:args[@"sessionKey"]
                           :datas[args[@"sessionKey"]]
                           :[args[@"result"] intValue]
                           :args[@"msg"]
         ];
    }
    return nil;
}


-(NSString *) log:(NSDictionary *) args
{
    if([jsbDelegate isStart]){
        NSLog(@"dSpider:%@",args[@"msg"]);
        [jsbDelegate log:args[@"msg"] :[args[@"type"] intValue]];
        
    }
    return nil;
}

@end
