#import "OWSLocationSpoofer.h"
#import "OWSContainerManager.h"
#import <objc/runtime.h>

@interface OWSLocationSpoofer ()
@property (nonatomic, strong) NSDictionary *citiesDatabase;
@end

@implementation OWSLocationSpoofer

+ (instancetype)sharedInstance {
    static OWSLocationSpoofer *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _isEnabled = YES;
        _currentFakeLocation = CLLocationCoordinate2DMake(48.8566, 2.3522); // Paris par défaut
        [self loadCitiesDatabase];
    }
    return self;
}

- (void)loadCitiesDatabase {
    // Base de données complète des villes françaises et internationales
    _citiesDatabase = @{
        // France - Grandes villes
        @"Paris": @{@"lat": @48.8566, @"lon": @2.3522},
        @"Marseille": @{@"lat": @43.2965, @"lon": @5.3698},
        @"Lyon": @{@"lat": @45.7640, @"lon": @4.8357},
        @"Toulouse": @{@"lat": @43.6047, @"lon": @1.4442},
        @"Nice": @{@"lat": @43.7102, @"lon": @7.2620},
        @"Nantes": @{@"lat": @47.2184, @"lon": @-1.5536},
        @"Strasbourg": @{@"lat": @48.5734, @"lon": @7.7521},
        @"Montpellier": @{@"lat": @43.6108, @"lon": @3.8767},
        @"Bordeaux": @{@"lat": @44.8378, @"lon": @-0.5792},
        @"Lille": @{@"lat": @50.6292, @"lon": @3.0573},
        @"Rennes": @{@"lat": @48.1173, @"lon": @-1.6778},
        @"Reims": @{@"lat": @49.2583, @"lon": @4.0317},
        @"Le Havre": @{@"lat": @49.4944, @"lon": @0.1079},
        @"Saint-Étienne": @{@"lat": @45.4397, @"lon": @4.3872},
        @"Toulon": @{@"lat": @43.1242, @"lon": @5.9280},
        @"Grenoble": @{@"lat": @45.1885, @"lon": @5.7245},
        @"Dijon": @{@"lat": @47.3220, @"lon": @5.0415},
        @"Angers": @{@"lat": @47.4784, @"lon": @-0.5632},
        @"Nîmes": @{@"lat": @43.8367, @"lon": @4.3601},
        @"Villeurbanne": @{@"lat": @45.7667, @"lon": @4.8833},
        @"Le Mans": @{@"lat": @48.0077, @"lon": @0.1984},
        @"Aix-en-Provence": @{@"lat": @43.5297, @"lon": @5.4474},
        @"Clermont-Ferrand": @{@"lat": @45.7772, @"lon": @3.0870},
        @"Brest": @{@"lat": @48.3905, @"lon": @-4.4860},
        @"Tours": @{@"lat": @47.3941, @"lon": @0.6848},
        @"Amiens": @{@"lat": @49.8941, @"lon": @2.2958},
        @"Limoges": @{@"lat": @45.8336, @"lon": @1.2611},
        @"Annecy": @{@"lat": @45.8992, @"lon": @6.1294},
        @"Perpignan": @{@"lat": @42.6886, @"lon": @2.8948},
        @"Boulogne-Billancourt": @{@"lat": @48.8350, @"lon": @2.2397},
        @"Metz": @{@"lat": @49.1193, @"lon": @6.1757},
        @"Besançon": @{@"lat": @47.2380, @"lon": @6.0243},
        @"Orléans": @{@"lat": @47.9029, @"lon": @1.9093},
        @"Mulhouse": @{@"lat": @47.7508, @"lon": @7.3359},
        @"Rouen": @{@"lat": @49.4432, @"lon": @1.0993},
        @"Caen": @{@"lat": @49.1829, @"lon": @-0.3707},
        @"Nancy": @{@"lat": @48.6921, @"lon": @6.1844},
        @"Argenteuil": @{@"lat": @48.9475, @"lon": @2.2469},
        @"Montreuil": @{@"lat": @48.8634, @"lon": @2.4430},
        @"Saint-Denis": @{@"lat": @48.9356, @"lon": @2.3539},
        
        // Europe
        @"London": @{@"lat": @51.5074, @"lon": @-0.1278},
        @"Berlin": @{@"lat": @52.5200, @"lon": @13.4050},
        @"Madrid": @{@"lat": @40.4168, @"lon": @-3.7038},
        @"Rome": @{@"lat": @41.9028, @"lon": @12.4964},
        @"Amsterdam": @{@"lat": @52.3676, @"lon": @4.9041},
        @"Barcelona": @{@"lat": @41.3851, @"lon": @2.1734},
        @"Munich": @{@"lat": @48.1351, @"lon": @11.5820},
        @"Milan": @{@"lat": @45.4642, @"lon": @9.1900},
        @"Prague": @{@"lat": @50.0755, @"lon": @14.4378},
        @"Vienna": @{@"lat": @48.2082, @"lon": @16.3738},
        @"Brussels": @{@"lat": @50.8503, @"lon": @4.3517},
        @"Lisbon": @{@"lat": @38.7223, @"lon": @-9.1393},
        @"Geneva": @{@"lat": @46.2044, @"lon": @6.1432},
        @"Zurich": @{@"lat": @47.3769, @"lon": @8.5417},
        @"Copenhagen": @{@"lat": @55.6761, @"lon": @12.5683},
        @"Stockholm": @{@"lat": @59.3293, @"lon": @18.0686},
        @"Oslo": @{@"lat": @59.9139, @"lon": @10.7522},
        @"Dublin": @{@"lat": @53.3498, @"lon": @-6.2603},
        @"Athens": @{@"lat": @37.9838, @"lon": @23.7275},
        @"Warsaw": @{@"lat": @52.2297, @"lon": @21.0122},
        
        // Amérique du Nord
        @"New York": @{@"lat": @40.7128, @"lon": @-74.0060},
        @"Los Angeles": @{@"lat": @34.0522, @"lon": @-118.2437},
        @"Chicago": @{@"lat": @41.8781, @"lon": @-87.6298},
        @"Miami": @{@"lat": @25.7617, @"lon": @-80.1918},
        @"San Francisco": @{@"lat": @37.7749, @"lon": @-122.4194},
        @"Las Vegas": @{@"lat": @36.1699, @"lon": @-115.1398},
        @"Toronto": @{@"lat": @43.6532, @"lon": @-79.3832},
        @"Vancouver": @{@"lat": @49.2827, @"lon": @-123.1207},
        @"Montreal": @{@"lat": @45.5017, @"lon": @-73.5673},
        @"Mexico City": @{@"lat": @19.4326, @"lon": @-99.1332},
        
        // Asie
        @"Tokyo": @{@"lat": @35.6762, @"lon": @139.6503},
        @"Seoul": @{@"lat": @37.5665, @"lon": @126.9780},
        @"Singapore": @{@"lat": @1.3521, @"lon": @103.8198},
        @"Hong Kong": @{@"lat": @22.3193, @"lon": @114.1694},
        @"Bangkok": @{@"lat": @13.7563, @"lon": @100.5018},
        @"Dubai": @{@"lat": @25.2048, @"lon": @55.2708},
        @"Shanghai": @{@"lat": @31.2304, @"lon": @121.4737},
        @"Beijing": @{@"lat": @39.9042, @"lon": @116.4074},
        @"Mumbai": @{@"lat": @19.0760, @"lon": @72.8777},
        @"Delhi": @{@"lat": @28.7041, @"lon": @77.1025},
        
        // Océanie
        @"Sydney": @{@"lat": @-33.8688, @"lon": @151.2093},
        @"Melbourne": @{@"lat": @-37.8136, @"lon": @144.9631},
        @"Auckland": @{@"lat": @-36.8485, @"lon": @174.7633},
        
        // Afrique
        @"Cairo": @{@"lat": @30.0444, @"lon": @31.2357},
        @"Cape Town": @{@"lat": @-33.9249, @"lon": @18.4241},
        @"Johannesburg": @{@"lat": @-26.2041, @"lon": @28.0473},
        @"Marrakech": @{@"lat": @31.6295, @"lon": @-7.9811},
        @"Casablanca": @{@"lat": @33.5731, @"lon": @-7.5898},
        
        // Amérique du Sud
        @"São Paulo": @{@"lat": @-23.5505, @"lon": @-46.6333},
        @"Rio de Janeiro": @{@"lat": @-22.9068, @"lon": @-43.1729},
        @"Buenos Aires": @{@"lat": @-34.6037, @"lon": @-58.3816},
        @"Lima": @{@"lat": @-12.0464, @"lon": @-77.0428},
        @"Bogotá": @{@"lat": @4.7110, @"lon": @-74.0721}
    };
    
    NSLog(@"[OWS] Loaded %lu cities in database", (unsigned long)_citiesDatabase.count);
}

