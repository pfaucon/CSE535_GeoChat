//
//  ViewController.m
//  CSE535_Project
//
//  Created by John Yu on 10/26/14.
//  Copyright (c) 2014 Paper Scissors, Rocks!. All rights reserved.
//

#import "ViewController.h"
#import <Firebase/Firebase.h>

@interface ViewController ()
{
    Firebase *db;
    CLLocationManager *locManager;
    NSDictionary *messages;
    NSArray *messagesArray;
    UIActivityIndicatorView *spinner;
}

@property (atomic) NSNumber *dataReady;
@property (atomic) NSNumber *locationReady;
@property (atomic) NSNumber *dataProcessed;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // Create a reference to a Firebase location
    db = [[Firebase alloc] initWithUrl:@"https://cse535-project.firebaseio.com/"];
    
    // Init location manager
    locManager = [[CLLocationManager alloc] init];
    [locManager requestWhenInUseAuthorization];
    locManager.delegate = self;
    locManager.desiredAccuracy = kCLLocationAccuracyBest;
    [locManager startUpdatingLocation];
    
    // Initialize the spinner.
    spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    spinner.color = [UIColor grayColor];
    
    spinner.center = CGPointMake(self.view.frame.size.width/2, self.view.frame.size.height/2);
    spinner.hidesWhenStopped = YES;
    [self.view addSubview:spinner];
    
    [spinner startAnimating];
    [self loadMessage];
}

- (void)loadMessage
{
    // Attach a block to read the data at our posts reference
    [db observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        // Retrieving data from
        messages = snapshot.value;
        messagesArray = [messages allKeys];
        
        //we finished our part
        @synchronized(self.dataReady)
        {
            self.dataReady = [NSNumber numberWithBool:YES];
        }
        
        //if the location is also ready then we can process the results
        @synchronized(self.dataProcessed)
        {
            //if data was processed then we probably just got an update, so it doesn't matter
            
            @synchronized(self.locationReady)
            {
                //if the location has been loaded we can process messages!
                if(self.locationReady)
                {
                    [self processMessages];
                }
            }
        }
        
    } withCancelBlock:^(NSError *error) {
        NSLog(@"%@", error.description);
    }];
}

- (IBAction)postMessage:(id)sender {
    
    NSMutableDictionary *message = [[NSMutableDictionary alloc] init];
    
    // Saving the location
    NSNumber *lon = [[NSNumber alloc] initWithDouble:locManager.location.coordinate.longitude];
    NSNumber *lat = [[NSNumber alloc] initWithDouble:locManager.location.coordinate.latitude];
    NSDictionary *location = @{@"lon":lon,
                               @"lat":lat};
    
    [message setObject:location forKey:@"location"];
    
    // Saving the message
    [message setObject:self.messageTextField.text forKey:@"message"];
    
    Firebase *messageRef = [db childByAutoId];
    
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
    
    if (newLocation != nil) {
        
        //we finished our part
        @synchronized(self.locationReady)
        {
            self.locationReady = [NSNumber numberWithBool:YES];
        }
        
        //if the location is also ready then we can process the results
        @synchronized(self.dataProcessed)
        {
            //if data was processed then we probably just got an update, so it doesn't matter
            
            @synchronized(self.dataReady)
            {
                //if the location has been loaded we can process messages!
                if(self.dataReady)
                {
                    [self processMessages];
                }
            }
        }
    }
    
}

#pragma mark - Data processing

//careful with future updates here, we're holding mutexes
-(void)processMessages
{
    messages = [self postsFromArray:messages InRangeOfLocation:locManager.location];
    self.dataProcessed = [NSNumber numberWithBool:YES];
    [spinner stopAnimating];
    [self.messageTable reloadData];
}

//this should be a dictionary of JSON-parsed posts (should have a key location with lat/lon children)
-(NSDictionary *)postsFromArray:(NSDictionary *)dict InRangeOfLocation:(CLLocation *)location
{
    NSMutableDictionary *ret = [dict mutableCopy];
    for(NSString *key in dict)
    {
        NSDictionary *post = dict[key];
        float lat = ((NSNumber *)post[@"location"][@"lat"]).floatValue;
        float lon = ((NSNumber *)post[@"location"][@"lon"]).floatValue;
        CLLocation *postLocation = [[CLLocation alloc] initWithLatitude:lat longitude:lon];
        
        //distance in meters
        CLLocationDistance distance = [location distanceFromLocation:postLocation];
        
        if (distance > 2500)
        {
            NSLog(@"removing key %@, distance %f",key, distance);
            [ret removeObjectForKey:key];
        }
    }
    
    return ret;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [messages count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"post" forIndexPath:indexPath];
    
    if(messages != nil)
    {
        cell.textLabel.text = [messages objectForKey:[messagesArray objectAtIndex:indexPath.row]][@"message"];
    }
    
    return cell;
}

@end
