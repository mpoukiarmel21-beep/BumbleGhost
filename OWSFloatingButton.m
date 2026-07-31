#import "OWSFloatingButton.h"
#import "OWSContainerManager.h"
#import "OWSLocationSpoofer.h"
#import "OWSDeviceSpoofer.h"
#import "OWSMapPickerViewController.h"
#import <QuartzCore/QuartzCore.h>

#define BUTTON_SIZE 56.0
#define MENU_WIDTH 320.0
#define MENU_HEIGHT 500.0

// Present a view controller from the app's topmost view controller,
// with a small delay to avoid "already presenting" conflicts.
static void OWSShowVC(UIViewController *vc) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.35 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        @try {
            UIViewController *top = [OWSContainerManager topViewController];
            if (top) {
                [top presentViewController:vc animated:YES completion:nil];
            }
        } @catch (NSException *e) {
            NSLog(@"[TinderGhost] Presentation failed (safe): %@", e);
        }
    });
}

@interface OWSFloatingWindow : UIWindow
@end

@implementation OWSFloatingWindow
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *hit = [super hitTest:point withEvent:event];
    if (hit == self) return nil;
    return hit;
}
@end

@interface OWSFloatingButton ()
@property (nonatomic, strong) UIWindow *floatingWindow;
@property (nonatomic, strong) UIButton *floatingButton;
@property (nonatomic, strong) UIPanGestureRecognizer *panGesture;
@property (nonatomic, assign) CGPoint lastLocation;
@end

@implementation OWSFloatingButton

- (instancetype)init {
    self = [super init];
    if (self) {
        @try {
            [self setupFloatingButton];
        } @catch (NSException *e) {
            NSLog(@"[TinderGhost] Floating button setup failed (safe): %@", e);
        }
    }
    return self;
}

- (void)setupFloatingButton {
    // Create a separate window for the floating button (always on top)
    _floatingWindow = [[OWSFloatingWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    _floatingWindow.windowLevel = UIWindowLevelAlert + 100;
    _floatingWindow.backgroundColor = [UIColor clearColor];
    _floatingWindow.userInteractionEnabled = YES;
    
    // Attach to the active scene (iOS 13+)
    if (@available(iOS 13.0, *)) {
        for (UIWindowScene *s in [UIApplication sharedApplication].connectedScenes) {
            if (![s isKindOfClass:[UIWindowScene class]]) continue;
            if (s.activationState == UISceneActivationStateForegroundActive) {
                _floatingWindow.windowScene = s;
                break;
            }
        }
    }
    
    // Create the gear button
    _floatingButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _floatingButton.frame = CGRectMake(20, 100, BUTTON_SIZE, BUTTON_SIZE);
    
    // Gear icon using SF Symbols (iOS 13+)
    if (@available(iOS 13.0, *)) {
        UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:24 weight:UIImageSymbolWeightBold];
        UIImage *gearImage = [UIImage systemImageNamed:@"gearshape.fill" withConfiguration:config];
        [_floatingButton setImage:gearImage forState:UIControlStateNormal];
    } else {
        // Fallback for older iOS
        [_floatingButton setTitle:@"⚙️" forState:UIControlStateNormal];
        _floatingButton.titleLabel.font = [UIFont systemFontOfSize:30];
    }
    
    // Style the button with a Tinder flame gradient
    _floatingButton.tintColor = [UIColor whiteColor];
    _floatingButton.layer.cornerRadius = BUTTON_SIZE / 2;
    _floatingButton.layer.masksToBounds = NO;
    
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = CGRectMake(0, 0, BUTTON_SIZE, BUTTON_SIZE);
    gradient.cornerRadius = BUTTON_SIZE / 2;
    gradient.colors = @[
        (id)[UIColor colorWithRed:1.0 green:0.35 blue:0.30 alpha:1.0].CGColor,
        (id)[UIColor colorWithRed:0.98 green:0.18 blue:0.42 alpha:1.0].CGColor
    ];
    gradient.startPoint = CGPointMake(0, 0);
    gradient.endPoint = CGPointMake(1, 1);
    [_floatingButton.layer insertSublayer:gradient atIndex:0];
    
    // White ring border
    _floatingButton.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.95].CGColor;
    _floatingButton.layer.borderWidth = 2.5;
    
    // Depth shadow with flame glow
    _floatingButton.layer.shadowColor = [UIColor colorWithRed:0.98 green:0.18 blue:0.42 alpha:1.0].CGColor;
    _floatingButton.layer.shadowOffset = CGSizeMake(0, 3);
    _floatingButton.layer.shadowOpacity = 0.55;
    _floatingButton.layer.shadowRadius = 6;
    _floatingButton.layer.shadowPath = [UIBezierPath bezierPathWithOvalInRect:_floatingButton.bounds].CGPath;
    
    // Add tap action
    [_floatingButton addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
    
    // Add pan gesture for dragging
    _panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    [_floatingButton addGestureRecognizer:_panGesture];
    
    [_floatingWindow addSubview:_floatingButton];

    NSLog(@"[TinderGhost] Floating button created");
}

- (void)buttonTapped:(UIButton *)sender {
    NSLog(@"[TinderGhost] Floating button tapped");
    
    // Haptic feedback
    if (@available(iOS 10.0, *)) {
        UIImpactFeedbackGenerator *feedback = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium];
        [feedback impactOccurred];
    }
    
    // Springy press animation
    sender.transform = CGAffineTransformMakeScale(0.9, 0.9);
    [UIView animateWithDuration:0.12
                          delay:0
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
        sender.transform = CGAffineTransformMakeScale(1.08, 1.08);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.18
                              delay:0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
            sender.transform = CGAffineTransformIdentity;
        } completion:nil];
    }];
    
    // Show menu
    [self showContainerMenu];
}

