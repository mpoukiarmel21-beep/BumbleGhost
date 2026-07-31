#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <objc/runtime.h>
#import "OWSFloatingButton.h"
#import "OWSContainerManager.h"
#import "OWSLocationSpoofer.h"
#import "OWSDeviceSpoofer.h"

static void sw(Class cls, SEL sel, IMP imp, IMP *old) {
    Method m = class_getInstanceMethod(cls, sel);
    if (m) { if (old) *old = method_getImplementation(m); method_setImplementation(m, imp); }
}

// Device Spoofing
static NSString* (*orig_name)(id,SEL);
static NSString* (*orig_model)(id,SEL);
static NSString* (*orig_version)(id,SEL);
static NSUUID* (*orig_idfv)(id,SEL);

static NSString* hook_name(id s,SEL _c){return [[OWSDeviceSpoofer sharedInstance]deviceName]?:orig_name(s,_c);}
static NSString* hook_model(id s,SEL _c){return [[OWSDeviceSpoofer sharedInstance]deviceModel]?:orig_model(s,_c);}
static NSString* hook_version(id s,SEL _c){return [[OWSDeviceSpoofer sharedInstance]deviceVersion]?:orig_version(s,_c);}
static NSUUID* hook_idfv(id s,SEL _c){NSString*c=[[OWSContainerManager sharedManager]currentContainerID];if(c)return[[OWSDeviceSpoofer sharedInstance]deviceIDFV];return orig_idfv(s,_c);}

// NSUserDefaults
static id(*o0)(id,SEL,id);static BOOL(*o1)(id,SEL,id);static void(*o2)(id,SEL,id,id);static void(*o3)(id,SEL,BOOL,id);static void(*o4)(id,SEL,id);
static id h0(id s,SEL _c,NSString*k){NSString*c=[[OWSContainerManager sharedManager]currentContainerID];if(c)return o0(s,_c,[NSString stringWithFormat:@"%@_%@",c,k]);return o0(s,_c,k);}
static BOOL h1(id s,SEL _c,NSString*k){NSString*c=[[OWSContainerManager sharedManager]currentContainerID];if(c)return o1(s,_c,[NSString stringWithFormat:@"%@_%@",c,k]);return o1(s,_c,k);}
static void h2(id s,SEL _c,id v,NSString*k){NSString*c=[[OWSContainerManager sharedManager]currentContainerID];if(c){o2(s,_c,v,[NSString stringWithFormat:@"%@_%@",c,k]);return;}o2(s,_c,v,k);}
static void h3(id s,SEL _c,BOOL v,NSString*k){NSString*c=[[OWSContainerManager sharedManager]currentContainerID];if(c){o3(s,_c,v,[NSString stringWithFormat:@"%@_%@",c,k]);return;}o3(s,_c,v,k);}
static void h4(id s,SEL _c,NSString*k){NSString*c=[[OWSContainerManager sharedManager]currentContainerID];if(c){o4(s,_c,[NSString stringWithFormat:@"%@_%@",c,k]);return;}o4(s,_c,k);}

// GPS
static CLLocation*(*ol)(id,SEL);static void(*osu)(id,SEL);static void(*orl)(id,SEL);
static CLLocation*hl(id s,SEL _c){if([[OWSLocationSpoofer sharedInstance]isEnabled]){CLLocationCoordinate2D cc=[[OWSLocationSpoofer sharedInstance]currentFakeLocation];return[[CLLocation alloc]initWithLatitude:cc.latitude longitude:cc.longitude];}return ol(s,_c);}
static void hsu(id s,SEL _c){osu(s,_c);if([[OWSLocationSpoofer sharedInstance]isEnabled]){dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(0.5*NSEC_PER_SEC)),dispatch_get_main_queue(),^{CLLocationManager*m=(CLLocationManager*)s;if([m.delegate respondsToSelector:@selector(locationManager:didUpdateLocations:)]){CLLocationCoordinate2D cc=[[OWSLocationSpoofer sharedInstance]currentFakeLocation];CLLocation*l=[[CLLocation alloc]initWithCoordinate:cc altitude:0 horizontalAccuracy:5 verticalAccuracy:5 timestamp:[NSDate date]];[m.delegate locationManager:m didUpdateLocations:@[l]];}});}}
static void hrl(id s,SEL _c){if([[OWSLocationSpoofer sharedInstance]isEnabled]){dispatch_async(dispatch_get_main_queue(),^{CLLocationManager*m=(CLLocationManager*)s;if([m.delegate respondsToSelector:@selector(locationManager:didUpdateLocations:)]){CLLocationCoordinate2D cc=[[OWSLocationSpoofer sharedInstance]currentFakeLocation];CLLocation*l=[[CLLocation alloc]initWithCoordinate:cc altitude:0 horizontalAccuracy:5 verticalAccuracy:5 timestamp:[NSDate date]];[m.delegate locationManager:m didUpdateLocations:@[l]];}});return;}orl(s,_c);}

// Ghost Button
static OWSFloatingButton *fb;
static BOOL(*oda)(id,SEL,UIApplication*,NSDictionary*);
static BOOL hda(id s,SEL _c,UIApplication*a,NSDictionary*d){BOOL r=oda(s,_c,a,d);dispatch_after(dispatch_time(DISPATCH_TIME_NOW,3*NSEC_PER_SEC),dispatch_get_main_queue(),^{if(!fb){fb=[[OWSFloatingButton alloc]init];[fb show];}});return r;}
static void showFB(void){if(!fb){fb=[[OWSFloatingButton alloc]init];[fb show];}}

// Constructor
__attribute__((constructor))
static void init(void) {
    Class ud=[UIDevice class];
    sw(ud,@selector(name),(IMP)hook_name,(IMP*)&orig_name);
    sw(ud,@selector(model),(IMP)hook_model,(IMP*)&orig_model);
    sw(ud,@selector(systemVersion),(IMP)hook_version,(IMP*)&orig_version);
    sw(ud,@selector(identifierForVendor),(IMP)hook_idfv,(IMP*)&orig_idfv);

    Class nud=[NSUserDefaults class];
    sw(nud,@selector(objectForKey:),(IMP)h0,(IMP*)&o0);
    sw(nud,@selector(boolForKey:),(IMP)h1,(IMP*)&o1);
    sw(nud,@selector(setObject:forKey:),(IMP)h2,(IMP*)&o2);
    sw(nud,@selector(setBool:forKey:),(IMP)h3,(IMP*)&o3);
    sw(nud,@selector(removeObjectForKey:),(IMP)h4,(IMP*)&o4);

    Class cl=[CLLocationManager class];
    sw(cl,@selector(location),(IMP)hl,(IMP*)&ol);
    sw(cl,@selector(startUpdatingLocation),(IMP)hsu,(IMP*)&osu);
    sw(cl,@selector(requestLocation),(IMP)hrl,(IMP*)&orl);

    sw([UIApplication class],@selector(application:didFinishLaunchingWithOptions:),(IMP)hda,(IMP*)&oda);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,4*NSEC_PER_SEC),dispatch_get_main_queue(),^{showFB();});

    [[OWSContainerManager sharedManager]loadContainers];
    [[OWSLocationSpoofer sharedInstance]startSpoofer];
    NSLog(@"[BumbleGhost] v2.1 loaded");
}
