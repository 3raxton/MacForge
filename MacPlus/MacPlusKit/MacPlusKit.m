//
//  MacPlusKit.m
//  MacPlusKit
//
//  Created by Wolfgang Baird on 7/5/18.
//  Copyright © 2018 Erwan Barrier. All rights reserved.
//

#import "STPrivilegedTask.h"
#import "MacPlusKit.h"
#import "SIMBL.h"

@implementation MacPlusKit

+ (MacPlusKit*) sharedInstance {
    static MacPlusKit* macPlus = nil;
    if (macPlus == nil)
        macPlus = [[MacPlusKit alloc] init];
    return macPlus;
}

+ (Boolean)runSTPrivilegedTask:(NSString*)launchPath :(NSArray*)args {
    STPrivilegedTask *privilegedTask = [[STPrivilegedTask alloc] init];
    NSMutableArray *components = [args mutableCopy];
    [privilegedTask setLaunchPath:launchPath];
    [privilegedTask setArguments:components];
    [privilegedTask setCurrentDirectoryPath:[[NSBundle mainBundle] resourcePath]];
    Boolean result = false;
    OSStatus err = [privilegedTask launch];
    if (err != errAuthorizationSuccess) {
        if (err == errAuthorizationCanceled) {
            NSLog(@"User cancelled");
        }  else {
            NSLog(@"Something went wrong: %d", (int)err);
        }
    } else {
        result = true;
    }
    return result;
}

+ (NSString*)runScript:(NSString*)script {
    NSPipe *pipe = [NSPipe pipe];
    NSFileHandle *file = pipe.fileHandleForReading;
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = @"/bin/sh";
    task.arguments = @[@"-c", script];
    task.standardOutput = pipe;
    [task launch];
    NSData *data = [file readDataToEndOfFile];
    [file closeFile];
    NSString *output = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
    return output;
}

+ (Boolean)SIP_enabled {
    return ([[MacPlusKit runScript:@"touch /System/test 2>&1"] rangeOfString:@"Operation not permitted"].length);
}

+ (Boolean)AMFI_enabled {
    return !([[MacPlusKit runScript:@"nvram boot-args 2>&1"] rangeOfString:@"amfi_get_out_of_my_way=1"].length);
}

+ (Boolean)AMFI_toggle {
    BOOL success = false;
    if (![MacPlusKit SIP_enabled]) {
        NSArray *args = [NSArray arrayWithObject:[[NSBundle bundleForClass:[MacPlusKit class]] pathForResource:@"amfiswitch" ofType:nil]];
        success = [MacPlusKit runSTPrivilegedTask:@"/bin/sh" :args];
    }
    return success;
}

+ (Boolean)MacPlus_remove {
    BOOL success = false;
    if (![MacPlusKit SIP_enabled]) {
        NSArray *args = [NSArray arrayWithObject:[[NSBundle bundleForClass:[MacPlusKit class]] pathForResource:@"installSIMBL" ofType:nil]];
        success = [MacPlusKit runSTPrivilegedTask:@"/bin/sh" :args];
    }
    return success;
}

+ (void)installMacPlus {
//    NSError *error;
//    if ([DKInstaller isInstalled] == NO && [DKInstaller install:&error] == NO) {
//        assert(error != nil);
//        NSLog(@"Couldn't install MachInjectSample (domain: %@ code: %@)", error.domain, [NSNumber numberWithInteger:error.code]);
//    }
}

+ (void)startWatching {
    NSNotificationCenter *notificationCenter = [[NSWorkspace sharedWorkspace] notificationCenter];
    [notificationCenter addObserverForName:NSWorkspaceDidLaunchApplicationNotification
                                    object:nil
                                     queue:nil
                                usingBlock:^(NSNotification * _Nonnull note) {
                                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.05 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                        NSRunningApplication *app = [note.userInfo valueForKey:NSWorkspaceApplicationKey];
                                        [MacPlusKit injectBundle:app];
                                    });
                                }];
}

+ (void)injectBundle:(NSRunningApplication*)runningApp {
    // Hardcoded blacklist
    if ([@[] containsObject:runningApp.bundleIdentifier]) return;
    
    // Don't inject if somehow the executable doesn't seem to exist
    if (!runningApp.executableURL.path.length) return;
    
    // If you change the log level externally, there is pretty much no way
    // to know when the changed. Just reading from the defaults doesn't validate
    // against the backing file very ofter, or so it seems.
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults synchronize];
    
    NSString* appName = runningApp.localizedName;
    SIMBLLogInfo(@"%@ started", appName);
    SIMBLLogDebug(@"app start notification: %@", runningApp);
    
    // Check to see if there are plugins to load
    if ([SIMBL shouldInstallPluginsIntoApplication:[NSBundle bundleWithURL:runningApp.bundleURL]] == NO) return;
    
    // User Blacklist
    NSString* appIdentifier = runningApp.bundleIdentifier;
    NSArray* blacklistedIdentifiers = [defaults stringArrayForKey:@"SIMBLApplicationIdentifierBlacklist"];
    if (blacklistedIdentifiers != nil && [blacklistedIdentifiers containsObject:appIdentifier]) {
        SIMBLLogNotice(@"ignoring injection attempt for blacklisted application %@ (%@)", appName, appIdentifier);
        return;
    }
    
    // Abort you're running something other than macOS 10.X.X
    if (NSProcessInfo.processInfo.operatingSystemVersion.majorVersion != 10) {
        SIMBLLogNotice(@"something fishy - OS X version %ld", NSProcessInfo.processInfo.operatingSystemVersion.majorVersion);
        return;
    }
    
    // System item Inject
    if ([[[runningApp.executableURL.path pathComponents] firstObject] isEqualToString:@"System"]) {
        SIMBLLogDebug(@"send system process inject event");
        return;
    }
    
    SIMBLLogDebug(@"send standard process inject event");
    
//    pid_t pid = [runningApp processIdentifier];
//    for (NSString *bundlePath in [SIMBL pluginsToLoadList:[NSBundle bundleWithPath:runningApp.bundleURL.path]]) {
//        NSError *error;
//        if ([DKInjectorProxy injectPID:pid :bundlePath :&error] == false) {
//            assert(error != nil);
//            NSLog(@"Couldn't inject App (domain: %@ code: %@)", error.domain, [NSNumber numberWithInteger:error.code]);
//        }
//    }
}

+ (void)injectAllProc {
    for (NSRunningApplication *app in NSWorkspace.sharedWorkspace.runningApplications)
        [MacPlusKit injectBundle:app];
}

@end
