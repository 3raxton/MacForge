//
//  AppDelegate.m
//  MacForge
//
//  Created by Wolfgang Baird on 1/9/16.
//  Copyright © 2016 Wolfgang Baird. All rights reserved.
//

#import "AppDelegate.h"

AppDelegate             *myDelegate;
Boolean                 isdiscoverView = true;
NSDate                  *appStart;
NSMutableDictionary     *myPreferences;
NSWindow                *sipWarningWindow;

@implementation AppDelegate

NSUInteger osx_ver;
NSArray *tabViewButtons;
Boolean showBundleOnOpen;
Boolean appSetupFinished = false;

- (void)searchFieldDidEndSearching:(NSSearchField *)sender {
    [_searchPlugins abortEditing];
}

- (void)controlTextDidChange:(NSNotification *)obj{
    [(MF_featuredTab*)_tabFeatured setFilter:_searchPlugins.stringValue];
    if (_tabFeatured.superview == NULL) {
        [myDelegate selectView:_sidebarDiscover];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [(MF_featuredTab*)self.tabFeatured setFilter:self.searchPlugins.stringValue];
        });
    }
}

- (void)movePreviousPurchases {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *applicationSupportDirectory = [paths firstObject];
    
    // Probably should have some error checking
    NSString *MF_SupportDirectory = [NSString stringWithFormat:@"%@/MacForge", applicationSupportDirectory];
    NSString *PV_SupportDirectory = [NSString stringWithFormat:@"%@/purchaseValidationApp", applicationSupportDirectory];
    for (NSString *file in [FileManager contentsOfDirectoryAtPath:MF_SupportDirectory error:nil]) {
        NSString *transferedLicensePath = [NSString stringWithFormat:@"%@/%@", PV_SupportDirectory, file];
        if (![FileManager fileExistsAtPath:transferedLicensePath]) {
            NSString *ogLicensePath = [NSString stringWithFormat:@"%@/%@", MF_SupportDirectory, file];
            [FileManager copyItemAtPath:ogLicensePath toPath:transferedLicensePath error:nil];
        }
    }
}

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

// Cleanup some stuff when user changes dark mode
- (void)systemDarkModeChange:(NSNotification *)notif {
    if (osx_ver >= 14) {
        if (notif == nil) {
            // Need to fix for older versions of macos
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
    osx_ver = NSProcessInfo.processInfo.operatingSystemVersion.minorVersion;
    return self;
}

// Quit when window closed
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication {
    return YES;
}

// Handle macforge:// url scheme
- (void)application:(NSApplication *)application
           openURLs:(NSArray<NSURL *> *)urls {
//    NSLog(@"------------- %@", urls);
    NSLog(@"zzt aourls ------------- %@", [NSDate date]);
    
    // Convert urls to paths
    NSMutableArray *paths = [[NSMutableArray alloc] init];
    for (NSURL *url in urls)
        if ([FileManager fileExistsAtPath:url.path])
            [paths addObject:url.path];
    
    // If there are any paths try installing them
    if (paths.count > 0)
        [PluginManager.sharedInstance installBundles:paths];

    // Handle requests to open to specific plugin
    if ([urls.lastObject.absoluteString containsString:@"macforge://"]) {
        NSString *bundleID = urls.lastObject.absoluteString.lastPathComponent;
        [MSAnalytics trackEvent:@"macforge://" withProperties:@{@"Product ID" : bundleID}];
        MSPlugin *p = [[MSPlugin alloc] init];
        pluginData *data = pluginData.sharedInstance;
        NSString *repo = @"https://github.com/MacEnhance/MacForgeRepo/raw/master/repo";
        
        if ([data.repoPluginsDic objectForKey:bundleID]) {
            p = [data.repoPluginsDic objectForKey:bundleID];
            NSLog(@"zzt aourls ------------- data.repoPluginsDic objectForKey:t.lastPathComponent ------------- %@", p.webName);
        } else {
            [data fetch_repo:repo];
            p = [data.repoPluginsDic objectForKey:bundleID];
            
            if (!p) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [data fetch_repo:repo];
                    dispatch_async(dispatch_get_main_queue(), ^(void){
                        if ([data.repoPluginsDic objectForKey:bundleID])
                            pluginData.sharedInstance.currentPlugin = [data.repoPluginsDic objectForKey:bundleID];
                        
                        NSLog(@"zzt aourls ------------- data fetch_repo:repo ------------- %@", bundleID);
                        NSLog(@"zzt aourls ------------- data fetch_repo:repo ------------- %@", pluginData.sharedInstance.currentPlugin.bundleID);
                    });
                });
            }
        }
        
        if (appSetupFinished) {
            [myDelegate showLink:p];
        } else {
            dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
                // Wait for the app to finish launching
                while (!appSetupFinished)
                    [NSThread sleepForTimeInterval:1.0f];
                [myDelegate showLink:p];
                dispatch_async(dispatch_get_main_queue(), ^(void){
                    
                });
            });
        }
    }
}

