#import <UIKit/UIKit.h>

@interface OWSFloatingButton : NSObject

- (void)show;
- (void)hide;

@end

@interface OWSContainerMenuViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, copy) void (^onDismiss)(void);

@end
