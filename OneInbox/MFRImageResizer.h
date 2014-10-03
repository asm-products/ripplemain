//
//  MFRImageResizer.h
//  Ripple
//
//  Created by Ed Rex on 03/03/2014.
//  Copyright (c) 2014 Ed Rex. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MFRImageResizer : NSObject

+(UIImage*)resizeAndCropImage:(UIImage*)originalImage toSize:(CGSize)newSize;
+(UIImage*)scaleShorterDimensionOfImage:(UIImage*)image toSize:(CGSize)newSize;
+(UIImage*)imageByCropping:(UIImage *)image toSize:(CGSize)size;

@end
