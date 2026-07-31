#import "OWSContainerManager.h"
#import <UIKit/UIKit.h>

#define CONTAINERS_FILE @"OWSContainers.plist"
#define CURRENT_CONTAINER_KEY @"OWSCurrentContainerID"

@implementation OWSContainer

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (instancetype)initWithName:(NSString *)name city:(NSString *)city latitude:(double)lat longitude:(double)lon {
    self = [super init];
    if (self) {
        _containerID = [[NSUUID UUID] UUIDString];
        _displayName = name;
        _city = city;
        _latitude = lat;
        _longitude = lon;
        _createdDate = [NSDate date];
        
        // Generate random color for visual identification
        CGFloat hue = (arc4random() % 256) / 256.0;
        _color = [UIColor colorWithHue:hue saturation:0.8 brightness:0.9 alpha:1.0];

        // Random device characteristics per container
        NSArray *models = @[@"iPhone15,2",@"iPhone15,3",@"iPhone14,7",@"iPhone14,8",@"iPhone15,4",@"iPhone15,5"];
        NSArray *versions = @[@"16.5",@"16.6",@"17.0",@"17.1",@"16.3"];
        _deviceModel = models[arc4random_uniform((uint32_t)models.count)];
        _deviceVersion = versions[arc4random_uniform((uint32_t)versions.count)];
        _deviceName = @"iPhone";
        _deviceIDFV = [[NSUUID UUID] UUIDString];
    }
    return self;
}

// NSCoding implementation for persistence
- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:_containerID forKey:@"containerID"];
    [coder encodeObject:_displayName forKey:@"displayName"];
    [coder encodeObject:_city forKey:@"city"];
    [coder encodeDouble:_latitude forKey:@"latitude"];
    [coder encodeDouble:_longitude forKey:@"longitude"];
    [coder encodeObject:_createdDate forKey:@"createdDate"];
    [coder encodeObject:_color forKey:@"color"];
    [coder encodeObject:_deviceName forKey:@"deviceName"];
    [coder encodeObject:_deviceModel forKey:@"deviceModel"];
    [coder encodeObject:_deviceVersion forKey:@"deviceVersion"];
    [coder encodeObject:_deviceIDFV forKey:@"deviceIDFV"];
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        @try {
            _containerID = [coder decodeObjectOfClass:[NSString class] forKey:@"containerID"];
            _displayName = [coder decodeObjectOfClass:[NSString class] forKey:@"displayName"];
            _city = [coder decodeObjectOfClass:[NSString class] forKey:@"city"];
            _latitude = [coder decodeDoubleForKey:@"latitude"];
            _longitude = [coder decodeDoubleForKey:@"longitude"];
            _createdDate = [coder decodeObjectOfClass:[NSDate class] forKey:@"createdDate"];
            _color = [coder decodeObjectOfClass:[UIColor class] forKey:@"color"];
            _deviceName = [coder decodeObjectOfClass:[NSString class] forKey:@"deviceName"];
            _deviceModel = [coder decodeObjectOfClass:[NSString class] forKey:@"deviceModel"];
            _deviceVersion = [coder decodeObjectOfClass:[NSString class] forKey:@"deviceVersion"];
            _deviceIDFV = [coder decodeObjectOfClass:[NSString class] forKey:@"deviceIDFV"];
        } @catch (NSException *e) {
            NSLog(@"[OWS] Error decoding container: %@", e);
            return nil;
        }
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<OWSContainer: %@ (%@) - %@>", _displayName, _city, _containerID];
}

@end

@implementation OWSContainerManager {
    NSMutableArray<OWSContainer *> *_mutableContainers;
    OWSContainer *_currentContainer;
}

+ (instancetype)sharedManager {
    static OWSContainerManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _mutableContainers = [NSMutableArray array];
        [self loadContainers];
    }
    return self;
}

- (NSArray<OWSContainer *> *)containers {
    return [_mutableContainers copy];
}

- (NSString *)currentContainerID {
    return _currentContainer.containerID;
}