- (void)showLink:(MSPlugin*)p {
    if (p) {
            showBundleOnOpen = true;
            [myDelegate selectView:_sidebarFeatured];
            pluginData.sharedInstance.currentPlugin = p;
            NSView *v = myDelegate.sourcesBundle;
            dispatch_async(dispatch_get_main_queue(), ^(void){
                [self setMainViewSubView:v :true];
            });
    } else {
        showBundleOnOpen = false;
    }
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
//    [MSCrashes generateTestCrash];

    [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(systemDarkModeChange:) name:@"AppleInterfaceThemeChangedNotification" object:nil];
    [[NSDistributedNotificationCenter defaultCenter] addObserverForName:@"com.w0lf.MacForgeNotify"
                                                                 object:nil
                                                                  queue:nil
                                                             usingBlock:^(NSNotification *notification)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([notification.object isEqualToString:@"prefs"]) [self showPreferences:nil];
            if ([notification.object isEqualToString:@"about"]) [self showAbout:nil];
            if ([notification.object isEqualToString:@"manage"]) [self selectView:self.sidebarManage];
            if ([notification.object isEqualToString:@"update"]) [self selectView:self.sidebarUpdates];
            if ([notification.object isEqualToString:@"check"]) { [PluginManager.sharedInstance checkforPluginUpdates:nil :self->_viewUpdateCounter]; }
        });
    }];

    // Loop looking for bundle updates
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [PluginManager.sharedInstance checkforPluginUpdates:nil :self->_viewUpdateCounter];
    });

    NSArray *args = [[NSProcessInfo processInfo] arguments];
    if (args.count > 1) {
        if ([args containsObject:@"prefs"]) [self showPreferences:nil];
        if ([args containsObject:@"about"]) [self showAbout:nil];
        if ([args containsObject:@"manage"]) [self selectView:self.sidebarManage];
        if ([args containsObject:@"update"]) [self selectView:self.sidebarUpdates];
    }

    [self installXcodeTemplate];
    appSetupFinished = true;
        
    NSDate *methodFinish = [NSDate date];
    NSTimeInterval executionTime = [methodFinish timeIntervalSinceDate:appStart];
    NSLog(@"Launch time : %f Seconds", executionTime);
}

- (void)executionTime:(NSString*)s {
    SEL sl = NSSelectorFromString(s);
    NSDate *startTime = [NSDate date];
    if ([self respondsToSelector:sl])
        ((void (*)(id, SEL))[self methodForSelector:sl])(self, sl);
    
    NSDate *methodFinish = [NSDate date];
    NSTimeInterval executionTime = [methodFinish timeIntervalSinceDate:startTime];
    NSLog(@"%f Seconds : %@", executionTime, s);
}

// Loading
- (void)applicationWillFinishLaunching:(NSNotification *)aNotification {
    // Start alanlytics and crash reporting
    [MSAppCenter start:@"ffae4e14-d61c-4078-825c-bb4635407861" withServices:@[
      [MSAnalytics class],
      [MSCrashes class]
    ]];
    
    [MSAnalytics trackEvent:@"Application Launching"];
    
    // Crash on exceptions?
    [NSUserDefaults.standardUserDefaults registerDefaults:@{@"NSApplicationCrashOnExceptions": [NSNumber numberWithBool:true]}];
    
    /* Configure Firebase */
    [FIRApp configure];
    
    /* Setup our handler for Authenthication events */
    [[FIRAuth auth] addAuthStateDidChangeListener:^(FIRAuth *_Nonnull auth, FIRUser *_Nullable user) {
        self->_user = user;
        
        [self updateUserButtonWithUser:user andAuth:auth];
        
        /* Update the Under Construction view's login/logout button */
        self->_signInOrOutButton.title = (self->_user) ? @"Sign Out" : @"Sign In";
        
        if (user)
            [self setViewSubView:self.tabAccount :self.tabAccountPurchases];
        else
            [self setViewSubView:self.tabAccount :self.tabAccountRegister];
    }];
    
    /* Get signed-in user */
    _user = [FIRAuth auth].currentUser;
    
    /* Check if there actually is someone signed-in */
    if (_user) {
        NSLog(@"Current signed-in user id: %@", _user.uid);
    } else {
        NSLog(@"No user signed-in.");
    }
    
    myPreferences = [self getmyPrefs];
    
    // Make sure default sources are in place
    NSArray *defaultRepos = @[@"https://github.com/w0lfschild/myRepo/raw/master/mytweaks",
                              @"https://github.com/w0lfschild/myRepo/raw/master/myPaidRepo",
                              @"https://github.com/w0lfschild/macplugins/raw/master"];
        
    NSMutableArray *newArray = [NSMutableArray arrayWithArray:[myPreferences objectForKey:@"sources"]];
    for (NSString *item in defaultRepos)
        if (![[myPreferences objectForKey:@"sources"] containsObject:item])
            [newArray addObject:item];
    [[NSUserDefaults standardUserDefaults] setObject:newArray forKey:@"sources"];
    [myPreferences setObject:newArray forKey:@"sources"];
    
    [self executionTime:@"tabs_sideBar"];
    [self executionTime:@"setupWindow"];
    [self executionTime:@"setupPrefstab"];
//    [self executionTime:@"addLoginItem"];
    [self executionTime:@"launchHelper"];
    [self executionTime:@"movePreviousPurchases"];
    [self toggleLoginItem:nil];
    
//    [FIRApp configure];
//    [self executionTime:@"fireBaseSetup"];
    
    // Setup plugin table
    [_tblView registerForDraggedTypes:[NSArray arrayWithObject:NSFilenamesPboardType]];
    [_blackListTable registerForDraggedTypes:[NSArray arrayWithObject:NSFilenamesPboardType]];

    [self setupEventListener];
    [self executionTime:@"setupSIMBLview"];
    
    [_window makeKeyAndOrderFront:self];
        
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    });
    
    // Make sure we're in /Applications
    PFMoveToApplicationsFolderIfNecessary();
}

