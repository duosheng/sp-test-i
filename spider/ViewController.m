//
//  ViewController.m
//  spider
//
//  Created by 杜文 on 17/1/4.
//  Copyright © 2017年 杜文. All rights reserved.
//

#import "ViewController.h"
#import "spidersdk.h"
#import "dSpider.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    CGRect bounds=self.view.bounds;
    UIButton *btnVisible=[[UIButton alloc] initWithFrame:CGRectMake(10, 64,bounds.size.width/4, 20)];
    [self.view addSubview: btnVisible];
    [btnVisible setTitle:@"显式爬取" forState:normal];
    [btnVisible addTarget:self action:@selector(onClick:) forControlEvents:UIControlEventTouchUpInside];
    btnVisible.backgroundColor=UIColor.redColor;
    [dSpider init:1];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    

}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
     
-(void) onClick:(UIButton *) btn{
    
    DSpiderViewController *controller=[[DSpiderViewController alloc]init];
    controller.resultDelegate=self;
    //[self.navigationController pushViewController:controller animated:YES];
    [self presentViewController:controller animated:YES completion:nil];
    [controller start:1 title:@"测试"];
}
     
-(void)onSucceed:(NSString *)sessionKey data:(NSMutableArray *)data{

}

//-(void)onFail:(int)code :(NSString *)msg{
// 
//}

//-(BOOL)onRetry:(int)code :(NSString *)msg{
//    return YES;
//}

@end
