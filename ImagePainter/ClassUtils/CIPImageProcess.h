//
//  CIPImageProcess.h
//  ImagePainter
//
//  Created by yuxinjin on 12-9-29.
//  Copyright (c) 2012年 yuxinjin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CIPImageProcess : NSObject

+ (unsigned char *) getBitmapDataFrom:(CGImageRef)image;
+ (unsigned char *) getPixelColorFromImage:(CGImageRef)cgImage at:(CGPoint)point;
+ (unsigned char *) getAverageColorFromImage:(CGImageRef)cgImage around:(CGPoint)point withN:(NSUInteger)n;

+ (CGFloat) getScaleFor:(UIImage*)image toFitInto:(CGSize) size;
+ (CGFloat) getScaleFor:(UIImage*)image toFitOutof:(CGSize) size;

+ (UIImage*) fitImage:(UIImage*)srcImage into:(CGSize) size;
+ (UIImage*) fitImage:(UIImage*)srcImage outof:(CGSize) size;
+ (UIImage*) pasteImage:(UIImage*)srcImage intoSize:(CGSize)size;

+ (UIImage*) scaleImage:(UIImage*)srcImage withScale:(CGFloat) scale;
+ (UIImage*) scaleImage:(UIImage*)srcImage withScaleX:(CGFloat)scaleX scaleY:(CGFloat)scaleY;

+ (UIImage*) rotateImage:(UIImage*)srcImage withAngle:(CGFloat) angle;

+ (UIImage*) cropImage:(UIImage *)srcImage within:(CGRect)cropRect;
+ (UIImage*) clearImage:(UIImage *)srcImage in:(CGRect)clearRect;

+ (UIImage*) drawImage:(UIImage *)image onto:(UIImage*)backImage inRect:(CGRect)rect;

+ (CGRect) getImageBoundsFor:(CGImageRef)cgImage;

+ (void)convertRGB:(CGFloat*)rgb toHSV:(CGFloat*)hsv;
+ (void)convertHSV:(CGFloat*)hsv toRGB:(CGFloat*)rgb;

+ (CGImageRef) generateImageWithMask:(UIImage*)mask withColor:(UIColor*)color;

+ (UIImage*) generateImageWithColor:(UIColor*)color onMask:(UIImage*)maskImage;

+ (UIImage*) test:(UIImage*)cgImage;

@end
