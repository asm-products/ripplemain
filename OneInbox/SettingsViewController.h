//
//  SettingsViewController.h
//  Ripple
//
//  Created by Ed Rex on 03/04/2014.
//  Copyright (c) 2014 Ed Rex. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>

@interface SettingsViewController : UIViewController <UINavigationBarDelegate, UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate, MFMailComposeViewControllerDelegate>

@property (nonatomic, retain) IBOutlet UINavigationBar* navBar;
@property (nonatomic, retain) IBOutlet UITableView* settingsTableView;

-(IBAction)dismissSettingsViewController:(id)sender;

@end
