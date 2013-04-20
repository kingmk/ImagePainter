//
//  CIPPalette.m
//  ImagePainter
//
//  Created by yuxinjin on 12-9-28.
//  Copyright (c) 2012年 yuxinjin. All rights reserved.
//

NSString *const JSKEY_COLOR_STROKE = @"strokeColor";
NSString *const JSKEY_COLOR_FILL = @"fillColor";
NSString *const JSKEY_BRUSHTYPE = @"brushType";
NSString *const JSKEY_SHAPETYPE = @"shapeType";
NSString *const JSKEY_STROKE_WIDTH = @"strokeWidth";
NSString *const JSKEY_LINE_JOIN = @"lineJoin";
NSString *const JSKEY_LINE_CAP = @"lineCap";
NSString *const JSKEY_FONT = @"font";
NSString *const JSKEY_FONT_COLOR = @"fontColor";
NSString *const JSKEY_FONT_COLOR_BORDER = @"fontBorderColor";
NSString *const JSKEY_FONT_BORDER_WIDTH = @"fontBorderWidth";
NSString *const JSKEY_TEXT_MODE = @"textMode";
NSString *const JSKEY_TEXT_ALIGNMENT = @"textAlignment";
NSString *const JSKEY_COLOR_HISTORY = @"colorHistory";

NSUInteger const COLOR_HISTORY_CAPACITY = 15;

#import "CIPPalette.h"
static NSArray *systemColors;
@implementation CIPPalette

- (id) init {
    self.strokeColor = [UIColor colorWithRed:0.9 green:0.3 blue:0.3 alpha:0.7];
    self.fillColor = [UIColor colorWithRed:0.0 green:0.5 blue:0.9 alpha:0.6];
    self.brushType = 0;
    self.shapeType = ShapeRect;
    self.strokeWidth = 8;
    self.lineJoin = kCGLineJoinRound;
    self.lineCap = kCGLineCapRound;
    
    self.font = [UIFont fontWithName:@"Bradley Hand" size:14];
    self.fontColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1.0];
    self.fontBorderColor = [UIColor colorWithRed:0.0 green:0.0 blue:1.0 alpha:1.0];
    self.fontBorderWidth = 1;
    self.textMode = kCGTextFill;
    self.textAlignment = NSTextAlignmentLeft;
    
    self.colorHistory = [NSMutableArray arrayWithCapacity:COLOR_HISTORY_CAPACITY];
    return self;
}

- (id) copy {
    CIPPalette *copy = [[CIPPalette alloc] init];
    copy.strokeColor = [CIPUtilities copyColor:self.strokeColor];
    copy.fillColor = [CIPUtilities copyColor:self.fillColor];
    copy.brushType = self.brushType;
    copy.shapeType = self.shapeType;
    copy.strokeWidth = self.strokeWidth;
    copy.lineJoin = self.lineJoin;
    copy.lineCap = self.lineCap;
    
    copy.font = [CIPUtilities copyFont:self.font];
    copy.fontColor = [CIPUtilities copyColor:self.fontColor];
    copy.fontBorderColor = [CIPUtilities copyColor:self.fontBorderColor];
    copy.fontBorderWidth = self.fontBorderWidth;
    copy.textMode = self.textMode;
    copy.textAlignment = self.textAlignment;
    return copy;
}

- (void) copyFontFrom:(CIPPalette*)palette {

    self.font = [CIPUtilities copyFont:palette.font];
    self.fontColor = [CIPUtilities copyColor:palette.fontColor];
    self.fontBorderColor = [CIPUtilities copyColor:palette.fontBorderColor];
    self.fontBorderWidth = palette.fontBorderWidth;
    self.textMode = palette.textMode;
    self.textAlignment = palette.textAlignment;
    return;
}

- (void) recordColor:(UIColor *)color {
    int i = 0;
    while (i<self.colorHistory.count) {
        UIColor *tmpColor = self.colorHistory[i];
        const CGFloat *comps1 = CGColorGetComponents(color.CGColor);
        const CGFloat *comps2 = CGColorGetComponents(tmpColor.CGColor);
        BOOL equal = YES;
        for (int j=0; j<4; j++) {
            CGFloat t1 = comps1[j];
            CGFloat t2 = comps2[j];
            if (fabsf(t1-t2) >= 0.01) {
                equal = NO;
                break;
            }
        }
        if (equal) {
            [self.colorHistory removeObjectAtIndex:i];
        } else {
            i++;
        }
    }
    if (self.colorHistory.count == COLOR_HISTORY_CAPACITY) {
        [self.colorHistory removeLastObject];
    }
    [self.colorHistory insertObject:color atIndex:0];
}

