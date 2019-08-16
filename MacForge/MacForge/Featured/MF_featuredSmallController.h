//
//  MF_featuredSmallController.h
//  MacForge
//
//  Created by Wolfgang Baird on 8/2/19.
//  Copyright © 2019 MacEnhance. All rights reserved.
//

@import AppKit;
#import "MSPlugin.h"
#import "PluginManager.h"
#import "MF_Purchase.h"
#import <SDWebImage/SDWebImage.h>
#import "SYFlatButton.h"

NS_ASSUME_NONNULL_BEGIN

@interface MF_featuredSmallController : NSViewController
{
    MSPlugin *plug;
}

@property IBOutlet NSTextField*     bundleName;
@property IBOutlet NSTextField*     bundleDesc;
@property IBOutlet NSImageView*     bundleBanner;
@property IBOutlet NSButton*        bundleButton;
@property IBOutlet SYFlatButton*    bundleGet;
@property IBOutlet NSProgressIndicator*    bundleProgress;

- (IBAction)getOrOpen:(id)sender;
- (IBAction)moreInfo:(id)sender;
- (void)setupWithPlugin:(MSPlugin*)plugin;

@end

NS_ASSUME_NONNULL_END
