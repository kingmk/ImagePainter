//
//  CIPPalettePanel.m
//  ImagePainter
//
//  Created by yuxinjin on 12-10-25.
//  Copyright (c) 2012年 yuxinjin. All rights reserved.
//

#import "CIPPalettePanel.h"
@interface CIPPalettePanel()
@property (nonatomic, retain) UISlider *sizeSlider;
@property (nonatomic, retain) UIScrollView *brushScroll;

@property (nonatomic, retain) UIImage *backImage;

@property (nonatomic) CGRect orgFrame;

@property (nonatomic) CGFloat ctrlH;
@property (nonatomic) BOOL hasInitViews;

// true for stroke, false for fill
@property (nonatomic) BOOL isStroke;
@property (nonatomic) BOOL isFullMode;

@end


@implementation CIPPalettePanel

- (id) initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.hasInitViews = NO;
    }
    return self;
}


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.orgFrame = frame;
        [self initSubviewsLayout];
        self.isStroke = false;
        self.isFullMode = false;
    }
    return self;
}

- (void) initSubviewsLayout {
    self.backImage = [UIImage imageNamed:@"back_palette.png"];
    self.layer.contents = (id)self.backImage.CGImage;
    
    CGFloat w = self.frame.size.width;
    CGFloat h = self.frame.size.height;
    CGFloat ox = self.frame.origin.x;
    CGFloat oy = self.frame.origin.y;
    
    self.layer.position = CGPointMake(ox+w-h/2, oy+h/2);
    self.layer.anchorPoint = CGPointMake((w-h/2)/w, 0.5);
    
    self.ctrlH = h-6;
    CGFloat ctrlH = self.ctrlH;
    CGFloat tmpW = w-20;
    
    CGFloat sliderW = tmpW*0.45;
    CGFloat sliderH = MIN(26, ctrlH);
    CGFloat scrollW = tmpW*0.55;
    
    CGRect sizeSliderFrame = CGRectMake(w-sliderW-6, (h-sliderH)/2, sliderW, sliderH);
    self.sizeSlider = [CIPCustomViewUtils createSizeSliderWithFrame:sizeSliderFrame];
    self.sizeSlider.tag = TagPaletteSizeSlider;
    [self.sizeSlider addTarget:self action:@selector(changeSizeSlider:) forControlEvents:UIControlEventValueChanged];
    
    CGRect scrollFrame = CGRectMake(6, 3, scrollW, self.ctrlH);
    self.brushScroll = [CIPCustomViewUtils createBrushScrollWithFrame:scrollFrame  target:self action:@selector(selectStyle:) forControlEvents:UIControlEventTouchDown];

    self.hasInitViews = YES;
}

- (void) updateSubviewsLayout:(ImageProcState)procState withPalette:(CIPPalette *)palette {
    if (!self.hasInitViews) {
        [self initSubviewsLayout];
    }
    self.procState = procState;
    if (palette) {
        self.palette = palette;
    }
    [self.sizeSlider setValue:[self sizeWithCurrentState]];

    [self showSubviews];
}

#pragma mark -
#pragma mark Action Function
- (IBAction)changeSizeSlider:(UISlider*)sender {
    [self changeSize:sender.value];
    [self sendActionsForControlEvents:UIControlEventValueChanged];
}

- (IBAction)selectStyle:(UIButton*)sender {
    [self selectScrollStyle:sender.tag-TagStyleScrollTagOff scrollTo:NO];
    [self sendActionsForControlEvents:UIControlEventValueChanged];
}

#pragma mark -
#pragma mark Color Function

- (void) changeSize:(CGFloat)size {
    if (self.procState != ProcText) {
        self.palette.strokeWidth = size;
    } else {
        self.palette.font = [self.palette.font fontWithSize:size];
    }
}