// Cleanup
- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
    [MSAnalytics trackEvent:@"Application Closing"];
}

- (NSMutableDictionary *)getmyPrefs {
    return [[NSMutableDictionary alloc] initWithDictionary:[[NSUserDefaults standardUserDefaults] dictionaryRepresentation]];
}

- (IBAction)resetSidebar:(id)sender {
    [self tabs_sideBar];
}

// Setup sidebar
- (void)tabs_sideBar {
    // Establish the sidebar order
    tabViewButtons = @[_sidebarFeatured, _sidebarDiscover, _sidebarManage, _sidebarSystem, _sidebarUpdates, _sidebarAccount];
    
    // Setup top buttons
    NSInteger height = 42;
    NSArray *topButtons = @[_sidebarFeatured, _sidebarDiscover, _sidebarManage, _sidebarSystem, _sidebarUpdates];
    NSUInteger yLoc = _window.frame.size.height - 96 - height;
    for (MF_sidebarButton *sideButton in topButtons) {
        NSButton *btn = sideButton.buttonClickArea;
        if (btn.enabled) {
            sideButton.hidden = false;
            NSRect newFrame = [sideButton frame];
            newFrame.origin.x = 0;
            newFrame.origin.y = yLoc;
            newFrame.size.height = 42;
            yLoc -= height;
            [sideButton setFrame:newFrame];
            [sideButton setWantsLayer:YES];
        } else {
            sideButton.hidden = true;
        }
    }
    
    // Set target + action
    for (MF_sidebarButton *sideButton in tabViewButtons) {
        NSButton *btn = sideButton.buttonClickArea;
        [btn setTarget:self];
        [btn setAction:@selector(selectView:)];
    }
    
    NSUInteger buttonYPos = 70;
    
    // Discord Button
    if (![NSUserDefaults.standardUserDefaults boolForKey:@"prefHideDiscord"]) {
        [_sidebarDiscord setFrame:CGRectMake(0, buttonYPos, _sidebarDiscord.frame.size.width, 60)];
        [_sidebarDiscord.buttonClickArea sd_setImageWithURL:[NSURL URLWithString:@"https://discordapp.com/api/guilds/608740492561219617/widget.png?style=banner2"]];
        [_sidebarDiscord.buttonClickArea setImageScaling:NSImageScaleAxesIndependently];
        [_sidebarDiscord.buttonClickArea setAutoresizingMask:NSViewMaxYMargin];
        [_sidebarDiscord setHidden:false];
        buttonYPos += 60;
    } else {
        [_sidebarDiscord setHidden:true];
    }
    
    // Warning button
    if (![MacForgeKit SIP_HasRequiredFlags] || [MacForgeKit LIBRARYVALIDATION_enabled]) {
        [_sidebarWarning setFrame:CGRectMake(0, buttonYPos, _sidebarWarning.frame.size.width, 60)];
        [_sidebarWarning setWantsLayer:YES];
        [_sidebarWarning.layer setBackgroundColor:NSColor.systemPinkColor.CGColor];
        [_sidebarWarning.buttonClickArea setTarget:self];
        [_sidebarWarning.buttonClickArea setAction:@selector(selectView:)];
        [_sidebarWarning setHidden:false];
    } else {
        [_sidebarWarning setHidden:true];
    }
    
    // Account Button
    [_sidebarAccount setFrameOrigin:CGPointMake(0, 10)];
    _sidebarAccount.buttonClickArea.wantsLayer = YES;
    _sidebarAccount.buttonClickArea.target = self;
    _sidebarAccount.buttonClickArea.action = @selector(selectView:);
    _sidebarAccount.buttonLabel.stringValue = [CBIdentity identityWithName:NSUserName() authority:[CBIdentityAuthority defaultIdentityAuthority]].fullName;
    _sidebarAccount.buttonImage.image = [CBIdentity identityWithName:NSUserName() authority:[CBIdentityAuthority defaultIdentityAuthority]].image;
    _sidebarAccount.buttonImage.wantsLayer = YES;
    _sidebarAccount.buttonImage.layer.cornerRadius = _sidebarAccount.buttonImage.layer.frame.size.height/2;
    _sidebarAccount.buttonImage.layer.masksToBounds = YES;
    _sidebarAccount.buttonImage.animates = YES;
    
}

- (void)byeSIP {
    exit(0);
}

- (void)restartSIP {
    system("osascript -e 'tell application \"Finder\" to restart'");
}

- (void)closeSIP {
    [_window endSheet:sipWarningWindow];
}