- (void)startSpoofer {
    @try {
        _isEnabled = YES;

        NSString *cityOverride = [[NSUserDefaults standardUserDefaults] objectForKey:@"spoofedCity"];
        if (cityOverride) {
            [self setFakeLocationForCity:cityOverride];
            NSLog(@"[OWS] Location spoofer started - %@ (override)", cityOverride);
        } else {
            // Load location from current container
            OWSContainer *container = [[OWSContainerManager sharedManager] currentContainer];
            if (container) {
                _currentFakeLocation = CLLocationCoordinate2DMake(container.latitude, container.longitude);
                NSLog(@"[OWS] Location spoofer started - %@ (%.4f, %.4f)", container.city, container.latitude, container.longitude);
            }
        }

        // Hook CLLocationManager
        [self hookLocationManager];
    } @catch (NSException *e) {
        NSLog(@"[OWS] startSpoofer failed (safe): %@", e);
    }
}

- (void)stopSpoofer {
    _isEnabled = NO;
    NSLog(@"[OWS] Location spoofer stopped");
}

- (void)setFakeLocation:(CLLocationCoordinate2D)coordinate {
    _currentFakeLocation = coordinate;
    NSLog(@"[OWS] Fake location set to: %.4f, %.4f", coordinate.latitude, coordinate.longitude);
    
    // Post notification for location change
    [[NSNotificationCenter defaultCenter] postNotificationName:@"OWSLocationChanged" object:nil];
}

