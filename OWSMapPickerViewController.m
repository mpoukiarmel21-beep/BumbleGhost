#import "OWSMapPickerViewController.h"
#import "OWSLocationSpoofer.h"
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>

@interface OWSMapPickerViewController ()
@property (nonatomic, strong) MKMapView *mapView;
@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) UISegmentedControl *segmentedControl;
@property (nonatomic, strong) UITableView *resultsTableView;
@property (nonatomic, strong) UITableView *citiesTableView;
@property (nonatomic, strong) UIButton *useButton;
@property (nonatomic, strong) UIView *topBar;

@property (nonatomic, strong) MKLocalSearchCompleter *searchCompleter;
@property (nonatomic, strong) NSArray<MKLocalSearchCompletion *> *searchResults;
@property (nonatomic, strong) NSArray<NSString *> *cities;

@property (nonatomic, assign) CLLocationCoordinate2D selectedCoordinate;
@property (nonatomic, assign) BOOL hasSelection;
@property (nonatomic, strong) NSString *selectedName;
@property (nonatomic, strong) MKPointAnnotation *pin;
@property (nonatomic, strong) CLGeocoder *geocoder;
@end

@implementation OWSMapPickerViewController

- (instancetype)initWithCompletion:(OWSMapPickerCompletion)completion {
    self = [super init];
    if (self) {
        _onSelect = completion;
    }
    return self;
}

- (instancetype)init {
    return [self initWithCompletion:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    _hasSelection = NO;
    _selectedName = nil;
    _geocoder = [[CLGeocoder alloc] init];

    [self setupTopBar];
    [self setupSearchBar];
    [self setupSegmentedControl];
    [self setupMapView];
    [self setupTables];
    [self setupUseButton];
    [self loadCities];

    // Worldwide search completer
    _searchCompleter = [[MKLocalSearchCompleter alloc] init];
    _searchCompleter.delegate = self;
    _searchCompleter.region = MKCoordinateRegionMake(CLLocationCoordinate2DMake(20, 0),
                                                      MKCoordinateSpanMake(180, 360));
    _searchCompleter.resultTypes = MKLocalSearchCompleterResultTypeAddress | MKLocalSearchCompleterResultTypePointOfInterest;
}

- (void)loadCities {
    _cities = [[OWSLocationSpoofer sharedInstance] availableCities];
    [_citiesTableView reloadData];
}

#pragma mark - UI Setup

- (void)setupTopBar {
    _topBar = [[UIView alloc] init];
    _topBar.backgroundColor = [UIColor colorWithRed:0.98 green:0.18 blue:0.42 alpha:1.0];
    _topBar.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_topBar];

    UILabel *title = [[UILabel alloc] init];
    title.text = @"📍 Localisation";
    title.font = [UIFont boldSystemFontOfSize:18];
    title.textColor = [UIColor whiteColor];
    title.translatesAutoresizingMaskIntoConstraints = NO;
    [_topBar addSubview:title];

    UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [closeButton setTitle:@"Fermer" forState:UIControlStateNormal];
    [closeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    closeButton.titleLabel.font = [UIFont boldSystemFontOfSize:15];
    closeButton.translatesAutoresizingMaskIntoConstraints = NO;
    [closeButton addTarget:self action:@selector(closeTapped:) forControlEvents:UIControlEventTouchUpInside];
    [_topBar addSubview:closeButton];

    [NSLayoutConstraint activateConstraints:@[
        [_topBar.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [_topBar.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [_topBar.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [_topBar.heightAnchor constraintEqualToConstant:96],

        [title.leadingAnchor constraintEqualToAnchor:_topBar.leadingAnchor constant:16],
        [title.bottomAnchor constraintEqualToAnchor:_topBar.bottomAnchor constant:-10],

        [closeButton.trailingAnchor constraintEqualToAnchor:_topBar.trailingAnchor constant:-16],
        [closeButton.centerYAnchor constraintEqualToAnchor:title.centerYAnchor]
    ]];
}

- (void)setupSearchBar {
    _searchBar = [[UISearchBar alloc] init];
    _searchBar.placeholder = @"Rechercher une ville (ex: New York, Paris, Tokyo…)";
    _searchBar.delegate = self;
    _searchBar.searchBarStyle = UISearchBarStyleMinimal;
    _searchBar.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_searchBar];
}

- (void)setupSegmentedControl {
    _segmentedControl = [[UISegmentedControl alloc] initWithItems:@[@"🗺 Carte", @"📋 Liste"]];
    _segmentedControl.selectedSegmentIndex = 0;
    [_segmentedControl addTarget:self action:@selector(segmentChanged:) forControlEvents:UIControlEventValueChanged];
    _segmentedControl.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_segmentedControl];
}

- (void)setupMapView {
    _mapView = [[MKMapView alloc] init];
    _mapView.delegate = self;
    _mapView.mapType = MKMapTypeStandard;
    _mapView.translatesAutoresizingMaskIntoConstraints = NO;

    CLLocationCoordinate2D paris = CLLocationCoordinate2DMake(48.8566, 2.3522);
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(paris, 300000, 300000);
    [_mapView setRegion:region animated:NO];

    UILongPressGestureRecognizer *lp = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(mapLongPress:)];
    lp.minimumPressDuration = 0.6;
    [_mapView addGestureRecognizer:lp];

    [self.view addSubview:_mapView];
}

- (void)setupTables {
    _resultsTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    _resultsTableView.dataSource = self;
    _resultsTableView.delegate = self;
    _resultsTableView.hidden = YES;
    _resultsTableView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_resultsTableView];

    _citiesTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    _citiesTableView.dataSource = self;
    _citiesTableView.delegate = self;
    _citiesTableView.hidden = YES;
    _citiesTableView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_citiesTableView];
}

