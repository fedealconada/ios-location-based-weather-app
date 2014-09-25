//
//  MyLocationViewController.m
//  App
//
//  Created by Federico Martín Alconada Verzini on 02/02/14.
//  Copyright (c) 2014 Federico Martín Alconada Verzini. All rights reserved.
//

#import "MyLocationViewController.h"
#import "Weather.h"

@interface MyLocationViewController ()

@end

@implementation MyLocationViewController
@synthesize mapView;
Weather *theWeather;
NSString *lat;
NSString *lng;
NSData *data;

- (void)viewDidLoad
{
    [super viewDidLoad];
    //Hago visible la toolbar ya que por defecto no se muestra
    self.navigationController.toolbarHidden = NO;
    mapView.delegate = self;
    //Cada vez que se carga la pantalla del mapa llamo este método para que me centre el mapa en mi ubicación.
    [self mapView:mapView didUpdateUserLocation:mapView.userLocation];
    
    /*
     * Para agregar el botón de posicionamiento, tengo que obtener el arreglo de items de la toolbar
     * hacerlo mutable y agregar el botón (previamente creado).
     */
    //Creo el botón
    MKUserTrackingBarButtonItem *buttonItem = [[MKUserTrackingBarButtonItem alloc] initWithMapView:self.mapView];
    //Obtengo el arreglo de items de la toolbar y lo hago mutable
    NSMutableArray *items = [[NSMutableArray alloc]initWithArray:_toolbar.items];
    //Agrego el botón al arreglo
    [items addObject:buttonItem];
    //Reemplazo el arreglo de items original por el nuevo
    _toolbar.items = items;
    [self.view addSubview:_toolbar];
    
    //Weather
    theWeather = [[Weather alloc] init];
    [self invocarWeatherService];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)showActivityView:(id)sender {
    //Tomo la captura del mapa
    [self snapshot];
}

-(void) snapshot {
    MKMapSnapshotOptions *options = [[MKMapSnapshotOptions alloc]init];
    options.region = mapView.region;
    options.mapType = MKMapTypeStandard;
    options.showsBuildings = NO;
    options.showsPointsOfInterest = YES;
    options.size = CGSizeMake(1000, 500);
    
    MKMapSnapshotter *snapshotter = [[MKMapSnapshotter alloc]initWithOptions:options];
    [snapshotter startWithQueue:dispatch_get_main_queue() completionHandler:^(MKMapSnapshot *snapshot, NSError *error) {
        if( error ) {
            NSLog( @"An error occurred: %@", error );
        } else {
            
            //Obtengo la imagen
            UIImage *image = snapshot.image;
            
            //Defino el temaño de la imagen final
            //CGRect finalImageRect = CGRectMake(0, 0, image.size.width, image.size.height);
            
            //Defino el pin para ponerle a la imagen
            MKAnnotationView *pin = [[MKPinAnnotationView alloc] initWithAnnotation:nil reuseIdentifier:@""];
            UIImage *pinImage = pin.image;
            
            //Creo la imagen final
            UIGraphicsBeginImageContextWithOptions(image.size, YES, image.scale);
            
            //Dibujo la imagen
            [image drawAtPoint:CGPointMake(0, 0)];
            
            //Agrego el pin a la imagen
            CGPoint point = [snapshot pointForCoordinate:mapView.userLocation.coordinate];
            CGPoint pinCenterOffset = pin.centerOffset;
            point.x -= pin.bounds.size.width / 2.0;
            point.y -= pin.bounds.size.height / 2.0;
            point.x += pinCenterOffset.x;
            point.y += pinCenterOffset.y;
            [pinImage drawAtPoint:point];
            
            //Grabo la imagen final
            UIImage *finalImage = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            
            //Actualiza el data con la imagen
            data = UIImagePNGRepresentation(finalImage);
            
            //Inicializar ventana
            [self initialize];
        }
    }];
}

- (void) initialize{
    //Creo un elemento a compartir (en este caso el texto con la posición)
    NSString *shareText = [NSString stringWithFormat: @"Tu posición actual es %@, %@. Gracias por usar la aplicación! :)", lat, lng];
    
    //Defino in array que contiene los elementos a compartir (en este caso sólo un elemento)
    NSArray *itemsToShare = @[shareText,data];
    //Declaro un ViewController que se desplegará con los botones de compartir.
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:itemsToShare applicationActivities:nil];
    //Excluyo de las aplicaciones disponibles a Mail
    activityVC.excludedActivityTypes = @[UIActivityTypeMail];
    [self presentViewController:activityVC animated:YES completion:nil];
}

- (IBAction)showWeather:(id)sender {
    NSString *report = [NSString stringWithFormat:
                        @"Temp actual.: %2.1f C\n"
                        @"Vel. del viento: %2.1f Km/h\n"
                        @"Humedad: %2ld%% \n",
                        theWeather.tempCurrent,
                        theWeather.windSpeed,
                        (long)theWeather.humidity
                        ];
    NSString *city = [NSString stringWithFormat:@"Tiempo en %@\n",theWeather.city[0][@"name"]];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:city
                                                    message:report
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
    
    
}

//Método para alternar entre la vista de satélite y la estándar
- (IBAction)setMap:(id)sender {
    switch (((UISegmentedControl *) sender).selectedSegmentIndex) {
        case 0:
            self.mapView.mapType = MKMapTypeStandard;
            break;
        case 1:
            self.mapView.mapType = MKMapTypeSatellite;
            break;
    }
}

- (void)mapView:(MKMapView *)mView didUpdateUserLocation:(MKUserLocation *)userLocation
{
    /*
     * Cada vez que la posición cambia, este método es invocado.
     */
    
    //Actualizo la latitud y longitud.
    lat = [[NSNumber numberWithDouble:userLocation.coordinate.latitude] stringValue];
    lng = [[NSNumber numberWithDouble:userLocation.coordinate.longitude] stringValue];
    
    //Invoco al servicio Weather
    [self invocarWeatherService];
    
    //Si ya existe un pin, lo borro
    [mapView removeAnnotations:mapView.annotations];
    //Indico zoom y que se centre en mi posición
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(userLocation.coordinate, 800, 800);
    [self.mapView setRegion:[self.mapView regionThatFits:region] animated:YES];
    
    //Cambio el texto de la anotación que viene por defecto
    mapView.userLocation.title = NSLocalizedString (@"Mi posición es",@"Mi posición es" );
    
    mapView.userLocation.subtitle = [NSString stringWithFormat: @"%@, %@", lat, lng];
    
    [self performSelector:@selector(openCallout:) withObject:mapView.userLocation afterDelay:3.0];
    
}

- (void)openCallout:(id<MKAnnotation>)annotation {
    [mapView selectAnnotation:annotation animated:YES];
}

- (void)invocarWeatherService {
    //Obtengo la latitud
    NSString *lat = [[NSNumber numberWithDouble:mapView.userLocation.coordinate.latitude] stringValue];
    //Obtengo la longtitud
    NSString *lng = [[NSNumber numberWithDouble:mapView.userLocation.coordinate.longitude] stringValue];
    //Armo el string con la latitud y longitud
    NSString *latlng = [NSString stringWithFormat: @"lat=%@&lon=%@", lat, lng];
    //Invoco al servicio
    [theWeather getCurrent:latlng];
}

@end
