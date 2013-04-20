//
//  CIPCustomViewUtils.m
//  ImagePainter
//
//  Created by yuxinjin on 12-10-24.
//  Copyright (c) 2012年 yuxinjin. All rights reserved.
//

#import "CIPCustomViewUtils.h"

#define PATTERN_NUMBER 8

@implementation CIPCustomViewUtils
void checkBoardPattern (void *info, CGContextRef context) {
    CGRect bounds = *((CGRect*)info);
    
    CGImageRef checkerBoard = [CIPFilter generateCheckerBoardWithSize:bounds.size gridWidth:bounds.size.height/3 withColor:[UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:1.0]];
    CGContextDrawImage(context, bounds, checkerBoard);
    
    CGGradientRef gradient;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGFloat locations[2] = {0.0, 1.0};
    CGFloat components[8] = {0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0};
    gradient = CGGradientCreateWithColorComponents(colorSpace, components, locations, 2);
    CGContextDrawLinearGradient(context, gradient, CGPointZero, CGPointMake(bounds.size.width, 0), 0);
    CGColorSpaceRelease(colorSpace);
    CGGradientRelease(gradient);
    CGImageRelease(checkerBoard);
}

+ (void) makeCustomSlider:(UISlider*)slider withBackImage:(UIImage*)backImage withThumbImage:(UIImage*)thumbImage {
    if (backImage) {
        UIImage *trackImage = [backImage stretchableImageWithLeftCapWidth:9 topCapHeight:0];
        [slider setMinimumTrackImage:trackImage forState:UIControlStateNormal];
        [slider setMaximumTrackImage:trackImage forState:UIControlStateNormal];
    }
    if (thumbImage) {
        [slider setThumbImage:thumbImage forState:UIControlStateNormal];
    }
}

+ (void) makeCustomScroll:(UIScrollView*)scroll withImages:(NSArray*)images target:(id)target action:(SEL)action forEvent:(UIControlEvents)event {
    CGRect frame = scroll.frame;
    CGFloat w = frame.size.height;
    CGFloat h = w;
    CGFloat x = 0;
    int i = 0;
    for (UIImage *image in images) {
        UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(x, 0, w, h)];
        UIImage *btnImage = [CIPImageProcess fitImage:image into:CGSizeMake(w, h)];
        btn.layer.contents = (id)btnImage.CGImage;
        btn.tag = TagStyleScrollTagOff+i;
        [btn addTarget:target action:action forControlEvents:event];
        [scroll addSubview:btn];
        x += w;
        i++;
    }
    scroll.contentSize = CGSizeMake(x, h);
    
    UIView *selectView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, w, h)];
    selectView.layer.borderColor = [UIColor orangeColor].CGColor;
    selectView.layer.borderWidth = 2;
    selectView.layer.cornerRadius = 4;
    selectView.tag = TagStyleScrollSelect;
    
    [scroll addSubview:selectView];
}

