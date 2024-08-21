//
//  InfoView.m
//  Paverho
//
//  Created by Michael on 01.03.18.
//  Copyright © 2018 Michael Mangelsdorf. All rights reserved.
//

#import "InfoView.h"

@implementation InfoView

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (void) initInfoView {
        
    UIGraphicsBeginImageContext(self.frame.size);
    [[UIImage imageNamed:@"leaftex1.png"] drawInRect:self.bounds];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    self.backgroundColor = [UIColor colorWithPatternImage:image];
    
    //self.backgroundColor = [UIColor lightGrayColor];
    
    UILabel *label1 = [[UILabel alloc] init];
    label1.frame  = CGRectMake(30, 0, 150, 40);
    label1.font = [UIFont boldSystemFontOfSize:32];
    label1.text = @"Move finger left/right to pan background,";
    label1.textColor =  [UIColor whiteColor];
    label1.numberOfLines = 1;
    [label1 sizeToFit];
    [self addSubview:(UIView*)label1];

    UILabel *label1b = [[UILabel alloc] init];
    label1b.frame  = CGRectMake(30, 40, 150, 40);
    label1b.font = [UIFont boldSystemFontOfSize:32];
    label1b.text = @"swipe to start/stop rotation";
    label1b.textColor =  [UIColor whiteColor];
    label1b.numberOfLines = 1;
    [label1b sizeToFit];
    [self addSubview:(UIView*)label1b];
    
    UILabel *label2 = [[UILabel alloc] init];
    label2.frame  = CGRectMake(30, 120, 150, 40);
    label2.font = [UIFont boldSystemFontOfSize:32];
    label2.text = @"Move inlay square with two fingers";
    label2.textColor =  [UIColor whiteColor];
    label2.numberOfLines = 1;
    [label2 sizeToFit];
    [self addSubview:(UIView*)label2];

    UILabel *label3 = [[UILabel alloc] init];
    label3.frame  = CGRectMake(30, 160, 150, 40);
    label3.font = [UIFont boldSystemFontOfSize:32];
    label3.text = @"Pinch screen to resize console";
    label3.textColor =  [UIColor whiteColor];
    label3.numberOfLines = 1;
    [label3 sizeToFit];
    [self addSubview:(UIView*)label3];

    UILabel *label4 = [[UILabel alloc] init];
    label4.frame  = CGRectMake(30, 200, 150, 40);
    label4.font = [UIFont boldSystemFontOfSize:32];
    label4.text = @"Move two fingers across to blend background";
    label4.textColor =  [UIColor whiteColor];
    label4.numberOfLines = 1;
    [label4 sizeToFit];
    [self addSubview:(UIView*)label4];

    UILabel *label5 = [[UILabel alloc] init];
    label5.frame  = CGRectMake(30, 240, 150, 40);
    label5.font = [UIFont boldSystemFontOfSize:32];
    label5.text = @"Orange door cycles background image";
    label5.textColor =  [UIColor whiteColor];
    label5.numberOfLines = 1;
    [label5 sizeToFit];
    [self addSubview:(UIView*)label5];
    
    UILabel *label6 = [[UILabel alloc] init];
    label6.frame  = CGRectMake(30, 280, 150, 40);
    label6.font = [UIFont boldSystemFontOfSize:32];
    label6.text = @"Green door cycles skybox environment";
    label6.textColor =  [UIColor whiteColor];
    label6.numberOfLines = 1;
    [label6 sizeToFit];
    [self addSubview:(UIView*)label6];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
