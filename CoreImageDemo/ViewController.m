//
//  ViewController.m
//  CoreImageDemo
//
//  Created by Andhieka Putra on 20/10/15.
//  Copyright © 2015 Andhieka Putra. All rights reserved.
//

@import CoreImage;

#import "ViewController.h"
#import "FaceBlurFilter.h"


@interface ViewController ()

@property (strong, nonatomic) EAGLContext *eaglContext;
@property (strong, nonatomic) CIContext *context;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) CIImage *originalImage;
@property (assign, nonatomic) BOOL isBlurActive;
@property (assign, nonatomic) CGPoint lastPanPoint;
@property (assign, nonatomic) CGFloat currentBrightness;
@property (assign, nonatomic) CGFloat previewBrightness;
@property (assign, nonatomic) BOOL isRendering;
@property (strong, nonatomic) CIImage *lastFrame;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _eaglContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    _context = [CIContext contextWithEAGLContext:_eaglContext
                                         options:@{
                                                   kCIContextWorkingColorSpace: [NSNull null]
                                                   }];
    _originalImage = [CIImage imageWithCGImage:[UIImage imageNamed:@"family"].CGImage];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapImageView:)];
    tapGesture.numberOfTapsRequired = 2;
    [self.imageView addGestureRecognizer:tapGesture];
    
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(didPanImageView:)];
    [self.imageView addGestureRecognizer:panGesture];
    
    _isBlurActive = NO;
    _lastPanPoint = CGPointZero;
    _currentBrightness = 0.0;
    _previewBrightness = 0.0;
    _isRendering = NO;
    _lastFrame = nil;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self processAndRenderImage];
}

- (void)didPanImageView:(UIPanGestureRecognizer *)sender {
    CGPoint touchPoint = [sender translationInView:self.imageView];
    if (sender.state == UIGestureRecognizerStateBegan) {
        _lastPanPoint = touchPoint;
    } else if (sender.state == UIGestureRecognizerStateChanged) {
        CGFloat deltaX = touchPoint.x - _lastPanPoint.x;
        self.previewBrightness = MAX(-1.0, MIN(1.0, self.currentBrightness + [self scaleBrightness:deltaX]));
    } else if (sender.state == UIGestureRecognizerStateEnded) {
        _lastPanPoint = CGPointZero;
        self.currentBrightness = self.previewBrightness;
    }
    [self processAndRenderImage];
}

- (void)didTapImageView:(UITapGestureRecognizer *)sender {
    _isBlurActive = !_isBlurActive;
    [self processAndRenderImage];
}

- (CGFloat)scaleBrightness:(CGFloat)deltaX {
    return (deltaX / 300.0);
}

- (void)processAndRenderImage {
    CIImage *result = self.originalImage;
    
    // apply face blur effect if activated and if brightness is not being adjusted
    if (CGPointEqualToPoint(self.lastPanPoint, CGPointZero) && self.isBlurActive) {
        FaceBlurFilter *faceBlurFilter = [[FaceBlurFilter alloc] init];
        faceBlurFilter.inputImage = result;
        result = faceBlurFilter.outputImage;
    }

    // apply brightness adjustment
    result = [self processBrightness:result];

    [self renderImage:result];
}

- (void)renderImage:(CIImage *)image {
    _lastFrame = image;
    if (_isRendering) {
        return;
    }
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
        _isRendering = YES;
        // render result image and set the result to UIImageView
        UIImage *renderedImage = [UIImage imageWithCGImage: [self.context createCGImage:image fromRect:image.extent]];
        [self.imageView performSelectorOnMainThread:@selector(setImage:) withObject:renderedImage waitUntilDone:NO];
        _isRendering = NO;
        if (_lastFrame != image) {
            [self renderImage:_lastFrame];
        }
    });
}

- (CIImage *)processBrightness:(CIImage *)image {
    CIFilter *colorControl = [CIFilter filterWithName:@"CIColorControls"];
    [colorControl setValue:image forKey:kCIInputImageKey];
    [colorControl setValue:[NSNumber numberWithFloat:self.previewBrightness] forKey:kCIInputBrightnessKey];
    return [colorControl outputImage];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