+ (void) makeHueSliderWith:(UISlider *)slider {
    CGRect frame = slider.frame;
    CGFloat l = frame.size.width-8;
    CGFloat h = frame.size.height*0.8;
    CGFloat paddingx = 4;
    CGFloat paddingy = frame.size.height*0.1;
    
    UIGraphicsBeginImageContext(frame.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGFloat step = l/239.0f;
    CGFloat x = paddingx;
    int hue = 0;
    while (x < l+paddingx) {
        UIColor *color = [UIColor colorWithHue:(CGFloat)hue/240.0f saturation:1.0 brightness:1.0 alpha:1.0];
        CGContextMoveToPoint(context, x, paddingy);
        CGContextAddLineToPoint(context, x, h+paddingy);
        CGContextSetLineWidth(context, step);
        CGContextSetStrokeColorWithColor(context, color.CGColor);
        CGContextStrokePath(context);
        x += step;
        hue++;
    }
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    h = frame.size.height;
    UIGraphicsBeginImageContext(CGSizeMake(12, frame.size.height));
    context = UIGraphicsGetCurrentContext();
    const CGPoint points1[] = {CGPointMake(1, 1), CGPointMake(11, 1), CGPointMake(11, 1), CGPointMake(11, 5), CGPointMake(11, 5), CGPointMake(6, 9), CGPointMake(6, 9), CGPointMake(1, 5), CGPointMake(1, 5), CGPointMake(1, 1)};
    const CGPoint points2[] = {CGPointMake(1, h-1), CGPointMake(11, h-1), CGPointMake(11, h-1), CGPointMake(11, h-5), CGPointMake(11, h-5), CGPointMake(6, h-9), CGPointMake(6, h-9), CGPointMake(1, h-5), CGPointMake(1, h-5), CGPointMake(1, h-1)};
    
    CGContextSetStrokeColorWithColor(context, [UIColor grayColor].CGColor);
    CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
    CGContextAddLines(context, points1, 10);
    CGContextStrokePath(context);
    CGContextAddLines(context, points1, 10);
    CGContextFillPath(context);
    CGContextAddLines(context, points2, 10);
    CGContextStrokePath(context);
    CGContextAddLines(context, points2, 10);
    CGContextFillPath(context);
    
    UIImage *thumbImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    [self makeCustomSlider:slider withBackImage:image withThumbImage:thumbImage];
}

+ (void) makeValueSliderWith:(UISlider*)slider withHue:(CGFloat)hue withSaturation:(CGFloat)sat {
    CGSize size = CGSizeApplyAffineTransform(slider.frame.size, CGAffineTransformInvert(slider.transform));
    
    CGFloat w = abs(size.width);
    CGFloat h = abs(size.height);
    CGFloat hsv[3] = {hue, sat, 0};
    CGFloat rgb[3];
    CGFloat components[8];
    
    [CIPImageProcess convertHSV:hsv toRGB:rgb];
    memcpy(components, rgb, 3*sizeof(CGFloat));
    components[3] = 1.0;
    
    hsv[2] = 1.0;
    [CIPImageProcess convertHSV:hsv toRGB:rgb];
    memcpy(components+4, rgb, 3*sizeof(CGFloat));
    components[7] = 1.0;
    
    const CGFloat locations[2] = {0.0, 1.0};
    
    UIGraphicsBeginImageContext(CGSizeMake(w, h));
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGGradientRef gradient = CGGradientCreateWithColorComponents(colorSpace, components, locations, 2);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextDrawLinearGradient(context, gradient, CGPointZero, CGPointMake(w, 0), kCGGradientDrawsBeforeStartLocation);
    CGColorSpaceRelease(colorSpace);
    CGGradientRelease(gradient);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    [self makeCustomSlider:slider withBackImage:image withThumbImage:nil];
}

+ (void) makeAlphaSliderWith:(UISlider *)slider {
    CGRect frame = slider.frame;
    
    UIGraphicsBeginImageContext(frame.size);
    CGContextRef context = UIGraphicsGetCurrentContext();   
    CGRect bounds = {CGPointZero, frame.size};
    
    CGImageRef checkerBoard = [CIPFilter generateCheckerBoardWithSize:bounds.size gridWidth:bounds.size.height/3 withColor:[UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:1.0]];
    CGContextDrawImage(context, bounds, checkerBoard);
    
    CGGradientRef gradient;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGFloat locations[2] = {0.0, 1.0};
    CGFloat components[8] = {0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0};
    gradient = CGGradientCreateWithColorComponents(colorSpace, components, locations, 2);
    CGContextDrawLinearGradient(context, gradient, CGPointZero, CGPointMake(bounds.size.width, 0), 0);
    CGColorSpaceRelease(colorSpace);
    CGGradientRelease(gradient);
    CGImageRelease(checkerBoard);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    [self makeCustomSlider:slider withBackImage:image withThumbImage:nil];

}

+ (void) makeSizeSliderWith:(UISlider *)slider {
    CGRect frame = slider.frame;
    CGFloat w = frame.size.width;
    CGFloat h = frame.size.height;
    
    UIGraphicsBeginImageContext(frame.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:1.0].CGColor);
    CGContextFillRect(context, CGRectMake(0, 0, w, h));
    
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathMoveToPoint(path, nil, 2, h/2);
    CGPathAddLineToPoint(path, nil, w-h/2, 2);
    CGPathAddArc(path, nil, w-h/2, h/2, h/2-1, M_PI*1.5, M_PI*0.5, 0);
    CGPathCloseSubpath(path);
    
    CGContextSetFillColorWithColor(context, [UIColor lightGrayColor].CGColor);
    CGContextAddPath(context, path);
    CGContextFillPath(context);
    CGPathRelease(path);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    [self makeCustomSlider:slider withBackImage:image withThumbImage:nil];
}

