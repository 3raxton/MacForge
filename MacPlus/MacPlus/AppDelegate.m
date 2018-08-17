//
//  AppDelegate.m
//  MacPlus
//
//  Created by Wolfgang Baird on 1/9/16.
//  Copyright © 2016 Wolfgang Baird. All rights reserved.
//

#import "AppDelegate.h"

AppDelegate* myDelegate;

NSMutableArray *allLocalPlugins;
NSMutableArray *allReposPlugins;
NSMutableArray *allRepos;

NSMutableDictionary *myPreferences;
NSMutableArray *pluginsArray;

NSMutableDictionary *installedPluginDICT;
NSMutableDictionary *needsUpdate;

NSMutableArray *confirmDelete;

NSArray *sourceItems;
NSArray *discoverItems;
Boolean isdiscoverView = true;

NSDate *appStart;

NSButton *selectedView;

NSMutableDictionary *myDict;
NSUserDefaults *sharedPrefs;
NSDictionary *sharedDict;

@implementation AppDelegate

NSUInteger osx_ver;
NSArray *tabViewButtons;
NSArray *tabViews;

// Shared instance
+ (AppDelegate*) sharedInstance {
    static AppDelegate* myDelegate = nil;
    
    if (myDelegate == nil)
        myDelegate = [[AppDelegate alloc] init];
    
    return myDelegate;
}

// Run bash script
- (NSString*) runCommand: (NSString*)command {
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/bin/sh"];
    NSArray *arguments = [NSArray arrayWithObjects:@"-c", [NSString stringWithFormat:@"%@", command], nil];
    [task setArguments:arguments];
    NSPipe *pipe = [NSPipe pipe];
    [task setStandardOutput:pipe];
    NSFileHandle *file = [pipe fileHandleForReading];
    [task launch];
    NSData *data = [file readDataToEndOfFile];
    NSString *output = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    return output;
}

// Show DevMate feedback
- (IBAction)showFeedbackDialog:(id)sender {
    [DevMateKit showFeedbackDialog:nil inMode:DMFeedbackDefaultMode];
}

// Cleanup some stuff when user changes dark mode
- (void)systemDarkModeChange:(NSNotification *)notif {
    if (osx_ver >= 14) {
        if (notif == nil) {
            if ([NSApp.effectiveAppearance.name isEqualToString:NSAppearanceNameAqua]) {
                [_changeLog setTextColor:[NSColor blackColor]];
            } else {
                [_changeLog setTextColor:[NSColor whiteColor]];
            }
        } else {
            NSString *osxMode = [[NSUserDefaults standardUserDefaults] stringForKey:@"AppleInterfaceStyle"];
            if ([osxMode isEqualToString:@"Dark"]) {
                [_changeLog setTextColor:[NSColor whiteColor]];
            } else {
                [_changeLog setTextColor:[NSColor blackColor]];
            }
        }
    }
}

// Startup
- (instancetype)init {
    myDelegate = self;
    appStart = [NSDate date];
    osx_ver = [[NSProcessInfo processInfo] operatingSystemVersion].minorVersion;
    return self;
}

// Quit when window closed
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication {
    return YES;
}

// Try to install bundles when passed to application
- (void)application:(NSApplication *)sender openFiles:(NSArray*)filenames {
    [PluginManager.sharedInstance installBundles:filenames];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [DevMateKit sendTrackingReport:nil delegate:nil];
    [DevMateKit setupIssuesController:nil reportingUnhandledIssues:YES];

    [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(systemDarkModeChange:) name:@"AppleInterfaceThemeChangedNotification" object:nil];
    [[NSDistributedNotificationCenter defaultCenter] addObserverForName:@"com.w0lf.MacPlusNotify"
                                                                 object:nil
                                                                  queue:nil
                                                             usingBlock:^(NSNotification *notification)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([notification.object isEqualToString:@"prefs"]) [self selectView:self->_viewPreferences];
            if ([notification.object isEqualToString:@"about"]) [self selectView:self->_viewAbout];
            if ([notification.object isEqualToString:@"manage"]) [self selectView:self->_viewPlugins];
            if ([notification.object isEqualToString:@"check"]) { [PluginManager.sharedInstance checkforPluginUpdates:nil :self->_viewUpdateCounter]; }
        });
    }];

    // Loop looking for bundle updates
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [PluginManager.sharedInstance checkforPluginUpdates:nil :self->_viewUpdateCounter];
    });

    NSArray *args = [[NSProcessInfo processInfo] arguments];
    if (args.count > 1) {
        if ([args containsObject:@"prefs"]) [self selectView:_viewPreferences];
        if ([args containsObject:@"about"]) [self selectView:_viewAbout];
        if ([args containsObject:@"manage"]) [self selectView:_viewPlugins];
    }

    [self installXcodeTemplate];
    
//    DMKitDebugAddDevMateMenu();
    
    [self executionTime:@"startPaddle"];

//    NSDictionary *productInfo = [NSDictionary dictionaryWithObjectsAndKeys:
//                                 @"1.99", kPADCurrentPrice,
//                                 @"Wolfgang Baird", kPADDevName,
//                                 @"USD", kPADCurrency,
//                                 @"https://dl.devmate.com/org.w0lf.cDock-GUI/icons/5aae1388a46dd_128.png", kPADImage,
//                                 @"moreMenu", kPADProductName,
//                                 @"0", kPADTrialDuration,
//                                 @"Thanks for purchasing", kPADTrialText,
//                                 @"icon.icns", kPADProductImage,
//                                 nil];
//
//    [thePaddle startLicensing:productInfo timeTrial:YES withWindow:self.window];
//    [thePaddle verifyLicenceWithCompletionBlock:^(BOOL verified, NSError *error) {
//        if (verified) {
//            NSLog(@"Verified");
//        } else {
//            NSLog(@"Not verified: %@", [error localizedDescription]);
//        }
//    }];
    
    // 5F9588C2-A31F8D2B-E7F5997B-FA18A063-97E00C6D

//    [thePaddle startPurchaseForChildProduct:@"534450"];
//    [[PADProduct alloc] productInfo:@"534450" apiKey:@"02a3c57238af53b3c465ef895729c765" vendorId:@"26643" withCompletionBlock:^(BOOL fin) { NSLog(@"Hi"); }];
    
