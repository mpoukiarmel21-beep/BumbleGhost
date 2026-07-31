#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface OWSContainer : NSObject <NSCoding>

@property (nonatomic, strong) NSString *containerID;
@property (nonatomic, strong) NSString *displayName;
@property (nonatomic, strong) NSString *city;
@property (nonatomic, assign) double latitude;
@property (nonatomic, assign) double longitude;
@property (nonatomic, strong) NSDate *createdDate;
@property (nonatomic, strong) UIColor *color;

- (instancetype)initWithName:(NSString *)name city:(NSString *)city latitude:(double)lat longitude:(double)lon;

@end

@interface OWSContainerManager : NSObject

@property (nonatomic, strong, readonly) NSArray<OWSContainer *> *containers;
@property (nonatomic, strong, readonly) OWSContainer *currentContainer;
@property (nonatomic, strong, readonly) NSString *currentContainerID;

+ (instancetype)sharedManager;

- (void)loadContainers;
- (void)saveContainers;
- (void)createContainer:(NSString *)name city:(NSString *)city latitude:(double)lat longitude:(double)lon;
- (void)deleteContainer:(NSString *)containerID;
- (void)switchToContainer:(NSString *)containerID;
- (OWSContainer *)getContainerByID:(NSString *)containerID;

@end
