//
//  CIPImageProcess.m
//  ImagePainter
//
//  Created by yuxinjin on 12-9-29.
//  Copyright (c) 2012年 yuxinjin. All rights reserved.
//

#import "CIPImageProcess.h"

@implementation CIPImageProcess

+ (unsigned char *)getBitmapDataFrom:(CGImageRef)cgImage {
    NSUInteger w = CGImageGetWidth(cgImage);
    NSUInteger h = CGImageGetHeight(cgImage);
    NSUInteger bitsPerComponent = 8;
    NSUInteger bytesPerRow = w*4;
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    unsigned char *data = malloc(w*h*4);
    CGContextRef context = CGBitmapContextCreate(data, w, h, bitsPerComponent, bytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast);
    CGContextDrawImage(context, CGRectMake(0, 0, w, h), cgImage);
    
    data = CGBitmapContextGetData(context);
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);
    return data;
}

+ (unsigned char *) getPixelColorFromImage:(CGImageRef)cgImage at:(CGPoint)point {
    if (!cgImage) {
        return nil;
    }
    NSUInteger size = sizeof(unsigned char)*4;
    unsigned char  *cs = malloc(size);
    unsigned char* data = [CIPImageProcess getBitmapDataFrom:cgImage];
    NSInteger w = CGImageGetWidth(cgImage);
    NSInteger h = CGImageGetHeight(cgImage);
    NSUInteger bytesPerRow = w*4;
    NSUInteger bytesPerPixel = 4;
    if (point.x<0 || point.x>w || point.y<0 || point.y>h) {
        free(data);
        free(cs);
        return nil;
    } else {
        NSUInteger i = round(point.y)*bytesPerRow + round(point.x)*bytesPerPixel;
        memcpy(cs, data+i, size);
        free(data);
        return cs;
    }
}

+ (unsigned char *) getAverageColorFromImage:(CGImageRef)cgImage around:(CGPoint)point withN:(NSUInteger)n {
    if (!cgImage) {
        return nil;
    }
//    [CIPUtilities printPoint:point withDescription:@"select point"];
//    [CIPUtilities printImageInfo:cgImage];
    NSUInteger size = sizeof(unsigned char)*4;
    unsigned char  *cs = malloc(size);
    unsigned char* data = [CIPImageProcess getBitmapDataFrom:cgImage];
    NSInteger w = CGImageGetWidth(cgImage);
    NSInteger h = CGImageGetHeight(cgImage);
    NSUInteger bytesPerRow = w*4;
    NSUInteger bytesPerPixel = 4;
    
    NSInteger minx, maxx, miny, maxy;
    minx = MAX(round(point.x)-n, 0);
    maxx = MIN(round(point.x)+n, w-1);
    miny = MAX(round(point.y)-n, 0);
    maxy = MIN(round(point.y)+n, h-1);
    
    if (minx>=maxx || miny>=maxy) {
        free(data);
        free(cs);
        return nil;
    } else {
        int count = 0;
        int tmpcs[4] = {0, 0, 0, 0};
        for (int y=miny; y<=maxy; y++) {
            for (int x=minx; x<=maxx; x++) {
                int idx = y*bytesPerRow + x*bytesPerPixel;
                //NSLog(@"point: (%d, %d), select color: %d, %d, %d, %d", x, y, data[idx], data[idx+1], data[idx+2], data[idx+3]);
                tmpcs[0] += data[idx];
                tmpcs[1] += data[idx+1];
                tmpcs[2] += data[idx+2];
                tmpcs[3] += data[idx+3];
                count ++;
            }
        }
        cs[0] = tmpcs[0]/count;
        cs[1] = tmpcs[1]/count;
        cs[2] = tmpcs[2]/count;
        cs[3] = tmpcs[3]/count;
        free(data);
        return cs;
    }
}

#pragma mark -
#pragma mark Scale and Rotate Functions
+ (CGFloat) getScaleFor:(UIImage *)image toFitInto:(CGSize)size {
    CGFloat scale = 1.0;
    if (image.size.width>size.width || image.size.height>size.height) {
        if (image.size.width*size.height>image.size.height*size.width) {
            // the pic's width is much longer
            scale = size.width/image.size.width;
        } else {
            scale = size.height/image.size.height;
        }
    }
    return scale;
}

+ (CGFloat) getScaleFor:(UIImage*)image toFitOutof:(CGSize) size {
    CGFloat scale = 1.0;
    if (image.size.width>size.width && image.size.height>size.height) {
        if (image.size.width*size.height>image.size.height*size.width) {
            // the pic's width is much longer
            scale = size.height/image.size.height;
        } else {
            scale = size.width/image.size.width;
        }
    }
    return scale;
}

