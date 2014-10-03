//
//  MFRImageResizer.m
//  Ripple
//
//  Created by Ed Rex on 03/03/2014.
//  Copyright (c) 2014 Ed Rex. All rights reserved.
//

#import "MFRImageResizer.h"

@implementation MFRImageResizer

+(UIImage*)resizeAndCropImage:(UIImage*)originalImage toSize:(CGSize)newSize {
    
    UIImage* resizedImage = [MFRImageResizer scaleShorterDimensionOfImage:originalImage toSize:newSize];
    
    UIImage* croppedImage = [MFRImageResizer imageByCropping:resizedImage toSize:newSize];
    
    return croppedImage;
}

// Reducing an image (600 * 300) to a size (200 * 200) will return an image (400 * 200)
+(UIImage*)scaleShorterDimensionOfImage:(UIImage*)image toSize:(CGSize)newSize {
    
    CGSize scaledSize;
    if (image.size.width > image.size.height) {
        // Resize to height of link image view
        scaledSize = CGSizeMake(image.size.width / (image.size.height/newSize.height), newSize.height);
    } else {
        // Resize to width of link image view
        scaledSize = CGSizeMake(newSize.width, image.size.height / (image.size.width/newSize.width));
    }
    
    CGRect newRect = CGRectIntegral(CGRectMake(0, 0, scaledSize.width, scaledSize.height));
    CGImageRef imageRef = image.CGImage;
    
    UIGraphicsBeginImageContextWithOptions(scaledSize, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // Set the quality level to use when rescaling
    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
    CGAffineTransform flipVertical = CGAffineTransformMake(1, 0, 0, -1, 0, scaledSize.height);
    
    CGContextConcatCTM(context, flipVertical);
    // Draw into the context; this scales the image
    CGContextDrawImage(context, newRect, imageRef);
    
    // Get the resized image from the context and a UIImage
    CGImageRef newImageRef = CGBitmapContextCreateImage(context);
    UIImage *newImage = [UIImage imageWithCGImage:newImageRef];
    
    CGImageRelease(newImageRef);
    UIGraphicsEndImageContext();
    
    return newImage;
}

+(UIImage*)imageByCropping:(UIImage *)image toSize:(CGSize)size
{
    CGRect cropRect;
    if (image.size.width > image.size.height) {
        int sideLength = image.size.height;
        cropRect = CGRectMake((image.size.width - sideLength) / 2, 0, sideLength, sideLength);
    } else {
        int sideLength = image.size.width;
        cropRect = CGRectMake(0, (image.size.height - sideLength) / 2, sideLength, sideLength);
    }
    
    CGImageRef imageRef = CGImageCreateWithImageInRect([image CGImage], cropRect);
    
    UIImage *cropped = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    
    return cropped;
}



@end
