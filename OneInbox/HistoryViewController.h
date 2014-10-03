//
//  HistoryViewController.h
//  Frisbee
//
//  Created by Ed Rex on 12/02/2014.
//  Copyright (c) 2014 Ed Rex. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HistoryViewController : UIViewController<UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, retain) IBOutlet UITableView* historyTableView;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView* sendingWheel;
@property (nonatomic, retain) IBOutlet UILabel* sendingLabel;

-(IBAction)pushInboxViewController;

-(void)displaySending;
-(void)informSuccess:(NSNumber*)success;

@end