- (void)setFakeLocationForCity:(NSString *)cityName {
    @try {
        NSDictionary *coords = [self coordinatesForCity:cityName];
        if (coords) {
            double lat = [coords[@"lat"] doubleValue];
            double lon = [coords[@"lon"] doubleValue];
            [self setFakeLocation:CLLocationCoordinate2DMake(lat, lon)];
            [[NSUserDefaults standardUserDefaults] setObject:cityName forKey:@"spoofedCity"];
            NSLog(@"[OWS] Fake location set to %@", cityName);
        }
    } @catch (NSException *e) {
        NSLog(@"[OWS] setFakeLocationForCity failed (safe): %@", e);
    }
}

- (NSDictionary *)coordinatesForCity:(NSString *)cityName {
    // Case-insensitive search
    for (NSString *city in _citiesDatabase.allKeys) {
        if ([city.lowercaseString isEqualToString:cityName.lowercaseString]) {
            return _citiesDatabase[city];
        }
    }
    
    // Partial match
    for (NSString *city in _citiesDatabase.allKeys) {
        if ([city.lowercaseString containsString:cityName.lowercaseString]) {
            return _citiesDatabase[city];
        }
    }
    
    // Default to Paris if not found
    NSLog(@"[OWS] City not found: %@, defaulting to Paris", cityName);
    return _citiesDatabase[@"Paris"];
}

