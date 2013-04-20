//
//  UILayerThumb.m
//  ImagePainter
//
//  Created by yuxinjin on 12-9-24.
//  Copyright (c) 2012年 yuxinjin. All rights reserved.
//

#import "CIPThumbView.h"

@interface CIPThumbView()

@property (nonatomic) BOOL isFocus;
@property (nonatomic) BOOL isMove;
@property (nonatomic, retain) UIImage *moveMask;

@end

@implementation CIPThumbView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.layer.contents = (id)[UIImage imageNamed:@"back_thumb"].CGImage;
        self.layer.cornerRadius = 8;
        self.clipsToBounds = YES;
        [self createMoveMask];
        [self createThumbLayer];
    }
    return self;
}

- (void) clearSubLayers {
    NSArray *sublayers = self.layer.sublayers;
    for (int i=0; i<sublayers.count; i++) {
        [(CALayer*)[sublayers lastObject] removeFromSuperlayer];
    }
}

- (void) setBackgroundColor:(UIColor *)backgroundColor withBorderColor:(UIColor *)borderColor {
    self.layer.backgroundColor = backgroundColor.CGColor;
    self.layer.borderColor = borderColor.CGColor;
    //self.layer.contents = (id) img.CGImage;
    UIGraphicsEndImageContext();
}

- (void) createMoveMask {
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, 1.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [UIColor colorWithRed:1.0 green:1.0 blue:0.0 alpha:0.5].CGColor);
    CGContextFillRect(context, self.bounds);
    self.moveMask = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
}

- (void) createThumbLayer {
    CALayer *layer =[[CALayer alloc] init];
    [self.layer addSublayer:layer];
}

- (void) setThumbLayerWith:(UIImage *)thumbImage {
    CALayer *layer =[[CALayer alloc] init];
    layer.frame = CGRectMake(0, 0, thumbImage.size.width, thumbImage.size.height);
    layer.position = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));

    if (thumbImage != Nil) {
        layer.contents = (id) thumbImage.CGImage;
    }
    
    CALayer *oldLayer = [self.layer.sublayers objectAtIndex:0];
    [self.layer replaceSublayer:oldLayer with:layer];

}

- (void) setFocusOfView:(BOOL)focus {
    if ((self.isFocus && focus) || (!self.isFocus && !focus)) {
        return;
    }
    
    if (focus) {
        [self.layer setBorderColor:[CIPPalette borderColor].CGColor];
        [self.layer setBorderWidth:3];
    } else {
        [self.layer setBorderColor:[UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:0.8].CGColor];
        [self.layer setBorderWidth:1];
    }
    
    self.isFocus = focus;
}

- (void) setMoveStatus:(BOOL)move{
    if ((self.isMove && move) || (!self.isMove && !move)) {
        return;
    }
    if (move) {
        CALayer *layer = [[CALayer alloc] init];
        layer.frame = self.bounds;
        layer.contents = (id)self.moveMask.CGImage;
        [self.layer addSublayer:layer];
    } else {
        [[self.layer.sublayers lastObject] removeFromSuperlayer];
    }
    self.isMove = move;
}


@end