+ (void) makeColorButtonWith:(UIButton*)button withColor:(UIColor*)color {
    CGSize size = button.frame.size;
    CGFloat diameter = MIN(size.width, size.height);
    button.frame = CGRectMake(button.frame.origin.x, button.frame.origin.y, diameter, diameter);
    CGSize shadowSize = CGSizeMake(diameter*88/80, diameter*88/80);
    
    CALayer *layer0 = [[CALayer alloc] init];
    layer0.frame = CGRectMake(3, 3, diameter-6, diameter-6);
    layer0.cornerRadius = diameter/2-3;
    layer0.backgroundColor = color.CGColor;
    [button.layer addSublayer:layer0];
    
    CALayer *layer1 = [[CALayer alloc] init];
    layer1.frame = CGRectMake(0, 0, shadowSize.width, shadowSize.height);
    layer1.contents = (id)[UIImage imageNamed:@"colorBtn.png"].CGImage;
    [button.layer addSublayer:layer1];
}

+ (UISlider*) createHueSliderWithFrame:(CGRect)frame {
    UISlider *hueSlider = [[UISlider alloc] initWithFrame:frame];
    [hueSlider setMinimumValue:0.0];
    [hueSlider setMaximumValue:1.0];
    [self makeHueSliderWith:hueSlider];
    return hueSlider;
}

+ (UISlider*) createValueSliderWithFrame:(CGRect)frame withHue:(CGFloat)hue withSaturation:(CGFloat)sat {
    UISlider *valueSlider = [[UISlider alloc] initWithFrame:frame];
    valueSlider.layer.cornerRadius = frame.size.height/2;
    valueSlider.layer.borderColor = [CIPPalette borderColor].CGColor;
    valueSlider.layer.borderWidth = 2;
    [valueSlider setClipsToBounds:YES];
    [valueSlider setMinimumValue:0.0];
    [valueSlider setMaximumValue:1.0];
    [self makeValueSliderWith:valueSlider withHue:hue withSaturation:sat];
    return valueSlider;
}

+ (UISlider*) createAlphaSliderWithFrame:(CGRect)frame {
    UISlider *alphaSlider = [[UISlider alloc] initWithFrame:frame];
    alphaSlider.layer.cornerRadius = frame.size.height/2;
    alphaSlider.layer.borderColor = [CIPPalette borderColor].CGColor;
    alphaSlider.layer.borderWidth = 2;
    [alphaSlider setClipsToBounds:YES];
    [alphaSlider setMinimumValue:0.0];
    [alphaSlider setMaximumValue:1.0];
    [self makeAlphaSliderWith:alphaSlider];
    return  alphaSlider;
}

+ (UISlider*) createSizeSliderWithFrame:(CGRect)frame {
    UISlider *sizeSlider = [[UISlider alloc] initWithFrame:frame];
    sizeSlider.layer.cornerRadius = frame.size.height/2;
    sizeSlider.layer.borderColor = [CIPPalette borderColor].CGColor;
    sizeSlider.layer.borderWidth = 2;
    [sizeSlider setClipsToBounds:YES];
    [sizeSlider setMinimumValue:1.0];
    [sizeSlider setMaximumValue:[CIPPalette maxSize]];
    [self makeSizeSliderWith:sizeSlider];
    return  sizeSlider;
}

+ (UIScrollView*)createBrushScrollWithFrame:(CGRect)frame target:(id)target action:(SEL)action forControlEvents:(UIControlEvents)controlEvent{
    NSMutableArray *brushImages = [NSMutableArray arrayWithCapacity:16];
    CGFloat colors[4] = {0, 0, 0, 1};
    for (int i=0; i<PATTERN_NUMBER; i++) {
        CGImageRef cgImage = [CIPBrushUtilities getBrushForType:i withColor:colors];
        [brushImages addObject:[UIImage imageWithCGImage:cgImage]];
        CGImageRelease(cgImage);
    }
    
    UIScrollView *scroll = [[UIScrollView alloc] initWithFrame:frame];
    [self makeCustomScroll:scroll withImages:brushImages target:target action:action forEvent:controlEvent];
    return scroll;
}