- (void)handlePan:(UIPanGestureRecognizer *)gesture {
    CGPoint translation = [gesture translationInView:_floatingWindow];
    
    if (gesture.state == UIGestureRecognizerStateBegan) {
        _lastLocation = _floatingButton.center;
    } else if (gesture.state == UIGestureRecognizerStateChanged) {
        CGPoint newCenter = CGPointMake(_lastLocation.x + translation.x, _lastLocation.y + translation.y);
        
        // Keep button within screen bounds
        CGFloat halfSize = BUTTON_SIZE / 2;
        newCenter.x = MAX(halfSize + 10, MIN(_floatingWindow.bounds.size.width - halfSize - 10, newCenter.x));
        newCenter.y = MAX(halfSize + 40, MIN(_floatingWindow.bounds.size.height - halfSize - 40, newCenter.y));
        
        _floatingButton.center = newCenter;
    } else if (gesture.state == UIGestureRecognizerStateEnded) {
        // Snap to edge
        CGFloat centerX = _floatingWindow.bounds.size.width / 2;
        if (_floatingButton.center.x < centerX) {
            // Snap to left
            [UIView animateWithDuration:0.3 animations:^{
                self.floatingButton.center = CGPointMake(BUTTON_SIZE / 2 + 10, self.floatingButton.center.y);
            }];
        } else {
            // Snap to right
            [UIView animateWithDuration:0.3 animations:^{
                self.floatingButton.center = CGPointMake(self.floatingWindow.bounds.size.width - BUTTON_SIZE / 2 - 10, self.floatingButton.center.y);
            }];
        }
    }
}

- (void)showContainerMenu {
    @try {
        OWSContainerMenuViewController *menuVC = [[OWSContainerMenuViewController alloc] init];
        menuVC.modalPresentationStyle = UIModalPresentationOverFullScreen;
        menuVC.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;

        __weak typeof(self) weakSelf = self;
        menuVC.onDismiss = ^{
            [weakSelf show];
        };

        [self hide];
        OWSShowVC(menuVC);
    } @catch (NSException *e) {
        NSLog(@"[TinderGhost] Menu presentation failed (safe): %@", e);
        [self show];
    }
}

