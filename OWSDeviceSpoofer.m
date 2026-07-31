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
    if (![[self ud] objectForKey:@"spoofedModel"]) {
        [self generateRandomDevice];
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
    NSString *v = [[self ud] objectForKey:@"spoofedName"];
    if (!v) { v = @"iPhone"; [[self ud] setObject:v forKey:@"spoofedName"]; }
    return v;
}
- (void)setDeviceName:(NSString *)name {
    [[self ud] setObject:name forKey:@"spoofedName"];
}

- (NSString *)deviceModel {
    NSString *v = [[self ud] objectForKey:@"spoofedModel"];
    if (!v) { [self generateRandomDevice]; v = [[self ud] objectForKey:@"spoofedModel"]; }
    return v;
}
- (void)setDeviceModel:(NSString *)m {
    [[self ud] setObject:m forKey:@"spoofedModel"];
}

- (NSString *)deviceVersion {
    NSString *v = [[self ud] objectForKey:@"spoofedVersion"];
    if (!v) { v = @"17.5"; [[self ud] setObject:v forKey:@"spoofedVersion"]; }
    return v;
}
- (void)setDeviceVersion:(NSString *)v {
    [[self ud] setObject:v forKey:@"spoofedVersion"];
}

- (NSUUID *)deviceIDFV {
    NSString *s = [[self ud] objectForKey:@"spoofedIDFV"];
    if (!s) { s = [[NSUUID UUID] UUIDString]; [[self ud] setObject:s forKey:@"spoofedIDFV"]; }
    return [[NSUUID alloc] initWithUUIDString:s];
}
- (void)setDeviceIDFV:(NSUUID *)u {
    [[self ud] setObject:u.UUIDString forKey:@"spoofedIDFV"];
}

- (void)applyToContainer:(NSString *)containerID {
    // Values are already stored per-container via the NSUserDefaults hooks.
}

@end