+ (UIScrollView*)createShapeScrollWithFrame:(CGRect)frame target:(id)target action:(SEL)action forControlEvents:(UIControlEvents)controlEvent {
    NSMutableArray *shapeImages = [NSMutableArray arrayWithCapacity:4];
    CGFloat w = frame.size.height;
    CGFloat h = w;
    CGContextRef context;
    
    // for line
    UIGraphicsBeginImageContext(CGSizeMake(w, h));
    context = UIGraphicsGetCurrentContext();
    CGContextSetStrokeColorWithColor(context, [UIColor blackColor].CGColor);
    CGContextMoveToPoint(context, w-4, 4);
    CGContextAddLineToPoint(context, 4, h-4);
    CGContextStrokePath(context);
    [shapeImages addObject:UIGraphicsGetImageFromCurrentImageContext()];
    UIGraphicsEndImageContext();
    
    // for rect
    UIGraphicsBeginImageContext(CGSizeMake(w, h));
    context = UIGraphicsGetCurrentContext();
    CGContextSetStrokeColorWithColor(context, [UIColor blackColor].CGColor);
    CGContextStrokeRect(context, CGRectMake(4, 6, w-8, h-12));
    CGContextSetFillColorWithColor(context, [UIColor lightGrayColor].CGColor);
    CGContextFillRect(context, CGRectMake(4, 6, w-8, h-12));
    [shapeImages addObject:UIGraphicsGetImageFromCurrentImageContext()];
    UIGraphicsEndImageContext();
    
    // for eclipse
    UIGraphicsBeginImageContext(CGSizeMake(w, h));
    context = UIGraphicsGetCurrentContext();
    CGContextSetStrokeColorWithColor(context, [UIColor blackColor].CGColor);
    CGContextStrokeEllipseInRect(context, CGRectMake(4, 6, w-8, h-12));
    CGContextSetFillColorWithColor(context, [UIColor lightGrayColor].CGColor);
    CGContextFillEllipseInRect(context, CGRectMake(4, 6, w-8, h-12));
    [shapeImages addObject:UIGraphicsGetImageFromCurrentImageContext()];
    UIGraphicsEndImageContext();
    
    UIScrollView *scroll = [[UIScrollView alloc] initWithFrame:frame];
    [self makeCustomScroll:scroll withImages:shapeImages target:target action:action forEvent:controlEvent];
    return scroll;
}

+ (UIScrollView*)createTextScrollWithFrame:(CGRect)frame target:(id)target action:(SEL)action forControlEvents:(UIControlEvents)controlEvent {
    NSMutableArray *textImages = [NSMutableArray arrayWithCapacity:4];
    CGFloat w = frame.size.height;
    CGFloat h = w;
    CGContextRef context;
    NSString *text = @"T";
    CGFloat fontSize = h-6;
    CGRect rect = CGRectMake(0, (h-fontSize)/2, w, fontSize);
    UIFont *font = [UIFont systemFontOfSize:fontSize];
    
    // for fill mode
    UIGraphicsBeginImageContext(CGSizeMake(w, h));
    context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [UIColor blueColor].CGColor);
    CGContextSetTextDrawingMode(context, kCGTextFill);
    [text drawInRect:rect withFont:font lineBreakMode:NSLineBreakByCharWrapping alignment:NSTextAlignmentCenter];
    [textImages addObject:UIGraphicsGetImageFromCurrentImageContext()];
    UIGraphicsEndImageContext();
    
    // for stroke mode
    UIGraphicsBeginImageContext(CGSizeMake(w, h));
    context = UIGraphicsGetCurrentContext();
    CGContextSetStrokeColorWithColor(context, [UIColor redColor].CGColor);
    CGContextSetTextDrawingMode(context, kCGTextStroke);
    [text drawInRect:rect withFont:font lineBreakMode:NSLineBreakByCharWrapping alignment:NSTextAlignmentCenter];
    [textImages addObject:UIGraphicsGetImageFromCurrentImageContext()];
    UIGraphicsEndImageContext();
    
    // for stroke fill mode
    UIGraphicsBeginImageContext(CGSizeMake(w, h));
    context = UIGraphicsGetCurrentContext();
    CGContextSetStrokeColorWithColor(context, [UIColor redColor].CGColor);
    CGContextSetFillColorWithColor(context, [UIColor blueColor].CGColor);
    CGContextSetTextDrawingMode(context, kCGTextFillStroke);
    [text drawInRect:rect withFont:font lineBreakMode:NSLineBreakByCharWrapping alignment:NSTextAlignmentCenter];
    [textImages addObject:UIGraphicsGetImageFromCurrentImageContext()];
    UIGraphicsEndImageContext();
    
    UIScrollView *scroll = [[UIScrollView alloc] initWithFrame:frame];
    [self makeCustomScroll:scroll withImages:textImages target:target action:action forEvent:controlEvent];
    UIView *view1 = [scroll viewWithTag:TagStyleScrollTagOff];
    UIView *view2 = [scroll viewWithTag:TagStyleScrollTagOff+1];
    UIView *view3 = [scroll viewWithTag:TagStyleScrollTagOff+2];
    view1.tag = TagStyleScrollTagOff+kCGTextFill;
    view2.tag = TagStyleScrollTagOff+kCGTextStroke;
    view3.tag = TagStyleScrollTagOff+kCGTextFillStroke;
    
    return scroll;
}