//    [[PaddleStoreKit sharedInstance] showProduct:@"534450"];
//    [[PaddleStoreKit sharedInstance] showStoreView];
//    [[PaddleStoreKit sharedInstance] showStoreViewForProductIds:@[@"534450"]];
    
//    [thePaddle verifyLicenceWithCompletionBlock:^(BOOL ver, NSError *e){ NSLog(@"%hhd : %@", ver, e.localizedDescription); }];
//    [thePaddle startLicensing:productInfo timeTrial:NO withWindow:self.window];
//    [thePaddle startLicensingSilently:productInfo timeTrial:NO];
//    [thePaddle setupChildProduct:@"534450" productInfo:productInfo timeTrial:NO];
//    [thePaddle startPurchaseForChildProduct:@"534450"];
//    [thePaddle verifyLicenceForChildProduct:@"534450" withCompletionBlock:^(BOOL ver, NSError *e){ NSLog(@"%hhd : %@", ver, e.localizedDescription); }];
//    [thePaddle showLicencing];
//    [PaddleStoreKit.sharedInstance recoverPurchases];
    
//    [thePaddle startLicensingSilently:productInfo timeTrial:NO];
//    [thePaddle setupChildProduct:@"534403.1" productInfo:productInfo timeTrial:NO];
//    [thePaddle startPurchaseForChildProduct:@"534403.1"];
//    [thePaddle purchaseChildProduct:@"534403.1" withWindow:self.window completionBlock:^(NSString* response, NSString* email, BOOL completed, NSError *error, NSDictionary *checkoutData){
//
//    }];
    
    
//    - (void)purchaseChildProduct:(nonnull NSString *)childProductId withWindow:(nullable NSWindow *)window completionBlock:(nonnull void (^)(NSString * _Nullable response, NSString * _Nullable email, BOOL completed, NSError * _Nullable error, NSDictionary * _Nullable checkoutData))completionBlock;

    
//    [thePaddle verifyLicenceWithCompletionBlock:^(BOOL verified, NSError *error) {
//        if (verified) {
//            NSLog(@"Verified");
//        } else {
//            NSLog(@"Not verified: %@", [error localizedDescription]);
//        }
//    }];
    
    NSDate *methodFinish = [NSDate date];
    NSTimeInterval executionTime = [methodFinish timeIntervalSinceDate:appStart];
    NSLog(@"Launch time : %f Seconds", executionTime);
}

- (void)startPaddle {
    _thePaddle = [Paddle sharedInstance];
    [_thePaddle setProductId:@"534403"];
    [_thePaddle setVendorId:@"26643"];
    [_thePaddle setApiKey:@"02a3c57238af53b3c465ef895729c765"];
    [PaddleAnalyticsKit enableTracking];
}

- (void)executionTime:(NSString*)s {
    SEL sl = NSSelectorFromString(s);
    NSDate *startTime = [NSDate date];

    if ([self respondsToSelector:sl])
        [self performSelector:sl];
    
    NSDate *methodFinish = [NSDate date];
    NSTimeInterval executionTime = [methodFinish timeIntervalSinceDate:startTime];
    NSLog(@"%@ execution time : %f Seconds", s, executionTime);
}

// Loading
- (void)applicationWillFinishLaunching:(NSNotification *)aNotification {
    sourceItems = [NSArray arrayWithObjects:_sourcesURLS, _sourcesPlugins, _sourcesBundle, nil];
    discoverItems = [NSArray arrayWithObjects:_discoverChanges, _sourcesBundle, nil];

    [_sourcesPush setEnabled:true];
    [_sourcesPop setEnabled:false];
    myPreferences = [self getmyPrefs];
    
    // Make sure default sources are in place
//    NSArray *defaultRepos = @[@"https://github.com/w0lfschild/myRepo/raw/master/mytweaks",
//                              @"https://github.com/w0lfschild/myRepo/raw/master/urtweaks",
//                              @"https://github.com/w0lfschild/myRepo/raw/master/test",
//                              @"https://github.com/w0lfschild/macplugins/raw/master"];
    
    NSArray *defaultRepos = @[@"https://github.com/w0lfschild/myRepo/raw/master/myPaidRepo"];
    
    NSMutableArray *newArray = [NSMutableArray arrayWithArray:[myPreferences objectForKey:@"sources"]];
    for (NSString *item in defaultRepos)
        if (![[myPreferences objectForKey:@"sources"] containsObject:item])
            [newArray addObject:item];
    [[NSUserDefaults standardUserDefaults] setObject:newArray forKey:@"sources"];
    [myPreferences setObject:newArray forKey:@"sources"];

    [_sourcesRoot setSubviews:[[NSArray alloc] initWithObjects:_discoverChanges, nil]];
    
    [self executionTime:@"updateAdButton"];
    [self executionTime:@"tabs_sideBar"];
    [self executionTime:@"setupWindow"];
    [self executionTime:@"setupPrefstab"];
//    [self executionTime:@"helperSetup"];
    [self executionTime:@"addLoginItem"];
    [self executionTime:@"launchHelper"];
    
//    [self updateAdButton];
//    [self tabs_sideBar];
//    [self setupWindow];
//    [self setupPrefstab];
//    [self addLoginItem];
//    [self launchHelper];
    
    // Setup plugin table
    [_tblView registerForDraggedTypes:[NSArray arrayWithObject:NSFilenamesPboardType]];

    [self setupEventListener];
    [_window makeKeyAndOrderFront:self];
    
    [self executionTime:@"setupSIMBLview"];
//    [self setupSIMBLview];

    [NSTimer scheduledTimerWithTimeInterval:30.0 target:self selector:@selector(keepThoseAdsFresh) userInfo:nil repeats:YES];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
    });
    
    // Make sure we're in /Applications
    PFMoveToApplicationsFolderIfNecessary();
}

// Cleanup
- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

- (NSMutableDictionary *)getmyPrefs {
    return [[NSMutableDictionary alloc] initWithDictionary:[[NSUserDefaults standardUserDefaults] dictionaryRepresentation]];
}


