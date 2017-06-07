//
//  DSpiderDataView.m
//  dspider
//
//  Created by 杜文 on 16/12/28.
//  Copyright © 2016年 杜文. All rights reserved.
//

#import "DSpiderDataView.h"

@interface DSpiderDataView (){
    bool exitDlg;
    bool retryDlg;
}

@property(weak) UIActivityIndicatorView  *progressLoading ;
@property(weak) SpiderView * spiderView;
@end

@implementation DSpiderDataView{
    
    NSString * spider;
    int maxProgress;
    JavaScriptBridge* api;
    bool start;
    int retryCount;
    NSInteger scriptCount;
    NSInteger scriptId;
    NSInteger taskId;
    int sid;
    bool spiderServiceState;
    NSString *script;
    bool isDebug;
    bool progressShow;
    NSString *arguments;
    
}

@synthesize spiderView,progressLoading,persistenceDelegate;
- (instancetype)initWithFrame:(CGRect)frame
{
    if(self=[super initWithFrame:frame])
    {
        maxProgress=100;
        start=false;
        retryCount=1;
        scriptCount=0;
        sid=0;
        scriptId=0;
        progressShow=false;
        spiderServiceState=true;
//        SpiderView *_spiderView=[[SpiderView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
//        spiderView=_spiderView;
//        spiderView.WebEventDelegate=self;
//        api=[[JavaScriptBridge alloc]init:self :spiderView];
//        spiderView.JavascriptInterfaceObject=api;
//        [self addSubview:spiderView];
        //CGRectMake((frame.size.width-60)/2, (frame.size.width-60)/2, 60, 60)
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector (hideKeyboard) name: UIKeyboardDidShowNotification object:nil];
        UIActivityIndicatorView * _progress= [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
        [_progress setColor:UIColor.blackColor];
        
        _progress.backgroundColor=UIColor.whiteColor;
        [self addSubview:_progress];
        progressLoading=_progress;
    }
    return self;
}

-(void) createSpiderView{
    if(spiderView){
        [spiderView removeFromSuperview];
    }else{
    }
    spiderView.Arguments=arguments;
    spiderView.ExceptUrl=@"";
    SpiderView *_spiderView=[[SpiderView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width,self.frame.size.height)];
    spiderView=_spiderView;
    spiderView.WebEventDelegate=self;
    api=nil;
    api=[[JavaScriptBridge alloc]init:self];
    api.webview=spiderView;
    spiderView.JavascriptInterfaceObject=api;
    [self insertSubview:spiderView atIndex:0];
}

- (void)start:(int)id {
    sid=id;
    retryCount=0;
    [self retry];
}

-(void)startDebug:(NSString *)debugScript debugUrl:(NSString *)debugUrl{

    start=true;
    isDebug=true;
    [self createSpiderView];
    [spiderView loadUrl:debugUrl];
    debugScript=[NSString  stringWithFormat : @"!function(){\n%@\n}();",debugScript];
    __weak SpiderView * w=spiderView;
    [self initEnv:^(NSString * _Nullable sdkScript, NSError * _Nullable error) {
        if(error){
            return [self handleError:error];
        }
        script=[NSString  stringWithFormat : @"%@\n%@",(NSString *)sdkScript,debugScript];
        __weak NSString * _script=script;
        __weak DSpiderDataView * _self=self;
        [spiderView setJavascriptContextInitedListener:^(void){
            [w evaluateJavaScript:_script completionHandler:^(NSString * _Nonnull result) {
                if(!result){
                    [_self handleError:[NSError errorWithDomain:@"A JavaScript exception occurred" code:DSPIDER_SCRIPT_ERROR userInfo:nil]];
                }
            }];
        }];
        
    }];
    
}

-(bool)canRetry{
    return (spiderServiceState && retryCount<scriptCount);
}

-(void)handleError: (NSError * _Nullable) error{
    
    if(error.code==DSPIDER_SERVICE_ERROR){
        spiderServiceState=false;
    }
    if(self.delegate && [self.delegate respondsToSelector:NSSelectorFromString(@"onError::")]){
        [self.delegate onError:(int)error.code :error.domain];
    }
    
}

