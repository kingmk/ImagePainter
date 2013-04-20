//
//  CIPBrushPattern.h
//  ImagePainter
//
//  Created by yuxinjin on 12-10-18.
//  Copyright (c) 2012年 yuxinjin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CIPBrushUtilities : NSObject

+ (CGImageRef)getBrushForType:(NSUInteger)patternIdx withColor:(CGFloat*)colors;

+ (void) drawBrushImage:(CGImageRef)brushImage inSize:(CGSize)size atPoint:(CGPoint)point on:(CGContextRef)context;
+ (void) drawBrushImage:(CGImageRef)brushImage inSize:(CGSize)size from:(CGPoint)p1 to:(CGPoint)p2 on:(CGContextRef)context withStep:(CGFloat)step;

+ (UIImageView*) test:(NSUInteger)patterIdx;

@end
