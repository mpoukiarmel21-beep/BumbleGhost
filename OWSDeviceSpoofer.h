#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface OWSDeviceSpoofer : NSObject

+ (instancetype)sharedInstance;

@property (nonatomic, copy) NSString *deviceName;
@property (nonatomic, copy) NSString *deviceModel;
@property (nonatomic, copy) NSString *deviceVersion;
@property (nonatomic, copy) NSUUID *deviceIDFV;

- (NSArray<NSDictionary *> *)availableDevices;
- (void)setDeviceByName:(NSString *)displayName;
- (void)generateRandomDevice;
- (void)applyToContainer:(NSString *)containerID;

@end
