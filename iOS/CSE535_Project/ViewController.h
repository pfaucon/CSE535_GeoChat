//
//  ViewController.h
//  CSE535_Project
//
//  Created by John Yu on 10/26/14.
//  Copyright (c) 2014 Paper Scissors, Rocks!. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@interface ViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, CLLocationManagerDelegate>

@property (strong, nonatomic) IBOutlet UITextField *messageTextField;
@property (strong, nonatomic) IBOutlet UITableView *messageTable;

- (IBAction)postMessage:(id)sender;

@end

