#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface OWSLocationSpoofer : NSObject

+ (instancetype)sharedInstance;

- (void)startSpoofer;
- (void)stopSpoofer;

- (void)setFakeLocation:(CLLocationCoordinate2D)coordinate;
- (void)setFakeLocationForCity:(NSString *)cityName;
- (void)setFakeLocationForLatitude:(double)latitude longitude:(double)longitude cityName:(NSString *)cityName;
- (NSDictionary *)coordinatesForCity:(NSString *)cityName;
- (NSArray<NSString *> *)availableCities;

@property (nonatomic, assign) BOOL isEnabled;
@property (nonatomic, assign) CLLocationCoordinate2D currentFakeLocation;

@end
