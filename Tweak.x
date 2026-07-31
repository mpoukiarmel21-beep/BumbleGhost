#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <objc/runtime.h>
#import "OWSFloatingButton.h"
#import "OWSContainerManager.h"
#import "OWSLocationSpoofer.h"

static void sw(Class cls, SEL sel, IMP imp, IMP *old) {
    Method m = class_getInstanceMethod(cls, sel);
    if (m) { if (old) *old = method_getImplementation(m); method_setImplementation(m, imp); }
}

static id (*orig_ud_obj)(id,SEL,id);
static void (*orig_ud_setObj)(id,SEL,id,id);
static void (*orig_ud_rem)(id,SEL,id);
static BOOL (*orig_ud_bool)(id,SEL,id);
static void (*orig_ud_setBool)(id,SEL,BOOL,id);

static id hook_ud_obj(id self, SEL _cmd, NSString *key) {
    NSString *cid = [[OWSContainerManager sharedManager] currentContainerID];
    if (cid) return orig_ud_obj(self, _cmd, [NSString stringWithFormat:@"%@_%@", cid, key]);
    return orig_ud_obj(self, _cmd, key);
}
static void hook_ud_setObj(id self, SEL _cmd, id val, NSString *key) {
    NSString *cid = [[OWSContainerManager sharedManager] currentContainerID];
    if (cid) { orig_ud_setObj(self, _cmd, val, [NSString stringWithFormat:@"%@_%@", cid, key]); return; }
    orig_ud_setObj(self, _cmd, val, key);
}
static void hook_ud_rem(id self, SEL _cmd, NSString *key) {
    NSString *cid = [[OWSContainerManager sharedManager] currentContainerID];
    if (cid) { orig_ud_rem(self, _cmd, [NSString stringWithFormat:@"%@_%@", cid, key]); return; }
    orig_ud_rem(self, _cmd, key);
}
static BOOL hook_ud_bool(id self, SEL _cmd, NSString *key) {
    NSString *cid = [[OWSContainerManager sharedManager] currentContainerID];
    if (cid) return orig_ud_bool(self, _cmd, [NSString stringWithFormat:@"%@_%@", cid, key]);
    return orig_ud_bool(self, _cmd, key);
}
static void hook_ud_setBool(id self, SEL _cmd, BOOL val, NSString *key) {
    NSString *cid = [[OWSContainerManager sharedManager] currentContainerID];
    if (cid) { orig_ud_setBool(self, _cmd, val, [NSString stringWithFormat:@"%@_%@", cid, key]); return; }
    orig_ud_setBool(self, _cmd, val, key);
}

static BOOL (*orig_didLaunch)(id,SEL,UIApplication*,NSDictionary*);
static OWSFloatingButton *floatingButton;

static BOOL hook_didLaunch(id self, SEL _cmd, UIApplication *app, NSDictionary *opts) {
    BOOL r = orig_didLaunch(self, _cmd, app, opts);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3*NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        if (!floatingButton) { floatingButton = [[OWSFloatingButton alloc] init]; [floatingButton show]; }
    });
    return r;
}

static CLLocation* (*orig_location)(id,SEL);
static void (*orig_startUpdating)(id,SEL);
static void (*orig_requestLocation)(id,SEL);

static CLLocation* hook_location(id self, SEL _cmd) {
    if ([[OWSLocationSpoofer sharedInstance] isEnabled]) {
        CLLocationCoordinate2D c = [[OWSLocationSpoofer sharedInstance] currentFakeLocation];
        return [[CLLocation alloc] initWithLatitude:c.latitude longitude:c.longitude];
    }
    return orig_location(self, _cmd);
}
static void hook_startUpdating(id self, SEL _cmd) {
    orig_startUpdating(self, _cmd);
    if ([[OWSLocationSpoofer sharedInstance] isEnabled]) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5*NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            CLLocationManager *mgr = (CLLocationManager *)self;
            if ([mgr.delegate respondsToSelector:@selector(locationManager:didUpdateLocations:)]) {
                CLLocationCoordinate2D c = [[OWSLocationSpoofer sharedInstance] currentFakeLocation];
                CLLocation *loc = [[CLLocation alloc] initWithCoordinate:c altitude:0 horizontalAccuracy:5.0 verticalAccuracy:5.0 timestamp:[NSDate date]];
                [mgr.delegate locationManager:mgr didUpdateLocations:@[loc]];
            }
        });
    }
}
static void hook_requestLocation(id self, SEL _cmd) {
    if ([[OWSLocationSpoofer sharedInstance] isEnabled]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            CLLocationManager *mgr = (CLLocationManager *)self;
            if ([mgr.delegate respondsToSelector:@selector(locationManager:didUpdateLocations:)]) {
                CLLocationCoordinate2D c = [[OWSLocationSpoofer sharedInstance] currentFakeLocation];
                CLLocation *loc = [[CLLocation alloc] initWithCoordinate:c altitude:0 horizontalAccuracy:5.0 verticalAccuracy:5.0 timestamp:[NSDate date]];
                [mgr.delegate locationManager:mgr didUpdateLocations:@[loc]];
            }
        });
        return;
    }
    orig_requestLocation(self, _cmd);
}

__attribute__((constructor))
static void init(void) {
    Class nud = [NSUserDefaults class];
    sw(nud, @selector(objectForKey:), (IMP)hook_ud_obj, (IMP*)&orig_ud_obj);
    sw(nud, @selector(setObject:forKey:), (IMP)hook_ud_setObj, (IMP*)&orig_ud_setObj);
    sw(nud, @selector(removeObjectForKey:), (IMP)hook_ud_rem, (IMP*)&orig_ud_rem);
    sw(nud, @selector(boolForKey:), (IMP)hook_ud_bool, (IMP*)&orig_ud_bool);
    sw(nud, @selector(setBool:forKey:), (IMP)hook_ud_setBool, (IMP*)&orig_ud_setBool);
    sw([UIApplication class], @selector(application:didFinishLaunchingWithOptions:), (IMP)hook_didLaunch, (IMP*)&orig_didLaunch);
    Class cl = [CLLocationManager class];
    sw(cl, @selector(location), (IMP)hook_location, (IMP*)&orig_location);
    sw(cl, @selector(startUpdatingLocation), (IMP)hook_startUpdating, (IMP*)&orig_startUpdating);
    sw(cl, @selector(requestLocation), (IMP)hook_requestLocation, (IMP*)&orig_requestLocation);
    [[OWSContainerManager sharedManager] loadContainers];
    [[OWSLocationSpoofer sharedInstance] startSpoofer];
    NSLog(@"[BumbleGhost] v1.0 loaded");
}