+ (UIImage*) fitImage:(UIImage *)srcImage into:(CGSize)size {
    CGFloat scale = [CIPImageProcess getScaleFor:srcImage toFitInto:size];

    size = CGSizeMake(srcImage.size.width*scale, srcImage.size.height*scale);
    
    UIGraphicsBeginImageContextWithOptions(size, NO, 1.0);
    [srcImage drawInRect:CGRectMake(0, 0, size.width, size.height)];
    
    UIImage *dstImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return dstImage;
}

+ (UIImage*) fitImage:(UIImage*)srcImage outof:(CGSize) size {
    CGFloat scale = [CIPImageProcess getScaleFor:srcImage toFitOutof:size];
    
    size = CGSizeMake(srcImage.size.width*scale, srcImage.size.height*scale);
    
    UIGraphicsBeginImageContextWithOptions(size, NO, 1.0);
    [srcImage drawInRect:CGRectMake(0, 0, size.width, size.height)];
    
    UIImage *dstImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return dstImage;
}

+ (UIImage*) pasteImage:(UIImage*)srcImage intoSize:(CGSize)size {
    if (srcImage.size.width > size.width || srcImage.size.height > size.height) {
        srcImage = [CIPImageProcess fitImage:srcImage into:size];
    }
    
    UIGraphicsBeginImageContextWithOptions(size, NO, 1.0);
    CGRect rect = CGRectMake((size.width-srcImage.size.width)/2, (size.height-srcImage.size.height)/2, srcImage.size.width, srcImage.size.height);
    [srcImage drawInRect:rect];
    
    UIImage *dstImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return dstImage;
}

