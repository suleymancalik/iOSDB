//
//  ViewController.m
//  iOSDBExample
//
//  Created by Suleyman Calik on 13/03/14.
//  Copyright (c) 2014 Süleyman Çalık All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
//    [iOSDB setupWithFileName:@"iOSDBTest" extension:@"sqlite" version:@"1"];

    [iOSDB selectFromTable:@"todos"
                  elements:@[@"a" , @"b"]
                      keys:@{@"a":@"1" , @"b":@"2"}];
}


@end
