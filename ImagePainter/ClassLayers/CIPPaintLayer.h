//
//  CAImageLayer.h
//  ImagePainter
//
//  Created by yuxinjin on 12-9-22.
//  Copyright (c) 2012年 yuxinjin. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

@interface CIPPaintLayer : CALayer
@property(nonatomic, retain) UIImage *backImage;
@property(nonatomic) CGFloat screenScale;
@property(nonatomic) CGFloat scale;

- (id) initWithFrame:(CGRect) frame;

+ (id) createLayerWithFrame:(CGRect)frame type:(LayerType)type withContent:(NSDictionary*)content;

- (void) resetBackImage:(UIImage*)backImage;

- (CGPoint) getPointFromViewPoint:(CGPoint) viewPoint;
- (BOOL) hasSelectAt:(CGPoint)point;

- (UIImage*) getThumbnailWithinSize:(CGSize) targetSize;

- (BOOL) erasePoint:(CGPoint)point withPalette:(CIPPalette*)palette;
- (BOOL) eraseLineFrom:(CGPoint)p1 to:(CGPoint)p2 withPalette:(CIPPalette*)palette;

// paint another image located in specified frame rectangle with position relative to the layer's container's origin (UIView). Scale means the image to paint's actual scale
- (BOOL) paintImage:(UIImage*)paintImage fromRect:(CGRect)paintRect scale:(CGFloat)paintScale;
- (UIImage*)getImageForPaint;

- (void) paintTest;

- (void) translate:(CGPoint)translate;
- (void) scaleComponent:(CGFloat)scale component:(NSUInteger)xy;
- (void) rotate:(CGFloat)angle;

- (void) applyScale;
- (void) applyRotate;
- (void) applyRotate:(CGFloat)angle;

- (void) cropImageIn:(CGRect)selRect;
- (void) clearImageIn:(CGRect)selRect;
- (UIImage*) copyImageIn:(CGRect)selRect;

- (LayerType) getLayerType;

- (NSDictionary*) getTransformHistory;
- (void) loadTransformHistory:(NSDictionary*)histAttrs;

- (NSDictionary*) getUpdateHistory;
+ (id) createFromUpdateHistory:(NSDictionary*)histAttrs;

- (NSData*) convert2LayerData;
+ (id) createLayerFromData:(NSData*)data;

@end