-(void)retry{
    isDebug=false;
    [self createSpiderView];
    if(retryCount!=0 && ![self canRetry]){
        NSLog(@"dSpider warning: Can't retry, retry ignored!");
        return;
    }
    [self initEnv:^(NSString * _Nullable sdkScript, NSError * _Nullable error) {
        if(error){
            return [self handleError:error];
        }
        [SpiderUtil initSpider:sid :++retryCount :^(NSDictionary * _Nullable data, NSError * _Nullable error) {
            if(error){
                return [self handleError:error];
            }
            //script=[NSString  stringWithFormat : @"%@\n%@",(NSString *)sdkScript,data[@"script"]];
            script=data[@"script"];
            scriptCount=[data[@"script_count"] integerValue];
            taskId=[data[@"id"] integerValue];
            scriptId=[data[@"script_id"] integerValue];
            start=true;
            [self showProgress:false];
            [self setProgressMax:100];
            [self setProgress:0];
            if(self.delegate && [self.delegate respondsToSelector:NSSelectorFromString(@"onScriptLoaded::")]){
                [self.delegate onScriptLoaded:retryCount];
            }
            NSString *pcUA=@"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/55.0.2883.95 Safari/537.36";
            NSString *phoneUA=@"Mozilla/5.0 (iPhone; CPU iPhone OS 9_1 like Mac OS X) AppleWebKit/601.1.46 (KHTML, like Gecko) Version/9.0 Mobile/13B143 Safari/601.1";
            NSInteger ua=[data[@"ua"] integerValue];
            if( ua==1){
                [spiderView setUserAgent:phoneUA];
            }else if(ua==2){
                [spiderView setUserAgent:pcUA];
            }
            [spiderView loadUrl:data[@"login_url"]];//加载
            __weak SpiderView * w=spiderView;
            __weak DSpiderDataView * _self=self;
            [spiderView setJavascriptContextInitedListener:^(void){
                [w evaluateJavaScript:sdkScript completionHandler:^(NSString * _Nonnull result) {
                    [w evaluateJavaScript:data[@"script"] completionHandler:^(NSString * _Nonnull result) {
                        if(!result){
                            [_self handleError:[NSError errorWithDomain:@"A JavaScript exception occurred" code:DSPIDER_SCRIPT_ERROR userInfo:nil]];
                        }
                    }];
                }];
                
            }];
        }];
        
    }];
}

-(void)initEnv: (void (^ _Nullable)(NSString * _Nullable sdkScript  ,NSError * _Nullable error)) handler{
    NSString *  URL_DQUERY=@"https://dspider.dtworkroom.com/public/dquery.js";
    NSString *dQuery = [[NSUserDefaults standardUserDefaults] stringForKey:@"ds_dquery"];
    if(dQuery==nil || [dQuery length]==0){
        [SpiderUtil request: URL_DQUERY method:@"GET"  data:nil  handler:^(id  _Nullable str, NSError * _Nullable error) {
            if(error){
                handler(nil,[NSError errorWithDomain:[error localizedDescription] code:DSPIDER_SERVICE_ERROR userInfo:nil]);
            }else{
                [[NSUserDefaults standardUserDefaults] setValue:str forKey:@"ds_dquery"];
                handler(str,nil);
            }
        }];
    }else{
        handler(dQuery,nil);
    }
}

-(void)setArguments:(NSDictionary *)args{
    arguments=[JSBUtil objToJsonString:args];
    spiderView.Arguments=[JSBUtil objToJsonString:args];
}


-(void) hideKeyboard {
    if(progressShow){
        [self endEditing:YES];
    }
}

-(void)stop
{
    start=false;
    [spiderView evaluateJavaScript:@"javascript:window.close()" completionHandler:nil];
    [spiderView clearCache];
}


-(bool)isStart
{
    return start;
}

- (void) setProgress:(int) progress
{
    if(self.delegate && [self.delegate respondsToSelector:NSSelectorFromString(@"onProgress::")]){
        [self.delegate onProgress:progress :maxProgress];
    }
}