- (void) showSubviews {
    if (self.procState == ProcPaint) {
        [self addSubview:self.sizeSlider];
        [self addSubview:self.brushScroll];
        [self selectScrollStyle:self.palette.brushType scrollTo:YES];
//        [self.textScroll removeFromSuperview];
    }
//    else if (self.procState == ProcText) {
//        [self addSubview:self.sizeSlider];
//        [self.brushScroll removeFromSuperview];
//        [self addSubview:self.textScroll];
//        [self selectScrollStyle:self.palette.textMode scrollTo:NO];
//    }
    else if (self.procState == ProcEraser) {
        [self addSubview:self.sizeSlider];
        [self.brushScroll removeFromSuperview];
//        [self.textScroll removeFromSuperview];
    } else {
        self.alpha = 0.0;
    }
}

- (CGFloat) sizeWithCurrentState {
    if (!self.palette) {
        return -1;
    }
    if (self.procState == ProcText) {
        return self.palette.font.pointSize;
    } else {
        return self.palette.strokeWidth;
    }
}

- (UIScrollView*) scrollWithCurrentState {
    if (self.procState == ProcPaint) {
        return self.brushScroll;
    }
//    else if (self.procState == ProcText) {
//        return self.textScroll;
//    }
    return nil;
}

- (void) setScrollValueWithCurrentState:(NSInteger) styleIndex {
    if (self.procState == ProcPaint) {
        self.palette.brushType = styleIndex;
        self.isStroke = true;
    } else if (self.procState == ProcText) {
        self.palette.textMode = styleIndex;
    }
    
}

- (void) selectScrollStyle:(NSInteger)styleTag scrollTo:(BOOL)isScroll {
    UIScrollView *scroll = [self scrollWithCurrentState];
    if (styleTag >= 0) {
        CGRect frame = [scroll viewWithTag:styleTag+TagStyleScrollTagOff].frame;
        [[scroll viewWithTag:TagStyleScrollSelect] setFrame:frame];
        if (isScroll) {
            CGFloat offset = frame.origin.x + 0.5*self.ctrlH - scroll.frame.size.width/2;
            offset = MAX(0, MIN(offset, scroll.contentSize.width-scroll.frame.size.width));
            [scroll setContentOffset:CGPointMake(offset, 0)];
        }
        [self setScrollValueWithCurrentState:styleTag];
    }
}

- (void) fullScreenMode:(BOOL)isFull {
    if (self.isFullMode == isFull) {
        return;
    }
    
    UIScrollView *curScroll = [self scrollWithCurrentState];
    if (isFull) {
        self.transform = CGAffineTransformMakeRotation(M_PI_2);
        self.layer.contents = nil;
        if (curScroll) {
            curScroll.alpha = 0.0;
        }
    } else {
        //return;
        self.transform = CGAffineTransformIdentity;
        self.frame = self.orgFrame;
        self.layer.contents = (id)self.backImage.CGImage;
        if (curScroll) {
            curScroll.alpha = 1.0;
        }
    }
    self.isFullMode = isFull;
}

- (void)beforeFullScreenMode:(BOOL)isFull {
    if (isFull) {
        CGFloat offx = self.sizeSlider.frame.origin.x;
        CGFloat w = self.frame.size.width-offx;
        CGFloat h = self.frame.size.height;
        CGFloat ox = self.frame.origin.x+offx;
        CGFloat oy = self.frame.origin.y;
        self.bounds = CGRectMake(offx, 0, self.frame.size.width-offx, self.frame.size.height);
        self.layer.position = CGPointMake(ox+w-h/2, oy+h/2);
        self.layer.anchorPoint = CGPointMake((w-h/2)/w, 0.5);
    } else {
        self.transform = CGAffineTransformIdentity;
        CGFloat w = self.orgFrame.size.width;
        CGFloat h = self.orgFrame.size.height;
        CGFloat ox = self.orgFrame.origin.x;
        CGFloat oy = self.orgFrame.origin.y;
        self.frame = self.orgFrame;
        self.bounds = CGRectMake(0, 0, w, h);
        self.layer.position = CGPointMake(ox+w-h/2, oy+h/2);
        self.layer.anchorPoint = CGPointMake((w-h/2)/w, 0.5);
        self.transform = CGAffineTransformMakeRotation(M_PI_2);
    }
}

@end