- (NSString *)containersFilePath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths firstObject];
    return [documentsDirectory stringByAppendingPathComponent:CONTAINERS_FILE];
}

- (void)loadContainers {
    @try {
        _mutableContainers = [NSMutableArray array];

        NSString *filePath = [self containersFilePath];
        if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
            NSData *data = [NSData dataWithContentsOfFile:filePath];
            if (data) {
                NSError *error = nil;
                NSArray *arr = [NSKeyedUnarchiver unarchivedObjectOfClasses:[NSSet setWithArray:@[[NSArray class], [OWSContainer class], [NSString class], [NSDate class], [UIColor class]]] 
                                                                 fromData:data 
                                                                    error:&error];
                if (error) {
                    NSLog(@"[OWS] Error loading containers: %@", error);
                    arr = nil;
                }
                if ([arr isKindOfClass:[NSArray class]]) {
                    NSMutableArray *valid = [NSMutableArray array];
                    for (id obj in arr) {
                        if ([obj isKindOfClass:[OWSContainer class]]) {
                            [valid addObject:obj];
                        }
                    }
                    _mutableContainers = valid;
                }
            }
        }

        // Load current container ID
        NSString *currentID = [[NSUserDefaults standardUserDefaults] objectForKey:CURRENT_CONTAINER_KEY];
        if (currentID) {
            _currentContainer = [self getContainerByID:currentID];
        }

        // Create default container if none exists
        if (_mutableContainers.count == 0) {
            [self createContainer:@"Compte Principal" city:@"Paris" latitude:48.8566 longitude:2.3522];
        }

        // Set first container as current if none is set
        if (!_currentContainer && _mutableContainers.count > 0) {
            _currentContainer = _mutableContainers[0];
            [[NSUserDefaults standardUserDefaults] setObject:_currentContainer.containerID forKey:CURRENT_CONTAINER_KEY];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }

        NSLog(@"[OWS] Loaded %lu containers, current: %@", (unsigned long)_mutableContainers.count, _currentContainer.displayName);
    } @catch (NSException *e) {
        NSLog(@"[OWS] loadContainers failed, using defaults: %@", e);
        _mutableContainers = [NSMutableArray array];
        if (_mutableContainers.count == 0) {
            @try {
                [self createContainer:@"Compte Principal" city:@"Paris" latitude:48.8566 longitude:2.3522];
            } @catch (NSException *e2) {
                NSLog(@"[OWS] Default container creation failed: %@", e2);
            }
        }
        if (!_currentContainer && _mutableContainers.count > 0) {
            _currentContainer = _mutableContainers[0];
        }
    }
}

- (void)saveContainers {
    @try {
        NSError *error = nil;
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:_mutableContainers 
                                             requiringSecureCoding:YES 
                                                             error:&error];

        if (error) {
            NSLog(@"[OWS] Error archiving containers: %@", error);
            return;
        }

        [data writeToFile:[self containersFilePath] atomically:YES];
        NSLog(@"[OWS] Saved %lu containers", (unsigned long)_mutableContainers.count);
    } @catch (NSException *e) {
        NSLog(@"[OWS] saveContainers failed (safe): %@", e);
    }
}

- (void)createContainer:(NSString *)name city:(NSString *)city latitude:(double)lat longitude:(double)lon {
    @try {
        OWSContainer *container = [[OWSContainer alloc] initWithName:name city:city latitude:lat longitude:lon];
        [_mutableContainers addObject:container];
        [self saveContainers];

        // Create isolated directory for this container
        [self createContainerDirectory:container.containerID];

        NSLog(@"[OWS] Created container: %@", container);

        // Post notification
        [[NSNotificationCenter defaultCenter] postNotificationName:@"OWSContainerCreated" object:container];
    } @catch (NSException *e) {
        NSLog(@"[OWS] createContainer failed (safe): %@", e);
    }
}