// Setup sidebar
- (void)tabs_sideBar {
    NSInteger height = _viewPlugins.frame.size.height;
    
    tabViewButtons = [NSArray arrayWithObjects:_viewPlugins, _viewSources, _viewChanges, _viewSystem, _viewAccount, _viewAbout, _viewPreferences, nil];
    NSArray *topButtons = [NSArray arrayWithObjects:_viewDiscover, _viewPlugins, _viewSources, _viewChanges, _viewSystem, _viewAccount, _viewAbout, _viewPreferences, nil];
    NSUInteger yLoc = _window.frame.size.height - 44 - height;
    for (NSButton *btn in topButtons) {
        if (btn.enabled) {
            NSRect newFrame = [btn frame];
            newFrame.origin.x = 0;
            newFrame.origin.y = yLoc;
            yLoc -= (height - 1);
            [btn setFrame:newFrame];
            [btn setWantsLayer:YES];
            [btn setTarget:self];
        } else {
            btn.hidden = true;
        }
    }
    
    [_viewUpdateCounter setFrameOrigin:CGPointMake(_viewChanges.frame.origin.x + _viewChanges.frame.size.width * .6,
                                                   _viewChanges.frame.origin.y + _viewChanges.frame.size.height * .5 - _viewUpdateCounter.frame.size.height * .5)];
    
    for (NSButton *btn in tabViewButtons)
        [btn setAction:@selector(selectView:)];
    
    NSArray *bottomButtons = [NSArray arrayWithObjects:_buttonDonate, _buttonAdvert, _buttonFeedback, _buttonReport, nil];
    NSMutableArray *visibleButons = [[NSMutableArray alloc] init];
    for (NSButton *btn in bottomButtons)
        if (![btn isHidden])
            [visibleButons addObject:btn];
    bottomButtons = [visibleButons copy];
    
    height = 30;
    yLoc = ([bottomButtons count] - 1) * (height - 1);
    for (NSButton *btn in bottomButtons) {
        [btn setFont:[NSFont fontWithName:btn.font.fontName size:14]];
        NSRect newFrame = [btn frame];
        newFrame.size.height = height;
        newFrame.origin.x = 0;
        newFrame.origin.y = yLoc;
        yLoc -= (height - 1);
        [btn setFrame:newFrame];
        [btn setAutoresizingMask:NSViewMaxYMargin];
        [btn setWantsLayer:YES];
    }
}


- (void)setupWindow {
    [_window setTitle:@""];
    [_window setMovableByWindowBackground:YES];
    
    if (osx_ver > 9) {
        [_window setTitlebarAppearsTransparent:true];
        _window.styleMask |= NSWindowStyleMaskFullSizeContentView;
    }
    
    [self simbl_blacklist];
//    [self getBlacklistAPPList];
    
    // Add blurred background if NSVisualEffectView exists
    Class vibrantClass=NSClassFromString(@"NSVisualEffectView");
    if (vibrantClass) {
        NSVisualEffectView *vibrant=[[vibrantClass alloc] initWithFrame:[[_window contentView] bounds]];
        [vibrant setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
        [vibrant setBlendingMode:NSVisualEffectBlendingModeBehindWindow];
        [vibrant setState:NSVisualEffectStateActive];
        [[_window contentView] addSubview:vibrant positioned:NSWindowBelow relativeTo:nil];
    } else {
        [_window setBackgroundColor:[NSColor whiteColor]];
    }
    
    [_window.contentView setWantsLayer:YES];
    
    NSBox *vert = [[NSBox alloc] initWithFrame:CGRectMake(_viewPlugins.frame.size.width - 1, 0, 1, _window.frame.size.height)];
    [vert setBoxType:NSBoxSeparator];
    [vert setAutoresizingMask:NSViewHeightSizable];
    [_window.contentView addSubview:vert];
    
//
//    NSArray *bottomButtons = [NSArray arrayWithObjects:_buttonFeedback, _buttonDonate, _buttonReport, nil];
//
//    for (NSButton *btn in bottomButtons) {
//        [btn setWantsLayer:YES];
//        [btn.layer setBackgroundColor:[NSColor colorWithCalibratedRed:0.438f green:0.121f blue:0.199f alpha:0.258f].CGColor];
//    }
    
    tabViews = [NSArray arrayWithObjects:_tabPlugins, _tabSources, _tabUpdates, _tabSystemInfo, _tabSources, _tabAbout, _tabPreferences, nil];
    
    NSDictionary* infoDict = [[NSBundle mainBundle] infoDictionary];
    [_appVersion setStringValue:[NSString stringWithFormat:@"Version %@ (%@)",
                                 [infoDict objectForKey:@"CFBundleShortVersionString"],
                                 [infoDict objectForKey:@"CFBundleVersion"]]];
    if ([[[NSString stringWithFormat:@"%@", [infoDict objectForKey:@"CFBundleShortVersionString"]] substringToIndex:1] isEqualToString:@"0"]) {
        [_appName setStringValue:[NSString stringWithFormat:@"%@ BETA", [infoDict objectForKey:@"CFBundleExecutable"]]];
    } else {
        [_appName setStringValue:[infoDict objectForKey:@"CFBundleExecutable"]];
    }
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy"];
    NSString * currentYEAR = [formatter stringFromDate:[NSDate date]];
    [_appCopyright setStringValue:[NSString stringWithFormat:@"Copyright © 2015 - %@ Wolfgang Baird", currentYEAR]];
    [[_changeLog textStorage] setAttributedString:[[NSAttributedString alloc] initWithURL:[[NSBundle mainBundle] URLForResource:@"Changelog" withExtension:@"rtf"] options:[[NSDictionary alloc] init] documentAttributes:nil error:nil]];
    [self systemDarkModeChange:nil];
    
    // Select tab view
    if ([[myPreferences valueForKey:@"prefStartTab"] integerValue] >= 0) {
        NSInteger tab = [[myPreferences valueForKey:@"prefStartTab"] integerValue];
        [self selectView:[tabViewButtons objectAtIndex:tab]];
        [_prefStartTab selectItemAtIndex:tab];
    } else {
        [self selectView:_viewPlugins];
        [_prefStartTab selectItemAtIndex:0];
    }
}

- (void)addLoginItem {
    NSBundle *helperBUNDLE = [NSBundle bundleWithPath:[NSString stringWithFormat:@"%@/Contents/Library/LoginItems/MacPlusHelper.app", [[NSBundle mainBundle] bundlePath]]];
//    NSBundle *helperBUNDLE = [NSBundle bundleWithPath:[NSWorkspace.sharedWorkspace absolutePathForAppBundleWithIdentifier:@"com.w0lf.MacPlusHelper"]];
    [helperBUNDLE enableLoginItem];
}

- (void)launchHelper {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // Path to MacPlusHelper
        NSString *path = [NSString stringWithFormat:@"%@/Contents/Library/LoginItems/MacPlusHelper.app", [[NSBundle mainBundle] bundlePath]];

        // Launch helper if it's not open
        //    if ([NSRunningApplication runningApplicationsWithBundleIdentifier:@"com.w0lf.MacPlusHelper"].count == 0)
        //        [[NSWorkspace sharedWorkspace] launchApplication:path];

        // Always relaunch in developement
        for (NSRunningApplication *run in [NSRunningApplication runningApplicationsWithBundleIdentifier:@"com.w0lf.MacPlusHelper"])
            [run terminate];
        
        // Seems to need to run on main thread
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [Workspace launchApplication:path];
            [[NSRunningApplication currentApplication] performSelector:@selector(activateWithOptions:) withObject:[NSNumber numberWithUnsignedInteger:NSApplicationActivateIgnoringOtherApps] afterDelay:0.0];
        });
    });
}