- (void)checkSIP {
    if (![MacForgeKit SIP_HasRequiredFlags]) {
        NSString *frameworkBundleID = @"org.w0lf.MacForgeKit";
        NSBundle *frameworkBundle = [NSBundle bundleWithIdentifier:frameworkBundleID];
        MFKSipView *p = [[MFKSipView alloc] initWithNibName:@"MFKSipView" bundle:frameworkBundle];
        NSView *view = p.view;
        [p.confirmQuit setTarget:self];
        [p.confirmQuit setAction:@selector(byeSIP)];
        [p.confirmReboot setTarget:self];
        [p.confirmReboot setAction:@selector(restartSIP)];
        [p.confirm setTarget:self];
        [p.confirm setAction:@selector(closeSIP)];
        
        sipWarningWindow = [[NSWindow alloc] initWithContentRect:[view frame] styleMask:NSWindowStyleMaskTitled backing:NSBackingStoreBuffered defer:YES];
        [sipWarningWindow setContentView:view];
        [_window beginSheet:sipWarningWindow completionHandler:^(NSModalResponse returnCode) { }];
    }
}

- (void)setupWindow {
    [_window setTitle:@""];
    [_window setMovableByWindowBackground:YES];
        
    [self executionTime:@"checkSIP"];
    
    [_window setTitlebarAppearsTransparent:true];
    [_window setTitleVisibility:NSWindowTitleHidden];
    [_window setStyleMask:_window.styleMask|NSWindowStyleMaskFullSizeContentView];
    
    [self simbl_blacklist];
    
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
    
    NSBox *vert = [[NSBox alloc] initWithFrame:CGRectMake(_sidebarManage.frame.size.width - 1, 0, 1, _window.frame.size.height)];
    [vert setBoxType:NSBoxSeparator];
    [vert setAutoresizingMask:NSViewHeightSizable];
    [_window.contentView addSubview:vert];
    
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
    [_appCopyright setStringValue:[NSString stringWithFormat:@"Copyright © 2015 - %@ macEnhance", currentYEAR]];
        
    NSString *path = [[[NSBundle mainBundle] URLForResource:@"CHANGELOG" withExtension:@"md"] path];
    CMDocument *cmd = [[CMDocument alloc] initWithContentsOfFile:path options:CMDocumentOptionsNormalize];
    CMAttributedStringRenderer *asr = [[CMAttributedStringRenderer alloc] initWithDocument:cmd attributes:[[CMTextAttributes alloc] init]];
    [_changeLog.textStorage setAttributedString:asr.render];
    
    [self systemDarkModeChange:nil];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self selectView:self.sidebarFeatured];
    });
}

- (IBAction)toggleLoginItem:(NSButton*)sender {
    NSBundle *helperBUNDLE = [NSBundle bundleWithPath:[NSString stringWithFormat:@"%@/Contents/Library/LoginItems/MacForgeHelper.app", [[NSBundle mainBundle] bundlePath]]];
    if ([NSUserDefaults.standardUserDefaults boolForKey:@"prefsNoAutoLaunch"]) {
        [helperBUNDLE disableLoginItem];
    } else {
        [helperBUNDLE enableLoginItem];
    }
}

- (void)launchHelper {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // Path to MacForgeHelper
        NSString *path = [NSString stringWithFormat:@"%@/Contents/Library/LoginItems/MacForgeHelper.app", [[NSBundle mainBundle] bundlePath]];

        // Launch helper if it's not open
        //    if ([NSRunningApplication runningApplicationsWithBundleIdentifier:@"com.w0lf.MacForgeHelper"].count == 0)
        //        [[NSWorkspace sharedWorkspace] launchApplication:path];

        // Always relaunch in developement
        for (NSRunningApplication *run in [NSRunningApplication runningApplicationsWithBundleIdentifier:@"com.w0lf.MacForgeHelper"])
            [run terminate];
        
        // Seems to need to run on main thread
        dispatch_async(dispatch_get_main_queue(), ^(void){
            [Workspace launchApplication:path];
            [[NSRunningApplication currentApplication] performSelector:@selector(activateWithOptions:) withObject:[NSNumber numberWithUnsignedInteger:NSApplicationActivateIgnoringOtherApps] afterDelay:0.0];
        });
    });
}

- (void)setupPrefstab {
    
    // Set defaults
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:true] forKey:@"SUAutomaticallyUpdate"];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:84000] forKey:@"SUScheduledCheckInterval"];
    
    if ([[myPreferences objectForKey:@"prefTips"] boolValue]) {
        NSToolTipManager *test = [NSToolTipManager sharedToolTipManager];
        [test setInitialToolTipDelay:0.1];
    }

    [[_webButton cell] setImageScaling:NSImageScaleProportionallyUpOrDown];
    [_webButton setAction:@selector(visitWebsite:)];
}

- (void)installXcodeTemplate {
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        if ([Workspace absolutePathForAppBundleWithIdentifier:@"com.apple.dt.Xcode"].length > 0) {
            NSString *localPath = [NSBundle.mainBundle pathForResource:@"plugin_template" ofType:@"zip"];
            NSString *installPath = [FileManager URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask].firstObject.path;
            installPath = [NSString stringWithFormat:@"%@/Developer/Xcode/Templates/Project Templates/MacForge", installPath];
            NSString *installFile = [NSString stringWithFormat:@"%@/MacForge plugin.xctemplate", installPath];
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
        dispatch_async(dispatch_get_main_queue(), ^(void){
        });
    });
}

- (IBAction)startCoding:(id)sender {
    // Open a test plugin for the user
    NSString *localPath = [NSBundle.mainBundle pathForResource:@"demo_xcode" ofType:@"zip"];
    NSString *installPath = [NSURL fileURLWithPath:[NSHomeDirectory()stringByAppendingPathComponent:@"Desktop"]].path;
    installPath = [NSString stringWithFormat:@"%@/MacForge_plugin_demo", installPath];
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

- (IBAction)visitWebsite:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://discord.gg/zjCHuew"]];
}