- (void)deleteContainer:(NSString *)containerID {
    OWSContainer *container = [self getContainerByID:containerID];
    if (!container) return;
    
    // Don't allow deletion of current container
    if ([_currentContainer.containerID isEqualToString:containerID]) {
        NSLog(@"[OWS] Cannot delete current container");
        return;
    }
    
    [_mutableContainers removeObject:container];
    [self saveContainers];
    
    // Delete container directory
    [self deleteContainerDirectory:containerID];
    
    NSLog(@"[OWS] Deleted container: %@", containerID);
    
    // Post notification
    [[NSNotificationCenter defaultCenter] postNotificationName:@"OWSContainerDeleted" object:containerID];
}

- (void)switchToContainer:(NSString *)containerID {
    OWSContainer *container = [self getContainerByID:containerID];
    if (!container) {
        NSLog(@"[OWS] Container not found: %@", containerID);
        return;
    }
    
    _currentContainer = container;
    [[NSUserDefaults standardUserDefaults] setObject:containerID forKey:CURRENT_CONTAINER_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    NSLog(@"[OWS] Switched to container: %@ (%@)", container.displayName, container.city);
    
    // Post notification
    [[NSNotificationCenter defaultCenter] postNotificationName:@"OWSContainerSwitched" object:container];
    
    // Show alert to user (only when app is active)
    if ([UIApplication sharedApplication].applicationState != UIApplicationStateActive) return;
    dispatch_async(dispatch_get_main_queue(), ^{
        @try {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"🔄 Conteneur changé" 
                                                                           message:[NSString stringWithFormat:@"Maintenant connecté à:\n%@ (%@)", container.displayName, container.city]
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                // Force app restart to apply changes
                exit(0);
            }]];
            
            UIViewController *topVC = [self topViewController];
            if (topVC) {
                [topVC presentViewController:alert animated:YES completion:nil];
            }
        } @catch (NSException *e) {
            NSLog(@"[OWS] Switch alert failed (safe): %@", e);
        }
    });
}

- (OWSContainer *)getContainerByID:(NSString *)containerID {
    for (OWSContainer *container in _mutableContainers) {
        if ([container.containerID isEqualToString:containerID]) {
            return container;
        }
    }
    return nil;
}

#pragma mark - Helper Methods

- (void)createContainerDirectory:(NSString *)containerID {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *baseDir = [paths firstObject];
    NSString *containerDir = [baseDir stringByAppendingPathComponent:[NSString stringWithFormat:@"OWSContainers/%@", containerID]];
    
    NSError *error = nil;
    [[NSFileManager defaultManager] createDirectoryAtPath:containerDir 
                              withIntermediateDirectories:YES 
                                               attributes:nil 
                                                    error:&error];
    if (error) {
        NSLog(@"[OWS] Error creating container directory: %@", error);
    }
}

- (void)deleteContainerDirectory:(NSString *)containerID {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *baseDir = [paths firstObject];
    NSString *containerDir = [baseDir stringByAppendingPathComponent:[NSString stringWithFormat:@"OWSContainers/%@", containerID]];
    
    NSError *error = nil;
    [[NSFileManager defaultManager] removeItemAtPath:containerDir error:&error];
    if (error) {
        NSLog(@"[OWS] Error deleting container directory: %@", error);
    }
}

- (UIViewController *)topViewController {
    UIWindow *window = nil;
    if (@available(iOS 13.0, *)) {
        for (UIWindowScene *s in [UIApplication sharedApplication].connectedScenes) {
            if (![s isKindOfClass:[UIWindowScene class]]) continue;
            if (s.activationState == UISceneActivationStateForegroundActive) {
                for (UIWindow *w in s.windows) {
                    if (w.isKeyWindow) { window = w; break; }
                }
                if (!window && s.windows.count > 0) window = s.windows.firstObject;
                if (window) break;
            }
        }
    }
    if (!window) window = [UIApplication sharedApplication].keyWindow;
    UIViewController *topVC = window.rootViewController;
    while (topVC.presentedViewController) {
        topVC = topVC.presentedViewController;
    }
    return topVC;
}

@end
