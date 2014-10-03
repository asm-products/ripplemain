//
//  InboxCell.m
//  Ripple
//
//  Created by Ed Rex on 21/02/2014.
//  Copyright (c) 2014 Ed Rex. All rights reserved.
//

#import "InboxCell.h"

#define LABEL_X_ORIGIN 22.0
#define SENDER_LABEL_Y_ORIGIN 5.0
#define MESSAGE_LABEL_Y_ORIGIN 30.0
#define SENDER_LABEL_WIDTH 120
#define MESSAGE_LABEL_WIDTH 180
#define LABEL_HEIGHT 15.0
#define SENDING_WHEEL_X_POSITION 11
#define SENDING_WHEEL_Y_POSITION 23
#define UNREAD_DOT_X_POSITION 5

@implementation InboxCell

@synthesize senderLabel = _senderLabel;
@synthesize messageLabel = _messageLabel;
@synthesize dateLabel = _dateLabel;
@synthesize unreadImageView = _unreadImageView;
@synthesize linkImageView = _linkImageView;
@synthesize sendingWheel = _sendingWheel;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        
        // Helpers
        CGSize size = self.contentView.frame.size;
        
        // IMAGE ON RIGHT
        self.senderLabel = [[UILabel alloc] initWithFrame:CGRectMake(LABEL_X_ORIGIN, SENDER_LABEL_Y_ORIGIN, SENDER_LABEL_WIDTH, LABEL_HEIGHT)];
        self.messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(LABEL_X_ORIGIN, MESSAGE_LABEL_Y_ORIGIN, MESSAGE_LABEL_WIDTH, LABEL_HEIGHT)];
        self.dateLabel = [[UILabel alloc] initWithFrame:CGRectMake(200, SENDER_LABEL_Y_ORIGIN, size.width - 50.0, LABEL_HEIGHT)];
        self.linkImageView = [[UIImageView alloc] initWithFrame:CGRectMake(size.width - 70, 0, 70, 70)];
        
        // Configure Main Label
        [self.senderLabel setFont:[UIFont fontWithName:@"Titillium-Regular" size:16.0]];
        [self.senderLabel setTextAlignment:NSTextAlignmentLeft];
        [self.senderLabel setTextColor:[UIColor blackColor]];
        [self.senderLabel setAutoresizingMask:(UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight)];
        
        [self.messageLabel setFont:[UIFont fontWithName:@"Titillium-Regular" size:14.0]];
        [self.messageLabel setTextAlignment:NSTextAlignmentLeft];
        [self.messageLabel setTextColor:[UIColor lightGrayColor]];
        [self.messageLabel setAutoresizingMask:(UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight)];
        
        [self.dateLabel setFont:[UIFont fontWithName:@"Titillium-Regular" size:14.0]];
        [self.dateLabel setTextAlignment:NSTextAlignmentLeft];
        [self.dateLabel setTextColor:[UIColor lightGrayColor]];
        [self.dateLabel setAutoresizingMask:(UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight)];
        
        // Add Main Label to Content View
        [self.contentView addSubview:self.senderLabel];
        [self.contentView addSubview:self.messageLabel];
        [self.contentView addSubview:self.dateLabel];
        [self.contentView addSubview:self.linkImageView];
        
        // Add unread image
        UIImage* unreadIcon = [UIImage imageNamed:@"Unread"];
        _unreadImageView = [[UIImageView alloc] initWithFrame:CGRectMake(UNREAD_DOT_X_POSITION, SENDER_LABEL_Y_ORIGIN + 12, 12, 12)];
        [_unreadImageView setImage:unreadIcon];
        [self.contentView addSubview:_unreadImageView];
        _unreadImageView.hidden = YES;
        
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
        self.sendingWheel = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [self.contentView addSubview:self.sendingWheel];
        self.sendingWheel.center = CGPointMake(SENDING_WHEEL_X_POSITION, SENDING_WHEEL_Y_POSITION);
        CGAffineTransform transform = self.sendingWheel.transform;
        self.sendingWheel.transform = CGAffineTransformScale(transform, 0.75, 0.75);
        self.sendingWheel.hidden = YES;
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(void)markAsUnread:(BOOL)unread {
    if (unread) {
        _unreadImageView.hidden = NO;
    } else {
        _unreadImageView.hidden = YES;
    }
}

-(void)displayLinkImage:(UIImage*)image {
    
    self.linkImageView.image = image;
    
    self.senderLabel.frame = CGRectMake(self.senderLabel.frame.origin.x, self.senderLabel.frame.origin.y, SENDER_LABEL_WIDTH, self.senderLabel.frame.size.height);
    self.messageLabel.frame = CGRectMake(self.messageLabel.frame.origin.x, self.messageLabel.frame.origin.y, MESSAGE_LABEL_WIDTH, self.messageLabel.frame.size.height);
    
    [self setAccessoryType:UITableViewCellAccessoryNone];
}

-(void)displayFullName:(NSString*)fullName {
    self.senderLabel.text = fullName;
    self.senderLabel.textColor = [UIColor blackColor];
}

-(void)displayPlaceholderName {
    self.senderLabel.text = @"Loading...";
    self.senderLabel.textColor = [UIColor lightGrayColor];
}

-(void)removeLinkImageAndMoveText {
    
    self.linkImageView.image = nil;
    
    self.senderLabel.frame = CGRectMake(self.senderLabel.frame.origin.x, self.senderLabel.frame.origin.y, SENDER_LABEL_WIDTH + 70.0, self.senderLabel.frame.size.height);
    self.messageLabel.frame = CGRectMake(self.messageLabel.frame.origin.x, self.messageLabel.frame.origin.y, MESSAGE_LABEL_WIDTH + 70.0, self.messageLabel.frame.size.height);
    
    [self setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
}

-(void)setSendingStatus:(MFRLocalMessageStatus)sendingStatus {
    
    UIColor* messageTextColor;
    
    if (sendingStatus == MFRLocalMessageStatusSendingFailed) {
        // Mark as sending failed
        self.messageLabel.text = @"Sending failed";
        messageTextColor = [UIColor redColor];
    } else {
        messageTextColor = [UIColor lightGrayColor];
    }
    
    if (sendingStatus == MFRLocalMessageStatusSending) {
        // Mark as sending
        self.messageLabel.text = @"Sending...";
        [self showSendingWheel:YES];
    } else {
        [self showSendingWheel:NO];
    }
    
    [self.messageLabel setTextColor:messageTextColor];
}

-(void)showSendingWheel:(BOOL)show {
    self.sendingWheel.hidden = !show;
    if (show) {
        [self.sendingWheel startAnimating];
    } else {
        [self.sendingWheel stopAnimating];
    }
}

@end
