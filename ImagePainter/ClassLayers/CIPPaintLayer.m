//
//  CAImageLayer.m
//  ImagePainter
//
//  Created by yuxinjin on 12-9-22.
//  Copyright (c) 2012年 yuxinjin. All rights reserved.
//

extern NSString *const HISTORY_KEY_TYPE;
extern NSString *const HISTORY_KEY_CENTER;
extern NSString *const HISTORY_KEY_IMAGE;
extern NSString *const HISTORY_KEY_SCALE;

NSString *const LAYER_CONTENT_IMAGE = @"image";
NSString *const LAYER_CONTENT_PALETTE = @"palette";
NSString *const LAYER_CONTENT_TEXT = @"text";

#import "CIPPaintLayer.h"
@interface CIPPaintLayer()

@end

@implementation CIPPaintLayer

- (id) init {
    self = [super init];
    if (self) {
        self.scale = 1.0;
        self.screenScale = [[UIScreen mainScreen] scale];
        
        NSMutableDictionary *actions = [[NSMutableDictionary alloc] initWithObjectsAndKeys:[NSNull null], @"onOrderIn", [NSNull null], @"onOrderOut", [NSNull null], @"position", [NSNull null], @"sublayers", [NSNull null], @"contents", [NSNull null], @"bounds", [NSNull null], @"frame", [NSNull null], @"transform", nil];
        self.actions = actions;
    }
    return self;
}

- (id) initWithFrame:(CGRect) frame {
    self = [super init];
    if (self) {
        self.scale = 1.0;
        self.screenScale = [[UIScreen mainScreen] scale];

        NSMutableDictionary *actions = [[NSMutableDictionary alloc] initWithObjectsAndKeys:[NSNull null], @"onOrderIn", [NSNull null], @"onOrderOut", [NSNull null], @"position", [NSNull null], @"sublayers", [NSNull null], @"contents", [NSNull null], @"bounds", [NSNull null], @"frame", [NSNull null], @"transform", nil];
        self.actions = actions;
        self.frame = frame;
        if (frame.size.width > 0 && frame.size.height > 0) {
            UIGraphicsBeginImageContextWithOptions(self.frame.size, NO, self.screenScale);
            CGContextRef context = UIGraphicsGetCurrentContext();
            CGContextSetFillColorWithColor(context, [UIColor clearColor].CGColor);
            CGContextFillRect(context, CGRectMake(0, 0, self.frame.size.width, self.frame.size.height));
            self.backImage = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
        }
    }
    return self;
}

+ (id) createLayerWithFrame:(CGRect)frame type:(LayerType)type withContent:(NSDictionary*)content {
    CIPPaintLayer *layer;
    switch (type) {
        case PaintLayer:
            layer = [[CIPPaintLayer alloc] initWithFrame:frame];
            [layer paintImage:[content valueForKey:LAYER_CONTENT_IMAGE] fromRect:frame scale:1.0];
            break;
        case PhotoLayer:
            layer = [[CIPPhotoLayer alloc] initWithFrame:frame];
            [(CIPPhotoLayer*)layer setBackgroundImage:[content valueForKey:LAYER_CONTENT_IMAGE] within:frame.size];
            break;
        case TextLayer: {
            UIColor *backColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.2];
            layer = [[CIPTextLayer alloc] initWithFrame:frame];
            if (content != nil) {
                [CIPUtilities printRect:frame withDescription:@"before creating, the frame "];
                [(CIPTextLayer*)layer setupTextRect:frame withBackColor:backColor withPalette:[content valueForKey:LAYER_CONTENT_PALETTE]];
                [(CIPTextLayer*)layer paintText:[content valueForKey:LAYER_CONTENT_TEXT] withPalette:[content valueForKey:LAYER_CONTENT_PALETTE] showBorder:NO];
            }
            break;
        }
        default:
            break;
    }
    return layer;
}

