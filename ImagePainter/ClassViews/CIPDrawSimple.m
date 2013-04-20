//
//  CIPDrawSimple.m
//  ImagePainter
//
//  Created by yuxinjin on 12-11-2.
//  Copyright (c) 2012年 yuxinjin. All rights reserved.
//

#import "CIPDrawSimple.h"
@interface CIPDrawSimple()
@property (nonatomic) CGFloat textW;
@property (nonatomic) CGFloat textH;

@end

@implementation CIPDrawSimple

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];

    return self;
}

- (void) initParams {
    self.textH = 46;
    self.textW = 20;
    
    int iconCount = 7;
    
    NSArray *iconNames = [NSArray arrayWithObjects: @"oper_view_t.png", @"oper_view_tt.png",  @"oper_paint_t.png", @"oper_paint_tt.png",   @"oper_text_t.png", @"oper_text_tt.png",  @"oper_crop_t.png", @"oper_crop_tt.png",  @"oper_eraser_t.png", @"oper_eraser_tt.png", @"oper_collage_t.png", @"oper_collage_tt.png", @"oper_filter_t.png", @"oper_filter_tt.png", nil];
    
    ImageProcState iconStates[] = {ProcView, ProcPaint, ProcText, ProcCrop, ProcEraser, ProcCollage, ProcFilter};
    CGFloat y = 10;
    for (int i=0; i<iconCount; i++) {
        UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0, y, self.textW, self.textH)];
        [button setImage:[UIImage imageNamed:iconNames[i*2+1]] forState:UIControlStateNormal];
        [button setImage:[UIImage imageNamed:iconNames[i*2]] forState:UIControlStateSelected];
        button.tag = iconStates[i];
        [button addTarget:self action:@selector(clickIcon:) forControlEvents:UIControlEventTouchDown];
        [self addSubview:button];
        y += self.textH;
    }

    self.selectedState = -1;
}

- (IBAction)clickIcon:(UIButton*)sender {
    if ([self setFocus:sender.tag]) {
        [self sendActionsForControlEvents:UIControlEventValueChanged];
    } else {
        if (self.selectedState != ProcCollage) {
            [self.delegate cipDrawSimpleCallFullScreen:NO];
        }
    }
}

- (BOOL) setFocus:(ImageProcState)state {
    if (state == self.selectedState) {
        return NO;
    }
    UIButton *selectedButton = (UIButton*)[self viewWithTag:self.selectedState];
    selectedButton.selected = NO;
    
    selectedButton = (UIButton*)[self viewWithTag:state];
    selectedButton.selected = YES;
    self.selectedState = state;
    return  YES;
}

- (void)selectState:(ImageProcState)state {
    [self setFocus:state];
}

@end
