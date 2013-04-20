//
//  CIPZoomView.m
//  ImagePainter
//
//  Created by yuxinjin on 13-3-24.
//  Copyright (c) 2013年 yuxinjin. All rights reserved.
//

#import "CIPZoomView.h"

@interface CIPZoomView()
@property (nonatomic, retain) CALayer *zoomLayer;

@end

@implementation CIPZoomView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initLayers];
    }
    return self;
}

- (void) initLayers {
    CGSize size = self.frame.size;
    CGFloat diameter = MIN(size.width, size.height);
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, diameter, diameter);
    
    self.layer.backgroundColor = [UIColor whiteColor].CGColor;
    self.layer.cornerRadius = 25;
    self.clipsToBounds = YES;
    
    self.zoomLayer = [[CALayer alloc] init];
    self.zoomLayer.frame = CGRectMake(6, 6, diameter-12, diameter-12);
    self.zoomLayer.cornerRadius = diameter/2-6;
    [self.layer addSublayer:self.zoomLayer];
    
    CALayer *layer1 = [[CALayer alloc] init];
    layer1.frame = CGRectMake(0, 0, diameter, diameter);
    layer1.contents = (id)[UIImage imageNamed:@"zoomview.png"].CGImage;
    [self.layer addSublayer:layer1];
}

- (void) updateImage:(UIImage*) image {
    self.zoomLayer.contents = (id)image.CGImage;
}

@end