#pragma mark -
#pragma mark Some Basic Function

- (UIImage*) getThumbnailWithinSize:(CGSize) targetSize {
    CGSize originSize = self.backImage.size;

    if (originSize.width>originSize.height) {
        targetSize.height = targetSize.width*originSize.height/originSize.width;
    } else {
        targetSize.width = targetSize.height*originSize.width/originSize.height;
    }
    
    UIGraphicsBeginImageContextWithOptions(targetSize, NO, 1.0);
    [self.backImage drawInRect:CGRectMake(0, 0, targetSize.width, targetSize.height)];
    UIImage* resizeImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return resizeImage;
}

- (void) resetBackImage:(UIImage*)backImage {
    self.backImage = backImage;
    self.contents = (id)self.backImage.CGImage;
}

- (CGPoint) scalePoint:(CGPoint)viewPoint {
    return CGPointApplyAffineTransform(viewPoint, CGAffineTransformMakeScale(self.screenScale/self.scale, self.screenScale/self.scale));
}

- (CGPoint) getPointFromViewPoint:(CGPoint) viewPoint {
    CGPoint point = CGPointMake(viewPoint.x-self.frame.origin.x, viewPoint.y-self.frame.origin.y);
    point = CGPointApplyAffineTransform(point, CGAffineTransformMakeScale(1/self.scale, 1/self.scale));
    return point;
}

- (BOOL) hasSelectAt:(CGPoint)point {
    point = [self getPointFromViewPoint:point];
    point = CGPointApplyAffineTransform(point, CGAffineTransformMakeScale(self.screenScale, self.screenScale));
    unsigned char *colors = [CIPImageProcess getAverageColorFromImage:self.backImage.CGImage around:point withN:4];
    BOOL result = NO;
    if (colors) {
        //NSLog(@"select color: %d, %d, %d, %d", colors[0], colors[1], colors[2], colors[3]);
        result = (colors[3] >= 1);
        free(colors);
    }
    return result;
}

#pragma mark -
#pragma mark Erase and Paint Function

