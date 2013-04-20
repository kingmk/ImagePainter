//
//  CIPFilterSetter.m
//  ImagePainter
//
//  Created by yuxinjin on 12-9-30.
//  Copyright (c) 2012年 yuxinjin. All rights reserved.
//

#import "CIPFilterSetter.h"
@interface CIPFilterSetter()
@property (nonatomic) CGFloat offsetY;
@property (nonatomic) CGFloat hspace;
@property (nonatomic) CGFloat vspace;
@property (nonatomic) CGFloat titleWidth;
@property (nonatomic) CGFloat ctrlHeight;
@property (nonatomic) CGFloat ctrlWidth;


@property (nonatomic, retain) NSMutableArray *keys;

@property (nonatomic,retain) UIImage *image;

@end

@implementation CIPFilterSetter

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.vspace = 5;
        self.hspace = 10;
        self.offsetY = self.vspace;
        self.titleWidth = 60;
        self.ctrlHeight = 20;
        self.ctrlWidth = 150;
        self.backgroundColor = [UIColor colorWithRed:0.7 green:0.3 blue:0.3 alpha:0.6];
        
        self.image = [UIImage imageNamed:@"icon_collage.png"];
        self.image = [CIPImageProcess fitImage:self.image into:CGSizeMake(40, 40)];
        UIImageView *imageView = [[UIImageView alloc] initWithImage:self.image];
        imageView.tag = 100;
        CGFloat x = self.hspace*3+self.titleWidth+self.ctrlWidth;
        imageView.frame = CGRectMake(x, self.vspace, 40, 40);
        [self addSubview:imageView];
        
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        btn.frame = CGRectMake(x, self.vspace*2+40, 60, 20);
        [btn setTitle:@"Preview" forState:UIControlStateNormal];
        btn.titleLabel.font = [UIFont systemFontOfSize:12];
        btn.tag = 101;
        [btn addTarget:self action:@selector(applyFilter:) forControlEvents:UIControlEventTouchDown];
        [self addSubview:btn];
        
        self.params = [[NSMutableDictionary alloc] initWithCapacity:5];
        self.keys = [[NSMutableArray alloc] initWithCapacity:5];
    }
    return self;
}

- (void) clearParamViews {
    for (UIView *subview in self.subviews){
        if (subview.tag != 100 && subview.tag != 101) {
            [subview removeFromSuperview];
        }
    }
    self.offsetY = self.vspace;
    [(UIImageView*)[self viewWithTag:100] setImage:self.image];
    [self.params removeAllObjects];
    [self.keys removeAllObjects];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

- (void)reloadFilterControl:(NSString *)filterName withAttrs:(NSDictionary *)filterAttrs {
    [self clearParamViews];
    self.filterName = filterName;
    [filterAttrs enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [self addParamControl:(NSString*)key withAttr:obj];
    }];
}

- (void) addParamControl:(NSString *)name withAttr:(NSDictionary *)attr {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(self.hspace, self.offsetY, self.titleWidth, self.ctrlHeight)];
    label.text = [name substringFromIndex:5];
    label.textColor = [UIColor whiteColor];
    label.font = [UIFont systemFontOfSize:14];
    label.textAlignment = NSTextAlignmentRight;
    label.backgroundColor = [UIColor clearColor];
    [self addSubview:label];
    
    NSInteger keyIndex = self.keys.count;
    [self.keys addObject:name];

    NSString *type = (NSString*)[attr valueForKey:@"CIAttributeClass"];
    if ([type isEqualToString:@"NSNumber"]) {
        UISlider *slider = [[UISlider alloc] initWithFrame:CGRectMake(self.hspace*2+self.titleWidth, self.offsetY, self.ctrlWidth, self.ctrlHeight)];
        slider.minimumValue = [(NSNumber*)[attr valueForKey:@"CIAttributeSliderMin"] floatValue];
        slider.maximumValue = [(NSNumber*)[attr valueForKey:@"CIAttributeSliderMax"] floatValue];
        slider.value = [(NSNumber*)[attr valueForKey:@"CIAttributeDefault"] floatValue];
        [self.params setValue:[NSNumber numberWithFloat:slider.value] forKey:name];
        
        slider.tag = keyIndex+20;
        [slider addTarget:self action:@selector(slideValue:) forControlEvents:UIControlEventValueChanged];
        [self addSubview:slider];
    }
    self.offsetY += self.ctrlHeight+self.vspace;
}

- (CGFloat) getHeight {
    return MAX(self.offsetY, 60+3*self.vspace);
}

- (IBAction)slideValue:(UISlider*)sender {
    NSInteger keyIndex = sender.tag-20;
    [self.params setValue:[NSNumber numberWithFloat:sender.value] forKey:self.keys[keyIndex]];
    UIImageView *imageView = (UIImageView*)[self viewWithTag:100];
    [imageView setImage:[UIImage imageWithCGImage:[CIPImageProcess applyFilter:self.filterName onImage:self.image.CGImage with:self.params]]];
}

- (IBAction)applyFilter:(UIButton*)sender {
    [self sendActionsForControlEvents:UIControlEventValueChanged];
}

@end
