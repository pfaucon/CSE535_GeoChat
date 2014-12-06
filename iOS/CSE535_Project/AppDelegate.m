//
//  AppDelegate.m
//  CSE535_Project
//
//  Created by John Yu on 10/26/14.
//  Copyright (c) 2014 Paper Scissors, Rocks!. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    //initialize the database info
    self.db = [[Firebase alloc] initWithUrl:@"https://cse535-project.firebaseio.com/"];
    
    // Init location manager
    self.locationManager = [[CLLocationManager alloc] init];
    [self.locationManager requestWhenInUseAuthorization];
    self.locationManager.delegate = self;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    [self.locationManager startUpdatingLocation];
    
    //configure the timer
    self.timer = [NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(timerFired:) userInfo:Nil repeats:YES];
    
    [Parse setApplicationId:@"FcA36waByxhXX3j7U58EfTWYtNmkMryH8kml4hvU"
                  clientKey:@"VF72A1Tgppe9ubr8cibkoXa4HEyauTRHSuuUfxs2"];
    
    [PFCloud callFunctionInBackground:@"calcZones"
                       withParameters:@{}
                                block:^(id result, NSError *error) {
                                    if (!error) {
                                        NSArray *em_class = result[1];
                                        [PFCloud callFunctionInBackground:@"namingZones"
                                                           withParameters:@{@"em_class": em_class}
                                                                    block:^(id result, NSError *error) {
                                                                        if (!error) {
                                                                            // ratings is 4.5
                                                                        }
                                                                    }];
                                    }
                                    else
                                    {
                                        NSLog(@"Cloud Code Error: %@", error);
                                    }
                                }];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


#pragma mark - timer response

-(void)timerFired:(NSTimer *)timer
{
    [self updateUserLocation];
}

- (void)updateUserLocation {
    
    //if the user hasn't logged in then we can't track their location...
    if(!(_userId && _currentUserInfo)) return;
    
    NSMutableDictionary *message = [[NSMutableDictionary alloc] init];
    
    // Saving the location
    NSNumber *lon = [[NSNumber alloc] initWithDouble:self.locationManager.location.coordinate.longitude];
    NSNumber *lat = [[NSNumber alloc] initWithDouble:self.locationManager.location.coordinate.latitude];
    message[@"lat"] = lat;
    message[@"lon"] = lon;
    
    // Saving the message
    message[@"timestamp"] = [[NSDate new] description];
    message[@"username"] = self.currentUserInfo[@"email"];
    
    //get a messageID
    Firebase *messageRef = [[self.db childByAppendingPath:kUserLocationsDirectory] childByAppendingPath:self.userId];
    
    // Putting it up to Firebase
    [messageRef setValue:message];
    
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"Location %@", @([CLLocationManager locationServicesEnabled]));
    if([CLLocationManager locationServicesEnabled])
    {
        UIAlertView *errorAlert = [[UIAlertView alloc]
                                   initWithTitle:@"Error" message:@"Location service is not turned on. Please go to settings to turn location service on for this app." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [errorAlert show];
    }
    
    else
    {
        UIAlertView *errorAlert = [[UIAlertView alloc]
                                   initWithTitle:@"Error" message:@"Failed to Get Your Location" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [errorAlert show];
    }
    
    NSLog(@"didFailWithError: %@", error);
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    NSLog(@"didUpdateToLocation: %@", newLocation);
}

#pragma mark - Custom Setters
//if the user logs in (and we acquire their credentials) update our db connection
-(void)setUserId:(NSString *)userId
{
    _userId = userId;
    
    if(_userId && _currentUserInfo)
    {
        [[[self.db childByAppendingPath:@"users"]
          childByAppendingPath:self.userId] setValue:self.currentUserInfo];
    }
}

-(void)setCurrentUserInfo:(NSDictionary *)currentUserInfo
{
    _currentUserInfo = currentUserInfo;
    
    if(_userId && _currentUserInfo)
    {
        [[[self.db childByAppendingPath:@"users"]
          childByAppendingPath:self.userId] setValue:self.currentUserInfo];
    }
}

@end