- (BOOL) erasePoint:(CGPoint)point withPalette:(CIPPalette*)palette {
    point = [self getPointFromViewPoint:point];
    UIGraphicsBeginImageContextWithOptions(self.backImage.size, NO, self.screenScale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    [self.backImage drawAtPoint:CGPointZero];
    CGContextSetBlendMode(context, kCGBlendModeClear);
    CGContextAddArc(context, point.x, point.y, palette.strokeWidth/2, 0, M_PI*2, 0);
    CGContextFillPath(context);
    
    self.backImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    self.contents = (id)self.backImage.CGImage;
    
    return YES;
}

- (BOOL) eraseLineFrom:(CGPoint)p1 to:(CGPoint)p2 withPalette:(CIPPalette*)palette {
    p1 = [self getPointFromViewPoint:p1];
    p2 = [self getPointFromViewPoint:p2];
    
    UIGraphicsBeginImageContextWithOptions(self.backImage.size, NO, self.screenScale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    [self.backImage drawAtPoint:CGPointZero];
    CGContextSetBlendMode(context, kCGBlendModeClear);
    CGContextSetLineJoin(context, palette.lineJoin);
    CGContextSetLineCap(context, palette.lineCap);
    CGContextSetLineWidth(context, palette.strokeWidth);
    CGContextMoveToPoint(context, p1.x, p1.y);
    CGContextAddLineToPoint(context, p2.x, p2.y);
    CGContextStrokePath(context);
    
    self.backImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    self.contents = (id)self.backImage.CGImage;
    
    return YES;
}

- (BOOL) paintImage:(UIImage *)paintImage fromRect:(CGRect)paintRect scale:(CGFloat)paintScale {
    CGRect orgRect = self.frame;
    CGRect addRect = paintRect;
    if (orgRect.size.width == 0 || orgRect.size.height == 0) {
        orgRect = addRect;
    }
    CGRect unionRect = CGRectUnion(orgRect, addRect);

    CGFloat offsetx = unionRect.origin.x;
    CGFloat offsety = unionRect.origin.y;
    UIImage *backImage = [self getImageForPaint];

    if (self.scale < paintScale) {
        // need to scale up the paint image
        paintImage = [CIPImageProcess scaleImage:paintImage withScale:paintScale/self.scale];
    } else if (self.scale > paintScale) {
        // need to scale up the back image
        backImage = [CIPImageProcess scaleImage:backImage withScale:self.scale/paintScale];
    }

    self.scale = MIN(self.scale, paintScale);
    UIGraphicsBeginImageContextWithOptions(unionRect.size, NO, self.screenScale);
    [backImage drawAtPoint:CGPointMake(orgRect.origin.x-offsetx, orgRect.origin.y-offsety)];
    paintRect = CGRectMake(addRect.origin.x-offsetx, addRect.origin.y-offsety, paintRect.size.width, paintRect.size.height);
    [paintImage drawInRect:paintRect];
    self.backImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    self.contents = (id)self.backImage.CGImage;
    if (self.scale != 1.0f) {
        self.affineTransform = CGAffineTransformMakeScale(self.scale, self.scale);
    }
    self.frame = unionRect;
    return YES;
}

- (UIImage*)getImageForPaint {
    return self.backImage;
}

- (void) paintTest {
    [self setNeedsDisplay];
}

#pragma mark -
#pragma mark Translate, Scale, Rotate, and Crop Function

- (void) translate:(CGPoint)translate {
    self.position = CGPointMake(self.position.x+translate.x, self.position.y+translate.y);
}

- (void) scaleComponent:(CGFloat)scale component:(NSUInteger)xy {
    CGFloat sx = 1.0;
    CGFloat sy = 1.0;
    if (xy == 0) { //apply only on x
        sx = scale;
    } else if (xy == 1) { // apply only on y
        sy = scale;
    } else {
        sx = scale;
        sy = scale;
    }
    
    self.affineTransform = CGAffineTransformScale(self.affineTransform, sx, sy);
}

- (void) rotate:(CGFloat)angle {
    self.affineTransform = CGAffineTransformRotate(self.affineTransform, angle);
}

- (void) applyScale {
    CGFloat scaleX = [CIPUtilities getScaleXOfAffine:self.affineTransform];
    CGFloat scaleY = [CIPUtilities getScaleYOfAffine:self.affineTransform];
    [self applyScaleX:scaleX scaleY:scaleY];
}

- (void) applyScaleX:(CGFloat)scaleX scaleY:(CGFloat)scaleY {
    self.backImage = [CIPImageProcess scaleImage:self.backImage withScaleX:scaleX scaleY:scaleY];
    CGSize size = self.backImage.size;

    CGPoint center = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame));
    self.affineTransform = CGAffineTransformIdentity;
    [self setFrame:CGRectMake(center.x-size.width/2, center.y-size.height/2, size.width, size.height)];
    self.contents = (id)self.backImage.CGImage;
    self.scale = 1.0;
}

- (void) applyRotate {
    CGFloat angle = [CIPUtilities getRotateOfAffine:self.affineTransform];
    [self applyRotate:angle];
}

- (void) applyRotate:(CGFloat)angle {
    UIImage *img = [CIPImageProcess rotateImage:self.backImage withAngle:angle];
    CGSize size = img.size;
    //CGSizeApplyAffineTransform(img.size, CGAffineTransformMakeScale(1/self.screenScale, 1/self.screenScale));

    CGPoint center = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame));
    self.affineTransform = CGAffineTransformIdentity;
    CGRect tmpRect = CGRectMake(center.x-size.width/2, center.y-size.height/2, size.width, size.height);
    CGRect cropRect = [CIPImageProcess getImageBoundsFor:img.CGImage];
    img = [CIPImageProcess cropImage:img within:cropRect];
    [self setFrame:CGRectMake(tmpRect.origin.x+cropRect.origin.x, tmpRect.origin.y+cropRect.origin.y, cropRect.size.width, cropRect.size.height)];

    self.backImage = img;
    self.contents = (id)self.backImage.CGImage;
}

