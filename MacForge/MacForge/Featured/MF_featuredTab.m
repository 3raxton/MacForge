//
//  MF_featuredTab.m
//  MacForge
//
//  Created by Wolfgang Baird on 8/2/19.
//  Copyright © 2019 MacEnhance. All rights reserved.
//

@import AppKit;
@import WebKit;

#import "PluginManager.h"
#import "AppDelegate.h"
#import "pluginData.h"
#import "MF_featuredTab.h"

extern AppDelegate* myDelegate;
extern NSString *repoPackages;
extern long selectedRow;

@implementation MF_featuredTab {
    bool doOnce;
    Boolean needsRefresh;
    NSMutableDictionary* installedPlugins;
    NSDictionary* item;
    PluginManager *_sharedMethods;
    pluginData *_pluginData;
    NSMutableDictionary *featuredRepo;
}

-(void)awakeFromNib {
    //    [NSAnimationContext beginGrouping];
        NSPoint newOrigin = NSMakePoint(0, self.frame.size.height - self.superview.frame.size.height);
        [self.enclosingScrollView.contentView scrollToPoint:newOrigin];
    //    [NSAnimationContext endGrouping];
    //    [self setSubviews:[NSArray array]];
    
        static dispatch_once_t aToken;
        dispatch_once(&aToken, ^{
            self->needsRefresh = true;
        });

        if (needsRefresh) {
            needsRefresh = false;
            
            _smallFeature01 = [[MF_featuredSmallController alloc] initWithNibName:0 bundle:nil];
            _smallFeature02 = [[MF_featuredSmallController alloc] initWithNibName:0 bundle:nil];
            _smallFeature03 = [[MF_featuredSmallController alloc] initWithNibName:0 bundle:nil];
            _smallFeature04 = [[MF_featuredSmallController alloc] initWithNibName:0 bundle:nil];
            _smallFeature05 = [[MF_featuredSmallController alloc] initWithNibName:0 bundle:nil];
            _smallFeature06 = [[MF_featuredSmallController alloc] initWithNibName:0 bundle:nil];
            
            _largeFeature01 = [[MF_featuredItemController alloc] initWithNibName:0 bundle:nil];
            _largeFeature02 = [[MF_featuredItemController alloc] initWithNibName:0 bundle:nil];
            _largeFeature03 = [[MF_featuredItemController alloc] initWithNibName:0 bundle:nil];

            //    NSArray *large = [[NSArray alloc] initWithObjects:_largeFeature01, _largeFeature02, nil];
            NSArray *small = [[NSArray alloc] initWithObjects:_smallFeature01, _smallFeature02, _smallFeature03, _smallFeature04, _smallFeature05, _smallFeature06, nil];
            
            dispatch_queue_t backgroundQueue = dispatch_queue_create("com.w0lf.MacForge", 0);
            dispatch_async(backgroundQueue, ^{
                if (self->_sharedMethods == nil)
                    self->_sharedMethods = [PluginManager sharedInstance];
                
                // Fetch repo content
                static dispatch_once_t aToken;
                dispatch_once(&aToken, ^{
                    self->_pluginData = [pluginData sharedInstance];
                    [self->_pluginData fetch_repos];
                    self->featuredRepo = [self->_pluginData fetch_repo:@"https://github.com/w0lfschild/myRepo/raw/master/featuredRepo"];
                });
                
    //            NSSortDescriptor *sorter = [[NSSortDescriptor alloc] initWithKey:@"webName" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
                NSArray *dank = [[NSMutableArray alloc] initWithArray:[self->featuredRepo allValues]];
                
                // Sort table by name
                //        NSSortDescriptor *sorter = [[NSSortDescriptor alloc] initWithKey:@"webName" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
                //        NSArray *dank = [[NSMutableArray alloc] initWithArray:[self->_pluginData.repoPluginsDic allValues]];
                //    dank = [self filterView:dank];
                //    _tableContent = [[dank sortedArrayUsingDescriptors:@[sorter]] copy];
                //
                //    // Fetch our local content too
                //    _localPlugins = [_sharedMethods getInstalledPlugins].allKeys;
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    int ypos = 0;
                    int xpos = 12;
                    int totalHeight = 0;
                    NSRect newFrame;
                    //            MSPlugin *item = [[MSPlugin alloc] init];
                    
                    // Background color if no background image provided
                    struct CGColor *clr = [NSColor.grayColor colorWithAlphaComponent:0.4].CGColor;
                    NSString *osxMode = [[NSUserDefaults standardUserDefaults] stringForKey:@"AppleInterfaceStyle"];
                    if ([osxMode isEqualToString:@"Dark"]) clr = [NSColor.whiteColor colorWithAlphaComponent:0.1].CGColor;
                    
                    // Setup large featured item
                    NSView *test2 = self->_largeFeature01.view;
                    [test2 setWantsLayer:true];
                    [test2 setFrame:CGRectMake(12, self.frame.size.height - test2.frame.size.height - 20, self.frame.size.width - 30, 180)];
                    [test2.layer setBackgroundColor:clr];
                    [test2.layer setCornerRadius:12];
                    [self addSubview:test2];
                    [self setupLargeController:dank :0 :self->_largeFeature01];
                    totalHeight = self.frame.size.height - (test2.frame.size.height * 2) + 10;
                    
                    // Setup 2nd large featured item
                    test2 = self->_largeFeature02.view;
                    [test2 setWantsLayer:true];
                    [test2 setFrame:CGRectMake(12, totalHeight - 50, self.frame.size.width - 30, 180)];
                    [test2.layer setBackgroundColor:clr];
                    [test2.layer setCornerRadius:12];
                    [self addSubview:test2];
                    [self setupLargeController:dank :1 :self->_largeFeature02];
                    totalHeight -= test2.frame.size.height + 20;
                    
                    // Setup 3rd large featured item
                    test2 = self->_largeFeature03.view;
                    [test2 setWantsLayer:true];
                    [test2 setFrame:CGRectMake(12, totalHeight - 50, self.frame.size.width - 30, 180)];
                    [test2.layer setBackgroundColor:clr];
                    [test2.layer setCornerRadius:12];
                    [self addSubview:test2];
                    [self setupLargeController:dank :2 :self->_largeFeature03];
                    totalHeight -= test2.frame.size.height + 20;
                   
                    NSUInteger totalFeatured = dank.count - 3;
                    for (int i = 0; i < totalFeatured; i++) {
                        MF_featuredSmallController *cont = (MF_featuredSmallController*)small[i];
                        
                        NSView *test = [cont view];
                        [test setWantsLayer:true];
                        newFrame = test.frame;
                        //                ypos = self.frame.size.height - ((test.frame.size.height + 20) * (i / 2)) - totalHeight;
                        ypos = totalHeight;
                        if (i % 2 == 0) {
                            xpos = 12;
                            [test setAutoresizingMask:test.autoresizingMask|NSViewMaxXMargin];
                        } else {
                            totalHeight -= 150;
                            xpos = (self.frame.size.width / 2) + 5;
                            [test setAutoresizingMask:test.autoresizingMask|NSViewMinXMargin];
                        }
                        newFrame.size.width = (self.frame.size.width / 2) - 25;
                        newFrame.origin.y = ypos;
                        newFrame.origin.x = xpos;
                        [test setFrame:newFrame];
                        [test.layer setBackgroundColor:clr];
                        [test.layer setCornerRadius:12];
                        [self addSubview:test];
                        [self setupSmallController:dank :i+3 :cont];


                        //                MSPlugin *item = [dank objectAtIndex:i + 2];
                        //                [cont setupWithPlugin:item];
                    }
                    
                    [self setFrameSize:CGSizeMake(self.frame.size.width, self.frame.size.height - totalHeight + 20)];
                    [self scrollPoint:CGPointMake(0, self.frame.size.height)];
                });
            });
        }
            
}

