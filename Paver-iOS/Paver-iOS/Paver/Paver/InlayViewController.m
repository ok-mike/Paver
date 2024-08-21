//
//  InlayViewController.m
//  Paverho
//
//  Created by Michael on 01.03.18.
//  Copyright © 2018 Michael Mangelsdorf. All rights reserved.
//

#import "InlayViewController.h"
#include "InlayView.h"

@interface InlayViewController ()

@end

@implementation InlayViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    InlayView* inlayView = [[InlayView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    [self.view addSubview:inlayView];
    
    [inlayView initInlayView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