- (void)show {
    _floatingWindow.hidden = NO;
    _floatingButton.alpha = 0;
    _floatingButton.transform = CGAffineTransformMakeScale(0.6, 0.6);
    [UIView animateWithDuration:0.35
                          delay:0
         usingSpringWithDamping:0.6
          initialSpringVelocity:0.6
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
        self.floatingButton.alpha = 1;
        self.floatingButton.transform = CGAffineTransformIdentity;
    } completion:nil];
}

- (void)hide {
    [UIView animateWithDuration:0.3 animations:^{
        self.floatingButton.alpha = 0;
    } completion:^(BOOL finished) {
        self.floatingWindow.hidden = YES;
    }];
}

- (UIViewController *)topViewController {
    return [OWSContainerManager topViewController];
}

@end

#pragma mark - Container Menu View Controller

@interface OWSContainerMenuViewController ()
@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray<OWSContainer *> *containers;
@property (nonatomic, strong) OWSContainer *currentContainer;
@property (nonatomic, strong) UIButton *addButtonView;
@end

@implementation OWSContainerMenuViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
    
    [self setupContainerView];
    [self loadContainers];
    
    // Add tap gesture to dismiss
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(backgroundTapped:)];
    [self.view addGestureRecognizer:tapGesture];
}

- (void)setupContainerView {
    // Main container
    _containerView = [[UIView alloc] initWithFrame:CGRectZero];
    _containerView.backgroundColor = [UIColor whiteColor];
    _containerView.layer.cornerRadius = 20;
    _containerView.layer.shadowColor = [UIColor blackColor].CGColor;
    _containerView.layer.shadowOffset = CGSizeMake(0, 5);
    _containerView.layer.shadowOpacity = 0.3;
    _containerView.layer.shadowRadius = 10;
    _containerView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_containerView];
    
    // Header
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = @"⚙️ TinderGhost";
    titleLabel.font = [UIFont boldSystemFontOfSize:24];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [_containerView addSubview:titleLabel];
    
    UILabel *subtitleLabel = [[UILabel alloc] init];
    subtitleLabel.text = @"Gestion des conteneurs";
    subtitleLabel.font = [UIFont systemFontOfSize:14];
    subtitleLabel.textColor = [UIColor grayColor];
    subtitleLabel.textAlignment = NSTextAlignmentCenter;
    subtitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [_containerView addSubview:subtitleLabel];
    
    // Table view
    _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.layer.cornerRadius = 10;
    _tableView.translatesAutoresizingMaskIntoConstraints = NO;
    [_containerView addSubview:_tableView];
    
    // Ghost button
    UIButton *ghostButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [ghostButton setTitle:@"👻 Ghost" forState:UIControlStateNormal];
    ghostButton.titleLabel.font = [UIFont boldSystemFontOfSize:15];
    ghostButton.backgroundColor = [UIColor colorWithRed:1.0 green:0.95 blue:0.95 alpha:1.0];
    [ghostButton setTitleColor:[UIColor colorWithRed:0.98 green:0.18 blue:0.42 alpha:1.0] forState:UIControlStateNormal];
    ghostButton.layer.cornerRadius = 10;
    ghostButton.translatesAutoresizingMaskIntoConstraints = NO;
    [ghostButton addTarget:self action:@selector(ghostTapped:) forControlEvents:UIControlEventTouchUpInside];
    [_containerView addSubview:ghostButton];
    
    // Location button
    UIButton *locButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [locButton setTitle:@"📍 Localisation" forState:UIControlStateNormal];
    locButton.titleLabel.font = [UIFont boldSystemFontOfSize:15];
    locButton.backgroundColor = [UIColor colorWithRed:1.0 green:0.95 blue:0.95 alpha:1.0];
    [locButton setTitleColor:[UIColor colorWithRed:0.98 green:0.18 blue:0.42 alpha:1.0] forState:UIControlStateNormal];
    locButton.layer.cornerRadius = 10;
    locButton.translatesAutoresizingMaskIntoConstraints = NO;
    [locButton addTarget:self action:@selector(locationTapped:) forControlEvents:UIControlEventTouchUpInside];
    [_containerView addSubview:locButton];
    
    // Add button
    UIButton *addButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [addButton setTitle:@"+ Nouveau conteneur" forState:UIControlStateNormal];
    addButton.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    [addButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    addButton.layer.cornerRadius = 10;
    addButton.clipsToBounds = YES;
    addButton.translatesAutoresizingMaskIntoConstraints = NO;
    [addButton addTarget:self action:@selector(addContainerTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self applyFlameGradient:addButton];
    [_containerView addSubview:addButton];
    _addButtonView = addButton;
    
    // Close button
    UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [closeButton setTitle:@"Fermer" forState:UIControlStateNormal];
    closeButton.titleLabel.font = [UIFont systemFontOfSize:16];
    closeButton.translatesAutoresizingMaskIntoConstraints = NO;
    [closeButton addTarget:self action:@selector(closeTapped:) forControlEvents:UIControlEventTouchUpInside];
    [_containerView addSubview:closeButton];
    
    // Constraints
    [NSLayoutConstraint activateConstraints:@[
        [_containerView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [_containerView.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
        [_containerView.widthAnchor constraintEqualToConstant:MENU_WIDTH],
        [_containerView.heightAnchor constraintEqualToConstant:MENU_HEIGHT],
        
        [titleLabel.topAnchor constraintEqualToAnchor:_containerView.topAnchor constant:20],
        [titleLabel.leadingAnchor constraintEqualToAnchor:_containerView.leadingAnchor constant:20],
        [titleLabel.trailingAnchor constraintEqualToAnchor:_containerView.trailingAnchor constant:-20],
        
        [subtitleLabel.topAnchor constraintEqualToAnchor:titleLabel.bottomAnchor constant:5],
        [subtitleLabel.leadingAnchor constraintEqualToAnchor:_containerView.leadingAnchor constant:20],
        [subtitleLabel.trailingAnchor constraintEqualToAnchor:_containerView.trailingAnchor constant:-20],
        
        [_tableView.topAnchor constraintEqualToAnchor:subtitleLabel.bottomAnchor constant:20],
        [_tableView.leadingAnchor constraintEqualToAnchor:_containerView.leadingAnchor constant:15],
        [_tableView.trailingAnchor constraintEqualToAnchor:_containerView.trailingAnchor constant:-15],
        [_tableView.bottomAnchor constraintEqualToAnchor:ghostButton.topAnchor constant:-15],
        
        [ghostButton.leadingAnchor constraintEqualToAnchor:_containerView.leadingAnchor constant:15],
        [ghostButton.trailingAnchor constraintEqualToAnchor:locButton.leadingAnchor constant:-10],
        [ghostButton.widthAnchor constraintEqualToAnchor:locButton.widthAnchor],
        [ghostButton.heightAnchor constraintEqualToConstant:44],
        
        [locButton.trailingAnchor constraintEqualToAnchor:_containerView.trailingAnchor constant:-15],
        [locButton.heightAnchor constraintEqualToConstant:44],
        
        [addButton.topAnchor constraintEqualToAnchor:ghostButton.bottomAnchor constant:10],
        [addButton.leadingAnchor constraintEqualToAnchor:_containerView.leadingAnchor constant:20],
        [addButton.trailingAnchor constraintEqualToAnchor:_containerView.trailingAnchor constant:-20],
        [addButton.heightAnchor constraintEqualToConstant:44],
        [addButton.bottomAnchor constraintEqualToAnchor:closeButton.topAnchor constant:-10],
        
        [closeButton.leadingAnchor constraintEqualToAnchor:_containerView.leadingAnchor constant:20],
        [closeButton.trailingAnchor constraintEqualToAnchor:_containerView.trailingAnchor constant:-20],
        [closeButton.heightAnchor constraintEqualToConstant:44],
        [closeButton.bottomAnchor constraintEqualToAnchor:_containerView.bottomAnchor constant:-20]
    ]];
}

- (void)applyFlameGradient:(UIButton *)button {
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.colors = @[
        (id)[UIColor colorWithRed:1.0 green:0.35 blue:0.30 alpha:1.0].CGColor,
        (id)[UIColor colorWithRed:0.98 green:0.18 blue:0.42 alpha:1.0].CGColor
    ];
    gradient.startPoint = CGPointMake(0, 0);
    gradient.endPoint = CGPointMake(1, 1);
    gradient.cornerRadius = 10;
    gradient.frame = button.bounds;
    button.layer.cornerRadius = 10;
    button.clipsToBounds = YES;
    [button.layer insertSublayer:gradient atIndex:0];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    for (CALayer *sublayer in _addButtonView.layer.sublayers) {
        if ([sublayer isKindOfClass:[CAGradientLayer class]]) {
            sublayer.frame = _addButtonView.bounds;
            sublayer.cornerRadius = 10;
        }
    }
}

- (void)loadContainers {
    _containers = [[OWSContainerManager sharedManager] containers];
    _currentContainer = [[OWSContainerManager sharedManager] currentContainer];
    [_tableView reloadData];
}

#pragma mark - TableView DataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _containers.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellID = @"ContainerCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellID];
    }
    
    OWSContainer *container = _containers[indexPath.row];
    
    cell.textLabel.text = container.displayName;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"📍 %@", container.city];
    
    // Color indicator
    UIView *colorView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
    colorView.backgroundColor = container.color;
    colorView.layer.cornerRadius = 15;
    colorView.layer.borderWidth = 2;
    colorView.layer.borderColor = [UIColor whiteColor].CGColor;
    cell.accessoryView = colorView;
    
    // Highlight current container
    if ([container.containerID isEqualToString:_currentContainer.containerID]) {
        cell.backgroundColor = [[UIColor colorWithRed:1.0 green:0.26 blue:0.38 alpha:1.0] colorWithAlphaComponent:0.1];
        cell.textLabel.font = [UIFont boldSystemFontOfSize:17];
        cell.imageView.image = [self checkmarkImage];
    } else {
        cell.backgroundColor = [UIColor whiteColor];
        cell.textLabel.font = [UIFont systemFontOfSize:17];
        cell.imageView.image = nil;
    }
    
    return cell;
}