- (void)setupPrefstab {
    NSString *plist = [NSString stringWithFormat:@"%@/Library/Preferences/net.culater.SIMBL.plist", NSHomeDirectory()];
    NSUInteger logLevel = [[[NSDictionary dictionaryWithContentsOfFile:plist] objectForKey:@"SIMBLLogLevel"] integerValue];
    [_SIMBLLogging selectItemAtIndex:logLevel];
    [_prefDonate setState:[[myPreferences objectForKey:@"prefDonate"] boolValue]];
    [_prefTips setState:[[myPreferences objectForKey:@"prefTips"] boolValue]];
    [_prefWindow setState:[[myPreferences objectForKey:@"prefWindow"] boolValue]];

    if ([[myPreferences objectForKey:@"prefWindow"] boolValue])
        [_window setFrameAutosaveName:@"MainWindow"];

    if ([[myPreferences objectForKey:@"prefTips"] boolValue]) {
        NSToolTipManager *test = [NSToolTipManager sharedToolTipManager];
        [test setInitialToolTipDelay:0.1];
    }

    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"SUAutomaticallyUpdate"]) {
        [_prefUpdateAuto selectItemAtIndex:2];
        [_updater checkForUpdatesInBackground];
    } else if ([[NSUserDefaults standardUserDefaults] boolForKey:@"SUEnableAutomaticChecks"]) {
        [_prefUpdateAuto selectItemAtIndex:1];
        [_updater checkForUpdatesInBackground];
    } else {
        [_prefUpdateAuto selectItemAtIndex:0];
    }

    [_prefUpdateInterval selectItemWithTag:[[myPreferences objectForKey:@"SUScheduledCheckInterval"] integerValue]];

    NSImage *img = [NSImage imageNamed:@"github"];
    [img setTemplate:true];
    [_gitButton setImage:img];
    
    img = [NSImage imageNamed:@"reddit"];
    [img setTemplate:true];
    [_emailButton setImage:img];
    
    img = [NSImage imageNamed:@"code"];
    [img setTemplate:true];
    [_sourceButton setImage:img];
    
    img = [NSImage imageNamed:@"tools"];
    [img setTemplate:true];
    [_xCodeButton setImage:img];
    
    [[_gitButton cell] setImageScaling:NSImageScaleProportionallyDown];
    [[_sourceButton cell] setImageScaling:NSImageScaleProportionallyDown];
    [[_emailButton cell] setImageScaling:NSImageScaleProportionallyDown];
    [[_xCodeButton cell] setImageScaling:NSImageScaleProportionallyDown];
    [[_webButton cell] setImageScaling:NSImageScaleProportionallyUpOrDown];
    
    [_sourceButton setAction:@selector(visitSource)];
    [_gitButton setAction:@selector(visitGithub)];
    [_webButton setAction:@selector(visitWebsite)];
    [_emailButton setAction:@selector(sendEmail)];
}

- (void)installXcodeTemplate {
    if ([Workspace absolutePathForAppBundleWithIdentifier:@"com.apple.dt.Xcode"].length > 0) {
        NSString *localPath = [NSBundle.mainBundle pathForResource:@"plugin_template" ofType:@"zip"];
        NSString *installPath = [FileManager URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask].firstObject.path;
        installPath = [NSString stringWithFormat:@"%@/Developer/Xcode/Templates/Project Templates/MacPlus", installPath];
        NSString *installFile = [NSString stringWithFormat:@"%@/MacPlus plugin.xctemplate", installPath];
        if (![FileManager fileExistsAtPath:installFile]) {
            // Make intermediaries
            NSError *err;
            [FileManager createDirectoryAtPath:installPath withIntermediateDirectories:true attributes:nil error:&err];
            NSLog(@"%@", err);
            
            // unzip our plugin demo project
            NSTask *task = [NSTask launchedTaskWithLaunchPath:@"/usr/bin/unzip" arguments:@[@"-o", localPath, @"-d", installPath]];
            [task waitUntilExit];
            if ([task terminationStatus] == 0) {
                // Yay
            }
        }
    }
}

- (IBAction)startCoding:(id)sender {
    // Open a test plugin for the user
    NSString *localPath = [NSBundle.mainBundle pathForResource:@"plugin_template" ofType:@"zip"];
    NSString *installPath = [NSURL fileURLWithPath:[NSHomeDirectory()stringByAppendingPathComponent:@"Desktop"]].path;
    installPath = [NSString stringWithFormat:@"%@/MacPlus_plugin_demo", installPath];
    NSString *installFile = [NSString stringWithFormat:@"%@/test.xcodeproj", installPath];
    if ([FileManager fileExistsAtPath:installFile]) {
        // Open the project if it exists
        [Workspace openFile:installFile];
    } else {
        // unzip our plugin demo project
        NSTask *task = [NSTask launchedTaskWithLaunchPath:@"/usr/bin/unzip" arguments:@[@"-o", localPath, @"-d", installPath]];
        [task waitUntilExit];
        if ([task terminationStatus] == 0) {
            // presumably the only case where we've successfully installed
            [Workspace openFile:installFile];
        }
    }
}