- (IBAction)visitDiscord:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://discord.gg/zjCHuew"]];
}

- (void)setupEventListener {
    watchdogs = [[NSMutableArray alloc] init];
    for (NSString *path in [PluginManager MacEnhancePluginPaths]) {
        SGDirWatchdog *watchDog = [[SGDirWatchdog alloc] initWithPath:path
                                                               update:^{
                                                                   [PluginManager.sharedInstance readPlugins:self->_tblView];
                                                               }];
        [watchDog start];
        [watchdogs addObject:watchDog];
    }
}

- (IBAction)toggleTips:(id)sender {
    NSToolTipManager *test = [NSToolTipManager sharedToolTipManager];
    if ([(NSButton*)sender state])
        [test setInitialToolTipDelay:0.1];
    else
        [test setInitialToolTipDelay:2];
}

- (IBAction)toggleHideMenubar:(id)sender {
    NSString *message = @"showMenu";
    if (![(NSButton*)sender state]) message = @"hideMenu";
    [[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"com.macenhance.MacForgeHelperNotify" object:message];
}

- (void)setupSIMBLview {
    [_SIMBLTogggle setState:[FileManager fileExistsAtPath:@"/Library/PrivilegedHelperTools/com.w0lf.MacForge.Injector"]];
    [_SIMBLAgentToggle setState:[FileManager fileExistsAtPath:@"/Library/PrivilegedHelperTools/com.w0lf.MacForge.Installer"]];
        
    Boolean sipEnabled = [MacForgeKit SIP_enabled];
    Boolean sipHasFlags = [MacForgeKit SIP_HasRequiredFlags];
    Boolean amfiEnabled = [MacForgeKit AMFI_enabled];
    Boolean LVEnabled = [MacForgeKit LIBRARYVALIDATION_enabled];
    
    [_SIP_TaskPID setState:![MacForgeKit SIP_TASK_FOR_PID]];
    [_SIP_filesystem setState:![MacForgeKit SIP_Filesystem]];
    
    if (!sipEnabled) [_SIP_status setStringValue:@"Disabled"];
    if (!amfiEnabled) [_AMFI_status setStringValue:@"Disabled"];
    if (!LVEnabled) [_LV_status setStringValue:@"Disabled"];
    if (sipEnabled && sipHasFlags) [_SIP_status setStringValue:@"Enabled (Custom)"];
    
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        [MacForgeKit AMFI_NUKE];
    });
}

- (void)simbl_blacklist {
    NSString *plist = @"Library/Preferences/com.w0lf.MacForgeHelper.plist";
    NSMutableDictionary *SIMBLPrefs = [NSMutableDictionary dictionaryWithContentsOfFile:[NSHomeDirectory() stringByAppendingPathComponent:plist]];
    NSArray *blacklist = [SIMBLPrefs objectForKey:@"SIMBLApplicationIdentifierBlacklist"];
    NSArray *alwaysBlaklisted = @[@"org.w0lf.mySIMBL", @"org.w0lf.cDock-GUI",
                                  @"com.w0lf.MacForge", @"com.w0lf.MacForgeHelper",
                                  @"org.w0lf.cDockHelper", @"com.macenhance.purchaseValidationApp"];
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
    NSMutableArray *bundleIDs = [[NSMutableArray alloc] init];
    NSIndexSet *selected = _blackListTable.selectedRowIndexes;
    NSUInteger idx = [selected firstIndex];
    while (idx != NSNotFound) {
        // do work with "idx"
//        NSLog (@"The current index is %lu", (unsigned long)idx);

        // Get row at specified index of column 0 ( We just have 1 column)
        blacklistTableCell *cellView = [_blackListTable viewAtColumn:0 row:idx makeIfNecessary:YES];
        NSString *bundleID = cellView.bundleID;
        NSLog(@"Deleting key: %@", bundleID);
        [bundleIDs addObject:bundleID];

        // get the next index in the set
        idx = [selected indexGreaterThanIndex:idx];
    }
    [MF_BlacklistManager removeBlacklistItems:bundleIDs.copy];
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
        NSLog(@"MacForge : %@", [opnDlg URLs]);
        [MF_BlacklistManager addBlacklistItems:opnDlg.URLs];
        [_blackListTable reloadData];
    } else {
        // Cancel was pressed...
    }
}

- (IBAction)uninstallMacForge:(id)sender {
    [MacForgeKit MacEnhance_remove];
}

- (IBAction)storeSelectView:(id)sender {
    NSMenuItem *item = (NSMenuItem*)sender;
    NSMenu *m = item.menu;
    NSUInteger position = [m indexOfItem:item];
    if (position > 1) position -= 2;
    NSArray *items = @[_sidebarFeatured, _sidebarDiscover, _sidebarManage, _sidebarSystem, _sidebarUpdates, _sidebarAccount];
    if (position == 9) position = 5;
    [self selectView:items[position]];
}