#pragma mark - TableView Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    OWSContainer *selectedContainer = _containers[indexPath.row];
    
    if ([selectedContainer.containerID isEqualToString:_currentContainer.containerID]) {
        // Already selected
        return;
    }
    
    // Confirm switch
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Changer de conteneur ?" 
                                                                   message:[NSString stringWithFormat:@"Passer à:\n%@ (%@)\n\n⚠️ L'app va redémarrer", selectedContainer.displayName, selectedContainer.city]
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Annuler" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Confirmer" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [[OWSContainerManager sharedManager] switchToContainer:selectedContainer.containerID];
    }]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Don't allow deletion of current container
    OWSContainer *container = _containers[indexPath.row];
    return ![container.containerID isEqualToString:_currentContainer.containerID];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        OWSContainer *container = _containers[indexPath.row];
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Supprimer le conteneur ?" 
                                                                       message:[NSString stringWithFormat:@"Toutes les données de '%@' seront supprimées", container.displayName]
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"Annuler" style:UIAlertActionStyleCancel handler:nil]];
        [alert addAction:[UIAlertAction actionWithTitle:@"Supprimer" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            [[OWSContainerManager sharedManager] deleteContainer:container.containerID];
            [self loadContainers];
        }]];
        
        [self presentViewController:alert animated:YES completion:nil];
    }
}

