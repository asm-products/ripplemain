//
//  MFRMessageBubbleView.m
//  Ripple
//
//  Created by Ed Rex on 28/02/2014.
//  Copyright (c) 2014 Ed Rex. All rights reserved.
//

#import "MFRMessageBubbleView.h"

@implementation MFRMessageBubbleView {
    
    BOOL _fromUser;
}

- (id)initWithFrame:(CGRect)frame fromUser:(BOOL)fromUser
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.backgroundColor = [UIColor clearColor];
        _fromUser = fromUser;
    }
    return self;
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    CGContextRef context=UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(context, .5f);
    CGContextSetStrokeColorWithColor(context, [UIColor lightGrayColor].CGColor);
    CGContextSetRGBFillColor(context, 1, 1, 1, 1);
    
    CGRect rrect = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
    rrect.origin.y++;
    CGFloat radius = 10;
    
    CGFloat minx = CGRectGetMinX(rrect), midx = CGRectGetMidX(rrect), maxx = CGRectGetMaxX(rrect);
    CGFloat miny = CGRectGetMinY(rrect), midy = CGRectGetMidY(rrect), maxy = CGRectGetMaxY(rrect);
    
    CGMutablePathRef outlinePath = CGPathCreateMutable();
    
    if (!_fromUser)
    {
        minx += 5;
        
        CGPathMoveToPoint(outlinePath, nil, midx, miny);
        CGPathAddArcToPoint(outlinePath, nil, maxx, miny, maxx, midy, radius);
        CGPathAddArcToPoint(outlinePath, nil, maxx, maxy, midx, maxy, radius);
        CGPathAddArcToPoint(outlinePath, nil, minx, maxy, minx, midy, radius);
        CGPathAddLineToPoint(outlinePath, nil, minx, miny + 20);
        CGPathAddLineToPoint(outlinePath, nil, minx - 5, miny + 15);
        CGPathAddLineToPoint(outlinePath, nil, minx, miny + 10);
        CGPathAddArcToPoint(outlinePath, nil, minx, miny, midx, miny, radius);
        CGPathCloseSubpath(outlinePath);
        
//        CGContextSetShadowWithColor(context, CGSizeMake(0,1), 1, [UIColor lightGrayColor].CGColor);
        CGContextAddPath(context, outlinePath);
        CGContextFillPath(context);
        
        CGContextAddPath(context, outlinePath);
        CGContextClip(context);
        CGPoint start = CGPointMake(rect.origin.x, rect.origin.y);
        CGPoint end = CGPointMake(rect.origin.x, rect.size.height);
        CGContextDrawLinearGradient(context, [self gradientWithFirstColor:[UIColor colorWithRed:155/255.0 green:89/255.0 blue:182/255.0 alpha:1.0] secondColor:[UIColor colorWithRed:142/255.0 green:68/255.0 blue:173/255.0 alpha:1.0]], start, end, 0);
    }
    else
    {
        maxx-=5;
        CGPathMoveToPoint(outlinePath, nil, midx, miny);
        CGPathAddArcToPoint(outlinePath, nil, minx, miny, minx, midy, radius);
        CGPathAddArcToPoint(outlinePath, nil, minx, maxy, midx, maxy, radius);
        CGPathAddArcToPoint(outlinePath, nil, maxx, maxy, maxx, midy, radius);
        CGPathAddLineToPoint(outlinePath, nil, maxx, miny + 20);
        CGPathAddLineToPoint(outlinePath, nil, maxx + 5, miny + 15);
        CGPathAddLineToPoint(outlinePath, nil, maxx, miny + 10);
        CGPathAddArcToPoint(outlinePath, nil, maxx, miny, midx, miny, radius);
        CGPathCloseSubpath(outlinePath);
        
//        CGContextSetShadowWithColor(context, CGSizeMake(0,1), 1, [UIColor lightGrayColor].CGColor);
        CGContextAddPath(context, outlinePath);
        CGContextFillPath(context);
        
        CGContextAddPath(context, outlinePath);
        CGContextClip(context);
        CGPoint start = CGPointMake(rect.origin.x, rect.origin.y);
        CGPoint end = CGPointMake(rect.origin.x, rect.size.height);
//        CGContextDrawLinearGradient(context, [self greenGradient], start, end, 0);
        CGContextDrawLinearGradient(context, [self gradientWithFirstColor:[UIColor colorWithRed:52/255.0 green:152/255.0 blue:219/255.0 alpha:1.0] secondColor:[UIColor colorWithRed:41/255.0 green:128/255.0 blue:185/255.0 alpha:1.0]], start, end, 0);
    }
    
    CGContextDrawPath(context, kCGPathFillStroke);
    
}

- (CGGradientRef)gradientWithFirstColor:(UIColor*)firstColor secondColor:(UIColor*)secondColor
{
    
    NSMutableArray *normalGradientLocations = [NSMutableArray arrayWithObjects:
                                               [NSNumber numberWithFloat:0.0f],
                                               [NSNumber numberWithFloat:1.0f],
                                               nil];
    
    
    NSMutableArray *colors = [NSMutableArray arrayWithCapacity:2];
    
    [colors addObject:(id)[firstColor CGColor]];
    [colors addObject:(id)[secondColor CGColor]];
    NSMutableArray  *normalGradientColors = colors;
    
    NSInteger locCount = [normalGradientLocations count];
    CGFloat locations[locCount];
    for (int i = 0; i < [normalGradientLocations count]; i++)
    {
        NSNumber *location = [normalGradientLocations objectAtIndex:i];
        locations[i] = [location floatValue];
    }
    CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
    
    CGGradientRef normalGradient = CGGradientCreateWithColors(space, (__bridge CFArrayRef)normalGradientColors, locations);
    CGColorSpaceRelease(space);
    
    return normalGradient;
}

@end
