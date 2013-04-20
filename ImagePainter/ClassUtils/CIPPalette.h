//
//  CIPPalette.h
//  ImagePainter
//
//  Created by yuxinjin on 12-9-28.
//  Copyright (c) 2012年 yuxinjin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CIPPalette : NSObject


@property (nonatomic) UIColor *strokeColor;
@property (nonatomic) UIColor *fillColor;

@property (nonatomic) NSUInteger brushType;
@property (nonatomic) ShapeType shapeType;
@property (nonatomic) CGFloat strokeWidth;
@property (nonatomic) CGLineJoin lineJoin;
@property (nonatomic) CGLineCap lineCap;

@property (nonatomic) UIFont *font;
@property (nonatomic) UIColor *fontColor;
@property (nonatomic) UIColor *fontBorderColor;
@property (nonatomic) CGFloat fontBorderWidth;
@property (nonatomic) CGTextDrawingMode textMode;
@property (nonatomic) NSTextAlignment textAlignment;

@property (nonatomic) NSMutableArray *colorHistory;

- (void) copyFontFrom:(CIPPalette*)palette;

- (void) recordColor:(UIColor*)color;

- (NSData*) convert2JSONData;
- (void) convertFromJSONData:(NSData*)jsData;


+ (UIColor*) replaceColor:(UIColor*) color component:(NSInteger)idx withValue:(CGFloat) value;
+ (CGFloat) getComponentInColor:(UIColor*) color at:(NSInteger) idx;
+ (CGFloat) getGrayColor:(UIColor*) color;

+ (UIColor*)borderColor;
+ (UIColor*)fontDarkColor;
+ (UIFont*)appFontWithSize:(CGFloat)size;
+ (NSArray*)systemColors;
+ (CGFloat)maxSize;
@end
