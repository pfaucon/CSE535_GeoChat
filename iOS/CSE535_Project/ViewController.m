//
//  ViewController.m
//  CSE535_Project
//
//  Created by John Yu on 10/26/14.
//  Copyright (c) 2014 Paper Scissors, Rocks!. All rights reserved.
//

#import "ViewController.h"
#import <Firebase/Firebase.h>
#import "AppDelegate.h"


@interface ViewController ()
{
    UIActivityIndicatorView *spinner;
}

@property (atomic) NSNumber *dataReady;
@property (atomic) NSNumber *dataProcessed;

@property (nonatomic) NSMutableArray *messagesArray;
@property Firebase *db;
@property AppDelegate *delegate;
@property (readonly) CLLocationManager *locationManager;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    //get a reference to the app delegate
    self.delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    // Create a reference to a Firebase location
    self.db = [[Firebase alloc] initWithUrl:@"https://cse535-project.firebaseio.com/"];
    [[[self.db childByAppendingPath:@"users"]
      childByAppendingPath:self.delegate.userId] setValue:self.delegate.currentUserInfo];
    
    // Initialize the spinner.
    spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    spinner.color = [UIColor grayColor];
    
    spinner.center = CGPointMake(self.view.frame.size.width/2, self.view.frame.size.height/2);
    spinner.hidesWhenStopped = YES;
    [self.view addSubview:spinner];
    
    [spinner startAnimating];
    [self loadMessage];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.title = self.zone;
}

- (void)loadMessage
{
    FQuery *query = [self.db childByAppendingPath:kMessageDirectory];
    
    [query observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *snapshot) {
        
        if(snapshot.hasChildren == NO) return;
        
        // Retrieving data from
        // for(FDataSnapshot *obj in snapshot.children)
        //{
        if([snapshot.value[@"zone"] isEqualToString:self.zone])
            [self.messagesArray addObject:snapshot.value];
        //}
        //we finished our part
        @synchronized(self.dataReady)
        {
            self.dataReady = [NSNumber numberWithBool:YES];
        }
        
        //if the location is also ready then we can process the results
        @synchronized(self.dataProcessed)
        {
            //if data was processed then we probably just got an update, so it doesn't matter
            [self processMessages];
        }
    } withCancelBlock:^(NSError *error) {
        NSLog(@"%@", error.description);
    }];
}

- (IBAction)postMessage:(id)sender {
    
    NSMutableDictionary *message = [[NSMutableDictionary alloc] init];
    
    // Saving the location
    NSNumber *lon = [[NSNumber alloc] initWithDouble:self.locationManager.location.coordinate.longitude];
    NSNumber *lat = [[NSNumber alloc] initWithDouble:self.locationManager.location.coordinate.latitude];
    message[@"lat"] = lat;
    message[@"lon"] = lon;
    
    // Saving the message
    message[@"message"] = self.messageTextField.text;
    message[@"timestamp"] = [[NSDate new] description];
    message[@"username"] = self.delegate.currentUserInfo[@"email"];
    message[@"zone"] = self.zone;
    
    //get a messageID
    Firebase *messageRef = [[self.db childByAppendingPath:kMessageDirectory] childByAutoId];
    
    // Putting it up to Firebase
    [messageRef setValue:message];
    
}



#pragma mark - Data processing

//careful with future updates here, we're holding mutexes
-(void)processMessages
{
    self.messagesArray = [self postsFromArray:self.messagesArray InRangeOfLocation:self.locationManager.location];
    self.dataProcessed = [NSNumber numberWithBool:YES];
    [spinner stopAnimating];
    [self.messageTable reloadData];
    [self.messageTextField resignFirstResponder];
    self.messageTextField.text = @"";
}

//this should be a dictionary of JSON-parsed posts (should have a key location with lat/lon children)
-(NSMutableArray *)postsFromArray:(NSArray *)arr InRangeOfLocation:(CLLocation *)location
{
    NSMutableArray *ret = [arr mutableCopy];
    NSMutableIndexSet *indexes = [NSMutableIndexSet new];
    
    [ret enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSDictionary *post = ret[idx];
        float lat = ((NSNumber *)post[@"lat"]).floatValue;
        float lon = ((NSNumber *)post[@"lon"]).floatValue;
        CLLocation *postLocation = [[CLLocation alloc] initWithLatitude:lat longitude:lon];
        
        //distance in meters
        CLLocationDistance distance = [location distanceFromLocation:postLocation];
        
        if (distance > 2500)
        {
            NSLog(@"removing a post at distance %f", distance);
            [indexes addIndex:idx];
        }
        
    }];
    
    //[ret removeObjectsAtIndexes:indexes]; //allow all messages in the zone that we are looking at
    return ret;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(self.messagesArray)
        return [self.messagesArray count];
    else
        return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"post" forIndexPath:indexPath];
    
    if(self.messagesArray)
    {
        cell.textLabel.text = self.messagesArray[indexPath.row][@"message"];
    }
    return cell;
}

#pragma mark - Custom getters

-(NSMutableArray *) messagesArray
{
    if(!_messagesArray) _messagesArray = [NSMutableArray new];
    return _messagesArray;
}

-(CLLocationManager *)locationManager
{
    return self.delegate.locationManager;
}

@end
