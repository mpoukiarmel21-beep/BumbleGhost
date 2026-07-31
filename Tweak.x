#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <objc/runtime.h>
#import "OWSFloatingButton.h"
#import "OWSContainerManager.h"
#import "OWSLocationSpoofer.h"
#import "OWSDeviceSpoofer.h"

static OWSFloatingButton *fb = nil;

%hook UIDevice
- (NSString*)name {
    NSString *spoofed = [[OWSDeviceSpoofer sharedInstance] deviceName];
    if (spoofed) return spoofed;
    return %orig;
}
- (NSString*)model {
    NSString *spoofed = [[OWSDeviceSpoofer sharedInstance] deviceModel];
    if (spoofed) return spoofed;
    return %orig;
}
- (NSString*)systemVersion {
    NSString *spoofed = [[OWSDeviceSpoofer sharedInstance] deviceVersion];
    if (spoofed) return spoofed;
    return %orig;
}
- (NSUUID*)identifierForVendor {
    NSUUID *spoofed = [[OWSDeviceSpoofer sharedInstance] deviceIDFV];
    if (spoofed) return spoofed;
    return %orig;
}
%end

%hook NSUserDefaults
- (id)objectForKey:(NSString*)key {
    NSString *cID = [[OWSContainerManager sharedManager] currentContainerID];
    if (cID && ![key hasPrefix:@"OWS"]) {
        return %orig([NSString stringWithFormat:@"%@_%@", cID, key]);
    }
    return %orig(key);
}
- (BOOL)boolForKey:(NSString*)key {
    NSString *cID = [[OWSContainerManager sharedManager] currentContainerID];
    if (cID) {
        return %orig([NSString stringWithFormat:@"%@_%@", cID, key]);
    }
    return %orig(key);
}
- (void)setObject:(id)obj forKey:(NSString*)key {
    NSString *cID = [[OWSContainerManager sharedManager] currentContainerID];
    if (cID) {
        %orig(obj, [NSString stringWithFormat:@"%@_%@", cID, key]);
        return;
    }
    %orig(obj, key);
}
- (void)setBool:(BOOL)b forKey:(NSString*)key {
    NSString *cID = [[OWSContainerManager sharedManager] currentContainerID];
    if (cID) {
        %orig(b, [NSString stringWithFormat:@"%@_%@", cID, key]);
        return;
    }
    %orig(b, key);
}
- (void)removeObjectForKey:(NSString*)key {
    NSString *cID = [[OWSContainerManager sharedManager] currentContainerID];
    if (cID) {
        %orig([NSString stringWithFormat:@"%@_%@", cID, key]);
        return;
    }
    %orig(key);
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

    [[OWSLocationSpoofer sharedInstance] loadCitiesDatabase];
    [[OWSDeviceSpoofer sharedInstance] generateRandomDevice];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 4 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        if (!fb) {
            fb = [[OWSFloatingButton alloc] init];
            [fb show];
        }
        [[OWSContainerManager sharedManager] loadContainers];
    });
}
