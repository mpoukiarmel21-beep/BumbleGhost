#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <objc/runtime.h>
#import "OWSFloatingButton.h"
#import "OWSContainerManager.h"
#import "OWSLocationSpoofer.h"
#import "OWSDeviceSpoofer.h"

static void sw(Class cls, SEL sel, IMP imp, IMP *old) {
    Method m = class_getInstanceMethod(cls, sel);
    if (m) {
        if (old) *old = method_getImplementation(m);
        method_setImplementation(m, imp);
    }
}

// ── Thread-local reentrancy guard for NSUserDefaults hooks ──────────
static __thread BOOL owsDefaultsInHook = NO;

static BOOL owsDefaultsReentrant(void) {
    if (owsDefaultsInHook) return YES;
    owsDefaultsInHook = YES;
    return NO;
}
static void owsDefaultsReset(void) {
    owsDefaultsInHook = NO;
}

// ── UIDevice hooks ────────────────────────────────────────────────
static NSString* (*orig_name)(id,SEL);
static NSString* (*orig_model)(id,SEL);
static NSString* (*orig_version)(id,SEL);
static NSUUID* (*orig_idfv)(id,SEL);

static NSString* hook_name(id s,SEL _c) {
    @try {
        NSString *v = [[OWSDeviceSpoofer sharedInstance] deviceName];
        return v ? v : orig_name(s,_c);
    } @catch (NSException *e) {
        return orig_name(s,_c);
    }
}
static NSString* hook_model(id s,SEL _c) {
    @try {
        NSString *v = [[OWSDeviceSpoofer sharedInstance] deviceModel];
        return v ? v : orig_model(s,_c);
    } @catch (NSException *e) {
        return orig_model(s,_c);
    }
}
static NSString* hook_version(id s,SEL _c) {
    @try {
        NSString *v = [[OWSDeviceSpoofer sharedInstance] deviceVersion];
        return v ? v : orig_version(s,_c);
    } @catch (NSException *e) {
        return orig_version(s,_c);
    }
}
static NSUUID* hook_idfv(id s,SEL _c) {
    @try {
        NSUUID *v = [[OWSDeviceSpoofer sharedInstance] deviceIDFV];
        return v ? v : orig_idfv(s,_c);
    } @catch (NSException *e) {
        return orig_idfv(s,_c);
    }
}

// ── NSUserDefaults hooks (container isolation) ─────────────────────
static id(*o0)(id,SEL,id);
static BOOL(*o1)(id,SEL,id);
static void(*o2)(id,SEL,id,id);
static void(*o3)(id,SEL,BOOL,id);
static void(*o4)(id,SEL,id);

static NSString* owsPrefixKey(NSString *key) {
    @try {
        if (![key isKindOfClass:[NSString class]]) return nil;
        if ([key hasPrefix:@"OWS"]) return nil;
        NSString *cID = [[OWSContainerManager sharedManager] currentContainerID];
        if (!cID) return nil;
        return [NSString stringWithFormat:@"%@_%@", cID, key];
    } @catch (NSException *e) {
        return nil;
    }
}

static id h0(id s,SEL _c,NSString*k) {
    if (owsDefaultsReentrant()) return o0(s,_c,k);
    @try {
        NSString *pk = owsPrefixKey(k);
        return pk ? o0(s,_c,pk) : o0(s,_c,k);
    } @catch (NSException *e) {
        return o0(s,_c,k);
    } @finally {
        owsDefaultsReset();
    }
}
static BOOL h1(id s,SEL _c,NSString*k) {
    if (owsDefaultsReentrant()) return o1(s,_c,k);
    @try {
        NSString *pk = owsPrefixKey(k);
        return pk ? o1(s,_c,pk) : o1(s,_c,k);
    } @catch (NSException *e) {
        return o1(s,_c,k);
    } @finally {
        owsDefaultsReset();
    }
}
static void h2(id s,SEL _c,id v,NSString*k) {
    if (owsDefaultsReentrant()) { o2(s,_c,v,k); return; }
    @try {
        NSString *pk = owsPrefixKey(k);
        if (pk) { o2(s,_c,v,pk); return; }
        o2(s,_c,v,k);
    } @catch (NSException *e) {
        o2(s,_c,v,k);
    } @finally {
        owsDefaultsReset();
    }
}
static void h3(id s,SEL _c,BOOL b,NSString*k) {
    if (owsDefaultsReentrant()) { o3(s,_c,b,k); return; }
    @try {
        NSString *pk = owsPrefixKey(k);
        if (pk) { o3(s,_c,b,pk); return; }
        o3(s,_c,b,k);
    } @catch (NSException *e) {
        o3(s,_c,b,k);
    } @finally {
        owsDefaultsReset();
    }
}
static void h4(id s,SEL _c,NSString*k) {
    if (owsDefaultsReentrant()) { o4(s,_c,k); return; }
    @try {
        NSString *pk = owsPrefixKey(k);
        if (pk) { o4(s,_c,pk); return; }
        o4(s,_c,k);
    } @catch (NSException *e) {
        o4(s,_c,k);
    } @finally {
        owsDefaultsReset();
    }
}

// ── Ghost button ───────────────────────────────────────────────────
static OWSFloatingButton *fb;

// ── Constructor ────────────────────────────────────────────────────
__attribute__((constructor))
static void init(void) {
    @try {
        NSLog(@"[BumbleGhost] v3.2 loaded");

        // 1. Initialize managers FIRST, before hooks, to avoid
        //    dispatch_once reentrancy deadlocks with NSUserDefaults.
        [OWSContainerManager sharedManager];
        [OWSDeviceSpoofer sharedInstance];
        [OWSLocationSpoofer sharedInstance];
        sw([UIDevice class], @selector(name), (IMP)hook_name, (IMP*)&orig_name);
        sw([UIDevice class], @selector(model), (IMP)hook_model, (IMP*)&orig_model);
        sw([UIDevice class], @selector(systemVersion), (IMP)hook_version, (IMP*)&orig_version);
        sw([UIDevice class], @selector(identifierForVendor), (IMP)hook_idfv, (IMP*)&orig_idfv);

        sw([NSUserDefaults class], @selector(objectForKey:), (IMP)h0, (IMP*)&o0);
        sw([NSUserDefaults class], @selector(boolForKey:), (IMP)h1, (IMP*)&o1);
        sw([NSUserDefaults class], @selector(setObject:forKey:), (IMP)h2, (IMP*)&o2);
        sw([NSUserDefaults class], @selector(setBool:forKey:), (IMP)h3, (IMP*)&o3);
        sw([NSUserDefaults class], @selector(removeObjectForKey:), (IMP)h4, (IMP*)&o4);

        // 3. Activate location spoofer (hooks CLLocationManager internally)
        [[OWSLocationSpoofer sharedInstance] startSpoofer];

        // 4. Show the floating button once the app is up
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 6 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            @try {
                if (!fb) {
                    fb = [[OWSFloatingButton alloc] init];
                    [fb show];
                }
                // Re-apply current container & city override now that hooks are active
                [[OWSContainerManager sharedManager] loadContainers];
                [[OWSLocationSpoofer sharedInstance] startSpoofer];
            } @catch (NSException *e) {
                NSLog(@"[BumbleGhost] Post-launch init failed (safe): %@", e);
            }
        });

        NSLog(@"[BumbleGhost] v3.2 ready");
    } @catch (NSException *e) {
        NSLog(@"[BumbleGhost] Constructor error (app continues without tweak): %@", e);
    }
}