- (NSData*) convert2JSONData {
    NSMutableDictionary *jObj = [NSMutableDictionary dictionaryWithCapacity:12];
    [jObj setValue:[CIPUtilities serializeRGBColor:self.strokeColor] forKey:JSKEY_COLOR_STROKE];
    [jObj setValue:[CIPUtilities serializeRGBColor:self.fillColor] forKey:JSKEY_COLOR_FILL];
    [jObj setValue:[NSNumber numberWithUnsignedInteger:self.brushType] forKey:JSKEY_BRUSHTYPE];
    [jObj setValue:[NSNumber numberWithUnsignedInteger:self.shapeType] forKey:JSKEY_SHAPETYPE];
    [jObj setValue:[NSNumber numberWithFloat:self.strokeWidth] forKey:JSKEY_STROKE_WIDTH];
    [jObj setValue:[NSNumber numberWithInteger:self.lineJoin] forKey:JSKEY_LINE_JOIN];
    [jObj setValue:[NSNumber numberWithInteger:self.lineCap] forKey:JSKEY_LINE_CAP];
    [jObj setValue:[CIPUtilities serializeFont:self.font] forKey:JSKEY_FONT];
    [jObj setValue:[CIPUtilities serializeRGBColor:self.fontColor] forKey:JSKEY_FONT_COLOR];
    [jObj setValue:[CIPUtilities serializeRGBColor:self.fontBorderColor] forKey:JSKEY_FONT_COLOR_BORDER];
    [jObj setValue:[NSNumber numberWithFloat:self.fontBorderWidth] forKey:JSKEY_FONT_BORDER_WIDTH];
    [jObj setValue:[NSNumber numberWithInteger:self.textMode] forKey:JSKEY_TEXT_MODE];
    [jObj setValue:[NSNumber numberWithInteger:self.textAlignment] forKey:JSKEY_TEXT_ALIGNMENT];

    NSMutableArray *colorHistArr = [NSMutableArray arrayWithCapacity:self.colorHistory.count];
    for (UIColor *color in self.colorHistory) {
        NSArray *jsColor = [CIPUtilities serializeRGBColor:color];
        [colorHistArr addObject:jsColor];
    }
    [jObj setValue:colorHistArr forKey:JSKEY_COLOR_HISTORY];
    return [NSJSONSerialization dataWithJSONObject:jObj options:NSJSONWritingPrettyPrinted error:Nil];
}

- (void) convertFromJSONData:(NSData*)jsData {
    NSDictionary *jObj = [NSJSONSerialization JSONObjectWithData:jsData options:NSJSONReadingAllowFragments error:Nil];
    self.strokeColor = [CIPUtilities deserializeRGBColor:[jObj valueForKey:JSKEY_COLOR_STROKE]];
    self.fillColor = [CIPUtilities deserializeRGBColor:[jObj valueForKey:JSKEY_COLOR_FILL]];
    self.brushType = [(NSNumber*)[jObj valueForKey:JSKEY_BRUSHTYPE] unsignedIntegerValue];
    self.shapeType = [(NSNumber*)[jObj valueForKey:JSKEY_SHAPETYPE] unsignedIntegerValue];
    self.strokeWidth = [(NSNumber*)[jObj valueForKey:JSKEY_STROKE_WIDTH] floatValue];
    self.lineJoin = [(NSNumber*)[jObj valueForKey:JSKEY_LINE_JOIN] integerValue];
    self.lineCap = [(NSNumber*)[jObj valueForKey:JSKEY_LINE_CAP] integerValue];
    
    self.font = [CIPUtilities deserializeFont:[jObj valueForKey:JSKEY_FONT]];
    self.fontColor = [CIPUtilities deserializeRGBColor:[jObj valueForKey:JSKEY_FONT_COLOR]];
    self.fontBorderColor = [CIPUtilities deserializeRGBColor:[jObj valueForKey:JSKEY_FONT_COLOR_BORDER]];
    
    self.fontBorderWidth = [(NSNumber*)[jObj valueForKey:JSKEY_FONT_BORDER_WIDTH] floatValue];
    self.textMode = [(NSNumber*)[jObj valueForKey:JSKEY_TEXT_MODE] integerValue];
    self.textAlignment = [(NSNumber*)[jObj valueForKey:JSKEY_TEXT_ALIGNMENT] integerValue];
    
    [self.colorHistory removeAllObjects];
    self.colorHistory = [NSMutableArray arrayWithCapacity:COLOR_HISTORY_CAPACITY];
    NSArray *colorHistArr = [jObj valueForKey:JSKEY_COLOR_HISTORY];
    for (NSArray *colorArr in colorHistArr) {
        UIColor *color = [CIPUtilities deserializeRGBColor:colorArr];
        [self.colorHistory addObject:color];
    }
}

+ (UIColor*) replaceColor:(UIColor*) color component:(NSInteger)idx withValue:(CGFloat) value {
    const CGFloat *components = CGColorGetComponents(color.CGColor);
    CGFloat newComponents[] = {components[0], components[1], components[2], components[3]};
    newComponents[idx] = value;
    return [UIColor colorWithRed:newComponents[0] green:newComponents[1] blue:newComponents[2] alpha:newComponents[3]];
}

+ (CGFloat) getComponentInColor:(UIColor *)color at:(NSInteger)idx {
    const CGFloat *components = CGColorGetComponents(color.CGColor);
    return components[idx];
}

+ (CGFloat) getGrayColor:(UIColor *)color {
    const CGFloat *components = CGColorGetComponents(color.CGColor);
    CGFloat gray = components[0]*0.3+components[1]*0.59+components[0]*0.11;
    
    return gray;
}

+ (UIColor*)borderColor {
    return [UIColor colorWithRed:0.27 green:0.6 blue:0.77 alpha:1.0];
}

+ (UIColor*)fontDarkColor {
    return [UIColor colorWithRed:0.14 green:0.31 blue:0.4 alpha:1.0];
}

+ (UIFont*)appFontWithSize:(CGFloat)size {
    return [UIFont fontWithName:@"Chalkboard SE" size:size];
}

+ (NSArray*)systemColors {
    if (!systemColors) {
        systemColors = [NSArray arrayWithObjects:[UIColor whiteColor], [UIColor blackColor], [UIColor redColor], [UIColor greenColor], [UIColor blueColor], [UIColor orangeColor], [UIColor cyanColor], [UIColor yellowColor], [UIColor purpleColor], [UIColor magentaColor], [UIColor brownColor], [UIColor grayColor], nil];
    }
    return systemColors;
}

+ (CGFloat)maxSize {
    return 40;
}
@end
