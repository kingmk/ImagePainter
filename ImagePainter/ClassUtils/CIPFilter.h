//
//  CIPFilter.h
//  ImagePainter
//
//  Created by yuxinjin on 12-11-10.
//  Copyright (c) 2012年 yuxinjin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CIPFilter : NSObject
+ (void) queryFilterInfo;

+ (NSDictionary*) queryFilterInfo:(NSString*) filterName;
+ (CGImageRef) applyFilter:(NSString*) filterName onImage:(CGImageRef)cgImage with:(NSDictionary*) params ;

+ (CGImageRef) generateCheckerBoardWithSize:(CGSize)size gridWidth:(CGFloat)width withColor:(UIColor *)color;
+ (CGImageRef) generateRandomWhiteSpecksIn:(CGSize) size;

+ (UIImage*) filterInstant:(UIImage*)image;
+ (UIImage*) filterExpose:(UIImage*)image;
+ (UIImage*) filterVibrance:(UIImage*)image;
+ (UIImage*) filterComic:(UIImage*)image;
+ (UIImage*) filterOcean:(UIImage*)image;
+ (UIImage*) filterLake:(UIImage*)image;
+ (UIImage*) filterEmboss:(UIImage*)image;
+ (UIImage*) filterOilPaint:(UIImage*)image;
+ (UIImage*) filterGrayish:(UIImage*)image;
+ (UIImage*) filterOldFilm:(UIImage *)image;

+ (UIImage*)test:(UIImage*) input;
@end
