//
//  CAVirtualLayer.m
//  ImagePainter
//
//  Created by yuxinjin on 12-9-23.
//  Copyright (c) 2012年 yuxinjin. All rights reserved.
//

#import "CIPVirtualLayer.h"
@interface CIPVirtualLayer()

@property(nonatomic, retain) UIImage *backImage;
@property(nonatomic) BOOL firstPaint;
@property(nonatomic) CGPoint translate;

@property(nonatomic) CGPoint pointLT; // left top point;
@property(nonatomic) CGPoint pointRB; // right bottom point;
@property(nonatomic, retain) NSMutableArray *pathPoints;


@end

@implementation CIPVirtualLayer

- (id) initWithFrame:(CGRect) frame {
    self = [super init];
    if (self) {
        self.frame = frame;
        self.screenScale = [[UIScreen mainScreen] scale];
        self.firstPaint = YES;
        self.pathPoints = [NSMutableArray arrayWithCapacity:10];
    }
    return self;
}

- (void) setVirtualLayer:(ImageProcState)procState at:(CGPoint)start {
    self.procState = procState;
    [self.pathPoints removeAllObjects];
    if (self.procState == ProcPaint) {
        UIGraphicsBeginImageContextWithOptions(self.frame.size, NO, self.screenScale);
        self.backImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    self.pointLT = start;
    self.pointRB = start;
    CGFloat psize = [CIPPalette maxSize];
    self.contentRect = CGRectMake(start.x-psize, start.y-psize, psize*2, psize*2);
}

- (CGPoint) getTranslate {
    return self.translate;
}

- (CGRect) calculateContentRect {
    CGFloat psize = [CIPPalette maxSize];
    self.contentRect = CGRectMake(self.pointLT.x-psize/2, self.pointLT.y-psize/2, self.pointRB.x-self.pointLT.x+psize, self.pointRB.y-self.pointLT.y+psize);
    return self.contentRect;
}

- (UIImage *) getFitBackImage {
    [self calculateContentRect];
    self.backImage = [UIImage imageWithCGImage:(CGImageRef)self.contents];
    return [CIPImageProcess cropImage:self.backImage within:CGRectApplyAffineTransform(self.contentRect, CGAffineTransformMakeScale(self.screenScale, self.screenScale))];
}

- (void) drawPaint:(CGPoint)curPoint withPalette:(CIPPalette *)palette {
    if (self.firstPaint) {
        self.firstPaint = NO;
        [self.pathPoints addObject:[NSValue valueWithCGPoint:curPoint]];
        return;
    }
    CGPoint startPoint = [(NSValue*)[self.pathPoints lastObject] CGPointValue];
    CGPoint drawPoint = curPoint;
    [self.pathPoints addObject:[NSValue valueWithCGPoint:drawPoint]];
    CGFloat width = palette.strokeWidth;
    
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, self.screenScale);
    CGContextRef context = UIGraphicsGetCurrentContext();

    if (palette.brushType == 0) {
        CGContextSetLineWidth(context, width);
        CGContextSetLineJoin(context, palette.lineJoin);
        CGContextSetLineCap(context, palette.lineCap);
        CGContextSetStrokeColorWithColor(context, palette.strokeColor.CGColor);
        CGPoint points[self.pathPoints.count];
        int i=0;
        for (NSValue *value in self.pathPoints) {
            CGPoint tmpPoint = [value CGPointValue];
            points[i].x = tmpPoint.x;
            points[i].y = tmpPoint.y;
            i++;
        }
        CGContextAddLines(context, points, i);
        CGContextStrokePath(context);
    } else {
        [self.backImage drawAtPoint:CGPointZero];
        const CGFloat *components = CGColorGetComponents(palette.strokeColor.CGColor);
        CGFloat colors[4];
        memcpy(colors, components, sizeof(colors));
        NSUInteger brushType = palette.brushType;
        CGImageRef brushImg = [CIPBrushUtilities getBrushForType:brushType withColor:colors];
        [CIPBrushUtilities drawBrushImage:brushImg inSize:CGSizeMake(width, width) from:startPoint to:drawPoint on:context withStep:1.5];
        CGImageRelease(brushImg);
    }

    self.pointLT = CGPointMake(MIN(self.pointLT.x, curPoint.x-width/2), MIN(self.pointLT.y, curPoint.y-width/2));
    self.pointRB = CGPointMake(MAX(self.pointRB.x, curPoint.x+width/2), MAX(self.pointRB.y, curPoint.y+width/2));
    self.backImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    self.contents = (id)self.backImage.CGImage;
}

- (UIImage*) copyImageIn:(CGRect)selRect {
    selRect = CGRectOffset(selRect, -self.frame.origin.x, -self.frame.origin.y);
    return [CIPImageProcess cropImage:self.backImage within:selRect];
}

@end
