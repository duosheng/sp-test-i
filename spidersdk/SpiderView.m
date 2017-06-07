//
//  SpiderView.m
//  spider
//
//  Created by 杜文 on 17/1/9.
//  Copyright © 2017年 杜文. All rights reserved.
//

#import "SpiderView.h"

@implementation SpiderView

/*
 // Only override drawRect: if you perform custom drawing.
 // An empty implementation adversely affects performance during animation.
 - (void)drawRect:(CGRect)rect {
 // Drawing code
 }
 */

@synthesize WebEventDelegate;
@synthesize ExceptUrl;

- (instancetype)initWithFrame:(CGRect)frame
{
    if(self=[super initWithFrame:frame]){
        [self setHandler];
    }
    return self;
}

-(void) setHandler
{
    id webview=[self getXWebview];
    if([webview isKindOfClass:[DUIwebview class]]){
        ((DUIwebview *)webview).WebEventDelegate=WebEventDelegate;
    }else{
        ((DWKwebview *)webview).navigationDelegate=self;
    }
}
- (void)setUserAgent:(NSString *)ua
{
    id webview=[self getXWebview];
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 9.0 && [webview isKindOfClass:[DWKwebview class]]) {
        [((DWKwebview *)webview) setCustomUserAgent:ua];
    }else{
        NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:ua, @"UserAgent", nil];
        [[NSUserDefaults standardUserDefaults] registerDefaults:dictionary];
    }
}
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    
    NSURLRequest *request = navigationAction.request;
    if(request){
        NSString * r=[[request URL]absoluteString];
        if(![@"about:blank" isEqualToString:r] && [r hasPrefix:@"http"]){
            url = [[request URL]absoluteString];
            if( [WebEventDelegate respondsToSelector:NSSelectorFromString(@"onPageStart:")]){
                [WebEventDelegate onPageStart:url];
            }
        }
    }
    decisionHandler(WKNavigationActionPolicyAllow);
}

-(void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation
{
    
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error
{
    if([url hasPrefix:@"http"] && error.code!=NSURLErrorCancelled){
        if([WebEventDelegate respondsToSelector: NSSelectorFromString(@"onpageError::")]){
            [WebEventDelegate onpageError:url :[error localizedDescription]];
        }
    }
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(null_unspecified WKNavigation *)navigation
{
    if( [url hasPrefix:@"http"] && [WebEventDelegate respondsToSelector:@selector(onpageFinished:)]){
        [WebEventDelegate onpageFinished: url];
    }
    
}

- (void)webView:(WKWebView *)webView didFailNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error
{
    if([url hasPrefix:@"http"] && error.code!=NSURLErrorCancelled){
        if([WebEventDelegate respondsToSelector: NSSelectorFromString(@"onpageError::")]){
            [WebEventDelegate onpageError:url :[error localizedDescription]];
        }
    }
}



@end