+ (UIImage*) scaleImage:(UIImage *)srcImage withScale:(CGFloat)scale {
    CGSize dstSize = CGSizeMake(srcImage.size.width*scale, srcImage.size.height*scale);
    
    UIGraphicsBeginImageContextWithOptions(dstSize, NO, 1.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
    //[srcImage drawInRect:CGRectMake(0, 0, dstSize.width, dstSize.height)];
    [srcImage drawInRect:CGRectMake(0, 0, truncf(dstSize.width), truncf(dstSize.height)) blendMode:kCGBlendModeCopy alpha:1.0];
    UIImage *dstImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return dstImage;
}

+ (UIImage*) scaleImage:(UIImage *)srcImage withScaleX:(CGFloat)scaleX scaleY:(CGFloat)scaleY{
    CGSize dstSize = CGSizeMake(srcImage.size.width*scaleX, srcImage.size.height*scaleY);
    
    UIGraphicsBeginImageContextWithOptions(dstSize, NO, 1.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
    [srcImage drawInRect:CGRectMake(0, 0, truncf(dstSize.width), truncf(dstSize.height))];
    
    UIImage *dstImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return dstImage;
}

+ (UIImage*) rotateImage:(UIImage *)srcImage withAngle:(CGFloat)angle {
    CGAffineTransform transform = CGAffineTransformMakeRotation(angle);
    CGRect rotateRect = CGRectApplyAffineTransform(CGRectMake(0, 0, srcImage.size.width, srcImage.size.height), transform);
    
    UIGraphicsBeginImageContextWithOptions(rotateRect.size, NO, 1.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(context, rotateRect.size.width/2, rotateRect.size.height/2);
    CGContextRotateCTM(context, angle);
    [srcImage drawAtPoint:CGPointMake(-srcImage.size.width/2, -srcImage.size.height/2)];
    

    UIImage *dstImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return dstImage;
}

#pragma mark -
#pragma mark Draw functions

+ (UIImage*)drawImage:(UIImage *)image onto:(UIImage *)backImage inRect:(CGRect)rect {
    UIGraphicsBeginImageContext(backImage.size);
    [backImage drawInRect:CGRectMake(0, 0, backImage.size.width, backImage.size.height)];
    [image drawInRect:rect];
    
    UIImage *rltImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return rltImage;
}

#pragma mark -
#pragma mark Crop functions

+ (CGRect) getImageBoundsFor:(CGImageRef)cgImage {
    int w = CGImageGetWidth(cgImage);
    int h = CGImageGetHeight(cgImage);
    CGRect rect = CGRectMake(0, 0, w, h);
    
    int bytesPerRow = w*4;
    unsigned char* data = [CIPImageProcess getBitmapDataFrom:cgImage];
    int x, y;
    int idx = 0;
    int minx = w, maxx = 0, miny = h, maxy = 0;
    int rowIdx = 0;
    for (y=0; y<h; y++) {
        idx = rowIdx;
        for (x=0; x<w; x++) {
            int a = data[idx+3];
            if (a > 1) {
                minx = MIN(x, minx);
                maxx = MAX(x, maxx);
                miny = MIN(y, miny);
                maxy = MAX(y, maxy);
            }
            idx += 4;
        }
        rowIdx += bytesPerRow;
    }
    if (minx==w && maxx==0 && miny==h && maxy==0) {
        // no any non-transparent pixel exists
        rect = CGRectMake(0, 0, 0, 0);
    } else {
        rect = CGRectMake(minx, miny, maxx-minx, maxy-miny);
    }
    free(data);
    return rect;
}

+ (UIImage*) cropImage:(UIImage *)srcImage within:(CGRect) cropRect {
    UIGraphicsBeginImageContextWithOptions(cropRect.size, NO, 1.0);
    [srcImage drawAtPoint:CGPointMake(-cropRect.origin.x, -cropRect.origin.y)];
    
    UIImage *dstImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return dstImage;
}

+ (UIImage*)clearImage:(UIImage *)srcImage in:(CGRect)clearRect {
    UIGraphicsBeginImageContextWithOptions(srcImage.size, NO, 1.0);
    [srcImage drawAtPoint:CGPointZero];
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextClearRect(context, clearRect);
    UIImage *dstImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return dstImage;
}


#pragma mark -
#pragma mark Filter Functions

+ (void) convertRGB:(CGFloat *)rgb toHSV:(CGFloat *)hsv {
    CGFloat r = rgb[0], g = rgb[1], b = rgb[2];
    CGFloat h, s, v;
    CGFloat rgbMin = MIN(MIN(r, g), b);
    CGFloat rgbMax = MAX(MAX(r, g), b);
    CGFloat rgbDelta = rgbMax - rgbMin;
    if (rgbMin == rgbMax) {
        h = 0;
    } else if (rgbMax == r) {
        h = 60.0f*(g-b)/rgbDelta;
        h = fmodf(h+360.0f, 360.0f);
    } else if (rgbMax == g) {
        h = 60.0f*(b-r)/rgbDelta+120.0f;
    } else {
        h = 60.0f*(r-g)/rgbDelta+240.0f;
    }
    v = rgbMax;
    if (rgbMax == 0) {
        s = 0;
    } else {
        s = 1.0-(rgbMin/rgbMax);
    }
    hsv[0] = h/360.0f;
    hsv[1] = s;
    hsv[2] = v;
}

+ (void) convertHSV:(CGFloat *)hsv toRGB:(CGFloat *)rgb {
    CGFloat h = hsv[0], s = hsv[1], v = hsv[2];
    CGFloat p, q, t;
    CGFloat r, g, b;
    if (s == 0) {
        r = g = b = v;
    } else {
        if (h == 1.0) {
            h = 0;
        }
        h *= 6;
        NSInteger k = floorf(h);
        CGFloat f = h-k;
        p = v*(1.0-s);
        q = v*(1.0-s*f);
        t = v*(1.0-s*(1.0-f));
        switch (k) {
            case 0:
                r = v; g = t; b = p;
                break;
            case 1:
                r = q; g = v; b = p;
                break;
            case 2:
                r = p; g = v; b = t;
                break;
            case 3:
                r = p; g = q; b = v;
                break;
            case 4:
                r = t; g = p; b = v;
                break;
            case 5:
                r = v; g = p; b = q;
                break;
            default:
                r = 0; g = 0; b = 0;
                break;
        }
    }
    rgb[0] = r;
    rgb[1] = g;
    rgb[2] = b;
}

+ (CGImageRef) generateImageWithMask:(UIImage *)maskImage withColor:(UIColor *)color {
    UIGraphicsBeginImageContext(maskImage.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextFillRect(context, CGRectMake(0, 0, maskImage.size.width, maskImage.size.height));
    UIImage *constImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    CGFloat bitsPerComponent = CGImageGetBitsPerComponent(maskImage.CGImage);
    CGFloat bitsPerPixel = CGImageGetBitsPerPixel(maskImage.CGImage);
    CGFloat bytesPerRow = CGImageGetBytesPerRow(maskImage.CGImage);
    CGImageRef mask = CGImageMaskCreate(maskImage.size.width, maskImage.size.height, bitsPerComponent, bitsPerPixel, bytesPerRow, CGImageGetDataProvider(maskImage.CGImage), nil, NO);
    
    CGImageRef rsltImage = CGImageCreateWithMask(constImage.CGImage, mask);
    CGImageRelease(mask);
    return rsltImage;
}

+ (NSData*) createCubeWithDimension:(NSUInteger)dimension forHue:(CGFloat)hue withTolerance:(CGFloat)tolerance inReplace1:(CGFloat*)rgbRep1 withReplace2:(CGFloat*)rgbRep2 {
    CGFloat *cubeData = (CGFloat *)malloc (dimension * dimension * dimension * sizeof (float) * 4);
    CGFloat rgb[3], hsv[3], *c = cubeData;
    for (int z=0; z<dimension; z++) {
        rgb[2] = ((double)z)/(dimension-1);
        for (int y=0; y<dimension; y++) {
            rgb[1] = ((double)y)/(dimension-1);
            for (int x=0; x<dimension; x++) {
                rgb[0] = ((double)x)/(dimension-1);
                [CIPImageProcess convertRGB:rgb toHSV:hsv];
                if (ABS(hsv[0]*360-hue)<tolerance) {
                    c[0] = rgbRep1[0];
                    c[1] = rgbRep1[1];
                    c[2] = rgbRep1[2];
                    c[3] = rgbRep1[3];
                } else if (rgbRep2) {
                    c[0] = rgbRep2[0];
                    c[1] = rgbRep2[1];
                    c[2] = rgbRep2[2];
                    c[3] = rgbRep2[3];
                } else {
                    c[0] = rgb[0];
                    c[1] = rgb[1];
                    c[2] = rgb[2];
                    c[3] = 1.0;
                }
                c += 4;
            }
        }
    }
    
    NSData *rltData= [NSData dataWithBytesNoCopy:cubeData length:dimension*dimension*dimension*sizeof(CGFloat)*4 freeWhenDone:YES];
    free(cubeData);
    
    return rltData;
}

+ (UIImage*) generateImageWithColor:(UIColor *)color onMask:(UIImage *)maskImage {
    CGRect rect = CGRectMake(0, 0, maskImage.size.width, maskImage.size.height);
    UIGraphicsBeginImageContextWithOptions(maskImage.size, 0.0, maskImage.scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextFillRect(context, rect);
    UIImage *constImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    CGFloat bitsPerComponent = CGImageGetBitsPerComponent(maskImage.CGImage);
    CGFloat bitsPerPixel = CGImageGetBitsPerPixel(maskImage.CGImage);
    CGFloat bytesPerRow = CGImageGetBytesPerRow(maskImage.CGImage);
    CGImageRef mask = CGImageMaskCreate(maskImage.size.width*maskImage.scale, maskImage.size.height*maskImage.scale, bitsPerComponent, bitsPerPixel, bytesPerRow, CGImageGetDataProvider(maskImage.CGImage), nil, NO);
    
    CGImageRef rltCGImage = CGImageCreateWithMask(constImage.CGImage, mask);
    CGImageRelease(mask);
    
    UIImage *rltImg = [UIImage imageWithCGImage:rltCGImage];
    CGImageRelease(rltCGImage);
    return rltImg;
}

+ (UIImage*) drawImage:(UIImage *)originImage onOpaqueAreaIn:(UIImage *)maskImage scale:(CGFloat)scale {
    if (originImage.size.width*originImage.scale != maskImage.size.width*maskImage.scale || originImage.size.height*originImage.scale != maskImage.size.height*maskImage.scale) {
        return originImage;
    }
    int w = originImage.size.width*originImage.scale;
    int h = originImage.size.height*originImage.scale;
    unsigned char* originData = [CIPImageProcess getBitmapDataFrom:originImage.CGImage];
    unsigned char *maskData = [CIPImageProcess getBitmapDataFrom:maskImage.CGImage];
    unsigned char*resultData = malloc(sizeof(unsigned char)*w*h*4);
    
    int idx=0;
    for (int y=0; y<h; y++) {
        for (int x=0; x<w; x++) {
            int alpha = (int)maskData[idx+3];
            if (alpha >= 10) {
                resultData[idx] = originData[idx];
                resultData[idx+1] = originData[idx+1];
                resultData[idx+2] = originData[idx+2];
                resultData[idx+3] = originData[idx+3];
            } else {
                resultData[idx] = 0;
                resultData[idx+1] = 0;
                resultData[idx+2] = 0;
                resultData[idx+3] = 0;
            }
            idx += 4;
        }
    }
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(resultData, w, h, 8, w*4, colorSpace, kCGImageAlphaPremultipliedLast);
    
    CGImageRef rltImageRef = CGBitmapContextCreateImage(context);
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);
    
    UIImage *rltImage = [UIImage imageWithCGImage:rltImageRef scale:scale orientation:UIImageOrientationUp];
    CGImageRelease(rltImageRef);
    return rltImage;
}


+ (UIImage*) test:(UIImage*)image {
    int w = image.size.width;
    int h = image.size.height;
    UIGraphicsBeginImageContext(CGSizeMake(w, h));
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextDrawImage(context, CGRectMake(0, 0, w, h), image.CGImage);
    CGContextRotateCTM(context, M_PI/6);
    
    UIImage *rltImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    return rltImage;
}

@end
