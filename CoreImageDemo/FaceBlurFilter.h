//
//  FaceBlurFilter.h
//  CoreImageDemo
//
//  Created by Andhieka Putra on 20/10/15.
//  Copyright © 2015 Andhieka Putra. All rights reserved.
//

@import CoreImage;

@interface FaceBlurFilter : CIFilter

@property (nonatomic, strong) CIImage *inputImage;

@end