- (IBAction)donate:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://goo.gl/DSyEFR"]];
}

- (IBAction)report:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/w0lfschild/MacPlus/issues/new"]];
}

- (void)sendEmail {
    [self visitReddit];
//    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"mailto:aguywithlonghair@gmail.com"]];
}

- (void)visitGithub {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/w0lfschild"]];
}

- (void)visitSource {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/w0lfschild/MacPlus"]];
}

- (void)visitReddit {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://www.reddit.com/r/OSXTweaks"]];
}

- (void)visitWebsite {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://w0lfschild.github.io/app_MacPlus.html"]];
}

- (void)setupEventListener {
    watchdogs = [[NSMutableArray alloc] init];
    for (NSString *path in [PluginManager SIMBLPaths]) {
        SGDirWatchdog *watchDog = [[SGDirWatchdog alloc] initWithPath:path
                                                               update:^{
                                                                   [PluginManager.sharedInstance readPlugins:self->_tblView];
                                                               }];
        [watchDog start];
        [watchdogs addObject:watchDog];
    }
}

- (IBAction)changeAutoUpdates:(id)sender {
    int selected = (int)[(NSPopUpButton*)sender indexOfSelectedItem];
    if (selected == 0)
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:false] forKey:@"SUEnableAutomaticChecks"];
    if (selected == 1) {
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:true] forKey:@"SUEnableAutomaticChecks"];
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:false] forKey:@"SUAutomaticallyUpdate"];
    }
    if (selected == 2) {
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:true] forKey:@"SUEnableAutomaticChecks"];
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:true] forKey:@"SUAutomaticallyUpdate"];
    }
}

- (IBAction)changeUpdateFrequency:(id)sender {
    int selected = (int)[(NSPopUpButton*)sender selectedTag];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:selected] forKey:@"SUScheduledCheckInterval"];
}

- (IBAction)changeSIMBLLogging:(id)sender {
    NSString *plist = [NSString stringWithFormat:@"%@/Library/Preferences/net.culater.SIMBL.plist", NSHomeDirectory()];
    NSMutableDictionary *dict = [[NSDictionary dictionaryWithContentsOfFile:plist] mutableCopy];
    NSString *logLevel = [NSString stringWithFormat:@"%ld", [_SIMBLLogging indexOfSelectedItem]];
    [dict setObject:logLevel forKey:@"SIMBLLogLevel"];
    [dict writeToFile:plist atomically:YES];
}

- (IBAction)toggleTips:(id)sender {
    NSButton *btn = sender;
    //    [myPreferences setObject:[NSNumber numberWithBool:[btn state]] forKey:@"prefTips"];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:[btn state]] forKey:@"prefTips"];
    NSToolTipManager *test = [NSToolTipManager sharedToolTipManager];
    if ([btn state])
        [test setInitialToolTipDelay:0.1];
    else
        [test setInitialToolTipDelay:2];
}

- (IBAction)toggleSaveWindow:(id)sender {
    NSButton *btn = sender;
    //    [myPreferences setObject:[NSNumber numberWithBool:[btn state]] forKey:@"prefWindow"];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:[btn state]] forKey:@"prefWindow"];
    if ([btn state]) {
        [[_window windowController] setShouldCascadeWindows:NO];      // Tell the controller to not cascade its windows.
        [_window setFrameAutosaveName:[_window representedFilename]];
    } else {
        [_window setFrameAutosaveName:@""];
    }
}

- (IBAction)toggleDonateButton:(id)sender {
    NSButton *btn = sender;
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:[btn state]] forKey:@"prefDonate"];
    if ([btn state]) {
        [NSAnimationContext beginGrouping];
        [[NSAnimationContext currentContext] setDuration:1.0];
        [[_buttonDonate animator] setAlphaValue:0];
        [[_buttonDonate animator] setHidden:true];
        [NSAnimationContext endGrouping];
    } else {
        [NSAnimationContext beginGrouping];
        [[NSAnimationContext currentContext] setDuration:1.0];
        [[_buttonDonate animator] setAlphaValue:1];
        [[_buttonDonate animator] setHidden:false];
        [NSAnimationContext endGrouping];
    }
}

- (IBAction)inject:(id)sender {
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//        [SIMBLFramework SIMBL_injectAll];
//        [[NSSound soundNamed:@"Blow"] play];
//    });
}

- (IBAction)showAbout:(id)sender {
    [self selectView:_viewAbout];
}

- (IBAction)showPrefs:(id)sender {
    [self selectView:_viewPreferences];
}

- (IBAction)aboutInfo:(id)sender {
    if ([sender isEqualTo:_showChanges]) {
        [_changeLog setEditable:true];
        [_changeLog.textStorage setAttributedString:[[NSAttributedString alloc] initWithPath:[[NSBundle mainBundle] pathForResource:@"Changelog" ofType:@"rtf"] documentAttributes:nil]];
        [_changeLog selectAll:self];
        [_changeLog alignLeft:nil];
        [_changeLog setSelectedRange:NSMakeRange(0,0)];
        [_changeLog setEditable:false];
        
        [NSAnimationContext beginGrouping];
        NSClipView* clipView = _changeLog.enclosingScrollView.contentView;
        NSPoint newOrigin = [clipView bounds].origin;
        newOrigin.y = 0;
        [[clipView animator] setBoundsOrigin:newOrigin];
        [NSAnimationContext endGrouping];
    }
    if ([sender isEqualTo:_showCredits]) {
        [_changeLog setEditable:true];
        [_changeLog.textStorage setAttributedString:[[NSAttributedString alloc] initWithPath:[[NSBundle mainBundle] pathForResource:@"Credits" ofType:@"rtf"] documentAttributes:nil]];
        [_changeLog selectAll:self];
        [_changeLog alignCenter:nil];
        [_changeLog setSelectedRange:NSMakeRange(0,0)];
        [_changeLog setEditable:false];
    }
    if ([sender isEqualTo:_showEULA]) {
        NSMutableAttributedString *mutableAttString = [[NSMutableAttributedString alloc] init];
        for (NSString *item in [FileManager contentsOfDirectoryAtPath:NSBundle.mainBundle.resourcePath error:nil]) {
            if ([item containsString:@"LICENSE"]) {
                [mutableAttString appendAttributedString:[[NSAttributedString alloc] initWithURL:[[NSBundle mainBundle] URLForResource:item withExtension:@""] options:[[NSDictionary alloc] init] documentAttributes:nil error:nil]];
                [mutableAttString appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n---------- ---------- ---------- ---------- ----------\n\n"]];
            }
        }
        [_changeLog.textStorage setAttributedString:mutableAttString];
        [NSAnimationContext beginGrouping];
        NSClipView* clipView = _changeLog.enclosingScrollView.contentView;
        NSPoint newOrigin = [clipView bounds].origin;
        newOrigin.y = 0;
        [[clipView animator] setBoundsOrigin:newOrigin];
        [NSAnimationContext endGrouping];
    }
    
    [self systemDarkModeChange:nil];
}

- (IBAction)toggleStartTab:(id)sender {
    NSPopUpButton *btn = sender;
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:[btn indexOfSelectedItem]] forKey:@"prefStartTab"];
}

