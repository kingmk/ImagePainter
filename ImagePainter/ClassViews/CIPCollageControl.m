//
//  CIPCollageScroll.m
//  ImagePainter
//
//  Created by yuxinjin on 12-11-6.
//  Copyright (c) 2012年 yuxinjin. All rights reserved.
//

NSUInteger const COLLAGE_COUNT = 69;
CGFloat const COLLAGE_HEIGHT = 50;

#import "CIPCollageControl.h"

@interface CIPCollageControl()
@property (nonatomic) CGFloat margin;
@property (nonatomic, retain) UIScrollView *scroll;

@property (nonatomic, retain) UIImage *backImage;
@property (nonatomic, retain) NSMutableArray *imageRects;

@end

@implementation CIPCollageControl

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initParam];
    }
    return self;
}

- (void) initParam {
    [self initBackground];
    
    self.scroll = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
    [self addSubview:self.scroll];
    self.margin = 10;
    [self loadCollage];
}

- (void) initBackground {
    CGSize size = self.frame.size;
    UIGraphicsBeginImageContext(size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    const CGFloat components[12] = {0.57, 0.71, 0.75, 0.9, 0.76, 0.83, 0.84, 0.8, 0.89, 0.96, 0.97, 0.7};
    const CGFloat locations[3] = {0, 0.3, 1.0};
    CGGradientRef gradient = CGGradientCreateWithColorComponents(colorSpace, components, locations, 3);
    CGContextDrawLinearGradient(context, gradient, CGPointMake(0, size.height), CGPointMake(0, 0), kCGGradientDrawsBeforeStartLocation);
    
    CGColorSpaceRelease(colorSpace);
    CGGradientRelease(gradient);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    self.layer.contents = (id)image.CGImage;
}

- (void) loadCollage {
    CGFloat screenScale = [[UIScreen mainScreen] scale];
    CGSize frameSize = self.frame.size;
    CGFloat h = COLLAGE_HEIGHT;
    CGFloat offy = self.margin;
    CGFloat offx = self.margin;
    int tmpidx = 0;
    NSMutableArray *imagesPerLine = [NSMutableArray arrayWithCapacity:6];
    NSMutableArray *lineImages = [NSMutableArray arrayWithCapacity:20];
    [self.imageRects removeAllObjects];
    self.imageRects = [NSMutableArray arrayWithCapacity:20];

    for (int i=0; i<COLLAGE_COUNT; i++) {
        NSString *name = [NSString stringWithFormat:@"image_%03d.png",i];
        UIImage *image = [UIImage imageNamed:name];
        image = [CIPImageProcess fitImage:image outof:CGSizeMake(10, h)];
        if (offx+image.size.width+self.margin>frameSize.width) {
            offx = (frameSize.width-offx+self.margin)/2;
            NSMutableArray *lineRects = [NSMutableArray arrayWithCapacity:imagesPerLine.count];
            UIGraphicsBeginImageContextWithOptions(CGSizeMake(frameSize.width, h), 0.0, screenScale);
            for (UIImage *image in imagesPerLine) {
                CGRect rect = CGRectMake(offx, offy, image.size.width, h);
                NSDictionary *rectDesc = [NSDictionary dictionaryWithObjectsAndKeys:[NSValue valueWithCGRect:rect], @"RECT", [NSNumber numberWithInt:tmpidx], @"INDEX", nil];
                tmpidx++;
                [lineRects addObject:rectDesc];
                [image drawAtPoint:CGPointMake(offx, 0)];
                offx += image.size.width+self.margin;
            }
            [self.imageRects addObject:lineRects];
            UIImage *lineImage = UIGraphicsGetImageFromCurrentImageContext();
            [lineImages addObject:lineImage];
            UIGraphicsEndImageContext();
            
            offy += self.margin+h;
            offx = self.margin;
            [imagesPerLine removeAllObjects];
        }
        offx += image.size.width+self.margin;
        [imagesPerLine addObject:image];
    }
    
    if (imagesPerLine.count > 0) {
        offx = (frameSize.width-offx+self.margin)/2;
        NSMutableArray *lineRects = [NSMutableArray arrayWithCapacity:imagesPerLine.count];
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(frameSize.width, h), 0.0, screenScale);
        for (UIImage *image in imagesPerLine) {
            CGRect rect = CGRectMake(offx, offy, image.size.width, h);
            NSDictionary *rectDesc = [NSDictionary dictionaryWithObjectsAndKeys:[NSValue valueWithCGRect:rect], @"RECT", [NSNumber numberWithInt:tmpidx], @"INDEX", nil];
            tmpidx++;
            [lineRects addObject:rectDesc];
            [image drawAtPoint:CGPointMake(offx, 0)];
            offx += image.size.width+self.margin;
        }
        [self.imageRects addObject:lineRects];
        UIImage *lineImage = UIGraphicsGetImageFromCurrentImageContext();
        [lineImages addObject:lineImage];
        UIGraphicsEndImageContext();
        
        [imagesPerLine removeAllObjects];
    }
    CGFloat scrollH = offy+h+self.margin;
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(frameSize.width, scrollH), 0.0, screenScale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
    CGContextFillRect(context, CGRectMake(0, 0, frameSize.width, scrollH));
    offy = self.margin;
    for (UIImage *lineImage  in lineImages) {
        [lineImage drawAtPoint:CGPointMake(0, offy)];
        offy += self.margin+h;
    }
    self.backImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    self.scroll.contentSize = CGSizeMake(frameSize.width, scrollH);
    UIView *controlView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, frameSize.width, scrollH)];
    
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(select:)];
    tapRecognizer.numberOfTapsRequired = 1;
    [controlView addGestureRecognizer:tapRecognizer];
    
    [self.scroll addSubview:controlView];
}

- (IBAction)select:(UITapGestureRecognizer*)sender {
    UIView *controlView = [self.scroll.subviews objectAtIndex:0];
    CGPoint point = [sender locationOfTouch:0 inView:controlView];
    
    CGFloat h = COLLAGE_HEIGHT;
    if (point.y < self.margin) {
        return;
    }
    int yidx = (point.y-self.margin)/(self.margin+h);
    if (point.y-(h+self.margin)*yidx > h) {
        return;
    }
    
    NSArray *lineRects = [self.imageRects objectAtIndex:yidx];
    int imgIdx = -1;
    for (NSDictionary *rectDesc in lineRects) {
        CGRect rect = [(NSValue*)[rectDesc objectForKey:@"RECT"] CGRectValue];
        if (point.x >= rect.origin.x && point.x <= rect.origin.x+rect.size.width) {
            imgIdx = [(NSNumber*)[rectDesc objectForKey:@"INDEX"] intValue];
            break;
        } else if (point.x < rect.origin.x) {
            break;
        }
    }
    
    if (imgIdx > -1) {
        NSString *name = [NSString stringWithFormat:@"image_%03d.png",imgIdx];
        self.selectedImage = [UIImage imageNamed:name];
        [self sendActionsForControlEvents:UIControlEventValueChanged];
    }
}

- (void) updateColor:(UIColor *)color {
    UIImage *contentImage = [CIPImageProcess generateImageWithColor:color onMask:self.backImage];
    UIView *controlView = [self.scroll.subviews objectAtIndex:0];
    controlView.layer.contents = (id)contentImage.CGImage;
}

@end
