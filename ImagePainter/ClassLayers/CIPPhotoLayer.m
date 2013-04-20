//
//  CABackLayer.m
//  ImagePainter
//
//  Created by yuxinjin on 12-9-24.
//  Copyright (c) 2012年 yuxinjin. All rights reserved.
//

#import "CIPPhotoLayer.h"

extern NSString *const HISTORY_KEY_TYPE;
extern NSString *const HISTORY_KEY_CENTER;
extern NSString *const HISTORY_KEY_IMAGE;
extern NSString *const HISTORY_KEY_SCALE;
extern NSString *const HISTORY_KEY_ANGLE;
@interface CIPPhotoLayer()

@end

@implementation CIPPhotoLayer


- (void) setBackgroundImage:(UIImage *)backImage within:(CGSize) viewSize {
    CGSize size = backImage.size;
    CGFloat screenScale = [[UIScreen mainScreen] scale];
    
    self.bounds = CGRectMake(0, 0, size.width/screenScale, size.height/screenScale);
    self.contents = (id)backImage.CGImage;
    self.backImage = backImage;
    
    CGSize resize = CGSizeMake(viewSize.width*screenScale, viewSize.height*screenScale);
    
    self.scale = 1.0;
    if (backImage.size.width>resize.width || backImage.size.height>resize.height) {
        if (size.width*resize.height>size.height*resize.width) {
            // the pic's width is much longer
            self.scale = resize.width/size.width;
        } else {
            self.scale = resize.height/size.height;
        }
    }
    self.affineTransform = CGAffineTransformMakeScale(self.scale, self.scale);
}

- (UIImage*)getImageForPaint {
    UIImage *paintImage = self.backImage;
    CGFloat angle = [CIPUtilities getRotateOfAffine:self.affineTransform];
    if (angle != 0) {
        paintImage = [CIPImageProcess rotateImage:self.backImage withAngle:angle];
    }
    return paintImage;
}

- (CGPoint) getPointFromViewPoint:(CGPoint) viewPoint {
    CGPoint point = CGPointMake(viewPoint.x-self.frame.origin.x, viewPoint.y-self.frame.origin.y);
    point = CGPointApplyAffineTransform(point, CGAffineTransformMakeScale(self.screenScale/self.scale, self.screenScale/self.scale));
    CGFloat angle = [CIPUtilities getRotateOfAffine:self.affineTransform];
    if (angle != 0) {
        CGSize size = CGSizeApplyAffineTransform(self.frame.size, CGAffineTransformMakeScale(self.screenScale/self.scale, self.screenScale/self.scale));
        
        point = CGPointMake(point.x-size.width/2, point.y-size.height/2);
        point = CGPointApplyAffineTransform(point, CGAffineTransformMakeRotation(-angle));
        point = CGPointMake(point.x+self.backImage.size.width/2, point.y+self.backImage.size.height/2);
    }
    return point;
}


- (BOOL) hasSelectAt:(CGPoint)point {
    point = [self getPointFromViewPoint:point];
    unsigned char *colors = [CIPImageProcess getAverageColorFromImage:self.backImage.CGImage around:point withN:4];
    BOOL result = NO;
    if (colors) {
        result = (colors[3] >= 1);
        free(colors);
    }
    return result;
}

#pragma mark -
#pragma mark Translate, Scale, Rotate, and Crop Function
- (void) scaleComponent:(CGFloat)scale component:(NSUInteger)xy {
    self.affineTransform = CGAffineTransformScale(self.affineTransform, scale, scale);
    self.scale = [CIPUtilities getScaleOfAffine:self.affineTransform];
}


- (CGPoint) scalePoint:(CGPoint)viewPoint {
    return CGPointApplyAffineTransform(viewPoint, CGAffineTransformMakeScale(self.screenScale/self.scale, self.screenScale/self.scale));
}

- (BOOL) erasePoint:(CGPoint)point withPalette:(CIPPalette *)palette {
    CGFloat strokeWidth = palette.strokeWidth;
    palette.strokeWidth = palette.strokeWidth/self.scale;
    [super erasePoint:point withPalette:palette];
    palette.strokeWidth = strokeWidth;
    return YES;
}

