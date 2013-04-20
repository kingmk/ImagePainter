//
//  CIPUtilities.h
//  ImagePainter
//
//  Created by yuxinjin on 12-10-1.
//  Copyright (c) 2012年 yuxinjin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CIPUtilities : NSObject

+ (void) printPoint:(CGPoint)point withDescription:(NSString*)description;
+ (void) printSize:(CGSize)size withDescription:(NSString*)description;
+ (void) printRect:(CGRect)rect withDescription:(NSString*)description;
+ (void) printAffineMatrix:(CGAffineTransform)affine withDescription:(NSString*)description;

+ (void) printColor:(UIColor*)color withDescription:(NSString*)description;
+ (void) printImageInfo:(CGImageRef)cgImage;

+ (UIColor*) copyColor:(UIColor*)color;
+ (UIFont*) copyFont:(UIFont*)font;

+ (void) randomColors:(CGFloat*)colors;
+ (NSInteger) randomInt:(NSInteger) maxInt;
+ (CGFloat) randomFloat:(CGFloat) maxFloat;

+ (CGFloat) getScaleOfAffine:(CGAffineTransform) affine;
+ (CGFloat) getScaleXOfAffine:(CGAffineTransform) affine;
+ (CGFloat) getScaleYOfAffine:(CGAffineTransform) affine;
+ (CGFloat) getRotateOfAffine:(CGAffineTransform) affine;

+ (CGFloat) distanceBetweenPoint:(CGPoint)point1 andPoint:(CGPoint)point2;

+ (NSArray*) serializeRGBColor:(UIColor*)color;
+ (NSDictionary*) serializeFont:(UIFont*)font;

+ (UIColor*) deserializeRGBColor:(NSArray*)array;
+ (UIFont*) deserializeFont:(NSDictionary*)dict;

+ (NSData*) dataFromRect:(CGRect)rect;
+ (CGRect) rectFromData:(NSData*)data;

+ (NSData*) dataFromAffine:(CGAffineTransform)affine;
+ (CGAffineTransform) affineFromData:(NSData*)data;

+ (NSArray*) getFontFamilies;
+ (NSString*) displayDate:(NSDate*)date;
+ (UIActivityIndicatorView*) initActivityIndicator:(UIView*)sView;
+ (void) activityIndicatorInView:(UIView*)sView withTask:(void (^)(void))task;


+ (id) test:(id)input;

@end