- (IBAction)segmentDiscoverTogglePush:(id)sender {
    NSInteger clickedSegment = [sender selectedSegment];
    NSArray *segements = @[_sourcesURLS, _discoverChanges];
    NSView* view = segements[clickedSegment];
    [view setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
    [view setFrameSize:_sourcesRoot.frame.size];
    isdiscoverView = clickedSegment;
    [_sourcesPush setEnabled:true];
    [_sourcesPop setEnabled:false];
    [[_sourcesRoot animator] replaceSubview:[_sourcesRoot.subviews objectAtIndex:0] with:view];
//    [_sourcesRoot.layer setBackgroundColor:NSColor.greenColor.CGColor];
}

- (IBAction)segmentNavPush:(id)sender {
    NSInteger clickedSegment = [sender selectedSegment];
    if (clickedSegment == 0) {
        [self popView:nil];
    } else {
        [self pushView:nil];
    }
}

- (void)reloadTable:(NSView *)view {
    // Get the subviews of the view
    NSArray *subviews = [view subviews];
    
    // Return if there are no subviews
    if ([subviews count] == 0) return; // COUNT CHECK LINE
    
    for (NSView *subview in subviews) {
        // Do what you want to do with the subview
        if ([subview.className isEqualToString:@"repopluginTable"]) {
            [subview performSelector:@selector(reloadData)];
            break;
        } else {
            // List the subviews of subview
            [self reloadTable:subview];
        }
    }
}

- (IBAction)pushView:(id)sender {
    NSArray *currView = sourceItems;
    if (isdiscoverView) currView = discoverItems;
    
    long cur = [currView indexOfObject:[_sourcesRoot.subviews objectAtIndex:0]];
    if ([_sourcesAllTable selectedRow] > -1) {
        [_sourcesPop setEnabled:true];

        if ((cur + 1) < [currView count]) {
            NSView *newView = [currView objectAtIndex:cur + 1];
            [newView setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
            [newView setFrameSize:_sourcesRoot.frame.size];
//            [[_sourcesRoot animator] setSubviews:@[newView]];
            [[_sourcesRoot animator] replaceSubview:[_sourcesRoot.subviews objectAtIndex:0] with:[currView objectAtIndex:cur + 1]];
            [_window makeFirstResponder: [currView objectAtIndex:cur + 1]];
        }
        
        if ((cur + 2) >= [currView count]) {
            [_sourcesPush setEnabled:false];
        } else {
            [_sourcesPush setEnabled:true];
            [self reloadTable:_sourcesRoot];
//            dumpViews(_sourcesRoot, 0);
//            if (osx_ver > 9) {
//                [[[[[[[_sourcesRoot subviews] firstObject] subviews] firstObject] subviews] firstObject] reloadData];
//            } else {
//                [[[[[[[_sourcesRoot subviews] firstObject] subviews] firstObject] subviews] lastObject] reloadData];
//            }
        }
        
        [_sourcesRoot setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
    }
}

- (IBAction)popView:(id)sender {
    NSArray *currView = sourceItems;
    if (isdiscoverView) currView = discoverItems;
    long cur = [currView indexOfObject:[_sourcesRoot.subviews objectAtIndex:0]];
    [_sourcesPush setEnabled:true];
    if ((cur - 1) <= 0)
        [_sourcesPop setEnabled:false];
    else
        [_sourcesPop setEnabled:true];
    if ((cur - 1) >= 0) {
        NSView *incoming = [currView objectAtIndex:cur - 1];
        [[_sourcesRoot animator] replaceSubview:[_sourcesRoot.subviews objectAtIndex:0] with:incoming];
        [_window makeFirstResponder:incoming];
    }
}

- (IBAction)rootView:(id)sender {
    [_sourcesPush setEnabled:true];
    [_sourcesPop setEnabled:false];
    NSView *currView = _sourcesURLS;
    if (isdiscoverView) currView = _discoverChanges;
    [[_sourcesRoot animator] replaceSubview:[_sourcesRoot.subviews objectAtIndex:0] with:currView];
}

- (IBAction)selectView:(id)sender {
    selectedView = sender;
    if ([tabViewButtons containsObject:sender]) {
        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
            NSView *v = [tabViews objectAtIndex:[tabViewButtons indexOfObject:sender]];
            dispatch_async(dispatch_get_main_queue(), ^(void){
//                [v.layer setBackgroundColor:[NSColor redColor].CGColor];
                [v setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
                [v setFrame:self->_tabMain.frame];
                [v setFrameOrigin:NSMakePoint(0, 0)];
                [v setTranslatesAutoresizingMaskIntoConstraints:true];
                [self->_tabMain setSubviews:[NSArray arrayWithObject:v]];
            });
        });
    }
    [_tabMain setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
    for (NSButton *g in tabViewButtons) {
        if (![g isEqualTo:sender])
            [[g layer] setBackgroundColor:[NSColor clearColor].CGColor];
        else
//            [[g layer] setBackgroundColor:[NSColor colorWithCalibratedRed:0.88f green:0.88f blue:0.88f alpha:0.258f].CGColor];
            [[g layer] setBackgroundColor:[NSColor colorWithCalibratedRed:0.121f green:0.4375f blue:0.1992f alpha:0.2578f].CGColor];
    }
}

- (IBAction)sourceAddorRemove:(id)sender {
    if ([[sender className] isEqualToString:@"NSMenuItem"]) {
        NSMutableArray *newSources = [[[NSUserDefaults standardUserDefaults] objectForKey:@"sources"] mutableCopy];
        NSString *str = (NSString*)[newSources objectAtIndex:[_sourcesRepoTable selectedRow]];
        [newSources removeObject:str];
        [[NSUserDefaults standardUserDefaults] setObject:newSources forKey:@"sources"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [myPreferences setObject:newSources forKey:@"sources"];
    } else {
        NSMutableArray *newArray = [NSMutableArray arrayWithArray:[myPreferences objectForKey:@"sources"]];
        NSString *input = _addsourcesTextFiled.stringValue;
        NSArray *arr = [input componentsSeparatedByString:@"\n"];
        for (NSString* item in arr) {
            if ([item length]) {
                if ([newArray containsObject:item]) {
                    [newArray removeObject:item];
                } else {
                    [newArray addObject:item];
                }
            }
        }
        
        [[NSUserDefaults standardUserDefaults] setObject:newArray forKey:@"sources"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [myPreferences setObject:newArray forKey:@"sources"];
    }
    
    [_srcWin close];
    [_sourcesAllTable reloadData];
    [_sourcesRepoTable reloadData];
}

- (IBAction)refreshSources:(id)sender {
    [_sourcesAllTable reloadData];
    [_sourcesRepoTable reloadData];
}

- (IBAction)sourceAddNew:(id)sender {
    NSRect newFrame = _window.frame;
    newFrame.origin.x += (_window.frame.size.width / 2) - (_srcWin.frame.size.width / 2);
    newFrame.origin.y += (_window.frame.size.height / 2) - (_srcWin.frame.size.height / 2);
    newFrame.size.width = _srcWin.frame.size.width;
    newFrame.size.height = _srcWin.frame.size.height;
    [_srcWin setFrame:newFrame display:true];
    [_window addChildWindow:_srcWin ordered:NSWindowAbove];
    [_srcWin makeKeyAndOrderFront:self];
}

- (CGFloat)splitView:(NSSplitView *)splitView constrainMinCoordinate:(CGFloat)proposedMinimumPosition ofSubviewAt:(NSInteger)dividerIndex {
    if (proposedMinimumPosition < 125) {
        proposedMinimumPosition = 125;
    }
    return proposedMinimumPosition;
}

- (CGFloat)splitView:(NSSplitView *)splitView constrainMaxCoordinate:(CGFloat)proposedMaximumPosition ofSubviewAt:(NSInteger)dividerIndex {
    if (proposedMaximumPosition >= 124) {
        proposedMaximumPosition = 125;
    }
    return proposedMaximumPosition;
}

- (IBAction)toggleAMFI:(id)sender {
    [MacPlusKit AMFI_toggle];
    [_AMFIStatus setState:[MacPlusKit AMFI_enabled]];
}

- (void)setupSIMBLview {
    [_SIMBLTogggle setState:[FileManager fileExistsAtPath:@"/Library/PrivilegedHelperTools/com.w0lf.MacPlus.Injector"]];
    [_SIMBLAgentToggle setState:[FileManager fileExistsAtPath:@"/Library/PrivilegedHelperTools/com.w0lf.MacPlus.Installer"]];
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        Boolean sip = [MacPlusKit SIP_enabled];
        Boolean amfi = [MacPlusKit AMFI_enabled];
        dispatch_async(dispatch_get_main_queue(), ^(void){
            [self->_SIPStatus setState:sip];
            [self->_AMFIStatus setState:amfi];
        });
    });
}

- (void)simbl_blacklist {
    NSString *plist = @"Library/Preferences/com.w0lf.MacPlusHelper.plist";
    NSMutableDictionary *SIMBLPrefs = [NSMutableDictionary dictionaryWithContentsOfFile:[NSHomeDirectory() stringByAppendingPathComponent:plist]];
    NSArray *blacklist = [SIMBLPrefs objectForKey:@"SIMBLApplicationIdentifierBlacklist"];
    NSArray *alwaysBlaklisted = @[@"org.w0lf.mySIMBL", @"org.w0lf.cDock-GUI"];
    NSMutableArray *newlist = [[NSMutableArray alloc] initWithArray:blacklist];
    for (NSString *app in alwaysBlaklisted)
        if (![blacklist containsObject:app])
            [newlist addObject:app];
    [SIMBLPrefs setObject:newlist forKey:@"SIMBLApplicationIdentifierBlacklist"];
    [SIMBLPrefs writeToFile:[NSHomeDirectory() stringByAppendingPathComponent:plist] atomically:YES];
}

- (IBAction)addorRemoveBlacklistItem:(id)sender {
    NSSegmentedControl *sc = (NSSegmentedControl*)sender;
    if (sc.selectedSegment == 0) {
        [self addBlacklistItem];
    } else {
        [self removeBlacklistItem];
    }
}

- (void)removeBlacklistItem {
    sharedPrefs = [[NSUserDefaults alloc] initWithSuiteName:@"com.w0lf.MacPlusHelper"];
    sharedDict = [sharedPrefs dictionaryRepresentation];
    NSMutableArray *newBlacklist = [[NSMutableArray alloc] initWithArray:[sharedPrefs objectForKey:@"SIMBLApplicationIdentifierBlacklist"]];
    
    NSIndexSet *selected = _blackListTable.selectedRowIndexes;
    NSUInteger idx = [selected firstIndex];
    while (idx != NSNotFound) {
        // do work with "idx"
//        NSLog (@"The current index is %lu", (unsigned long)idx);
        
        // Get row at specified index of column 0 ( We just have 1 column)
        blacklistTableCell *cellView = [_blackListTable viewAtColumn:0 row:idx makeIfNecessary:YES];
        NSString *bundleID = cellView.bundleID;
        NSLog(@"Deleting key: %@", bundleID);
        [newBlacklist removeObject:bundleID];
        
        // get the next index in the set
        idx = [selected indexGreaterThanIndex:idx];
    }
    
    [sharedPrefs setObject:[newBlacklist copy] forKey:@"SIMBLApplicationIdentifierBlacklist"];
    [sharedPrefs synchronize];
    [_blackListTable reloadData];
}

- (void)addBlacklistItem {
    NSOpenPanel* opnDlg = [NSOpenPanel openPanel];
    [opnDlg setTitle:@"Blacklist Selected Applications"];
    [opnDlg setPrompt:@"Blacklist"];
    [opnDlg setDirectoryURL:[NSURL fileURLWithPath:[NSSearchPathForDirectoriesInDomains(NSApplicationDirectory, NSLocalDomainMask, YES) firstObject]]];
    [opnDlg setAllowedFileTypes:@[@"app"]];

    [opnDlg setCanChooseFiles:true];            //Disable file selection
    [opnDlg setCanChooseDirectories: false];    //Enable folder selection
    [opnDlg setResolvesAliases: true];          //Enable alias resolving
    [opnDlg setAllowsMultipleSelection: true];  //Enable multiple selection
    
    if ([opnDlg runModal] == NSModalResponseOK) {
        // Got it, use the panel.URL field for something
        NSLog(@"MacPlus : %@", [opnDlg URL]);
        
        sharedPrefs = [[NSUserDefaults alloc] initWithSuiteName:@"com.w0lf.MacPlusHelper"];
        sharedDict = [sharedPrefs dictionaryRepresentation];
        NSMutableArray *newBlacklist = [[NSMutableArray alloc] initWithArray:[sharedPrefs objectForKey:@"SIMBLApplicationIdentifierBlacklist"]];

        NSArray *paths = opnDlg.URLs;
        for (NSURL *url in paths) {
            NSString *path = url.path;
            NSBundle *bundle = [NSBundle bundleWithPath:path];
            NSString *bundleID = [bundle bundleIdentifier];
            if (![newBlacklist containsObject:bundleID]) {
                NSLog(@"Adding key: %@", bundleID);
                [newBlacklist addObject:bundleID];
            }
        }
        
        [sharedPrefs setObject:[newBlacklist copy] forKey:@"SIMBLApplicationIdentifierBlacklist"];
        [sharedPrefs synchronize];
        [_blackListTable reloadData];

        NSError *error;
        if (error)
        NSLog(@"%@", error);
    } else {
        // Cancel was pressed...
    }
}

- (IBAction)uninstallMacPlus:(id)sender {
    [MacPlusKit MacPlus_remove];
}

- (IBAction)visit_ad:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:_adURL]];
}