+ (UIControl*)createHueSaturationRect:(CGRect)frame {
    NSUInteger x, y;
    CGFloat hsv[3];
    CGFloat rgb[3];
    UIControl *control = [[UIControl alloc] initWithFrame:frame];
    
    NSUInteger w = frame.size.width;
    NSUInteger h = frame.size.height;
    NSUInteger bitsPerComponent = 8;
    NSUInteger bytesPerRow = w*4;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    unsigned char *data = malloc(w*h*4);
    
    CGContextRef context = CGBitmapContextCreate(data, w, h, bitsPerComponent, bytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast);
    
    int idx = w*4*2+8;
    for (y=2; y<h-2; y++) {
        for (x=2; x<w-2; x++) {
            hsv[0] = (CGFloat)(x-2)/(CGFloat)(w-4);
            hsv[1] = (CGFloat)(y-2)/(CGFloat)(h-4);
            hsv[2] = 1.0;
            [CIPImageProcess convertHSV:hsv toRGB:rgb];
            data[idx+0] = (unsigned char)(rgb[0]*255);
            data[idx+1] = (unsigned char)(rgb[1]*255);
            data[idx+2] = (unsigned char)(rgb[2]*255);
            data[idx+3] = 255;
            idx+=4;
        }
        idx+=16;
    }
    CGImageRef cgImage = CGBitmapContextCreateImage(context);
    CGColorSpaceRelease(colorSpace);
    free(CGBitmapContextGetData(context));
    CGContextRelease(context);
    UIImage *image = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);
    
    control.layer.contents = (id)image.CGImage;
    control.layer.borderColor = [UIColor colorWithRed:0.2 green:0.53 blue:0.61 alpha:0.7].CGColor;
    control.layer.borderWidth = 2;
    return control;
}

+ (UIButton*)createColorButton:(CGRect)frame withColor:(UIColor*)color {
    UIButton *btn = [[UIButton alloc] initWithFrame:frame];
    [self makeColorButtonWith:btn withColor:color];
    return btn;
}

+ (UIButton*)createFilterButton:(CGRect)frame withImage:(UIImage*)image {
    UIButton *btn = [[UIButton alloc] initWithFrame:frame];
    CGFloat radius = MIN(frame.size.width, frame.size.height)*15/55;
    CALayer *layer0 = [[CALayer alloc] init];
    layer0.frame = CGRectMake(0, 0, frame.size.width, frame.size.height);
    layer0.cornerRadius = radius;
    layer0.contents = (id)image.CGImage;
    [btn.layer addSublayer:layer0];

    CALayer *layer1 = [[CALayer alloc] init];
    layer1.frame = CGRectMake(0, 0, frame.size.width, frame.size.height);
    layer1.cornerRadius = radius;
    layer1.borderWidth = 4;
    UIColor *borderColor = [CIPPalette borderColor];
    borderColor = [CIPPalette replaceColor:borderColor component:3 withValue:0.6];
    layer1.borderColor = borderColor.CGColor;
    [btn.layer addSublayer:layer1];

    return btn;
}


+ (void) makeMainBackgroundForView:(UIView *)view {
    CGSize size = view.frame.size;
    UIGraphicsBeginImageContext(size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    const CGFloat components[12] = {0.57, 0.71, 0.75, 0.8, 0.76, 0.83, 0.84, 0.6, 0.89, 0.96, 0.97, 0.5};
    const CGFloat locations[3] = {0, 0.3, 1.0};
    CGGradientRef gradient = CGGradientCreateWithColorComponents(colorSpace, components, locations, 3);
    CGContextDrawLinearGradient(context, gradient, CGPointMake(0, size.height), CGPointMake(0, 0), kCGGradientDrawsBeforeStartLocation);
    
    CGColorSpaceRelease(colorSpace);
    CGGradientRelease(gradient);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    view.layer.contents = (id)image.CGImage;
}
@end
