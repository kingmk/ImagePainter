//
//  CIPBrushPattern.m
//  ImagePainter
//
//  Created by yuxinjin on 12-10-18.
//  Copyright (c) 2012年 yuxinjin. All rights reserved.
//

#import "CIPBrushUtilities.h"

typedef struct {
    CGSize size;
    CGFloat colors[4];
    NSUInteger patternIdx;
} BruchPatternInfo;

#define PATTERN_WIDTH 60
#define PATTERN_NUMBER 8
#define PATTERN_IMAGE @"brush_style_2.png"

@implementation CIPBrushUtilities

static NSArray *patternImages;

void brushPattern(void *info, CGContextRef context) {
    BruchPatternInfo bInfo = *(BruchPatternInfo*)info;
    CGImageRef pattern = [CIPBrushUtilities getBrushForType:bInfo.patternIdx withColor:bInfo.colors];
    CGRect rect = CGRectMake(0, 0, bInfo.size.width, bInfo.size.height);
    CGContextDrawImage(context, rect, pattern);
    CGImageRelease(pattern);
}

+ (void) drawBrushImage:(CGImageRef)brushImage inSize:(CGSize)size atPoint:(CGPoint)point on:(CGContextRef)context {
    CGContextDrawImage(context, CGRectMake(point.x-size.width/2, point.y-size.height/2, size.width, size.height), brushImage);
}

+ (void) drawBrushImage:(CGImageRef)brushImage inSize:(CGSize)size from:(CGPoint)p1 to:(CGPoint)p2 on:(CGContextRef)context withStep:(CGFloat)step {
    CGFloat l = [CIPUtilities distanceBetweenPoint:p1 andPoint:p2];
    CGFloat xstep = step*(p2.x-p1.x)/l;
    CGFloat ystep = step*(p2.y-p1.y)/l;
    CGFloat x = p1.x;
    CGFloat y = p1.y;
    
    for (CGFloat i=0; i<l; i+=step) {
        [CIPBrushUtilities drawBrushImage:brushImage inSize:size atPoint:CGPointMake(x, y) on:context];
        x += xstep;
        y += ystep;
    }
}

+ (CGImageRef)getBrushForType:(NSUInteger)patternIdx withColor:(CGFloat*)colors {
    UIImage *patternImage;
    if (!patternImages) {
        patternImages = [CIPBrushUtilities loadPatterns];
    }
    patternImage = patternImages[patternIdx];
    CGRect rect = {0,0,PATTERN_WIDTH,PATTERN_WIDTH};
    
    UIGraphicsBeginImageContext(CGSizeMake(PATTERN_WIDTH, PATTERN_WIDTH));
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [UIColor colorWithRed:colors[0] green:colors[1] blue:colors[2] alpha:colors[3]].CGColor);
    CGContextFillRect(context, rect);
    UIImage *constImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    CGFloat bitsPerComponent = CGImageGetBitsPerComponent(patternImage.CGImage);
    CGFloat bitsPerPixel = CGImageGetBitsPerPixel(patternImage.CGImage);
    CGFloat bytesPerRow = CGImageGetBytesPerRow(patternImage.CGImage);
    CGImageRef mask = CGImageMaskCreate(PATTERN_WIDTH, PATTERN_WIDTH, bitsPerComponent, bitsPerPixel, bytesPerRow, CGImageGetDataProvider(patternImage.CGImage), nil, NO);
    
    CGImageRef rsltImage = CGImageCreateWithMask(constImage.CGImage, mask);
    CGImageRelease(mask);
    return rsltImage;
}

+ (NSArray*)loadPatterns{
    UIImage *patterns = [UIImage imageNamed:PATTERN_IMAGE];
    NSMutableArray *images = [NSMutableArray arrayWithCapacity:PATTERN_NUMBER];
    
    CGFloat xpos = 0;
    CGFloat ypos = 0;
    CGFloat w = PATTERN_WIDTH;
    
    for (int x=0; x<PATTERN_NUMBER; x++) {
        CGRect rect = CGRectMake(xpos, ypos, w, w);
        UIImage *pattern = [CIPImageProcess cropImage:patterns within:rect];
        [images addObject:pattern];
        xpos += w;
    }
    return images;
}

+ (CGPatternRef) createBrushPattern:(NSUInteger)patternIdx withSize:(CGSize)size withAffine:(CGAffineTransform)transform withColor:(CGFloat *)colors{
    static BruchPatternInfo info;
    info.size = CGSizeMake(size.width, size.height);
    memcpy(info.colors, colors, 4*sizeof(CGFloat));
    info.patternIdx = patternIdx;

    static const CGPatternCallbacks callbacks = {0, &brushPattern, NULL};
    CGPatternRef pattern = CGPatternCreate(&info, CGRectMake(0, 0, size.width, size.height), transform, 1, size.height,kCGPatternTilingConstantSpacing, true, &callbacks);
    return pattern;
}

+ (UIImageView*)test:(NSUInteger)patterIdx {
    


    return nil;
}

@end
