//
//  Weather.m
//  iOSApp
//
//  Created by Federico Martín Alconada Verzini on 03/02/14.
//  Copyright (c) 2014 Federico Martín Alconada Verzini. All rights reserved.
//

#import "Weather.h"
#import "AFNetworking.h"

@implementation Weather {
    NSDictionary *weatherServiceResponse;
}

- (id)init
{
    self = [super init];
    
    weatherServiceResponse = @{};
    
    return self;
}

- (void)getCurrent:(NSString *)query
{
    
    NSString *const BASE_URL_STRING = @"http://api.openweathermap.org/data/2.5/find?"; //URL para hacer el request de la temperatura
    NSString *const NUMBER_CITIES = @"&cnt=1"; //Limita a sólo una ciudad
    
    NSString *weatherURLText = [NSString stringWithFormat:@"%@%@%@",
                                BASE_URL_STRING, query, NUMBER_CITIES]; //Armo la URL completa
    NSURL *weatherURL = [NSURL URLWithString:weatherURLText];
    NSURLRequest *weatherRequest = [NSURLRequest requestWithURL:weatherURL];
    
    //Realizo la request que me devuelve la información obtenido en JSON
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc]
                                         initWithRequest:weatherRequest];
    operation.responseSerializer = [AFJSONResponseSerializer serializer];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        weatherServiceResponse = (NSDictionary *)responseObject;
        [self parseWeatherServiceResponse];
    } failure:nil];
    [operation start];

}

//Método para parsear la información que devuelve un request de AFNetworking
- (void)parseWeatherServiceResponse
{
    // clouds
    _cloudCover = [weatherServiceResponse[@"clouds"][@"all"] integerValue];
    
    // coord
    _latitude = [weatherServiceResponse[@"coord"][@"lat"] doubleValue];
    _longitude = [weatherServiceResponse[@"coord"][@"lon"] doubleValue];
    
    // dt
    _reportTime = [NSDate dateWithTimeIntervalSince1970:[weatherServiceResponse[@"dt"] doubleValue]];
    
    // main
    _humidity = [weatherServiceResponse[@"list"][0][@"main"][@"humidity"] doubleValue];
    _pressure = [weatherServiceResponse[@"list"][0][@"main"][@"pressure"] integerValue];
    _tempCurrent = [Weather kelvinToCelsius:[weatherServiceResponse[@"list"][0][@"main"][@"temp"] doubleValue]];
    _tempMin = [Weather kelvinToCelsius:[weatherServiceResponse[@"list"][0][@"main"][@"temp_min"] doubleValue]];
    _tempMax = [Weather kelvinToCelsius:[weatherServiceResponse[@"list"][0][@"main"][@"temp_max"] doubleValue]];
    
    // name
    _city = weatherServiceResponse[@"list"];
    
    // rain
    _rain3hours = [weatherServiceResponse[@"rain"][@"3h"] integerValue];
    
    // snow
    _snow3hours = [weatherServiceResponse[@"snow"][@"3h"] integerValue];
    
    // sys
    _country = weatherServiceResponse[@"sys"][@"country"];
    _sunrise = [NSDate dateWithTimeIntervalSince1970:[weatherServiceResponse[@"sys"][@"sunrise"] doubleValue]];
    _sunset = [NSDate dateWithTimeIntervalSince1970:[weatherServiceResponse[@"sys"][@"sunset"] doubleValue]];
    
    // weather
    _conditions = weatherServiceResponse[@"weather"];
    
    // wind
    _windDirection = [weatherServiceResponse[@"wind"][@"dir"] integerValue];
    _windSpeed = [Weather milesToKilometer:[weatherServiceResponse[@"list"][0][@"wind"][@"speed"] doubleValue]];
}

+ (double)kelvinToCelsius:(double)degreesKelvin
{
    const double ZERO_CELSIUS_IN_KELVIN = 273.15;
    return degreesKelvin - ZERO_CELSIUS_IN_KELVIN;
}

+ (double)milesToKilometer:(double)miles
{
    const double KM = 1.609344;
    return miles*KM;
}

@end