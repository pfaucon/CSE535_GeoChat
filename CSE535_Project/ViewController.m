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
    
    // Initialize the spinner.
    spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    spinner.color = [UIColor grayColor];
    
    spinner.center = CGPointMake(self.view.frame.size.width/2, self.view.frame.size.height/2);
    spinner.hidesWhenStopped = YES;
    [self.view addSubview:spinner];
    
    [spinner startAnimating];
    [self loadMessage];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

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

- (void)loadMessage
{
    // Attach a block to read the data at our posts reference
    [db observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        // Retrieving data from
        messages = snapshot.value;
        
#warning Need to fix this logic, it's trying to catch the the run-time error if no items exists on Firebase but does not work
        if(messages != [NSNull null] || [messages count] > 0)
        {
            messagesArray = [messages allKeys];
            [spinner stopAnimating];
            [self.messageTable reloadData];
        }
        
    } withCancelBlock:^(NSError *error) {
        NSLog(@"%@", error.description);
    }];
    
}

- (IBAction)postMessage:(id)sender {
    locManager.delegate = self;
    locManager.desiredAccuracy = kCLLocationAccuracyBest;
    [locManager startUpdatingLocation];
    
    [locManager startUpdatingLocation];
}

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
        NSMutableDictionary *message = [[NSMutableDictionary alloc] init];
        
        // Saving the location
        NSNumber *lon = [[NSNumber alloc] initWithDouble:newLocation.coordinate.longitude];
        NSNumber *lat = [[NSNumber alloc] initWithDouble:newLocation.coordinate.latitude];
        NSDictionary *location = @{@"lon":lon,
                                   @"lat":lat};
        
        [message setObject:location forKey:@"location"];
        
        // Saving the message
        [message setObject:self.messageTextField.text forKey:@"message"];
        
        Firebase *messageRef = [db childByAutoId];
        
        // Putting it up to Firebase
        [messageRef setValue:message];
        [locManager stopUpdatingLocation];
    }
    
    [locManager stopUpdatingLocation];
}
@end
