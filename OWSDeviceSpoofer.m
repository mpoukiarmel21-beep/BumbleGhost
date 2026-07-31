#import "OWSDeviceSpoofer.h"

@implementation OWSDeviceSpoofer

+ (instancetype)sharedInstance {
    static OWSDeviceSpoofer *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ instance = [[self alloc] init]; });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self ensureDefaults];
    }
    return self;
}

- (NSUserDefaults *)ud {
    return [NSUserDefaults standardUserDefaults];
}

- (void)ensureDefaults {
    @try {
        if (![[self ud] objectForKey:@"spoofedModel"]) {
            [self generateRandomDevice];
        }
    } @catch (NSException *e) {
        NSLog(@"[TinderGhost] ensureDefaults failed (safe): %@", e);
    }
}

- (NSArray<NSDictionary *> *)availableDevices {
    static NSArray *devices = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        devices = @[
            @{@"name": @"iPhone 11",        @"model": @"iPhone12,1", @"version": @"17.5"},
            @{@"name": @"iPhone 12",        @"model": @"iPhone13,2", @"version": @"17.5"},
            @{@"name": @"iPhone 12 Pro",    @"model": @"iPhone13,3", @"version": @"17.5"},
            @{@"name": @"iPhone 13",        @"model": @"iPhone14,5", @"version": @"17.5"},
            @{@"name": @"iPhone 13 Pro",    @"model": @"iPhone14,2", @"version": @"17.5"},
            @{@"name": @"iPhone 14",        @"model": @"iPhone14,7", @"version": @"17.5"},
            @{@"name": @"iPhone 14 Plus",   @"model": @"iPhone14,8", @"version": @"17.5"},
            @{@"name": @"iPhone 14 Pro",    @"model": @"iPhone15,2", @"version": @"17.5"},
            @{@"name": @"iPhone 15",        @"model": @"iPhone15,4", @"version": @"17.5"},
            @{@"name": @"iPhone 15 Plus",   @"model": @"iPhone15,5", @"version": @"17.5"},
            @{@"name": @"iPhone 15 Pro",    @"model": @"iPhone16,1", @"version": @"17.5"},
            @{@"name": @"iPhone 15 Pro Max",@"model": @"iPhone16,2", @"version": @"17.5"},
            @{@"name": @"iPhone 16",        @"model": @"iPhone17,3", @"version": @"18.5"},
            @{@"name": @"iPhone 16 Pro",    @"model": @"iPhone17,2", @"version": @"18.5"},
            @{@"name": @"iPhone 16 Pro Max",@"model": @"iPhone17,1", @"version": @"18.5"},
        ];
    });
    return devices;
}

- (void)setDeviceByName:(NSString *)displayName {
    for (NSDictionary *d in [self availableDevices]) {
        if ([d[@"name"] isEqualToString:displayName]) {
            [self setDeviceModel:d[@"model"]];
            [self setDeviceVersion:d[@"version"]];
            [self setDeviceName:@"iPhone"];
            return;
        }
    }
}

- (void)generateRandomDevice {
    NSArray *devices = [self availableDevices];
    NSDictionary *d = devices[arc4random_uniform((uint32_t)devices.count)];
    [self setDeviceModel:d[@"model"]];
    [self setDeviceVersion:d[@"version"]];
    [self setDeviceName:@"iPhone"];
    [self setDeviceIDFV:[NSUUID UUID]];
}

- (NSString *)deviceName {
    @try {
        NSString *v = [[self ud] objectForKey:@"spoofedName"];
        if (!v) { v = @"iPhone"; [[self ud] setObject:v forKey:@"spoofedName"]; }
        return v;
    } @catch (NSException *e) {
        return @"iPhone";
    }
}
- (void)setDeviceName:(NSString *)name {
    @try { [[self ud] setObject:name forKey:@"spoofedName"]; } @catch (NSException *e) {}
}

- (NSString *)deviceModel {
    @try {
        NSString *v = [[self ud] objectForKey:@"spoofedModel"];
        if (!v) { [self generateRandomDevice]; v = [[self ud] objectForKey:@"spoofedModel"]; }
        return v;
    } @catch (NSException *e) {
        return [[self ud] objectForKey:@"spoofedModel"];
    }
}
- (void)setDeviceModel:(NSString *)m {
    @try { [[self ud] setObject:m forKey:@"spoofedModel"]; } @catch (NSException *e) {}
}

- (NSString *)deviceVersion {
    @try {
        NSString *v = [[self ud] objectForKey:@"spoofedVersion"];
        if (!v) { v = @"17.5"; [[self ud] setObject:v forKey:@"spoofedVersion"]; }
        return v;
    } @catch (NSException *e) {
        return @"17.5";
    }
}
- (void)setDeviceVersion:(NSString *)v {
    @try { [[self ud] setObject:v forKey:@"spoofedVersion"]; } @catch (NSException *e) {}
}

- (NSUUID *)deviceIDFV {
    @try {
        NSString *s = [[self ud] objectForKey:@"spoofedIDFV"];
        if (!s) { s = [[NSUUID UUID] UUIDString]; [[self ud] setObject:s forKey:@"spoofedIDFV"]; }
        return [[NSUUID alloc] initWithUUIDString:s];
    } @catch (NSException *e) {
        return [NSUUID UUID];
    }
}
- (void)setDeviceIDFV:(NSUUID *)u {
    @try { [[self ud] setObject:u.UUIDString forKey:@"spoofedIDFV"]; } @catch (NSException *e) {}
}

- (void)applyToContainer:(NSString *)containerID {
    // Values are already stored per-container via the NSUserDefaults hooks.
}

@end
