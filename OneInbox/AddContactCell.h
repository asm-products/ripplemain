//
//  AddContactCell.h
//  Ripple
//
//  Created by Ed Rex on 04/03/2014.
//  Copyright (c) 2014 Ed Rex. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol AddContactCellDelegate
-(void)addContactAtIndex:(NSInteger)index;
@end

@interface AddContactCell : UITableViewCell {
    
    @public
    id <AddContactCellDelegate> delegate;
    NSInteger _index;
}

@property (nonatomic, retain) UILabel* usernameLabel;
@property (nonatomic, retain) UIButton* addButton;
@property (nonatomic, retain) UIButton* isContactButton;
@property (nonatomic, retain) UIButton* pendingButton;

-(void)displayIsContactButton;
-(void)displayAddContactButton;
-(void)displayPendingButton;

@end
