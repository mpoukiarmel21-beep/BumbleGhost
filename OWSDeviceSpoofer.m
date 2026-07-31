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
        [self generateRandomDevice];
    }
    return self;
}

- (void)generateRandomDevice {
    NSArray *models = @[@"iPhone15,2",@"iPhone15,3",@"iPhone14,7",@"iPhone14,8",@"iPhone15,4",@"iPhone15,5",@"iPhone14,5",@"iPhone14,6"];
    NSArray *versions = @[@"16.5",@"16.6",@"17.0",@"17.1",@"16.3",@"16.4"];
    NSArray *names = @[@"iPhone",@"iPhone",@"iPhone",@"iPhone"];

    _deviceModel = models[arc4random_uniform((uint32_t)models.count)];
    _deviceVersion = versions[arc4random_uniform((uint32_t)versions.count)];
    _deviceName = names[arc4random_uniform((uint32_t)names.count)];
    _deviceIDFV = [NSUUID UUID];
}

- (void)applyToContainer:(NSString *)containerID {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    NSString *prefix = containerID ? [NSString stringWithFormat:@"%@_", containerID] : @"";
    [ud setObject:_deviceName forKey:[NSString stringWithFormat:@"%@spoofedName", prefix]];
    [ud setObject:_deviceModel forKey:[NSString stringWithFormat:@"%@spoofedModel", prefix]];
    [ud setObject:_deviceVersion forKey:[NSString stringWithFormat:@"%@spoofedVersion", prefix]];
    [ud setObject:_deviceIDFV.UUIDString forKey:[NSString stringWithFormat:@"%@spoofedIDFV", prefix]];
    [ud synchronize];
}

@end
