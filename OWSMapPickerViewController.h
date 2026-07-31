#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@interface OWSMapPickerViewController : UIViewController <MKMapViewDelegate, UISearchBarDelegate, MKLocalSearchCompleterDelegate, UITableViewDataSource, UITableViewDelegate>

typedef void (^OWSMapPickerCompletion)(double latitude, double longitude, NSString *cityName);

@property (nonatomic, copy) OWSMapPickerCompletion onSelect;

- (instancetype)initWithCompletion:(OWSMapPickerCompletion)completion;

@end
