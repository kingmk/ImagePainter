//
//  CIPTextLayer.m
//  ImagePainter
//
//  Created by yuxinjin on 12-10-2.
//  Copyright (c) 2012年 yuxinjin. All rights reserved.
//

#import "CIPTextLayer.h"

extern NSString *const HISTORY_KEY_TYPE;
extern NSString *const HISTORY_KEY_ANGLE;
extern NSString *const HISTORY_KEY_TEXT;
extern NSString *const HISTORY_KEY_TEXTRECT;
extern NSString *const HISTORY_KEY_PALETTE;

CGFloat const TEXT_MAX_DIAMETER = 480;

@interface CIPTextLayer()
@property (nonatomic) UIColor *backColor;
@property (nonatomic) BOOL showBorder;
@property (nonatomic) CGFloat angle;

@end

@implementation CIPTextLayer

- (id) init {
    self = [super init];
    self.angle = 0;
    return self;
}

- (id) initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    self.angle = 0;
    return self;
}

- (BOOL) hasSelectAt:(CGPoint)point {
    point = [self getPointFromViewPoint:point];
    CGSize size = self.frame.size;
    point = CGPointMake(point.x-size.width/2, point.y-size.height/2);
    point = CGPointApplyAffineTransform(point, CGAffineTransformMakeRotation(-self.angle));
    size = self.textRect.size;
    if (ABS(point.x)<size.width/2 && ABS(point.y)<size.height/2) {
        return YES;
    }
    return NO;
}

- (void) display {
    CGSize maxSize;
    maxSize = CGSizeMake(self.textRect.size.width, TEXT_MAX_DIAMETER);
    CGSize actSize = self.textRect.size;
    UIGraphicsBeginImageContextWithOptions(maxSize, NO, self.screenScale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    if (self.text && self.text.length > 0) {
        CGContextSetFillColorWithColor(context, self.palette.fontColor.CGColor);
        CGContextSetStrokeColorWithColor(context, self.palette.fontBorderColor.CGColor);
        CGContextSetLineWidth(context, self.palette.fontBorderWidth);
        CGContextSetTextDrawingMode(context, self.palette.textMode);

        CGRect maxRect = {self.textRect.origin, maxSize};
        CGRect rect = maxRect;

        actSize = [self.text drawInRect:CGRectMake(8, 8, rect.size.width-16, rect.size.height-16) withFont:self.palette.font lineBreakMode:NSLineBreakByWordWrapping alignment:self.palette.textAlignment];
        actSize = CGSizeMake(actSize.width+16, actSize.height+16);
    }
    if (self.showBorder) {
        [self drawBorderInContext:context];
    }
    self.backImage = UIGraphicsGetImageFromCurrentImageContext();
    CGContextRestoreGState(context);
    UIGraphicsEndImageContext();
    self.backImage = [CIPImageProcess cropImage:self.backImage within:CGRectMake(0, 0, actSize.width, actSize.height)];
    self.textRect = CGRectMake(self.textRect.origin.x, self.textRect.origin.y, actSize.width, actSize.height);
    //[CIPUtilities printRect:self.textRect withDescription:@"after painting, the textRect "];

    if (self.angle != 0) {
        self.backImage = [CIPImageProcess rotateImage:self.backImage withAngle:self.angle];
    }
    CGPoint center = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame));
    CGSize size = self.backImage.size;
    self.frame = CGRectMake(center.x-size.width/2, center.y-size.height/2, size.width, size.height);
    self.contents = (id)self.backImage.CGImage;
}

- (void) drawBorderInContext:(CGContextRef) context{
    CGContextSetLineWidth(context, 2.0);
    const CGFloat dashes[] = {20, 14};
    CGContextSetLineDash(context, 0, dashes, 2);
    CGContextSetLineJoin(context, kCGLineJoinRound);
    CGContextSetLineCap(context, kCGLineCapRound);
    CGContextSetStrokeColorWithColor(context, [UIColor orangeColor].CGColor);
    CGContextSetFillColorWithColor(context, self.backColor.CGColor);
    CGRect rect = self.textRect;
    rect = CGRectMake(2, 2, rect.size.width-4, rect.size.height-4);
    CGContextAddRect(context, rect);
    CGContextStrokePath(context);
    CGContextAddRect(context, rect);
    CGContextFillPath(context);
}

