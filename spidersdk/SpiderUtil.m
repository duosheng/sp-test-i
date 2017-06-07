//
//  Util.m
//  dspider
//
//  Created by 杜文 on 16/12/27.
//  Copyright © 2016年 杜文. All rights reserved.
//

#import "SpiderUtil.h"
#import "dSpider.h"
#import <AdSupport/AdSupport.h>
#import <CommonCrypto/CommonDigest.h>
#import <sys/utsname.h>



@implementation SpiderUtil{
    
}
static NSURLSession *sURlSession=nil;
static NSData *sCertificate=nil;
static NSDictionary * sCommonParams=nil;

+(NSURLSession *) getNSURLSession{
    if(!sURlSession){
        SpiderUtil *delegate=[[SpiderUtil alloc] init];
        sURlSession=[NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]
                                                  delegate:delegate delegateQueue:[NSOperationQueue mainQueue]];
    }
    return  sURlSession;
}

+ (NSString*)getMD5WithData:(NSData *)data{
    const char* original_str = (const char *)[data bytes];
    unsigned char digist[CC_MD5_DIGEST_LENGTH]; //CC_MD5_DIGEST_LENGTH = 16
    CC_MD5(original_str, (uint)strlen(original_str), digist);
    NSMutableString* outPutStr = [NSMutableString stringWithCapacity:10];
    for(int  i =0; i<CC_MD5_DIGEST_LENGTH;i++){
        [outPutStr appendFormat:@"%02x",digist[i]];//小写x表示输出的是小写MD5，大写X表示输出的是大写MD5
    }
    return [outPutStr lowercaseString];
    
}

+ (void) request: (NSString *) url
          method:(NSString *) method
            data:(NSString * _Nullable)param
         handler:(void (^ _Nonnull)(id data ,NSError * _Nullable error) )handler
{
    
    NSURL *uri = [NSURL URLWithString:url];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:uri cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:10000];
    [request setHTTPMethod:method];
    [request setValue:@"XMLHttpRequest" forHTTPHeaderField:@"X-Requested-With"];
    if(param){
        [request setHTTPBody:[param dataUsingEncoding:NSUTF8StringEncoding]];
    }
    NSURLSession *session = [self getNSURLSession];
   // NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionTask *task =
    [session dataTaskWithRequest:request
               completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                   if(error){
                       if(error.code!=NSURLErrorCancelled){
                           handler(nil,[NSError errorWithDomain:error.localizedDescription code:DSPIDER_ERROR_MSG userInfo:nil]);
                       }else{
                           handler(nil,[NSError errorWithDomain:@"当前网络环境不安全，请不要使用代理" code:DSPIDER_ERROR_MSG userInfo:nil]);
                       }
                   }else{
                       NSDictionary * json=[NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
                       if([response.URL.path rangeOfString:@".js"].location==NSNotFound){
                           if(!json){
                               NSString *msg= [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                               handler(nil,[NSError errorWithDomain:msg code:DSPIDER_SERVICE_ERROR userInfo:nil]);
                           }else{
                               handler(json,nil);
                           }
                       }else{
                           handler([[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding],nil);
                       }
                       
                   }
               }
     ];
    [task resume];
}


- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential * _Nullable credential))completionHandler
{
    if([challenge.protectionSpace.authenticationMethod isEqualToString: NSURLAuthenticationMethodServerTrust])
    {
        SecTrustRef serverTrust = challenge.protectionSpace.serverTrust;
        SecCertificateRef serverCertificate = SecTrustGetCertificateAtIndex(serverTrust, 0);
        NSData *serverData = (__bridge_transfer NSData*)SecCertificateCopyData(serverCertificate);
        NSString *certMd5=[SpiderUtil getMD5WithData:serverData];
        if ([challenge.protectionSpace.host isEqualToString:@"api.dtworkroom.com"]
            &&[@"3b63ed1423a718c1226c04244d6f90e0" isEqualToString:certMd5])
        {
            NSURLCredential *credential = [NSURLCredential credentialForTrust:serverTrust];
            [challenge.sender useCredential:credential forAuthenticationChallenge:challenge];
            completionHandler(NSURLSessionAuthChallengeUseCredential,credential);
            return;
        }
    }
    completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge,nil);
    
}


+ (void)post:(NSString *)url
        data:(NSString *)param
     handler:(void (^ _Nonnull)(id data ,NSError * _Nullable error))handler
{
    [self request: url  method:@"POST"  data:param  handler:handler ] ;
}

+ (void)post:(NSString *)url
     dataMap:(NSDictionary *)dict
     handler:(void (^ _Nonnull)(id data ,NSError * _Nullable error))handler
{
    
    NSMutableString *param=nil;
    NSMutableDictionary*dic= [NSMutableDictionary dictionaryWithDictionary:[SpiderUtil getParams]];
    [dic addEntriesFromDictionary:dict];
    param=  [[NSMutableString alloc]init];
    int i=0;
    for (NSString *key in dic) {
        if(i++!=0){
            [param appendString:@"&"];
        }
        [param appendFormat:@"%@=%@",key,[[dic[key] description] stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding]];
    }
    [self request: url  method:@"POST"  data:param  handler:handler ] ;
}

+(NSDictionary *)getParams
{
    if(!sCommonParams){
        struct utsname systemInfo;
        uname(&systemInfo);
        NSString *adId = [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
        NSString *platform = [NSString stringWithCString:systemInfo.machine encoding:NSASCIIStringEncoding];
        sCommonParams=@{@"sid":@1,@"app_id":[NSNumber numberWithInteger:DSPIDER_APP_ID],@"os_version":[[UIDevice currentDevice] systemVersion],@"os":@"ios",@"mac_id":adId,@"bundle_id":[[NSBundle mainBundle]bundleIdentifier],@"sdk_version":@"1.0",@"model":platform,@"app_version":[[[NSBundle mainBundle]infoDictionary] objectForKey:@"CFBundleShortVersionString"]};
    };
    return sCommonParams;
}


+ (void)initSpider:(int)sid :(int)retryConunt :(void (^)(NSDictionary * _Nullable, NSError * _Nullable))handler
{
    NSDictionary*dic= @{@"sid":[NSNumber numberWithInt:sid],@"retry":[NSNumber numberWithInt:retryConunt]};
    [SpiderUtil post :[BASE_URL stringByAppendingString:@"script"] dataMap:dic handler:^(NSDictionary * _Nullable data, NSError * _Nullable error){
        if(error) {
            error= [NSError errorWithDomain:error.domain code:DSPIDER_ERROR_MSG userInfo:nil];
            handler(nil,error);
            return ;
        }
        if([data[@"code"] intValue]!=0){
            handler(nil,[NSError errorWithDomain:data[@"msg"] code:DSPIDER_ERROR_MSG userInfo:nil]);
            NSLog(@"%@",error);
            return ;
        }else{
            handler(data[@"data"],nil);
        }
    }];
    
}
@end
