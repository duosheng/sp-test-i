//
//  DSpiderViewController.m
//  spider
//
//  Created by 杜文 on 17/1/9.
//  Copyright © 2017年 杜文. All rights reserved.
//

#import "DSpiderViewController.h"
#import "DSWaveView.h"
#define UIColorFromRGB(rgbValue,a) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue &0xFF00) >>8))/255.0 blue:((float)(rgbValue &0xFF))/255.0 alpha:a]

@interface DSpiderViewController (){
    bool exitDlg;
    bool retryDlg;
}
@property(weak) DSCircleProgressView * progressView;
@property(weak) UILabel* progressMsg;
@property(weak) UIView* progressContainer;
@property(weak) DSpiderDataView* spiderView;
@property(weak) UIView *divider;
@property(weak) UIAlertView *alertView ;
@property(weak) UILabel *titleView ;
@end
@implementation DSpiderViewController

@synthesize progressView, progressMsg,resultDelegate,progressContainer,spiderView,alertView,divider,titleView;
- (void)viewDidLoad {
    [super viewDidLoad];
    CGRect bounds=self.view.bounds;
    self.view.backgroundColor=UIColor.whiteColor;
    int width=bounds.size.width/2.3;
    exitDlg=false;
    retryDlg=false;
    DSCircleProgressView *progress=[[DSCircleProgressView alloc] initWithFrame:CGRectMake((bounds.size.width-width)/2, 15, width, width)];
    UIView *toobar=[[UIView alloc]initWithFrame:CGRectMake(0, 0, bounds.size.width, 64)];
    UIView *container=[[UIView alloc]initWithFrame:CGRectMake(0, 64, bounds.size.width, bounds.size.height-64)];
    UIButton *btnClose=[[UIButton alloc] initWithFrame:CGRectMake(0, 20,50, 44)];
    [toobar addSubview:btnClose];
    [btnClose setTitle:@"返回" forState:normal];
    [btnClose addTarget:self action:@selector(onClick:) forControlEvents:UIControlEventTouchUpInside];
    btnClose.titleLabel.font = [UIFont systemFontOfSize: 13];
    [btnClose setTitleColor:UIColor.blackColor forState:normal];
    //toobar.backgroundColor=UIColor.redColor;
    
    UIView * _divider = [[UIView alloc] initWithFrame:CGRectMake(0, 63, bounds.size.width, 1.f/[UIScreen mainScreen].scale)];
    divider=_divider;
    [divider setBackgroundColor:[UIColor colorWithWhite:.6f alpha:.3f]];
    [toobar addSubview:divider];
    UILabel *tit=[[UILabel alloc]initWithFrame:CGRectMake(66, 22,bounds.size.width-132, 44)];
    titleView=tit;
    tit.textAlignment=NSTextAlignmentCenter;
    tit.textColor=UIColor.darkGrayColor;
    tit.font=[UIFont systemFontOfSize:13];
    [toobar addSubview:tit];
    
    progressView=progress;
    progressView.arcFinishColor=progressView.arcUnfinishColor=UIColorFromRGB(0x196296, 0.8f);
    progressView.arcBackColor=UIColorFromRGB(0x196296, 0.1f);
    int margin=16;
    UILabel *label=[[UILabel alloc]initWithFrame:CGRectMake(margin, 60+width,bounds.size.width-2*margin, 20)];
    label.textAlignment=NSTextAlignmentCenter;
    label.textColor=UIColor.darkGrayColor;
    label.font=[UIFont systemFontOfSize:14];
    progressMsg=label;
    
    [container addSubview:label];
    int top=150+width;
    DSWaveView *dsWaveView=[[DSWaveView alloc]initWithFrame:CGRectMake(0,top,bounds.size.width,bounds.size.height-top)];
    dsWaveView.firstWaveColor=UIColorFromRGB(0x196296, .75);
    DSWaveView *dsWaveView2=[[DSWaveView alloc]initWithFrame:CGRectMake(0,top,bounds.size.width,bounds.size.height-top)];
    dsWaveView2.firstWaveColor=UIColorFromRGB(0x196296, 1);
    [dsWaveView2 setOffset:40.0];
    [dsWaveView start];
    [dsWaveView2 start];
    
    [container addSubview:dsWaveView];
    [container addSubview:dsWaveView2];
    [container addSubview:progressView];
    
    
    
    DSpiderDataView * dsv= [[DSpiderDataView alloc]initWithFrame:CGRectMake(0, 64, bounds.size.width, bounds.size.height-64)];
    //[dsv setHidden:YES];
    dsv.backgroundColor=UIColor.redColor;
    dsv.delegate=self;
    [self.view addSubview:dsv];
    progressContainer=container;
    [container setHidden:YES];
    [self.view addSubview:toobar];
    [self.view addSubview:container];
    spiderView=dsv;
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)onProgress:(int)progress :(int)max
{
    progressView.percent=progress/(float)max;
}