- (void) setupTextRect:(CGRect)rect withBackColor:(UIColor*)backColor withPalette:(CIPPalette *)palette{
    int w = MAX(80, rect.size.width);
    int h = MAX(80, rect.size.height);
    self.frame = CGRectMake(rect.origin.x, rect.origin.y, w, h);
    self.textRect = self.frame;
    self.backColor = backColor;
    if (!self.palette) {
        self.palette = [palette copy];
    }

    self.showBorder = YES;
    [self setNeedsDisplay];
}

- (BOOL) erasePoint:(CGPoint)point withPalette:(CIPPalette *)palette {
    return NO;
}

- (BOOL) eraseLineFrom:(CGPoint)p1 to:(CGPoint)p2 withPalette:(CIPPalette *)palette {
    return NO;
}

- (void) paintText:(NSString *)text withPalette:(CIPPalette*) palette showBorder:(BOOL) showBorder {
    self.text = text;
    if(!self.palette) {
        self.palette = [[CIPPalette alloc] init];
    }
    [self.palette  copyFontFrom:palette];
    self.showBorder = showBorder;
    [self setNeedsDisplay];
}

- (void) paintTextWithBorder:(BOOL)showBorder {
    self.showBorder = showBorder;
    [self setNeedsDisplay];
}

- (UIImage*) getThumbnailWithinSize:(CGSize) targetSize {
    UIGraphicsBeginImageContextWithOptions(targetSize, NO, 1.0);
    [self.text drawInRect:CGRectMake(4, 4, targetSize.width-8, targetSize.height-8) withFont:[UIFont systemFontOfSize:12] lineBreakMode:NSLineBreakByTruncatingTail];
    UIImage *thumbImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return thumbImage;
}

- (void) translate:(CGPoint)translate {
    [super translate:translate];
    self.textRect = CGRectMake(self.textRect.origin.x+translate.x, self.textRect.origin.y+translate.y, self.textRect.size.width, self.textRect.size.height);
}

- (void) scaleComponent:(CGFloat)scale component:(NSUInteger)xy {
    CGAffineTransform trans = self.affineTransform;
    //self.affineTransform = CGAffineTransformIdentity;
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
    CGPoint center = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame));
    CGFloat fontSize = MIN(self.palette.font.pointSize*sy, [CIPPalette maxSize]);
    CGFloat newWidth = self.textRect.size.width*sx;

    CGSize newTextSize = CGSizeMake(newWidth, self.textRect.size.height);
    self.palette.font = [self.palette.font fontWithSize:fontSize];
    newTextSize = CGSizeMake(MAX(80, newTextSize.width), MAX(80, newTextSize.height));
    
    CGSize newFrameSize = CGSizeApplyAffineTransform(newTextSize, trans);
    self.textRect = CGRectMake(center.x-newTextSize.width/2, center.y-newTextSize.height/2, newTextSize.width, newTextSize.height);

    self.frame = CGRectMake(center.x-newFrameSize.width/2, center.y-newFrameSize.height/2, newFrameSize.width, newFrameSize.height);
    [self paintTextWithBorder:YES];
}

- (void) enlarge:(CGFloat)scale component:(NSUInteger)xy delta:(CGFloat)dx {
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
    CGPoint center = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame));
    CGFloat fontSize = MIN(self.palette.font.pointSize*sy, [CIPPalette maxSize]);
    CGFloat newWidth = self.textRect.size.width;
    if ((sx > 1 && dx > newWidth) || (sx < 1 && dx < newWidth)) {
        newWidth = dx;
    }
    CGSize newTextSize = CGSizeMake(newWidth, self.textRect.size.height);
    self.palette.font = [self.palette.font fontWithSize:fontSize];
    newTextSize = CGSizeMake(MAX(80, newTextSize.width), MAX(80, newTextSize.height));
    self.textRect = CGRectMake(center.x-newTextSize.width/2, center.y-newTextSize.height/2, newTextSize.width, newTextSize.height);
    
    self.frame = CGRectMake(center.x-newTextSize.width/2, center.y-newTextSize.height/2, newTextSize.width, newTextSize.height);
    [self paintTextWithBorder:YES];
    
}

- (void) rotate:(CGFloat) angle {
    //[super rotate:angle];
    self.angle = fmodf(self.angle+angle, M_PI*2);
    [self paintTextWithBorder:YES];
}

#pragma mark -
#pragma mark Layer Data Convert Function
- (LayerType) getLayerType {
    return TextLayer;
}

- (void) recoverLayerIn:(CGRect)textRect withText:(NSString*)text withAngle:(CGFloat)angle withPalette:(CIPPalette*)palette {
    [self setupTextRect:textRect withBackColor:[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.2] withPalette:palette];
    self.angle = angle;
    [self paintText:text withPalette:palette showBorder:NO];
}

