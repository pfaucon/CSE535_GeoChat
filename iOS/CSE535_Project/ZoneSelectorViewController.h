//
//  ZoneSelectorViewController.h
//  CSE535_Project
//
//  Created by PFaucon on 12/9/14.
//  Copyright (c) 2014 Paper Scissors, Rocks!. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ZoneSelectorViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) IBOutlet UITableView *zonesTable;
@end
