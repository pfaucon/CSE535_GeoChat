//
//  ViewController.m
//  CSE535_Project
//
//  Created by John Yu on 10/26/14.
//  Copyright (c) 2014 Paper Scissors, Rocks!. All rights reserved.
//

#import "ZoneSelectorViewController.h"
#import <Firebase/Firebase.h>
#import "AppDelegate.h"
#import "ViewController.h"


@interface ZoneSelectorViewController ()
{
    UIActivityIndicatorView *spinner;
}

@property (atomic) NSNumber *dataReady;
@property (atomic) NSNumber *dataProcessed;

@property (nonatomic) NSMutableArray *zonesArray;
@property Firebase *db;
@property AppDelegate *delegate;
@property (readonly) CLLocationManager *locationManager;

@end

@implementation ZoneSelectorViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    //get a reference to the app delegate
    self.delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    // Create a reference to a Firebase location
    self.db = [[Firebase alloc] initWithUrl:@"https://cse535-project.firebaseio.com/"];
    
    // Initialize the spinner.
    spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    spinner.color = [UIColor grayColor];
    
    spinner.center = CGPointMake(self.view.frame.size.width/2, self.view.frame.size.height/2);
    spinner.hidesWhenStopped = YES;
    [self.view addSubview:spinner];
    
    [spinner startAnimating];
    [self loadZones];
}

- (void)loadZones
{
    FQuery *query = [self.db childByAppendingPath:kZonesDirectory];
    
    [query observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *snapshot) {
        
        if(snapshot.hasChildren == NO) return;
        
        // Retrieving data from
        // for(FDataSnapshot *obj in snapshot.children)
        //{
        [self.zonesArray addObject:snapshot.key];
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




#pragma mark - Data processing

//careful with future updates here, we're holding mutexes
-(void)processMessages
{
    self.zonesArray = self.zonesArray;
    self.dataProcessed = [NSNumber numberWithBool:YES];
    [spinner stopAnimating];
    [self.zonesTable reloadData];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(self.zonesArray)
    return [self.zonesArray count];
    else
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"post" forIndexPath:indexPath];
    
    if(self.zonesArray)
    {
        cell.textLabel.text = self.zonesArray[indexPath.row];
    }
    return cell;
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // tell the message poster which zone it should be posting to
    ViewController *dest = segue.destinationViewController;
    dest.zone = self.zonesArray[self.zonesTable.indexPathForSelectedRow.row];
}

#pragma mark - Custom getters

-(NSMutableArray *) zonesArray
{
    if(!_zonesArray) _zonesArray = [NSMutableArray new];
    return _zonesArray;
}

-(CLLocationManager *)locationManager
{
    return self.delegate.locationManager;
}

@end
