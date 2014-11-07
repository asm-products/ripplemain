//
//  AddContactCell.m
//  Ripple
//
//  Created by Ed Rex on 04/03/2014.
//  Copyright (c) 2014 Ed Rex. All rights reserved.
//

#import "AddContactCell.h"

#define LABEL_X_ORIGIN 22.0
#define LABEL_Y_ORIGIN 14.0
#define LABEL_WIDTH 210
#define LABEL_HEIGHT 15.0
#define ADDBUTTON_X_POSITION 260
#define ADDBUTTON_Y_POSITION 6.0
#define ADDBUTTON_WIDTH 40.0
#define ADDBUTTON_HEIGHT 32.0

@implementation AddContactCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        
        self.usernameLabel = [[UILabel alloc] initWithFrame:CGRectMake(LABEL_X_ORIGIN, LABEL_Y_ORIGIN, LABEL_WIDTH, LABEL_HEIGHT)];
        
        // Configure Main Label
        [self.usernameLabel setFont:[UIFont fontWithName:@"Titillium-Regular" size:16.0]];
        [self.usernameLabel setTextAlignment:NSTextAlignmentLeft];
        [self.usernameLabel setTextColor:[UIColor blackColor]];
        [self.usernameLabel setAutoresizingMask:(UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight)];
        
        self.addButton = [[UIButton alloc] initWithFrame:CGRectMake(ADDBUTTON_X_POSITION, ADDBUTTON_Y_POSITION, ADDBUTTON_WIDTH, ADDBUTTON_HEIGHT)];
        [self.addButton setBackgroundImage:[UIImage imageNamed:@"AddUser"] forState:UIControlStateNormal];
        [self.addButton addTarget:self action:@selector(addButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        
        self.isContactButton = [[UIButton alloc] initWithFrame:CGRectMake(ADDBUTTON_X_POSITION, ADDBUTTON_Y_POSITION, ADDBUTTON_WIDTH, ADDBUTTON_HEIGHT)];
        [self.isContactButton setBackgroundImage:[UIImage imageNamed:@"UserAdded"] forState:UIControlStateNormal];
        [self.isContactButton addTarget:self action:@selector(isContactButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        
        self.pendingButton = [[UIButton alloc] initWithFrame:CGRectMake(ADDBUTTON_X_POSITION, ADDBUTTON_Y_POSITION, ADDBUTTON_WIDTH, ADDBUTTON_HEIGHT)];
        [self.pendingButton setBackgroundImage:[UIImage imageNamed:@"PendingUser"] forState:UIControlStateNormal];
        [self.pendingButton addTarget:self action:@selector(pendingButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        
        // Add UI elements to Content View
        [self.contentView addSubview:self.usernameLabel];
        [self.contentView addSubview:self.addButton];
        [self.contentView addSubview:self.isContactButton];
        [self.contentView addSubview:self.pendingButton];
        
        self.addButton.hidden = YES;
        self.isContactButton.hidden = YES;
        self.pendingButton.hidden = YES;
        
        self.accessoryType = UITableViewCellAccessoryNone;
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

#pragma mark - Add button
-(void)addButtonPressed {
    [delegate addContactAtIndex:_index];
}

-(void)isContactButtonPressed {
    // Remove friend
    // ...
}

-(void)pendingButtonPressed {
    // Retrace friend request
    // ...
}

-(void)displayIsContactButton {
    _addButton.hidden = YES;
    _isContactButton.hidden = NO;
    _pendingButton.hidden = YES;
}

-(void)displayAddContactButton {
    _addButton.hidden = NO;
    _isContactButton.hidden = YES;
    _pendingButton.hidden = YES;
}

-(void)displayPendingButton {
    _addButton.hidden = YES;
    _isContactButton.hidden = YES;
    _pendingButton.hidden = NO;
}

@end
