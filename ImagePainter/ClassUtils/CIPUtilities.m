//
//  CIPUtilities.m
//  ImagePainter
//
//  Created by yuxinjin on 12-10-1.
//  Copyright (c) 2012年 yuxinjin. All rights reserved.
//
NSString *const JSKEY_FONT_FAMILYNAME = @"familyName";
NSString *const JSKEY_FONT_POINTSIZE = @"pointSize";

#import "CIPUtilities.h"

static NSArray *fontFamilies;
@implementation CIPUtilities

#pragma mark -
#pragma mark Information Printing Function
+ (void)printPoint:(CGPoint)point withDescription:(NSString *)description {
    NSLog(@"%@ :point:(%.0f, %.0f)", description, point.x, point.y);}

+ (void) printSize:(CGSize)size withDescription:(NSString *)description {
    NSLog(@"%@ :size:(%.0f, %.0f)", description, size.width, size.height);
}

+ (void) printRect:(CGRect)rect withDescription:(NSString *)description {
    NSLog(@"%@ :rect origin:(%.0f, %.0f), size:(%.0f, %.0f)", description, rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
}

+ (void) printAffineMatrix:(CGAffineTransform)affine withDescription:(NSString *)description {
    NSLog(@"%@:\n%3.2f,%3.2f,0\n%3.2f,%3.2f,0\n%3.2f,%3.2f,1",description, affine.a, affine.b, affine.c, affine.d, affine.tx, affine.ty);
}

+ (void) printColor:(UIColor*)color withDescription:(NSString*)description {
    const CGFloat *components = CGColorGetComponents(color.CGColor);
    NSLog(@"%@ :red:%.2f, green:%.2f, blue:%.2f, alpha:%.2f", description, components[0], components[1], components[2], components[3]);
}

+ (void) printImageInfo:(CGImageRef)cgImage {
    int w = CGImageGetWidth(cgImage);
    int h = CGImageGetHeight(cgImage);
    int bytesPerRow = CGImageGetBytesPerRow(cgImage);
    int bitsPerPixel = CGImageGetBitsPerPixel(cgImage);
    int bitsPerComponent = CGImageGetBitsPerComponent(cgImage);
    NSLog(@"width:%d, height:%d, bitsPerPixel:%d, bitsPerComponent:%d, bytesPerRow:%d", w, h, bitsPerPixel, bitsPerComponent, bytesPerRow);
}

+ (UIColor*) copyColor:(UIColor*)color {
    CGColorRef cgColor = color.CGColor;
    CGColorRef cgCopyColor = CGColorCreateCopy(cgColor);
    return [UIColor colorWithCGColor:cgCopyColor];
}

+ (UIFont*) copyFont:(UIFont *)font {
    UIFont *copyFont = [UIFont fontWithName:font.familyName size:font.pointSize];
    return copyFont;
}

#pragma mark -
#pragma mark Random Function
+ (void) randomColors:(CGFloat*)colors {
    colors[0] = (CGFloat)rand()/RAND_MAX;
    colors[1] = (CGFloat)rand()/RAND_MAX;
    colors[2] = (CGFloat)rand()/RAND_MAX;
    colors[3] = (CGFloat)rand()/RAND_MAX;
}

+ (NSInteger) randomInt:(NSInteger) maxInt {
    return ((CGFloat)rand()/RAND_MAX)*(CGFloat)maxInt;
}

+ (CGFloat) randomFloat:(CGFloat) maxFloat {
    return ((CGFloat)rand()/RAND_MAX)*maxFloat;
}

#pragma mark -
#pragma mark Geometry Value Function
+ (CGFloat) getScaleOfAffine:(CGAffineTransform) affine {
    return sqrtf(affine.a*affine.a+affine.b*affine.b);
}

+ (CGFloat) getScaleXOfAffine:(CGAffineTransform) affine {
    return sqrtf(affine.a*affine.a+affine.c*affine.c);
}

+ (CGFloat) getScaleYOfAffine:(CGAffineTransform) affine {
    return sqrtf(affine.b*affine.b+affine.d*affine.d);
}

+ (CGFloat) getRotateOfAffine:(CGAffineTransform) affine {
    return atan2f(affine.b, affine.a);
}

+ (CGFloat) distanceBetweenPoint:(CGPoint)point1 andPoint:(CGPoint)point2 {
    CGFloat dx = point1.x-point2.x;
    CGFloat dy = point1.y-point2.y;
    return sqrtf(dx*dx+dy*dy);
}

#pragma mark -
#pragma mark Data Convertion Function
+ (NSArray*) serializeRGBColor:(UIColor *)color {
    const CGFloat *components = CGColorGetComponents(color.CGColor);
    NSArray *array = [NSArray arrayWithObjects:[NSNumber numberWithFloat:components[0]], [NSNumber numberWithFloat:components[1]], [NSNumber numberWithFloat:components[2]], [NSNumber numberWithFloat:components[3]], nil];
    return array;
}

+ (NSDictionary*) serializeFont:(UIFont *)font {
    NSMutableDictionary *fontDict = [NSMutableDictionary dictionaryWithCapacity:2];
    [fontDict setValue:font.familyName forKey:JSKEY_FONT_FAMILYNAME];
    [fontDict setValue:[NSNumber numberWithFloat:font.pointSize] forKey:JSKEY_FONT_POINTSIZE];
    
    return fontDict;
}

+ (UIColor*) deserializeRGBColor:(NSArray *)array {
    UIColor *color = [UIColor colorWithRed:[(NSNumber*)array[0] floatValue] green:[(NSNumber*)array[1] floatValue] blue:[(NSNumber*)array[2] floatValue] alpha:[(NSNumber*)array[3] floatValue]];
    return color;
}

+ (UIFont*) deserializeFont:(NSDictionary *)dict {
    UIFont *font = [UIFont fontWithName:[dict valueForKey:JSKEY_FONT_FAMILYNAME] size:[(NSNumber*)[dict valueForKey:JSKEY_FONT_POINTSIZE] floatValue]];
    
    return font;
}

+ (NSData*)dataFromRect:(CGRect)rect {
    CGFloat rectParams[] = {rect.origin.x, rect.origin.y, rect.size.width, rect.size.height};
    return [NSData dataWithBytes:rectParams length:sizeof(rectParams)];
}

+ (CGRect)rectFromData:(NSData *)data {
    CGFloat rectParams[4];
    [data getBytes:rectParams length:sizeof(rectParams)];
    return CGRectMake(rectParams[0], rectParams[1], rectParams[2], rectParams[3]);
}

+ (NSData*)dataFromAffine:(CGAffineTransform)affine {
    CGFloat affineParams[] = {affine.a, affine.b, affine.c, affine.d, affine.tx, affine.ty};
    return [NSData dataWithBytes:affineParams length:sizeof(affineParams)];
}

+ (CGAffineTransform)affineFromData:(NSData *)data {
    CGFloat affineParams[6];
    [data getBytes:affineParams length:sizeof(affineParams)];
    return  CGAffineTransformMake(affineParams[0], affineParams[1], affineParams[2], affineParams[3], affineParams[4], affineParams[5]);
}

#pragma mark -
#pragma mark Other Function

+ (NSArray*) getFontFamilies {
    if (!fontFamilies) {
        NSMutableArray *varfonts = [NSMutableArray arrayWithArray:[UIFont familyNames]];
        fontFamilies = [varfonts sortedArrayUsingSelector:@selector(compare:)];
    }
    return fontFamilies;
}

+ (NSString*) displayDate:(NSDate*)date {
    NSDateFormatter *datef = [[NSDateFormatter alloc] init];
    [datef setDateFormat:@"yyyy-MM-dd EEE HH:mm:ss"];
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *comp1 = [calendar components: NSUIntegerMax fromDate: [NSDate date]];
    [comp1 setHour: 0];
    [comp1 setMinute: 0];
    [comp1 setSecond: 0];
    
    NSDate *d1 = [calendar dateFromComponents: comp1];
    
    [comp1 setMonth:1];
    [comp1 setDay:1];
    NSDate *d2 = [calendar dateFromComponents: comp1];
    
    NSString *displayStr;
    if ([date compare:d1] == NSOrderedDescending) {
        [datef setDateFormat:@"HH:mm"];
        displayStr = [NSString stringWithFormat:@"Today %@", [datef stringFromDate:date]];
    } else if ([date compare:d2] == NSOrderedDescending) {
        [datef setDateFormat:@"MMM.dd HH:mm"];
        displayStr = [datef stringFromDate:date];
    } else {
        [datef setDateFormat:@"yyyy MMM.dd"];
        displayStr = [datef stringFromDate:date];
    }
    return displayStr;
}

+ (UIActivityIndicatorView*) initActivityIndicator:(UIView *)sView {
    UIActivityIndicatorView* activityIndicator = [[UIActivityIndicatorView alloc]
                              initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    activityIndicator.bounds = CGRectMake(0, 0, 40, 40);
    activityIndicator.hidesWhenStopped = YES;
    activityIndicator.alpha = 0.7f;
    activityIndicator.backgroundColor = [UIColor blackColor];
    activityIndicator.layer.cornerRadius = 10.0f;

    CGSize viewSize = sView.frame.size;
    activityIndicator.center = CGPointMake(viewSize.width / 2.0, viewSize.height / 2.0);
    [sView addSubview:activityIndicator];
    return activityIndicator;
}

+ (void) activityIndicatorInView:(UIView*)sView withTask:(void (^)(void))task{
    UIActivityIndicatorView *activityIndicator = [CIPUtilities initActivityIndicator:sView];
    [activityIndicator startAnimating];
    dispatch_queue_t queue = dispatch_queue_create("com.imagepainter.ActivityIndicator", nil);
    dispatch_async(queue, ^{
        task();
        [activityIndicator stopAnimating];
        [activityIndicator removeFromSuperview];
    });
    dispatch_release(queue);
}

+ (id)test:(id)input {
    return nil;
}

@end