- (NSDictionary*) getUpdateHistory {
    NSMutableDictionary *attrs = [NSMutableDictionary dictionaryWithCapacity:5];
    [attrs setValue:[NSNumber numberWithInteger:[self getLayerType]] forKey:HISTORY_KEY_TYPE];
    [attrs setValue:[NSValue valueWithCGRect:self.textRect] forKey:HISTORY_KEY_TEXTRECT];
    [attrs setValue:[NSNumber numberWithFloat:self.angle] forKey:HISTORY_KEY_ANGLE];
    [attrs setValue:self.text forKey:HISTORY_KEY_TEXT];
    [attrs setValue:[self.palette copy] forKey:HISTORY_KEY_PALETTE];
    return attrs;
}

- (void) loadUpdateHistory:(NSDictionary*)histAttrs {
    CGRect textRect = [(NSValue*)[histAttrs valueForKey:HISTORY_KEY_TEXTRECT] CGRectValue];
    CGFloat angle = [(NSNumber*)[histAttrs valueForKey:HISTORY_KEY_ANGLE] floatValue];
    NSString *text = [histAttrs valueForKey:HISTORY_KEY_TEXT];
    CIPPalette *palette = [histAttrs valueForKey:HISTORY_KEY_PALETTE];
    
    [self recoverLayerIn:textRect withText:text withAngle:angle withPalette:palette];
}

- (NSDictionary*) getTransformHistory {
    NSMutableDictionary *attrs = [NSMutableDictionary dictionaryWithCapacity:3];
    [attrs setValue:[NSNumber numberWithInteger:[self getLayerType]] forKey:HISTORY_KEY_TYPE];
    [attrs setValue:[NSValue valueWithCGRect:self.textRect] forKey:HISTORY_KEY_TEXTRECT];
    [attrs setValue:[NSNumber numberWithFloat:self.angle] forKey:HISTORY_KEY_ANGLE];
    return attrs;
}

- (void) loadTransformHistory:(NSDictionary*)histAttrs {
    CGRect textRect = [(NSValue*)[histAttrs valueForKey:HISTORY_KEY_TEXTRECT] CGRectValue];
    CGFloat angle = [(NSNumber*)[histAttrs valueForKey:HISTORY_KEY_ANGLE] floatValue];
    [self recoverLayerIn:textRect withText:self.text withAngle:angle withPalette:self.palette];
}

// text rect, angle, text length, text, palette length, palette
- (NSData*) getLayerData {
    NSMutableData *data = [NSMutableData dataWithCapacity:1024];
    [data appendData:[CIPUtilities dataFromRect:self.textRect]];
    CGFloat angle = self.angle;
    [data appendBytes:&angle length:sizeof(angle)];

    NSData *strData = [self.text dataUsingEncoding:NSUTF8StringEncoding];
    NSUInteger strL = strData.length;
    [data appendBytes:&strL length:sizeof(strL)];
    [data appendData:strData];

    NSData *paletteData = [self.palette convert2JSONData];
    NSUInteger paletteL = paletteData.length;
    [data appendBytes:&paletteL length:sizeof(paletteL)];
    [data appendData:paletteData];

    return data;
}

- (void) loadLayerData:(NSData*)data  {
    NSUInteger l = sizeof(CGFloat)*4;
    NSUInteger offset = 0;
    CGRect textRect = [CIPUtilities rectFromData:data];
    offset += l;
    
    CGFloat angle;
    l = sizeof(angle);
    [data getBytes:&angle range:NSMakeRange(offset, l)];
    offset += l;
    
    NSUInteger strL;
    l = sizeof(strL);
    [data getBytes:&strL range:NSMakeRange(offset, l)];
    offset += l;
    
    l = strL;
    NSString *text = [[NSString alloc] initWithData:[data subdataWithRange:NSMakeRange(offset, l)] encoding:NSUTF8StringEncoding];
    offset += l;
    
    NSUInteger paletteL;
    l = sizeof(paletteL);
    [data getBytes:&paletteL range:NSMakeRange(offset, l)];
    offset += l;
    
    CIPPalette *palette = [[CIPPalette alloc] init];
    [palette convertFromJSONData:[data subdataWithRange:NSMakeRange(offset, paletteL)]];
    
    [self recoverLayerIn:textRect withText:text withAngle:angle withPalette:palette];
}

@end
