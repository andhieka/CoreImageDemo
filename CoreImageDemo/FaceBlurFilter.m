//
//  FaceBlurFilter.m
//  CoreImageDemo
//
//  Created by Andhieka Putra on 20/10/15.
//  Copyright © 2015 Andhieka Putra. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "FaceBlurFilter.h"

@implementation FaceBlurFilter

- (CIImage *)outputImage {
    CIImage *faceMaskLayer = [self faceMaskLayer];
    CIFilter *blendFilter = [CIFilter filterWithName:@"CIBlendWithMask"];
    [blendFilter setValue:faceMaskLayer forKey:kCIInputMaskImageKey];
    [blendFilter setValue:[self pixellatedImage] forKey:kCIInputImageKey];
    [blendFilter setValue:self.inputImage forKey:kCIInputBackgroundImageKey];
    return [blendFilter outputImage];
}

- (CIImage *)pixellatedImage {
    CIImage *result = self.inputImage;
    CGFloat pixellateRadius = MAX(result.extent.size.height, result.extent.size.width) / 50;
    
    CIFilter *pixellateFilter = [CIFilter filterWithName:@"CIPixellate"];
    [pixellateFilter setValue:result forKey:kCIInputImageKey];
    [pixellateFilter setValue:[NSNumber numberWithFloat:pixellateRadius] forKey:kCIInputScaleKey];
    result = pixellateFilter.outputImage;
    
    return result;
}

- (CIImage *)faceMaskLayer {
    CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeFace
                                              context:nil
                                              options:nil];
    NSArray *faceArray = [detector featuresInImage:self.inputImage options:nil];
    
    // Create a green circle to cover the rects that are returned.
    
    CIImage *maskImage = nil;
    
    for (CIFeature *f in faceArray) {
        CGFloat centerX = f.bounds.origin.x + f.bounds.size.width / 2.0;
        CGFloat centerY = f.bounds.origin.y + f.bounds.size.height / 2.0;
        CGFloat radius = MIN(f.bounds.size.width, f.bounds.size.height) / 1.5;
        
        CIFilter *radialGradient = [CIFilter filterWithName:@"CIRadialGradient" keysAndValues:
                                    @"inputRadius0", @(radius),
                                    @"inputRadius1", @(radius + 1.0f),
                                    @"inputColor0", [CIColor colorWithRed:0.0 green:1.0 blue:0.0 alpha:1.0],
                                    @"inputColor1", [CIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.0],
                                    kCIInputCenterKey, [CIVector vectorWithX:centerX Y:centerY],
                                    nil];
        CIImage *circleImage = [radialGradient valueForKey:kCIOutputImageKey];
        if (maskImage == nil) {
            maskImage = circleImage;
        } else {
            maskImage = [CIFilter filterWithName:@"CISourceOverCompositing" keysAndValues:
                          kCIInputImageKey, circleImage,
                          kCIInputBackgroundImageKey, maskImage,
                          nil].outputImage;
        }
    }
    
    return maskImage;
}

@end