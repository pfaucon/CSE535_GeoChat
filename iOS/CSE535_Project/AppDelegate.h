//
//  AppDelegate.h
//  CSE535_Project
//
//  Created by John Yu on 10/26/14.
//  Copyright (c) 2014 Paper Scissors, Rocks!. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Firebase/Firebase.h>
#import <Parse/Parse.h>
@import CoreLocation;


#define kMessageDirectory @"Messages"
#define kZonesDirectory @"Zones"
#define kUserLocationsDirectory @"UserLocations"
#define kUserZonesDirectory @"UserZones"


@interface AppDelegate : UIResponder <UIApplicationDelegate, CLLocationManagerDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) NSDictionary *currentUserInfo;
@property (strong, nonatomic) NSString *userId;
@property Firebase *db;

@property NSTimer *timer;
@property CLLocationManager *locationManager;
@end

