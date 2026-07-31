#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <objc/runtime.h>
#import "OWSContainerManager.h"
#import "OWSLocationSpoofer.h"
#import "OWSDeviceSpoofer.h"

static OWSFloatingButton *fb = nil;

%hook UIDevice
- (NSString*)name { return [[OWSDeviceSpoofer sharedInstance] deviceName] ?: %orig; }
- (NSString*)model { return [[OWSDeviceSpoofer sharedInstance] deviceModel] ?: %orig; }
- (NSString*)systemVersion { return [[OWSDeviceSpoofer sharedInstance] deviceVersion] ?: %orig; }
- (NSUUID*)identifierForVendor { return [[OWSDeviceSpoofer sharedInstance] deviceIDFV] ?: %orig; }
%end

%hook NSUserDefaults
- (id)objectForKey:(NSString*)key {
    NSString *cID = [[OWSContainerManager sharedManager] currentContainerID];
    NSString *k = cID ? [NSString stringWithFormat:@"%@_%@", cID, key] : key;
    if ([key hasPrefix:@"OWS"]) return %orig(key);
    return %orig(k);
}
- (BOOL)boolForKey:(NSString*)key {
    NSString *cID = [[OWSContainerManager sharedManager] currentContainerID];
    NSString *k = cID ? [NSString stringWithFormat:@"%@_%@", cID, key] : key;
    return %orig(k);
}
- (void)setObject:(id)obj forKey:(NSString*)key {
    NSString *cID = [[OWSContainerManager sharedManager] currentContainerID];
    NSString *k = cID ? [NSString stringWithFormat:@"%@_%@", cID, key] : key;
    %orig(obj, k);
}
- (void)setBool:(BOOL)b forKey:(NSString*)key {
    NSString *cID = [[OWSContainerManager sharedManager] currentContainerID];
    NSString *k = cID ? [NSString stringWithFormat:@"%@_%@", cID, key] : key;
    %orig(b, k);
}
- (void)removeObjectForKey:(NSString*)key {
    NSString *cID = [[OWSContainerManager sharedManager] currentContainerID];
    NSString *k = cID ? [NSString stringWithFormat:@"%@_%@", cID, key] : key;
    %orig(k);
}
%end

%hook CLLocationManager
- (CLLocation*)location {
    if ([[OWSLocationSpoofer sharedInstance] isEnabled]) {
        CLLocationCoordinate2D coord = [[OWSLocationSpoofer sharedInstance] currentFakeLocation];
        return [[CLLocation alloc] initWithLatitude:coord.latitude longitude:coord.longitude];
    }
    return %orig;
}
- (void)startUpdatingLocation {
    %orig;
    if ([[OWSLocationSpoofer sharedInstance] isEnabled]) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            CLLocationCoordinate2D cc = [[OWSLocationSpoofer sharedInstance] currentFakeLocation];
            CLLocation *loc = [[CLLocation alloc] initWithCoordinate:cc altitude:0 horizontalAccuracy:5 verticalAccuracy:5 timestamp:[NSDate date]];
            if (self.delegate && [self.delegate respondsToSelector:@selector(locationManager:didUpdateLocations:)]) {
                [self.delegate locationManager:self didUpdateLocations:@[loc]];
            }
        });
    }
}
- (void)requestLocation {
    if ([[OWSLocationSpoofer sharedInstance] isEnabled]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            CLLocationCoordinate2D cc = [[OWSLocationSpoofer sharedInstance] currentFakeLocation];
            CLLocation *loc = [[CLLocation alloc] initWithCoordinate:cc altitude:0 horizontalAccuracy:5 verticalAccuracy:5 timestamp:[NSDate date]];
            if (self.delegate && [self.delegate respondsToSelector:@selector(locationManager:didUpdateLocations:)]) {
                [self.delegate locationManager:self didUpdateLocations:@[loc]];
            }
        });
        return;
    }
    %orig;
}
%end

%ctor {
    NSLog(@"[BumbleGhost] v2.1 loaded (Logos mode)");

    // Initialize managers FIRST (before any hook triggers them via NSUserDefaults or UIDevice)
    [[OWSLocationSpoofer sharedInstance] loadCitiesDatabase];
    [[OWSDeviceSpoofer sharedInstance] generateRandomDevice];

    // Show button after app is fully launched
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 4 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        if (!fb) {
            fb = [[OWSFloatingButton alloc] init];
            [fb show];
        }
        // Initialize containers once UI is ready (after hooks installed, avoids constructor deadlock)
        [[OWSContainerManager sharedManager] loadContainers];
    });
}
