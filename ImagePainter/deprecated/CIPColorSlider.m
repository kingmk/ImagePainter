//
//  UIColorRGBSlider.m
//  ImagePainter
//
//  Created by yuxinjin on 12-9-27.
//  Copyright (c) 2012年 yuxinjin. All rights reserved.
//

#import "CIPColorSlider.h"

@interface CIPColorSlider()
@property (weak, nonatomic) IBOutlet UIView *colorView;

- (IBAction)slideColor:(UISlider *)sender;

@end

@implementation CIPColorSlider

- (id)awakeAfterUsingCoder:(NSCoder *)aDecoder {
    int i = [self subviews].count;
    if (i == 0) {
        NSArray *nib = [[NSBundle mainBundle]loadNibNamed:@"ColorView" owner:Nil options:nil];
        self = [nib objectAtIndex:0];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

- (void) setColor:(UIColor *)color {
    _color = color;
    const CGFloat *components = CGColorGetComponents(self.color.CGColor);
    for (int tag=10; tag<=13; tag++) {
        UISlider *slider = (UISlider*)[self viewWithTag:tag];
        slider.value = components[tag-10];
        UILabel *label = (UILabel*)[self viewWithTag:tag+10];
        if (tag!=13) {
            label.text = [NSString stringWithFormat:@"%.0f", slider.value];
        } else {
            label.text = [NSString stringWithFormat:@"%.0f%%", slider.value*100];
        }
        
    }
    [self.colorView setBackgroundColor:self.color];
}


- (IBAction)slideColor:(UISlider *)sender {
    NSInteger tag = [sender tag];
    int componentIdx = tag-10;
    CGFloat v = [sender value];
    UILabel *label = (UILabel*)[self viewWithTag:tag+20];
    if (tag!=13) {
        label.text = [NSString stringWithFormat:@"%.0f", v];
    } else {
        label.text = [NSString stringWithFormat:@"%.0f%%", v*100];
    }
    self.color = [CIPPalette replaceColor:self.color component:componentIdx withValue:v];
    [self sendActionsForControlEvents:UIControlEventValueChanged];
}
@end
