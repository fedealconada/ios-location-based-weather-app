//
//  MyLocationViewController.h
//  iOSApp
//
//  Created by Federico Martín Alconada Verzini on 02/02/14.
//  Copyright (c) 2014 Federico Martín Alconada Verzini. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@interface MyLocationViewController : UIViewController <MKMapViewDelegate>
@property (nonatomic, strong) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
- (IBAction)showActivityView:(id)sender;
- (IBAction)showWeather:(id)sender;
- (IBAction)setMap:(id)sender;


@end