- (void) cropImageIn:(CGRect)selRect {
    selRect = CGRectOffset(selRect, -self.frame.origin.x, -self.frame.origin.y);
    self.backImage = [CIPImageProcess cropImage:self.backImage within:selRect];
    self.frame = CGRectMake(self.frame.origin.x+selRect.origin.x, self.frame.origin.y+selRect.origin.y, selRect.size.width, selRect.size.height);
    self.contents = (id)self.backImage.CGImage;
}

- (void) clearImageIn:(CGRect)selRect {
    selRect = CGRectOffset(selRect, -self.frame.origin.x, -self.frame.origin.y);
    self.backImage = [CIPImageProcess clearImage:self.backImage in:selRect];
    self.contents = (id)self.backImage.CGImage;
}

- (UIImage*) copyImageIn:(CGRect)selRect {
    selRect = CGRectOffset(selRect, -self.frame.origin.x, -self.frame.origin.y);
    
    if (selRect.origin.x+selRect.size.width <= 0 || selRect.origin.y+selRect.size.height<=0 || selRect.origin.x >= self.backImage.size.width || selRect.origin.y >= self.backImage.size.height) {
        return nil;
    }
    return [CIPImageProcess cropImage:self.backImage within:selRect];
}

#pragma mark -
#pragma mark Layer History Convert Function

- (LayerType) getLayerType {
    return PaintLayer;
}

- (void)recoverLayerAt:(CGPoint)center withScale:(CGFloat)scale {
    CGSize size = self.backImage.size;
    self.frame = CGRectMake(center.x-size.width/2, center.y-size.height/2, size.width, size.height);
    self.scale = scale;
    self.affineTransform = CGAffineTransformMakeScale(scale, scale);
}

- (void)recoverLayerAt:(CGPoint)center withImage:(UIImage*)image withScale:(CGFloat)scale {
    CGSize size = image.size;
    self.frame = CGRectMake(center.x-size.width/2, center.y-size.height/2, size.width, size.height);
    self.scale = scale;
    self.affineTransform = CGAffineTransformMakeScale(scale, scale);
    [self resetBackImage:image];
}

- (NSDictionary*) getUpdateHistory {
    NSMutableDictionary *attrs = [NSMutableDictionary dictionaryWithCapacity:4];
    [attrs setValue:[NSNumber numberWithInteger:[self getLayerType]] forKey:HISTORY_KEY_TYPE];
    [attrs setValue:self.backImage forKey:HISTORY_KEY_IMAGE];
    [attrs setValue:[NSValue valueWithCGPoint:CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame))] forKey:HISTORY_KEY_CENTER];
    [attrs setValue:[NSNumber numberWithFloat:self.scale] forKey:HISTORY_KEY_SCALE];
    return attrs;
}

- (void) loadUpdateHistory:(NSDictionary*)histAttrs {
    CGPoint center = [(NSValue*)[histAttrs valueForKey:HISTORY_KEY_CENTER] CGPointValue];
    CGFloat scale = [(NSNumber*)[histAttrs valueForKey:HISTORY_KEY_SCALE] floatValue];
    UIImage *image = [histAttrs valueForKey:HISTORY_KEY_IMAGE];
    [self recoverLayerAt:center withImage:image withScale:scale];
}