- (NSArray<NSString *> *)availableCities {
    return [_citiesDatabase.allKeys sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
}

- (CLLocation *)fakeLocation {
    return [[CLLocation alloc] initWithCoordinate:_currentFakeLocation
                                         altitude:10
                               horizontalAccuracy:5
                                 verticalAccuracy:5
                                           course:0
                                            speed:0
                                        timestamp:[NSDate date]];
}

#pragma mark - Location Manager Hooking

static void (*owsOrigStartUpdating)(id, SEL);
static void (*owsOrigRequestLocation)(id, SEL);

- (void)hookLocationManager {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        @try {
            Class cls = NSClassFromString(@"CLLocationManager");
            if (!cls) return;

            // Hook location getter
            Method locMethod = class_getInstanceMethod(cls, @selector(location));
            if (locMethod) {
                IMP originalLocIMP = method_getImplementation(locMethod);
                IMP newLocIMP = imp_implementationWithBlock(^CLLocation*(CLLocationManager *_self) {
                    @try {
                        OWSLocationSpoofer *sp = [OWSLocationSpoofer sharedInstance];
                        if (sp.isEnabled) {
                            return [sp fakeLocation];
                        }
                        return ((CLLocation*(*)(id,SEL))originalLocIMP)(_self, @selector(location));
                    } @catch (NSException *e) {
                        return ((CLLocation*(*)(id,SEL))originalLocIMP)(_self, @selector(location));
                    }
                });
                method_setImplementation(locMethod, newLocIMP);
                NSLog(@"[OWS] Hooked CLLocationManager.location");
            }

            // Hook startUpdatingLocation: deliver fake location to delegate
            Method startMethod = class_getInstanceMethod(cls, @selector(startUpdatingLocation));
            if (startMethod) {
                owsOrigStartUpdating = (void(*)(id,SEL))method_getImplementation(startMethod);
                IMP newStartIMP = imp_implementationWithBlock(^(CLLocationManager *_self) {
                    owsOrigStartUpdating(_self, @selector(startUpdatingLocation));
                    @try {
                        OWSLocationSpoofer *sp = [OWSLocationSpoofer sharedInstance];
                        if (sp.isEnabled) {
                            CLLocation *fakeLocation = [sp fakeLocation];
                            id delegate = _self.delegate;
                            if (delegate && [delegate respondsToSelector:@selector(locationManager:didUpdateLocations:)]) {
                                [delegate locationManager:_self didUpdateLocations:@[fakeLocation]];
                            }
                        }
                    } @catch (NSException *e) {
                        NSLog(@"[OWS] startUpdatingLocation hook error (safe): %@", e);
                    }
                });
                method_setImplementation(startMethod, newStartIMP);
                NSLog(@"[OWS] Hooked CLLocationManager.startUpdatingLocation");
            }

            // Hook requestLocation (iOS 9+): deliver fake location to delegate
            Method requestMethod = class_getInstanceMethod(cls, @selector(requestLocation));
            if (requestMethod) {
                owsOrigRequestLocation = (void(*)(id,SEL))method_getImplementation(requestMethod);
                IMP newRequestIMP = imp_implementationWithBlock(^(CLLocationManager *_self) {
                    owsOrigRequestLocation(_self, @selector(requestLocation));
                    @try {
                        OWSLocationSpoofer *sp = [OWSLocationSpoofer sharedInstance];
                        if (sp.isEnabled) {
                            CLLocation *fakeLocation = [sp fakeLocation];
                            id delegate = _self.delegate;
                            if (delegate && [delegate respondsToSelector:@selector(locationManager:didUpdateLocations:)]) {
                                [delegate locationManager:_self didUpdateLocations:@[fakeLocation]];
                            }
                        }
                    } @catch (NSException *e) {
                        NSLog(@"[OWS] requestLocation hook error (safe): %@", e);
                    }
                });
                method_setImplementation(requestMethod, newRequestIMP);
                NSLog(@"[OWS] Hooked CLLocationManager.requestLocation");
            }
        } @catch (NSException *e) {
            NSLog(@"[OWS] hookLocationManager failed (safe): %@", e);
        }
    });
}

@end
