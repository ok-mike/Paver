//
//  SecondViewController.m
//  Paverho
//
//  Created by Michael on 22.02.18.
//  Copyright © 2018 Michael Mangelsdorf. All rights reserved.
//

#import "InfoViewController.h"
#import "InfoView.h"

@interface InfoViewController ()

@end

@implementation InfoViewController

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    InfoView* infoView = [[InfoView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    [self.view addSubview:infoView];
    
    [infoView initInfoView];

}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