- (IBAction)selectView:(id)sender {
    MF_sidebarButton *buttonContainer = nil;
    
    NSButton *button = (NSButton*)sender;
    if (button.superview.class == MF_sidebarButton.class) {
        buttonContainer = (MF_sidebarButton*)button.superview;
    } else if ([sender class] == MF_sidebarButton.class) {
        buttonContainer = (MF_sidebarButton*)sender;
        button = buttonContainer.buttonClickArea;
    }
           
    // Select the view
    if (buttonContainer) {
        // Log that the user clicked on a sidebar button
        NSString *analyticsTitle = [button title];
        if ([buttonContainer isEqualTo:_sidebarAccount]) analyticsTitle = @"👨‍💻 Account";
        [MSAnalytics trackEvent:@"Selected View" withProperties:@{@"View" : analyticsTitle}];
        
        // Set if the view is a scrolling view
        Boolean viewScrolls = false;
        if ([buttonContainer isEqualTo:self.sidebarFeatured] || [buttonContainer isEqualTo:self.sidebarDiscover])
            viewScrolls = true;
            
        // Special stuff for web views
        if ([buttonContainer isEqualTo:self.sidebarFeatured]) [(MF_featuredTab*)self.tabFeatured showFeatured];
        if ([buttonContainer isEqualTo:self.sidebarDiscover]) [(MF_featuredTab*)self.tabFeatured setFilter:@""];
        
        // Add the view to our main view
        [self setMainViewSubView:buttonContainer.linkedView :viewScrolls];
    }
    
    // Adjust text and background color
    [_tabMain setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
    NSString *osxMode = [[NSUserDefaults standardUserDefaults] stringForKey:@"AppleInterfaceStyle"];
    NSColor *primary = NSColor.darkGrayColor;
    NSColor *secondary = NSColor.blackColor;
    NSColor *highlight = NSColor.blackColor;
    if (osx_ver >= 14) {
        if ([osxMode isEqualToString:@"Dark"]) {
            primary = NSColor.lightGrayColor;
            secondary = NSColor.whiteColor;
            highlight = NSColor.whiteColor;
        }
    }

    for (MF_sidebarButton *sidebarButton in tabViewButtons) {
        NSTextField *g = sidebarButton.buttonLabel;
        NSMutableAttributedString *colorTitle = [[NSMutableAttributedString alloc] initWithString:g.stringValue];
        if (![sidebarButton isEqualTo:buttonContainer]) {
            [[sidebarButton layer] setBackgroundColor:[NSColor clearColor].CGColor];
            [colorTitle addAttribute:NSForegroundColorAttributeName value:primary range:NSMakeRange(0, g.attributedStringValue.length)];
            [g setAttributedStringValue:colorTitle];
        } else {
            [[sidebarButton layer] setBackgroundColor:[highlight colorWithAlphaComponent:.25].CGColor];
            [colorTitle addAttribute:NSForegroundColorAttributeName value:secondary range:NSMakeRange(0, g.attributedStringValue.length)];
            [g setAttributedStringValue:colorTitle];
        }
    }
}

- (IBAction)selectAboutInfo:(id)sender {
    NSUInteger selected = [(NSSegmentedControl*)sender selectedSegment];
    
    if (selected == 0) {
        NSString *path = [[[NSBundle mainBundle] URLForResource:@"CHANGELOG" withExtension:@"md"] path];
        CMDocument *cmd = [[CMDocument alloc] initWithContentsOfFile:path options:CMDocumentOptionsNormalize];
        CMAttributedStringRenderer *asr = [[CMAttributedStringRenderer alloc] initWithDocument:cmd attributes:[[CMTextAttributes alloc] init]];
        [_changeLog.textStorage setAttributedString:asr.render];
    }
    if (selected == 1) {
        NSString *path = [[[NSBundle mainBundle] URLForResource:@"CREDITS" withExtension:@"md"] path];
        CMDocument *cmd = [[CMDocument alloc] initWithContentsOfFile:path options:CMDocumentOptionsNormalize];
        CMAttributedStringRenderer *asr = [[CMAttributedStringRenderer alloc] initWithDocument:cmd attributes:[[CMTextAttributes alloc] init]];
        [_changeLog.textStorage setAttributedString:asr.render];
    }
    if (selected == 2) {
        NSMutableAttributedString *mutableAttString = [[NSMutableAttributedString alloc] init];
        for (NSString *item in [FileManager contentsOfDirectoryAtPath:NSBundle.mainBundle.resourcePath error:nil]) {
            if ([item containsString:@"LICENSE"]) {
                
                NSString *unicodeStr = @"\n\u00a0\t\t\n\n";
                NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithString:unicodeStr];
                NSRange strRange = NSMakeRange(0, str.length);

                NSMutableParagraphStyle *const tabStyle = [[NSMutableParagraphStyle alloc] init];
                tabStyle.headIndent = 16; //padding on left and right edges
                tabStyle.firstLineHeadIndent = 16;
                tabStyle.tailIndent = -70;
                NSTextTab *listTab = [[NSTextTab alloc] initWithTextAlignment:NSTextAlignmentCenter location:_changeLog.frame.size.width - tabStyle.headIndent + tabStyle.tailIndent options:@{}]; //this is how long I want the line to be
                tabStyle.tabStops = @[listTab];
                [str  addAttribute:NSParagraphStyleAttributeName value:tabStyle range:strRange];
                [str addAttribute:NSStrikethroughStyleAttributeName value:[NSNumber numberWithInt:2] range:strRange];
                
                [mutableAttString appendAttributedString:[[NSAttributedString alloc] initWithURL:[[NSBundle mainBundle] URLForResource:item withExtension:@""] options:[[NSDictionary alloc] init] documentAttributes:nil error:nil]];
                [mutableAttString appendAttributedString:str];
            }
        }
        [_changeLog.textStorage setAttributedString:mutableAttString];
    }
    if (selected == 3) {
        NSString *path = [[[NSBundle mainBundle] URLForResource:@"README" withExtension:@"md"] path];
        CMDocument *cmd = [[CMDocument alloc] initWithContentsOfFile:path options:CMDocumentOptionsNormalize];
        CMAttributedStringRenderer *asr = [[CMAttributedStringRenderer alloc] initWithDocument:cmd attributes:[[CMTextAttributes alloc] init]];
        [_changeLog.textStorage setAttributedString:asr.render];
    }
    
    [NSAnimationContext beginGrouping];
    NSClipView* clipView = _changeLog.enclosingScrollView.contentView;
    NSPoint newOrigin = [clipView bounds].origin;
    newOrigin.y = 0;
    [[clipView animator] setBoundsOrigin:newOrigin];
    [NSAnimationContext endGrouping];
    
    [self systemDarkModeChange:nil];
}

