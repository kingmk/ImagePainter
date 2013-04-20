//
//  CIPOperMenu.m
//  ImagePainter
//
//  Created by yuxinjin on 12-10-26.
//  Copyright (c) 2012年 yuxinjin. All rights reserved.
//

#import "CIPDrawMenu.h"
@interface CIPDrawMenu()
//@property (nonatomic, retain) UIScrollView *scroll;
@property (nonatomic, retain) UIImageView *selectedView;
@property (nonatomic, retain) NSMutableDictionary *btnTextDic;
@property (nonatomic) CGFloat iconH;

@end

@implementation CIPDrawMenu

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initParams];
    }
    return self;
}

- (void) initParams {
    CGSize frameSize = self.frame.size;

    self.layer.contents = (id)[UIImage imageNamed:@"bar_drawmenu.png"].CGImage;
    self.iconH = 46;
    
    self.selectedView = [[UIImageView alloc] initWithFrame:CGRectMake(0, self.iconH, frameSize.width+20, self.iconH)];
    self.selectedView.image = [UIImage imageNamed:@"oper_zselect.png"];
    UIImageView *selectedTextView = [[UIImageView alloc] initWithFrame:CGRectMake(frameSize.width, 0, 20, self.iconH)];
    [self.selectedView addSubview:selectedTextView];
    [self addSubview:self.selectedView];
    
    int iconCount = 7;
    self.btnTextDic = [NSMutableDictionary dictionaryWithCapacity:iconCount];
    
    NSArray *iconNames = [NSArray arrayWithObjects:@"oper_view.png", @"oper_view_h.png", @"oper_view_t.png", @"oper_paint.png", @"oper_paint_h.png", @"oper_paint_t.png",  @"oper_text.png", @"oper_text_h.png", @"oper_text_t.png", @"oper_crop.png", @"oper_crop_h.png", @"oper_crop_t.png", @"oper_eraser.png", @"oper_eraser_h.png", @"oper_eraser_t.png", @"oper_collage.png", @"oper_collage_h.png", @"oper_collage_t.png", @"oper_filter.png", @"oper_filter_h.png", @"oper_filter_t.png", nil];
    
    ImageProcState iconStates[] = {ProcView, ProcPaint, ProcText, ProcCrop, ProcEraser, ProcCollage, ProcFilter};
    CGFloat y = 10;
    CGFloat w = self.frame.size.width;
    for (int i=0; i<iconCount; i++) {
        [self.btnTextDic setObject:[UIImage imageNamed:iconNames[i*3+2]] forKey:[NSNumber numberWithInteger:iconStates[i]]];
        
        UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0, y, w, self.iconH)];
        [button setImage:[UIImage imageNamed:iconNames[i*3]] forState:UIControlStateNormal];
        [button setImage:[UIImage imageNamed:iconNames[i*3+1]] forState:UIControlStateSelected];
        button.tag = iconStates[i];
        [button addTarget:self action:@selector(clickIcon:) forControlEvents:UIControlEventTouchDown];
        [self addSubview:button];
        y += self.iconH;
    }

    self.selectedState = -1;
}

- (IBAction)clickIcon:(UIButton*)sender {
    if ([self setFocus:sender.tag]) {
        [self sendActionsForControlEvents:UIControlEventValueChanged];
    };
}

- (BOOL) setFocus:(ImageProcState)state {
    if (state == self.selectedState) {
        return NO;
    }
    ImageProcState orgState = self.selectedState;
    self.selectedState = state;
    [UIView animateWithDuration:0.1 animations:^{
        UIButton *selectedButton = (UIButton*)[self viewWithTag:orgState];
        selectedButton.selected = false;
        
        selectedButton = (UIButton*)[self viewWithTag:self.selectedState];
        
        CGFloat y = selectedButton.frame.origin.y;
        CGRect selectViewRect = self.selectedView.frame;
        selectViewRect = CGRectMake(0, y, selectViewRect.size.width, selectViewRect.size.height);
        self.selectedView.frame = selectViewRect;
        selectedButton.selected = true;
        
        [(UIImageView*)self.selectedView.subviews[0] setImage:[self.btnTextDic objectForKey:[NSNumber numberWithInteger:state]]];
    } completion:^(BOOL finished) {
    }];
    return YES;
}

- (void) selectState:(ImageProcState)state {
    [self setFocus:state];
}

@end