-(void)setupLargeController:(NSArray*)array :(int)index :(MF_featuredItemController*)vc {
    MSPlugin *p = [[MSPlugin alloc] init];
    if (index < array.count) {
        p = [array objectAtIndex:index];
        [vc setupWithPlugin:p];
    }
}

-(void)setupSmallController:(NSArray*)array :(int)index :(MF_featuredSmallController*)vc {
    MSPlugin *p = [[MSPlugin alloc] init];
    if (index < array.count) {
        p = [array objectAtIndex:index];
        [vc setupWithPlugin:p];
    }
}

//-(void)viewWillDraw {
////    [NSAnimationContext beginGrouping];
//    NSPoint newOrigin = NSMakePoint(0, self.frame.size.height - self.superview.frame.size.height);
//    [self.enclosingScrollView.contentView scrollToPoint:newOrigin];
////    [NSAnimationContext endGrouping];
////    [self setSubviews:[NSArray array]];
//
//    static dispatch_once_t aToken;
//    dispatch_once(&aToken, ^{
//        self->needsRefresh = true;
//    });
//
//    if (needsRefresh) {
//        needsRefresh = false;
//
//        _smallFeature01 = [[MF_featuredSmallController alloc] initWithNibName:0 bundle:nil];
//        _smallFeature02 = [[MF_featuredSmallController alloc] initWithNibName:0 bundle:nil];
//        _smallFeature03 = [[MF_featuredSmallController alloc] initWithNibName:0 bundle:nil];
//        _smallFeature04 = [[MF_featuredSmallController alloc] initWithNibName:0 bundle:nil];
//        _smallFeature05 = [[MF_featuredSmallController alloc] initWithNibName:0 bundle:nil];
//        _smallFeature06 = [[MF_featuredSmallController alloc] initWithNibName:0 bundle:nil];
//        _largeFeature01 = [[MF_featuredItemController alloc] initWithNibName:0 bundle:nil];
//        _largeFeature02 = [[MF_featuredItemController alloc] initWithNibName:0 bundle:nil];
//
//        //    NSArray *large = [[NSArray alloc] initWithObjects:_largeFeature01, _largeFeature02, nil];
//        NSArray *small = [[NSArray alloc] initWithObjects:_smallFeature01, _smallFeature02, _smallFeature03, _smallFeature04, _smallFeature05, _smallFeature06, nil];
//
//        dispatch_queue_t backgroundQueue = dispatch_queue_create("com.w0lf.MacForge", 0);
//        dispatch_async(backgroundQueue, ^{
//            if (self->_sharedMethods == nil)
//                self->_sharedMethods = [PluginManager sharedInstance];
//
//            // Fetch repo content
//            static dispatch_once_t aToken;
//            dispatch_once(&aToken, ^{
//                self->_pluginData = [pluginData sharedInstance];
//                [self->_pluginData fetch_repos];
//                self->featuredRepo = [self->_pluginData fetch_repo:@"https://github.com/w0lfschild/myRepo/raw/master/featuredRepo"];
//            });
//
////            NSSortDescriptor *sorter = [[NSSortDescriptor alloc] initWithKey:@"webName" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
//            NSArray *dank = [[NSMutableArray alloc] initWithArray:[self->featuredRepo allValues]];
//
//            // Sort table by name
//            //        NSSortDescriptor *sorter = [[NSSortDescriptor alloc] initWithKey:@"webName" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
//            //        NSArray *dank = [[NSMutableArray alloc] initWithArray:[self->_pluginData.repoPluginsDic allValues]];
//            //    dank = [self filterView:dank];
//            //    _tableContent = [[dank sortedArrayUsingDescriptors:@[sorter]] copy];
//            //
//            //    // Fetch our local content too
//            //    _localPlugins = [_sharedMethods getInstalledPlugins].allKeys;
//
//            dispatch_async(dispatch_get_main_queue(), ^{
//                int ypos = 0;
//                int xpos = 12;
//                int totalHeight = 0;
//                NSRect newFrame;
//                //            MSPlugin *item = [[MSPlugin alloc] init];
//
//                // Background color if no background image provided
//                struct CGColor *clr = [NSColor.grayColor colorWithAlphaComponent:0.4].CGColor;
//                NSString *osxMode = [[NSUserDefaults standardUserDefaults] stringForKey:@"AppleInterfaceStyle"];
//                if ([osxMode isEqualToString:@"Dark"]) clr = [NSColor.whiteColor colorWithAlphaComponent:0.1].CGColor;
//
//                // Setup large featured item
//                NSView *test2 = self->_largeFeature01.view;
//                [test2 setWantsLayer:true];
//                [test2 setFrame:CGRectMake(12, self.frame.size.height - test2.frame.size.height - 20, self.frame.size.width - 30, 180)];
//                [test2.layer setBackgroundColor:clr];
//                [test2.layer setCornerRadius:12];
//                [self addSubview:test2];
//                [self setupLargeController:dank :0 :self->_largeFeature01];
//                totalHeight = self.frame.size.height - (test2.frame.size.height * 2) + 10;
//
//                // Setup 2nd large featured item
//                test2 = self->_largeFeature02.view;
//                [test2 setWantsLayer:true];
//                [test2 setFrame:CGRectMake(12, totalHeight - 50, self.frame.size.width - 30, 180)];
//                [test2.layer setBackgroundColor:clr];
//                [test2.layer setCornerRadius:12];
//                [self addSubview:test2];
//                [self setupLargeController:dank :1 :self->_largeFeature02];
//                totalHeight -= test2.frame.size.height + 20;
//
//                // Setup 6 small featured items
//                for (int i = 0; i < 6; i++) {
////                    MF_featuredSmallController *cont = (MF_featuredSmallController*)small[i];
//                    MF_featuredSmallController *cont = [[MF_featuredSmallController alloc] initWithNibName:0 bundle:nil];
//
//                    NSView *test = [cont view];
//                    [test setWantsLayer:true];
//                    newFrame = test.frame;
//                    //                ypos = self.frame.size.height - ((test.frame.size.height + 20) * (i / 2)) - totalHeight;
//                    ypos = totalHeight;
//                    if (i % 2 == 0) {
//                        xpos = 12;
//                        [test setAutoresizingMask:test.autoresizingMask|NSViewMaxXMargin];
//                    } else {
//                        totalHeight -= 150;
//                        xpos = (self.frame.size.width / 2) + 5;
//                        [test setAutoresizingMask:test.autoresizingMask|NSViewMinXMargin];
//                    }
//                    newFrame.size.width = (self.frame.size.width / 2) - 25;
//                    newFrame.origin.y = ypos;
//                    newFrame.origin.x = xpos;
//                    [test setFrame:newFrame];
//                    [test.layer setBackgroundColor:clr];
//                    [test.layer setCornerRadius:12];
//                    [self addSubview:test];
//                    [self setupSmallController:dank :i+2 :cont];
//
//                    NSLog(@"%@", NSStringFromSelector(cont.bundleBanner.action));
//
//                    //                MSPlugin *item = [dank objectAtIndex:i + 2];
//                    //                [cont setupWithPlugin:item];
//                }
//            });
//        });
//    }
//
//}

@end