- (BOOL) eraseLineFrom:(CGPoint)p1 to:(CGPoint)p2 withPalette:(CIPPalette *)palette {
    CGFloat strokeWidth = palette.strokeWidth;
    palette.strokeWidth = palette.strokeWidth/self.scale;
    [super eraseLineFrom:p1 to:p2 withPalette:palette];
    palette.strokeWidth = strokeWidth;
    return YES;
}

- (void) cropImageIn:(CGRect)selRect {
    selRect = CGRectOffset(selRect, -self.frame.origin.x, -self.frame.origin.y);
    CGRect scaleRect = CGRectApplyAffineTransform(selRect, CGAffineTransformMakeScale(self.screenScale/self.scale, self.screenScale/self.scale));
    CGFloat angle = [CIPUtilities getRotateOfAffine:self.affineTransform];
    self.backImage = [CIPImageProcess cropImage:[CIPImageProcess rotateImage:self.backImage withAngle:angle] within:scaleRect];
    CGRect frame = self.frame;
    self.affineTransform = CGAffineTransformIdentity;
    self.frame = CGRectMake(frame.origin.x+selRect.origin.x, frame.origin.y+selRect.origin.y, selRect.size.width, selRect.size.height);
    self.contents = (id)self.backImage.CGImage;
}

- (void) clearImageIn:(CGRect)selRect {
    selRect = CGRectOffset(selRect, -self.frame.origin.x, -self.frame.origin.y);
    CGRect scaleRect = CGRectApplyAffineTransform(selRect, CGAffineTransformMakeScale(self.screenScale/self.scale, self.screenScale/self.scale));
    CGFloat angle = [CIPUtilities getRotateOfAffine:self.affineTransform];
    
    self.backImage = [CIPImageProcess clearImage:[CIPImageProcess rotateImage:self.backImage withAngle:angle] in:scaleRect];
    CGRect frame = self.frame;
    self.affineTransform = CGAffineTransformIdentity;
    self.frame = frame;
    
    self.contents = (id)self.backImage.CGImage;
}

- (UIImage*)copyImageIn:(CGRect)selRect {
    selRect = CGRectOffset(selRect, -self.frame.origin.x, -self.frame.origin.y);
    CGRect scaleRect = CGRectApplyAffineTransform(selRect, CGAffineTransformMakeScale(self.screenScale/self.scale, self.screenScale/self.scale));
    CGFloat angle = [CIPUtilities getRotateOfAffine:self.affineTransform];
    UIImage *copyImage = [CIPImageProcess cropImage:[CIPImageProcess rotateImage:self.backImage withAngle:angle] within:scaleRect];
    copyImage = [CIPImageProcess scaleImage:copyImage withScale:self.scale];
    return copyImage;
}

#pragma mark -
#pragma mark Layer History Convert Function

- (LayerType) getLayerType {
    return PhotoLayer;
}

- (void)recoverLayerAt:(CGPoint)center withScale:(CGFloat)scale withAngle:(CGFloat)angle {
    self.scale = scale;
    self.affineTransform = CGAffineTransformConcat(CGAffineTransformMakeScale(scale, scale), CGAffineTransformMakeRotation(angle));
    self.position = center;
}

- (void) recoverLayerAt:(CGPoint)center withImage:(UIImage*)image withScale:(CGFloat)scale withAngle:(CGFloat)angle {
    [self setBackgroundImage:image within:image.size];
    [self recoverLayerAt:center withScale:scale withAngle:angle];
}

- (NSDictionary*) getUpdateHistory {
    NSMutableDictionary *attrs = [NSMutableDictionary dictionaryWithCapacity:5];
    [attrs setValue:[NSNumber numberWithInteger:[self getLayerType]] forKey:HISTORY_KEY_TYPE];
    [attrs setValue:self.backImage forKey:HISTORY_KEY_IMAGE];
    [attrs setValue:[NSValue valueWithCGPoint:CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame))] forKey:HISTORY_KEY_CENTER];
    [attrs setValue:[NSNumber numberWithFloat:self.scale] forKey:HISTORY_KEY_SCALE];
    CGFloat angle = [CIPUtilities getRotateOfAffine:self.affineTransform];
    [attrs setValue:[NSNumber numberWithFloat:angle] forKey:HISTORY_KEY_ANGLE];
    return attrs;
}