- (NSDictionary*) getTransformHistory {
    NSMutableDictionary *attrs = [NSMutableDictionary dictionaryWithCapacity:3];
    [attrs setValue:[NSNumber numberWithInteger:[self getLayerType]] forKey:HISTORY_KEY_TYPE];
    [attrs setValue:[NSValue valueWithCGPoint:CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame))] forKey:HISTORY_KEY_CENTER];
    [attrs setValue:[NSNumber numberWithFloat:self.scale] forKey:HISTORY_KEY_SCALE];
    return attrs;
}

- (void) loadTransformHistory:(NSDictionary*)histAttrs {
    CGPoint center = [(NSValue*)[histAttrs valueForKey:HISTORY_KEY_CENTER] CGPointValue];
    CGFloat scale = [(NSNumber*)[histAttrs valueForKey:HISTORY_KEY_SCALE] floatValue];
    [self recoverLayerAt:center withScale:scale];
}

+ (id) createFromUpdateHistory:(NSDictionary*)histAttrs{
    LayerType type = [(NSNumber*)[histAttrs valueForKey:HISTORY_KEY_TYPE] integerValue];
    
    CIPPaintLayer *layer;
    switch (type) {
        case PaintLayer:
            layer = [[CIPPaintLayer alloc] init];
            break;
        case PhotoLayer:
            layer = [[CIPPhotoLayer alloc] init];
            break;
        case TextLayer:
            layer = [[CIPTextLayer alloc] init];
            break;
        default:
            break;
    }
    [layer loadUpdateHistory:histAttrs];
    return layer;
}

#pragma mark -
#pragma mark Layer Data Convert Function
// frame, image length, image data
- (NSData*) getLayerData {
    NSData *imageData = UIImagePNGRepresentation(self.backImage);
    NSUInteger imageDataL = imageData.length;
    NSMutableData *data = [NSMutableData dataWithCapacity:imageDataL+sizeof(imageDataL)+sizeof(CGFloat)*3];
    
    CGFloat center[] = { CGRectGetMidX(self.frame), CGRectGetMidY(self.frame)};
    [data appendBytes:center length:sizeof(center)];
    CGFloat scale = self.scale;
    [data appendBytes:&scale length:sizeof(scale)];
    
    [data appendBytes:&imageDataL length:sizeof(imageDataL)];
    [data appendData:imageData];
    return data;
}

- (void) loadLayerData:(NSData*)data {
    NSUInteger l = sizeof(CGFloat)*2;
    NSUInteger offset = 0;
    CGFloat center[2];
    [data getBytes:center length:l];
    offset += l;
    l = sizeof(CGFloat);
    CGFloat scale;
    [data getBytes:&scale range:NSMakeRange(offset, l)];
    offset += l;
    NSUInteger imageDataL;
    l = sizeof(imageDataL);
    [data getBytes:&imageDataL range:NSMakeRange(offset, l)];
    offset += l;
    
    UIImage *image = [UIImage imageWithData:[data subdataWithRange:NSMakeRange(offset, imageDataL)] scale:self.screenScale];
    [self recoverLayerAt:CGPointMake(center[0], center[1]) withImage:image withScale:scale];
}

- (NSData*) convert2LayerData {
    NSMutableData *data = [NSMutableData dataWithCapacity:1024];
    LayerType type = [self getLayerType];
    [data appendBytes:&type length:sizeof(type)];
    [data appendData:[self getLayerData]];
    return data;
}

+ (id) createLayerFromData:(NSData *)data {
    LayerType type;
    NSUInteger l =sizeof(type);
    [data getBytes:&type length:sizeof(type)];
    NSUInteger offset = l;
    
    CIPPaintLayer *layer;
    switch (type) {
        case PaintLayer:
            layer = [[CIPPaintLayer alloc] init];
            break;
        case PhotoLayer:
            layer = [[CIPPhotoLayer alloc] init];
            break;
        case TextLayer:
            layer = [[CIPTextLayer alloc] init];
            break;
        default:
            break;
    }
    [layer loadLayerData:[data subdataWithRange:NSMakeRange(offset, data.length-offset)]];
    
    return layer;
}
@end