- (void)setupUseButton {
    _useButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_useButton setTitle:@"✔ Utiliser cette position" forState:UIControlStateNormal];
    [_useButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    _useButton.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    _useButton.backgroundColor = [UIColor colorWithRed:0.98 green:0.18 blue:0.42 alpha:1.0];
    _useButton.layer.cornerRadius = 12;
    _useButton.enabled = NO;
    _useButton.alpha = 0.5;
    _useButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_useButton addTarget:self action:@selector(useLocationTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_useButton];

    [NSLayoutConstraint activateConstraints:@[
        [_searchBar.topAnchor constraintEqualToAnchor:_topBar.bottomAnchor],
        [_searchBar.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:8],
        [_searchBar.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-8],

        [_segmentedControl.topAnchor constraintEqualToAnchor:_searchBar.bottomAnchor constant:4],
        [_segmentedControl.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16],
        [_segmentedControl.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-16],

        [_mapView.topAnchor constraintEqualToAnchor:_segmentedControl.bottomAnchor constant:8],
        [_mapView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [_mapView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],

        [_useButton.topAnchor constraintEqualToAnchor:_mapView.bottomAnchor constant:12],
        [_useButton.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16],
        [_useButton.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-16],
        [_useButton.heightAnchor constraintEqualToConstant:48],
        [_useButton.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor constant:-24],

        [_resultsTableView.topAnchor constraintEqualToAnchor:_segmentedControl.bottomAnchor constant:8],
        [_resultsTableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [_resultsTableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [_resultsTableView.bottomAnchor constraintEqualToAnchor:_useButton.topAnchor constant:-8],

        [_citiesTableView.topAnchor constraintEqualToAnchor:_segmentedControl.bottomAnchor constant:8],
        [_citiesTableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [_citiesTableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [_citiesTableView.bottomAnchor constraintEqualToAnchor:_useButton.topAnchor constant:-8]
    ]];
}

#pragma mark - Actions

- (void)closeTapped:(UIButton *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)segmentChanged:(UISegmentedControl *)seg {
    BOOL mapMode = seg.selectedSegmentIndex == 0;
    _mapView.hidden = !mapMode;
    _citiesTableView.hidden = mapMode;
    _resultsTableView.hidden = YES;
    [self.view endEditing:YES];
}

- (void)mapLongPress:(UILongPressGestureRecognizer *)gesture {
    if (gesture.state != UIGestureRecognizerStateBegan) return;
    CGPoint point = [gesture locationInView:_mapView];
    CLLocationCoordinate2D coord = [_mapView convertPoint:point toCoordinateFromView:_mapView];
    [self setSelectionAtCoordinate:coord];
    [self reverseGeocode:coord];
}

- (void)reverseGeocode:(CLLocationCoordinate2D)coord {
    CLLocation *loc = [[CLLocation alloc] initWithLatitude:coord.latitude longitude:coord.longitude];
    [_geocoder reverseGeocodeLocation:loc completionHandler:^(NSArray<CLPlacemark *> *placemarks, NSError *error) {
        CLPlacemark *pm = placemarks.firstObject;
        if (pm && !error) {
            _selectedName = pm.locality ?: pm.administrativeArea ?: pm.country;
            [self refreshPinSubtitle];
        }
    }];
}

- (void)setSelectionAtCoordinate:(CLLocationCoordinate2D)coord {
    _selectedCoordinate = coord;
    _hasSelection = YES;
    if (!_selectedName) _selectedName = @"Position personnalisée";

    [_mapView removeAnnotation:_pin];
    _pin = [[MKPointAnnotation alloc] init];
    _pin.coordinate = coord;
    _pin.title = _selectedName;
    _pin.subtitle = [NSString stringWithFormat:@"%.4f, %.4f", coord.latitude, coord.longitude];
    [_mapView addAnnotation:_pin];

    _useButton.enabled = YES;
    _useButton.alpha = 1.0;
}

- (void)refreshPinSubtitle {
    if (_pin && _hasSelection) {
        _pin.title = _selectedName;
    }
}

- (void)useLocationTapped:(UIButton *)sender {
    if (!_hasSelection) return;
    if (self.onSelect) {
        self.onSelect(_selectedCoordinate.latitude, _selectedCoordinate.longitude, _selectedName);
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Search

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    if (searchText.length >= 2) {
        _searchCompleter.queryFragment = searchText;
        _resultsTableView.hidden = NO;
        _mapView.hidden = YES;
        _citiesTableView.hidden = YES;
    } else {
        _searchResults = @[];
        [_resultsTableView reloadData];
        _resultsTableView.hidden = YES;
        if (_segmentedControl.selectedSegmentIndex == 0) {
            _mapView.hidden = NO;
        } else {
            _citiesTableView.hidden = NO;
        }
    }
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    searchBar.text = @"";
    [searchBar resignFirstResponder];
}

- (void)completerDidUpdateResults:(MKLocalSearchCompleter *)completer {
    _searchResults = completer.results;
    [_resultsTableView reloadData];
}

- (void)completer:(MKLocalSearchCompleter *)completer didFailWithError:(NSError *)error {
    NSLog(@"[TinderGhost] Search failed: %@", error);
}

#pragma mark - TableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView == _resultsTableView) return _searchResults.count;
    return _cities.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellID = @"CityCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellID];
    }

    if (tableView == _resultsTableView) {
        MKLocalSearchCompletion *c = _searchResults[indexPath.row];
        cell.textLabel.text = c.title;
        cell.detailTextLabel.text = c.subtitle;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else {
        NSString *city = _cities[indexPath.row];
        NSDictionary *coords = [[OWSLocationSpoofer sharedInstance] coordinatesForCity:city];
        cell.textLabel.text = city;
        cell.detailTextLabel.text = [NSString stringWithFormat:@"📍 %.2f, %.2f", [coords[@"lat"] doubleValue], [coords[@"lon"] doubleValue]];
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self.view endEditing:YES];

    if (tableView == _resultsTableView) {
        MKLocalSearchCompletion *completion = _searchResults[indexPath.row];
        MKLocalSearchRequest *request = [[MKLocalSearchRequest alloc] initWithCompletion:completion];
        MKLocalSearch *search = [[MKLocalSearch alloc] initWithRequest:request];
        [search startWithCompletionHandler:^(MKLocalSearchResponse *response, NSError *error) {
            if (response.mapItems.count > 0) {
                MKPlacemark *pm = response.mapItems.firstObject.placemark;
                _selectedName = pm.locality ?: pm.administrativeArea ?: pm.country ?: completion.title;
                [self setSelectionAtCoordinate:pm.coordinate];
                [_mapView setRegion:MKCoordinateRegionMakeWithDistance(pm.coordinate, 50000, 50000) animated:YES];
                _segmentedControl.selectedSegmentIndex = 0;
                [self segmentChanged:_segmentedControl];
            }
        }];
    } else {
        NSString *city = _cities[indexPath.row];
        NSDictionary *coords = [[OWSLocationSpoofer sharedInstance] coordinatesForCity:city];
        double lat = [coords[@"lat"] doubleValue];
        double lon = [coords[@"lon"] doubleValue];
        _selectedName = city;
        [self setSelectionAtCoordinate:CLLocationCoordinate2DMake(lat, lon)];
        _segmentedControl.selectedSegmentIndex = 0;
        [self segmentChanged:_segmentedControl];
    }
}

#pragma mark - MKMapViewDelegate

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    if (![annotation isKindOfClass:[MKPointAnnotation class]]) return nil;
    static NSString *pinID = @"OWSPin";
    MKPinAnnotationView *pinView = (MKPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:pinID];
    if (!pinView) {
        pinView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:pinID];
        pinView.pinTintColor = [UIColor colorWithRed:0.98 green:0.18 blue:0.42 alpha:1.0];
        pinView.canShowCallout = YES;
    } else {
        pinView.annotation = annotation;
    }
    return pinView;
}

@end
