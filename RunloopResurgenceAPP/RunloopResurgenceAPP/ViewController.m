//
//  ViewController.m
//  RunloopResurgenceAPP
//
//  Created by lemon on 2018/8/23.
//  Copyright © 2018年 Lemon. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor brownColor];
    // Do any additional setup after loading the view, typically from a nib.
    UIButton *button = [[UIButton alloc]init];
    [button setTitle:@"点击就异常" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(buttonClick) forControlEvents:UIControlEventTouchUpInside];
    button.frame = CGRectMake(100, 100, 100, 20);
    [self.view addSubview:button];
}

- (void)buttonClick{
    id array = @[@"myBlog",@"lemon2Well.top"];
    [array objectAtIndex:3];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