- (void) loadUpdateHistory:(NSDictionary*)histAttrs {
    CGPoint center = [(NSValue*)[histAttrs valueForKey:HISTORY_KEY_CENTER] CGPointValue];
    CGFloat scale = [(NSNumber*)[histAttrs valueForKey:HISTORY_KEY_SCALE] floatValue];
    CGFloat angle = [(NSNumber*)[histAttrs valueForKey:HISTORY_KEY_ANGLE] floatValue];
    UIImage *image = [histAttrs valueForKey:HISTORY_KEY_IMAGE];
    [self recoverLayerAt:center withImage:image withScale:scale withAngle:angle];
}

- (NSDictionary*) getTransformHistory {
    NSMutableDictionary *attrs = [NSMutableDictionary dictionaryWithCapacity:4];
    [attrs setValue:[NSNumber numberWithInteger:[self getLayerType]] forKey:HISTORY_KEY_TYPE];
    [attrs setValue:[NSValue valueWithCGPoint:CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame))] forKey:HISTORY_KEY_CENTER];
    [attrs setValue:[NSNumber numberWithFloat:self.scale] forKey:HISTORY_KEY_SCALE];
    CGFloat angle = [CIPUtilities getRotateOfAffine:self.affineTransform];
    [attrs setValue:[NSNumber numberWithFloat:angle] forKey:HISTORY_KEY_ANGLE];
    return attrs;
}

- (void) loadTransformHistory:(NSDictionary*)histAttrs {
    CGPoint center = [(NSValue*)[histAttrs valueForKey:HISTORY_KEY_CENTER] CGPointValue];
    CGFloat scale = [(NSNumber*)[histAttrs valueForKey:HISTORY_KEY_SCALE] floatValue];
    CGFloat angle = [(NSNumber*)[histAttrs valueForKey:HISTORY_KEY_ANGLE] floatValue];
    [self recoverLayerAt:center withScale:scale withAngle:angle];
}

#pragma mark -
#pragma mark Layer Data Convert Function

// center, scale, angle, image length, image data
- (NSData*) getLayerData {
    NSData *imageData = UIImagePNGRepresentation(self.backImage);
    NSUInteger imageDataL = imageData.length;

    NSMutableData *data = [NSMutableData dataWithCapacity:imageDataL+sizeof(imageDataL)+sizeof(CGFloat)*4];
    
    CGFloat center[] = { CGRectGetMidX(self.frame), CGRectGetMidY(self.frame)};
    [CIPUtilities printPoint:CGPointMake(center[0], center[1]) withDescription:@"center to save"];
    [data appendBytes:center length:sizeof(center)];
    CGFloat scale = self.scale;
    [data appendBytes:&scale length:sizeof(scale)];
    CGFloat angle = [CIPUtilities getRotateOfAffine:self.affineTransform];
    [data appendBytes:&angle length:sizeof(angle)];
    
    [data appendBytes:&imageDataL length:sizeof(imageDataL)];
    [data appendData:imageData];
    return data;
}

- (void) loadLayerData:(NSData*)data  {
    NSUInteger l = sizeof(CGFloat)*2;
    NSUInteger offset = l;
    CGFloat center[2];
    [data getBytes:center length:l];
    l = sizeof(CGFloat);
    CGFloat scale, angle;
    [data getBytes:&scale range:NSMakeRange(offset, l)];
    offset += l;
    [data getBytes:&angle range:NSMakeRange(offset, l)];
    offset += l;

    NSUInteger imageDataL;
    l = sizeof(imageDataL);
    [data getBytes:&imageDataL range:NSMakeRange(offset, l)];
    offset += l;
    
    UIImage *image = [UIImage imageWithData:[data subdataWithRange:NSMakeRange(offset, imageDataL)]];
    
    [self recoverLayerAt:CGPointMake(center[0], center[1]) withImage:image withScale:scale withAngle:angle];
}

@end