- (void)keepThoseAdsFresh {
    if (_adArray != nil) {
        if (!_buttonAdvert.hidden) {
            NSInteger arraySize = _adArray.count;
            NSInteger displayNum = (NSInteger)arc4random_uniform((int)[_adArray count]);
            if (displayNum == _lastAD) {
                displayNum++;
                if (displayNum >= arraySize)
                    displayNum -= 2;
                if (displayNum < 0)
                    displayNum = 0;
            }
            _lastAD = displayNum;
            NSDictionary *dic = [_adArray objectAtIndex:displayNum];
            NSString *name = [dic objectForKey:@"name"];
            name = [NSString stringWithFormat:@"    %@", name];
            NSString *url = [dic objectForKey:@"homepage"];
            [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context){
                [context setDuration:1.25];
                [[self->_buttonAdvert animator] setTitle:name];
            } completionHandler:^{
            }];
            if (url)
                _adURL = url;
            else
                _adURL = @"https://github.com/w0lfschild/mySIMBL";
        }
    }
}

- (void)updateAdButton {
    // Local ads
    NSArray *dict = [[NSArray alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"ads" ofType:@"plist"]];
    NSInteger displayNum = (NSInteger)arc4random_uniform((int)[dict count]);
    NSDictionary *dic = [dict objectAtIndex:displayNum];
    NSString *name = [dic objectForKey:@"name"];
    name = [NSString stringWithFormat:@"    %@", name];
    NSString *url = [dic objectForKey:@"homepage"];
    
    [_buttonAdvert setTitle:name];
    if (url)
        _adURL = url;
    else
        _adURL = @"https://github.com/w0lfschild/mySIMBL";
    
    _adArray = dict;
    _lastAD = displayNum;
    
    // Check web for new ads
    dispatch_queue_t queue = dispatch_queue_create("com.yourdomain.yourappname", NULL);
    dispatch_async(queue, ^{
        //code to be executed in the background
        
        NSURL *installURL = [NSURL URLWithString:@"https://github.com/w0lfschild/app_updates/raw/master/mySIMBL/ads.plist"];
        NSURLRequest *request = [NSURLRequest requestWithURL:installURL];
        NSError *error;
        NSURLResponse *response;
        NSData *result = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        
        if (!result) {
            // Download failed
            // NSLog(@"mySIMBL : Error");
        } else {
            NSPropertyListFormat format;
            NSError *err;
            NSArray *dict = (NSArray*)[NSPropertyListSerialization propertyListWithData:result
                                                                                options:NSPropertyListMutableContainersAndLeaves
                                                                                 format:&format
                                                                                  error:&err];
            // NSLog(@"mySIMBL : %@", dict);
            if (dict) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    //code to be executed on the main thread when background task is finished
                    
                    NSInteger displayNum = (NSInteger)arc4random_uniform((int)[dict count]);
                    NSDictionary *dic = [dict objectAtIndex:displayNum];
                    NSString *name = [dic objectForKey:@"name"];
                    name = [NSString stringWithFormat:@"    %@", name];
                    NSString *url = [dic objectForKey:@"homepage"];
                    
                    [self->_buttonAdvert setTitle:name];
                    if (url)
                        self->_adURL = url;
                    else
                        self->_adURL = @"https://github.com/w0lfschild/mySIMBL";
                    
                    self->_adArray = dict;
                    self->_lastAD = displayNum;
                });
            }
        }
    });
}

- (Boolean)keypressed:(NSEvent *)theEvent {
    NSString*   const   character   =   [theEvent charactersIgnoringModifiers];
    unichar     const   code        =   [character characterAtIndex:0];
    bool                specKey     =   false;
    
    switch (code) {
        case NSLeftArrowFunctionKey: {
            [self popView:nil];
            specKey = true;
            break;
        }
        case NSRightArrowFunctionKey: {
            [self pushView:nil];
            specKey = true;
            break;
        }
        case NSCarriageReturnCharacter: {
            [self pushView:nil];
            specKey = true;
            break;
        }
    }
    
    return specKey;
}

@end
