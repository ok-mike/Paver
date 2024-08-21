//
//  MyViewController.m
//  Phos-iOS
//
//  Created by Michael on 10.02.18.
//  Copyright © 2018 Michael Mangelsdorf. All rights reserved.
//

#import "ConsoleViewController.h"
#import "ConsoleView.h"

@interface ConsoleViewController ()

@end

@implementation ConsoleViewController

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    CGFloat width = [[UIScreen mainScreen] bounds].size.width;
    CGFloat height = [[UIScreen mainScreen] bounds].size.height;
    
    // Create an OpenGL ES context and assign it
    ConsoleView *view = (ConsoleView*) self.view;
    
    view.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
    
    // Configure renderbuffers created by the view
    view.drawableColorFormat = GLKViewDrawableColorFormatRGBA8888;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    view.drawableStencilFormat = GLKViewDrawableStencilFormat8;
    
    // Need redraw when bounds change
    view.contentMode = UIViewContentModeRedraw;
    
    // Enable multisampling
    // view.drawableMultisample = GLKViewDrawableMultisample4X;
    
    // Set animation frame rate
    self.preferredFramesPerSecond = 40;

    [EAGLContext setCurrentContext:view.context];
    [view initMyView];
    
    UITextInputAssistantItem* item = self.inputAssistantItem;
    item.leadingBarButtonGroups = @[];
    item.trailingBarButtonGroups = @[];
}


- (void)update
{
    // Called automatically by view controller
    // use timeSinceLastUpdate
    
    [(ConsoleView*) self.view frameUpdate];
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    [(ConsoleView*) view frameDraw:rect];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



//    self.bounds = CGRectMake(0, 0, 900, 500);

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.view endEditing:YES];
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)keyboardWillShow:(NSNotification *)notification
{
    CGSize keyboardSize = [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    [UIView animateWithDuration:0.3 animations:^{
        CGRect f = self.view.frame;
        f.origin.y = -keyboardSize.height;
        self.view.frame = f;
    }];
    
    [self keyboardWillToggle:notification];
}

-(void)keyboardWillHide:(NSNotification *)notification
{
    [UIView animateWithDuration:0.3 animations:^{
        CGRect f = self.view.frame;
        f.origin.y = 0.0f;
        self.view.frame = f;
    }];
    
    [self keyboardWillToggle:notification];
}

- (void) keyboardWillToggle:(NSNotification *)aNotification
{
    CGRect frame = [[[self tabBarController] tabBar] frame];
    CGRect keyboard = [[aNotification.userInfo valueForKey:@"UIKeyboardFrameEndUserInfoKey"] CGRectValue];
    frame.origin.y = keyboard.origin.y - frame.size.height;
    [UIView animateWithDuration:[[aNotification.userInfo valueForKey:@"UIKeyboardAnimationDurationUserInfoKey"] floatValue] animations:^
     {
         [[[self tabBarController] tabBar] setFrame:frame];
     }];
}


@end
