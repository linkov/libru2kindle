//
//  SDWMainWindowController.m
//  Lists
//
//  Created by alex on 11/4/14.
//  Copyright (c) 2014 SDWR. All rights reserved.
//

#import "SDWMainWindowController.h"

@interface SDWMainWindowController () <NSWindowDelegate>

@end

@implementation SDWMainWindowController

- (void)windowDidLoad {
    [super windowDidLoad];
    self.window.delegate = self;
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (void)windowDidUpdate:(NSNotification *)notification {
    NSWindow *win = notification.object;
    win.titlebarAppearsTransparent = YES;
    win.titleVisibility = NSWindowTitleHidden;
    win.styleMask = win.styleMask | NSFullSizeContentViewWindowMask;
    win.delegate = nil;
}

@end
