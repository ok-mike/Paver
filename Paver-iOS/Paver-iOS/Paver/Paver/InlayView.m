//
//  InlayView.m
//  Paverho
//
//  Created by Michael on 01.03.18.
//  Copyright © 2018 Michael Mangelsdorf. All rights reserved.
//

#import "InlayView.h"

@implementation InlayView

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (void) initInlayView {
    
    self.backgroundColor = [UIColor blackColor];
    
//    // Show inlay graphics
//
//    UIImage *image = [UIImage imageNamed:@"poppy.tga"];
//    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"poppy" ofType:@"tga"];
//    gfxRawData = (UInt8*) CFDataGetBytePtr( [self textureFileData:filePath] );
//    // UIImage *image = [UIImage imageWithData:[NSData dataWithBytes:(const void *)gfxRawData length:4*256*256];];
//    // Remove background (black=>transparent)
//    CGFloat colorMasking[] = {0, 1,  0, 1,  0, 1, 255, 255};
//    CGImageRef imageRef = CGImageCreateWithMaskingColors(image.CGImage, colorMasking);
//    image = [UIImage imageWithCGImage:imageRef];
//
//    CGFloat borderWidth = 4.0;
//
//    inlayView = [[UIImageView alloc] initWithImage:image];
//    inlayView.layer.backgroundColor = [[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.5] CGColor];
//    inlayView.layer.cornerRadius = 10;
//    inlayView.layer.borderWidth = borderWidth;
//    inlayView.layer.masksToBounds = YES;
//    inlayView.layer.borderColor=[[UIColor whiteColor] CGColor];
//    inlayView.frame = CGRectMake( width - 300, 50, 256, 256);
//    [self addSubview:inlayView];
}


/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
