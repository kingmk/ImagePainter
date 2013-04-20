//
//  CIPCustomViewUtils.h
//  ImagePainter
//
//  Created by yuxinjin on 12-10-24.
//  Copyright (c) 2012年 yuxinjin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CIPCustomViewUtils : NSObject

+ (void) makeHueSliderWith:(UISlider*)slider;
+ (void) makeValueSliderWith:(UISlider*)slider withHue:(CGFloat)hue withSaturation:(CGFloat)sat;
+ (void) makeAlphaSliderWith:(UISlider*)slider;
+ (void) makeSizeSliderWith:(UISlider*)slider;
+ (void) makeColorButtonWith:(UIButton*)button withColor:(UIColor*)color;

+ (UISlider*) createHueSliderWithFrame:(CGRect)frame;
+ (UISlider*) createValueSliderWithFrame:(CGRect)frame withHue:(CGFloat)hue withSaturation:(CGFloat)sat;
+ (UISlider*) createAlphaSliderWithFrame:(CGRect)frame;
+ (UISlider*) createSizeSliderWithFrame:(CGRect)frame;
+ (UIScrollView*)createBrushScrollWithFrame:(CGRect)frame target:(id)target action:(SEL)action forControlEvents:(UIControlEvents)controlEvent;
+ (UIScrollView*)createShapeScrollWithFrame:(CGRect)frame target:(id)target action:(SEL)action forControlEvents:(UIControlEvents)controlEvent;
+ (UIScrollView*)createTextScrollWithFrame:(CGRect)frame target:(id)target action:(SEL)action forControlEvents:(UIControlEvents)controlEvent;

+ (UIControl*)createHueSaturationRect:(CGRect)frame;
+ (UIButton*)createColorButton:(CGRect)frame withColor:(UIColor*)color;
+ (UIButton*)createFilterButton:(CGRect)frame withImage:(UIImage*)image;


+ (void)makeMainBackgroundForView:(UIView*)view;
@end