- (void) setProgressMax:(int)max
{
    maxProgress=max;
}
- (void)finish:(NSString *)sessionKey :(NSMutableArray<NSString *>*)result :(int) code :(NSString *)errmsg;
{
    start=false;
    DSPIDER_STATE state=code;
    if(state==DSPIDER_SUCCEED){
        if(self.delegate && [self.delegate respondsToSelector:NSSelectorFromString(@"onResult:data:")]){
            [self.delegate onResult:sessionKey data:result];
        }
    }else{
        if(self.delegate && [self.delegate respondsToSelector:NSSelectorFromString(@"onError::")]){
            [self.delegate onError:code :errmsg];
        }
    }
    if(!isDebug){
        [self reportState:code :errmsg];
    }
    [spiderView evaluateJavaScript:@"javascript:window.close()" completionHandler:nil];
}

-(void)reportState:(int) code :(NSString *)errmsg{
    
    NSDictionary*dic=@{@"state":[NSNumber numberWithInteger:code],@"task_id":[NSNumber numberWithInteger:taskId],@"script_id":[NSNumber numberWithInteger:scriptId],@"msg":errmsg};
    [SpiderUtil post:[BASE_URL stringByAppendingString:@"report"] dataMap:dic handler:^(id  _Nullable data, NSError * _Nullable error) {
        
    }];
    
}

-(void)log:(NSString *)msg :(int)type{
    NSLog(@"%@ type:%d",msg,type);
    if(self.delegate  && [self.delegate respondsToSelector:NSSelectorFromString(@"onLog::")]){
        [self.delegate onLog:msg :type];
    }
}

- (void) setProgressMsg:(NSString *)msg
{
    if(self.delegate && [self.delegate respondsToSelector:NSSelectorFromString(@"onProgressMsg:")]){
        [self.delegate onProgressMsg:msg];
    }
}
-(void)showProgress:(bool)show
{
    progressShow=show;
    if(self.delegate && [self.delegate respondsToSelector:NSSelectorFromString(@"onProgressShow:")]){
        [self.delegate onProgressShow :show];
    }
}

-(void)save:(NSString *)key :(NSString *)value{
    if(persistenceDelegate && [persistenceDelegate respondsToSelector:NSSelectorFromString(@"save::")]){
        [persistenceDelegate save:key :value];
    }else{
        [[NSUserDefaults standardUserDefaults] setValue:value forKey:key];
    }
}

-(NSString *)read:(NSString *)key{
    if(persistenceDelegate && [persistenceDelegate respondsToSelector:NSSelectorFromString(@"read:")]){
        return  [persistenceDelegate read:key];
    }else{
        return [[NSUserDefaults standardUserDefaults] stringForKey:key];
    }
}

//Webevent delegate
- (void) onpageError:(NSString *)url :(NSString *) msg{
    
    if(self.delegate && [url hasPrefix:@"http"] && [self.delegate respondsToSelector:NSSelectorFromString(@"onError::")]){
        [self.delegate onError:DSPIDER_WEB_ERROR :msg];
    }
}
- (void) onSdkError:(NSString *)description :(NSString *) url{
    if(self.delegate && [self.delegate respondsToSelector:NSSelectorFromString(@"onError::")]){
        [self.delegate onError:DSPIDER_SERVICE_ERROR :description];
    }
}
-(void)onPageStart:(NSString *)url{
    if([url hasPrefix:@"http"]){
        [progressLoading startAnimating];
        [progressLoading setHidden:NO];
        
        if(spiderView.ExceptUrl && [spiderView.ExceptUrl isEqualToString:url] ){
            if(self.delegate && [self.delegate respondsToSelector:NSSelectorFromString(@"onProgressShow:")]){
                progressShow=true;
                [self.delegate onProgressShow:true];
            }
        }
    }
}
-(void)onpageFinished:(NSString *)url{
    if([url hasPrefix:@"http"]){
        [progressLoading stopAnimating];
        [progressLoading setHidden:YES];
    }
}

@end