#pragma mark - Actions

- (void)addContainerTapped:(UIButton *)sender {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Nouveau conteneur" 
                                                                   message:@"Créer un nouveau profil isolé"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"Nom (ex: Client Lyon)";
    }];
    
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"Ville (ex: Lyon)";
    }];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Annuler" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Créer" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSString *name = alert.textFields[0].text;
        NSString *city = alert.textFields[1].text;
        
        if (name.length > 0 && city.length > 0) {
            // Get coordinates for the city
            NSDictionary *coords = [[OWSLocationSpoofer sharedInstance] coordinatesForCity:city];
            double lat = [coords[@"lat"] doubleValue];
            double lon = [coords[@"lon"] doubleValue];
            
            [[OWSContainerManager sharedManager] createContainer:name city:city latitude:lat longitude:lon];
            [self loadContainers];
        }
    }]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)closeTapped:(UIButton *)sender {
    [self dismissViewControllerAnimated:YES completion:^{
        if (self.onDismiss) {
            self.onDismiss();
        }
    }];
}

- (void)ghostTapped:(UIButton *)sender {
    @try {
        OWSDeviceSpoofer *spoofer = [OWSDeviceSpoofer sharedInstance];
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"👻 Ghost - Modèle iPhone"
                                                                       message:@"Choisir le modèle simulé pour ce conteneur"
                                                                preferredStyle:UIAlertControllerStyleActionSheet];
        for (NSDictionary *d in [spoofer availableDevices]) {
            NSString *name = d[@"name"];
            [alert addAction:[UIAlertAction actionWithTitle:name style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [spoofer setDeviceByName:name];
                [self showConfirmation:[NSString stringWithFormat:@"Modèle Ghost: %@", name]];
            }]];
        }
        [alert addAction:[UIAlertAction actionWithTitle:@"Annuler" style:UIAlertActionStyleCancel handler:nil]];
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            alert.popoverPresentationController.sourceView = sender;
        }
        [self presentViewController:alert animated:YES completion:nil];
    } @catch (NSException *e) {
        NSLog(@"[TinderGhost] ghostTapped failed (safe): %@", e);
    }
}

