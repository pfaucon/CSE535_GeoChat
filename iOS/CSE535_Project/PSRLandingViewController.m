//
//  PSRLandingViewController.m
//  PaperScissorsRock
//
//  Created by PFaucon on 9/17/14.
//  Copyright (c) 2014 Team Roflcopter. All rights reserved.
//

#import "PSRLandingViewController.h"
#import "AppDelegate.h"
#import <Firebase/Firebase.h>

@interface PSRLandingViewController ()
@property (weak, nonatomic) IBOutlet UIButton *gameOnButton;

@property (weak, nonatomic) IBOutlet UITextField *loginUsernameField;
@property (weak, nonatomic) IBOutlet UITextField *loginPasswordTextField;

@property (weak, nonatomic) IBOutlet UITextField *signupUsernameTextField;
@property (weak, nonatomic) IBOutlet UITextField *signupPasswordTextField;

@property (weak, nonatomic) IBOutlet UIButton *signUpButton;

@property Firebase *db;
@end

@implementation PSRLandingViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.gameOnButton.enabled = NO;
    self.signUpButton.enabled = NO;
    
    self.db = [[Firebase alloc] initWithUrl:@"https://cse535-project.firebaseio.com/"];
}

- (IBAction)gameOn:(id)sender {
  
    [self.db authUser:self.loginUsernameField.text password:self.loginPasswordTextField.text withCompletionBlock:^(NSError *error, FAuthData *authData) {
        if (error) {
            // an error occurred while attempting login
            NSLog(@"%s, %@",__FUNCTION__,error);
            [[[UIAlertView alloc] initWithTitle:@"Error" message:@"Login failed D:" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
        } else {
            // user is logged in, check authData for data
            
            AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
            appDelegate.currentUserInfo = @{
                                            @"provider": authData.provider,
                                            @"email": authData.providerData[@"email"]
                                            };
            appDelegate.userId = authData.uid;
            
            [self performSegueWithIdentifier:@"segueToChat" sender:self];
        }
    }];

}

- (IBAction)signUpPressed:(id)sender {
    [self.db createUser:self.signupUsernameTextField.text password:self.signupPasswordTextField.text withCompletionBlock:^(NSError *error) {
        if(error){
            NSLog(@"%s, %@",__FUNCTION__,error);
            [[[UIAlertView alloc] initWithTitle:@"Error" message:@"Signup failed D:" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
        } else {
            
            [self performSegueWithIdentifier:@"segueToChat" sender:self];
        }
    }];
}

- (IBAction)fieldUpdatedContents:(id)sender
{
    if(self.signupUsernameTextField.text.length >0 && self.signupPasswordTextField.text.length>0)
    {
        self.signUpButton.enabled = YES;
    }
    else
    {
        self.signUpButton.enabled = NO;
    }
    
    if (self.loginUsernameField.text.length>0 && self.loginPasswordTextField.text.length>0) {
        self.gameOnButton.enabled = YES;
    } else {
        self.gameOnButton.enabled = NO;
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    [self fieldUpdatedContents:textField];
    return YES;
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.view endEditing:YES];
    [super touchesBegan:touches withEvent:event];
}

@end