-(void)onProgressMsg:(NSString *)msg
{
    progressMsg.text=msg;
}

-(void)setPersistenceDelegate:(id<Persistence>)persistenceDelegate{
    spiderView.persistenceDelegate=persistenceDelegate;
}

-(void)onResult:(NSString *)sessionKey data:(NSMutableArray *)data
{
    SEL sel=NSSelectorFromString(@"onSucceed:data:");
    if(resultDelegate && [resultDelegate respondsToSelector:sel]){
        [resultDelegate onSucceed:sessionKey data:data];
    }
    [self goBack];
}

-(void)onProgressShow:(bool)isShow
{
    BOOL show=isShow?YES:NO;
    [progressContainer setHidden:!show];
    [spiderView setHidden:show];
    [divider setHidden:show];
}

-(void)goBack{
    [self dismissViewControllerAnimated:YES completion:nil];
    
}
-(void) onError:(int)code :(NSString *)msg
{
    if([spiderView canRetry]){
        exitDlg=false;
        if(alertView){
            [alertView dismissWithClickedButtonIndex:0 animated:YES];
        }
        
        SEL sel=NSSelectorFromString(@"onRetry::");
        if(resultDelegate && [resultDelegate respondsToSelector:sel]){
            if( [resultDelegate onRetry:code :msg]==YES){
                [spiderView retry];
                return;
            }
        }else{
            UIAlertView *alert = [[UIAlertView alloc]  initWithTitle:@"提示" message:@"本次爬取遇到了点问题，但检测到新的方案，是否重试？"
                                                            delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil, nil];
            alertView=alert;
            [alertView show];
            return;
        }
    }
    SEL sel=NSSelectorFromString(@"onFail::");
    if(resultDelegate && [resultDelegate respondsToSelector:sel]){
        [resultDelegate onFail:code :msg];
    }else{
        UIAlertView *alert= [[UIAlertView alloc]  initWithTitle:@"提示" message:msg
                                                       delegate:nil cancelButtonTitle:nil otherButtonTitles:@"确定", nil, nil];
  
        [alert show];
    }
    
    [self goBack];
    
    
}

-(void) onClick:(UIButton *) btn{
    
    exitDlg=true;
    UIAlertView *alert= [[UIAlertView alloc]  initWithTitle:@"提示" message:@"退出后当前任务将中断，确定退出？"
                                                   delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil, nil];
    alertView=alert;
    [alertView show];
    
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if(exitDlg){
        if(buttonIndex==1){
            [spiderView stop];
            [self onCancel:@"任务被中断"];
        }
        exitDlg=false;
    }else{
        if(buttonIndex==1){
            [spiderView retry];
        }else{
            [self onCancel:@"重试被取消"];
        }
    }
}

-(void) onCancel:(NSString *)msg{
    SEL sel=NSSelectorFromString(@"onFail::");
    if(resultDelegate && [resultDelegate respondsToSelector:sel]){
        [resultDelegate onFail:DSPIDER_ERROR_MSG :msg];
    }
    [self goBack];
    
}

-(void)setArguments:(NSDictionary *) args{
    [spiderView setArguments:args];
}
-(void)start:(int) sid title:(NSString *)title{
    titleView.text=title;
    [spiderView start:sid];
}
-(void)startDebug:(NSString *)title debugScript:(NSString *)debugScript debugUrl:(NSString *)debugUrl{
     titleView.text=title;
    [spiderView startDebug:debugScript debugUrl:debugUrl];
}


@end