- (IBAction)showAbout:(id)sender {
    [_preferencesTabController setSelectedSegment:_preferencesTabController.segmentCount - 1];
    [self selectPreference:_preferencesTabController];
}

- (IBAction)showPreferences:(id)sender {
    [self selectPreference:_preferencesTabController];
}

- (IBAction)selectPreference:(id)sender {
    NSArray *preferenceViews = @[_preferencesGeneral, _preferencesBundles, _preferencesData, _preferencesAbout];
    NSView *selectedPane = [preferenceViews objectAtIndex:[(NSSegmentedControl*)sender selectedSegment]];
    [_windowPreferences setIsVisible:true];
    [_windowPreferences.contentView setSubviews:@[selectedPane]];
    Class vibrantClass=NSClassFromString(@"NSVisualEffectView");
    if (vibrantClass) {
        NSVisualEffectView *vibrant=[[vibrantClass alloc] initWithFrame:[[_windowPreferences contentView] bounds]];
        [vibrant setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
        [vibrant setBlendingMode:NSVisualEffectBlendingModeBehindWindow];
        [vibrant setState:NSVisualEffectStateActive];
        [[_windowPreferences contentView] addSubview:vibrant positioned:NSWindowBelow relativeTo:nil];
    }
    CGRect newFrame = _windowPreferences.frame;
    CGFloat contentHeight = [_windowPreferences contentRectForFrameRect: _windowPreferences.frame].size.height;
    CGFloat titleHeight = _windowPreferences.frame.size.height - contentHeight;
    newFrame.size.height = selectedPane.frame.size.height + titleHeight;
    newFrame.size.width = selectedPane.frame.size.width;
    CGFloat yDiff = _windowPreferences.frame.size.height - newFrame.size.height;
    newFrame.origin.y += yDiff;
    [_windowPreferences setFrame:newFrame display:true animate:true];
    _windowPreferences.styleMask &= ~NSWindowStyleMaskResizable;
    [NSApp activateIgnoringOtherApps:true];
}

// -------------------
// USER AUTHENTICATION
// -------------------

- (void)setMainViewSubView:(NSView*)subview :(BOOL)scrolls {
    MFFlippedView *documentView = [[MFFlippedView alloc] initWithFrame:NSMakeRect(0, 0, _mainViewHolder.frame.size.width, subview.frame.size.height)];
    _mainViewHolder.documentView = documentView;
    
    [subview setFrameOrigin:CGPointZero];
    
    if (scrolls) {
        [subview setAutoresizingMask:NSViewWidthSizable];
        [subview setFrameSize:CGSizeMake(_mainViewHolder.frame.size.width, subview.frame.size.height)];
        [documentView setAutoresizingMask:NSViewWidthSizable];
    } else {
        [subview setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
        [subview setFrameSize:CGSizeMake(_mainViewHolder.frame.size.width, _mainViewHolder.frame.size.height - 2)];
        [documentView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
        [documentView setFrameSize:CGSizeMake(_mainViewHolder.frame.size.width, _mainViewHolder.frame.size.height - 2)];
    }
    
    [documentView setSubviews:@[subview]];
    [_mainViewHolder scrollPoint:CGPointZero];
}

- (void)setViewSubView:(NSView*)container :(NSView*)subview {
    [subview setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
    [subview setFrameSize:CGSizeMake(container.frame.size.width, container.frame.size.height)];
    [container setSubviews:@[subview]];
}

- (void)setViewSubViewWithAnimation:(NSView*)container :(NSView*)subview {
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context){
        [context setDuration:0.1];
        [[container.subviews.firstObject animator] setFrameOrigin:NSMakePoint(0, container.frame.size.height)];
    } completionHandler:^{
        [self setViewSubView:container :subview];
        [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context){
            [context setDuration:0.2];
            NSPoint startPoint = NSMakePoint(0, subview.frame.size.height);
            [subview setFrameOrigin:startPoint];
            [[subview animator] setFrameOrigin:NSMakePoint(0, 0)];
        } completionHandler:^{
        }];
    }];
}

- (IBAction)showPurchases:(id)sender {
    [self setViewSubView:self.tabAccount :self.tabAccountPurchases];
}

- (IBAction)showUser:(id)sender {
    [self setViewSubView:self.tabAccount :self.tabAccountManage];
}

- (IBAction)signUpUser:(id)sender {
    NSString *username  = _loginUsername.stringValue;
    NSString *email     = _email.stringValue;
    NSString *password  = _password.stringValue;
    NSURL *photoURL     = [NSURL URLWithString:_loginImageURL.stringValue];
    
    MF_accountManager *accountManager = [[MF_accountManager alloc] init];
    
    /* Try to create a new account */
    [accountManager createAccountWithUsername:username
                                        email:email
                                     password:password
                                  andPhotoURL:photoURL
                        withCompletionHandler:^(FIRAuthDataResult * _Nullable authResult, NSError * _Nullable err) {
        if (!err) {
            NSLog(@"Successfully created user!");
            
            dispatch_async(dispatch_get_main_queue(), ^{
                self->_loginUID.stringValue = authResult.user.uid;
            });
        }
        else {
            NSLog(@"%@", err);
        }
    }];
}

- (IBAction)updateUser:(id)sender {
    NSString *username = _loginUsername.stringValue;
    NSURL *photoURL = [NSURL URLWithString:_loginImageURL.stringValue];
    
    MF_accountManager *accountManager = [[MF_accountManager alloc] init];
    
    /* Try to update account */
    [accountManager updateAccountWithUsername:username andPhotoURL:photoURL withCompletionHandler:^(FIRAuthDataResult * _Nullable authResult, NSError * _Nullable err) {
        if (!err) {
            [self updateUserButtonWithUser:self->_user andAuth:nil];
            NSLog(@"Successfully signed-in!");
        } else {
            NSLog(@"%@", err);
        }
    }];
}

- (IBAction)signInUser:(id)sender {
    NSString *email = _email.stringValue;
    NSString *password = _password.stringValue;
    
    MF_accountManager *accountManager = [[MF_accountManager alloc] init];
    
    /* Try to log into an account */
    [accountManager loginAccountWithEmail:email
                              andPassword:password
                    withCompletionHandler:^(FIRAuthDataResult * _Nullable authResult, NSError * _Nullable err) {
        if (!err) {
            NSLog(@"Successfully signed-in!");
            
            [self selectView:self.sidebarAccount];
        }
        else {
            NSLog(@"%@", err);
        }
    }];
}

- (IBAction)signOutUSer:(id)sender {
    NSError *signOutError;
    
    NSLog(@"Signing-out user: %@", [FIRAuth auth].currentUser.uid);
    
    BOOL status = [[FIRAuth auth] signOut:&signOutError];
    
    if (!status) {
        NSLog(@"Error signing out: %@", signOutError);
        return;
    }
    
    NSLog(@"Successfully signed-out.");
    
    /* show sign-in form */
    [self selectView:_tabAccountRegister];
}

- (IBAction)signInOrOut:(id)sender {
    if (_user)
        [self signOutUSer:sender];
    else
        [self selectView:_tabAccountRegister];
}

- (IBAction)openRegisterForm:(id)sender {
    [self selectView:_tabAccountRegister];
}

- (IBAction)setPhotoURL:(id)sender {
    NSOpenPanel *op = [NSOpenPanel openPanel];
    
    op.allowsMultipleSelection = NO;
    op.allowedFileTypes = @[@"jpg", @"png", @"tiff"];
    [op runModal];
    
    _loginImageURL.stringValue = op.URL.absoluteString;
}

// Updates title and photo of user on sidebar upon FIRAuth event
- (void)updateUserButtonWithUser:(FIRUser *)user andAuth:(FIRAuth *)auth {
    NSLog(@"Auth-event for user: %@", user.displayName);
    
    /* check if a user is signed-in */
    if (_user) {
        NSURL *photoURL = _user.photoURL;
        NSString *displayName = _user.displayName;

        if (displayName.length > 0) {
            _sidebarAccount.buttonLabel.stringValue = displayName;
            _loginUsername.stringValue = displayName;
        } else {
            _sidebarAccount.buttonLabel.stringValue = [CBIdentity identityWithName:NSUserName() authority:[CBIdentityAuthority defaultIdentityAuthority]].fullName;
            _loginUsername.stringValue = @"";
        }

        if (photoURL.absoluteString.length > 0) {
            _sidebarAccount.buttonImage.image = [NSImage sd_imageWithData:[NSData dataWithContentsOfURL:photoURL]];
            _loginImageURL.stringValue = photoURL.absoluteString;
        } else {
            _sidebarAccount.buttonImage.image = [CBIdentity identityWithName:NSUserName() authority:[CBIdentityAuthority defaultIdentityAuthority]].image;
            _loginImageURL.stringValue = @"";
        }
        
        _loginEmail.stringValue = _user.email;
        _loginUID.stringValue = _user.uid;
//        _user.emailVerified
//        _user.providerID
        
        _sidebarAccount.buttonImage.layer.backgroundColor = NSColor.clearColor.CGColor;
    }
    /* no user signed-in; going with OS user */
    else {
        _sidebarAccount.buttonImage.image = [NSImage imageNamed:NSImageNameUserGroup];
        _sidebarAccount.buttonImage.layer.backgroundColor = NSColor.grayColor.CGColor;
        _sidebarAccount.buttonLabel.stringValue = @"Create Account";
    }
}

@end