- (void)locationTapped:(UIButton *)sender {
    @try {
        OWSMapPickerViewController *picker = [[OWSMapPickerViewController alloc] initWithCompletion:^(double lat, double lon, NSString *cityName) {
            [[OWSLocationSpoofer sharedInstance] setFakeLocationForLatitude:lat longitude:lon cityName:cityName];
            [self showConfirmation:[NSString stringWithFormat:@"Localisation: %@\n(%.4f, %.4f)", cityName ?: @"Position personnalisée", lat, lon]];
        }];
        picker.modalPresentationStyle = UIModalPresentationFullScreen;
        OWSShowVC(picker);
    } @catch (NSException *e) {
        NSLog(@"[TinderGhost] locationTapped failed (safe): %@", e);
    }
}

- (void)showConfirmation:(NSString *)message {
    @try {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"✅ TinderGhost"
                                                                       message:message
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        OWSShowVC(alert);
    } @catch (NSException *e) {
        NSLog(@"[TinderGhost] showConfirmation failed (safe): %@", e);
    }
}

- (void)backgroundTapped:(UITapGestureRecognizer *)gesture {
    CGPoint location = [gesture locationInView:self.view];
    if (!CGRectContainsPoint(_containerView.frame, location)) {
        [self closeTapped:nil];
    }
}

#pragma mark - Helpers

- (UIImage *)checkmarkImage {
    if (@available(iOS 13.0, *)) {
        return [UIImage systemImageNamed:@"checkmark.circle.fill"];
    }
    return nil;
}

@end
