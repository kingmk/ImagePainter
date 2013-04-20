//
//  CIPColorPickerController.m
//  ImagePainter
//
//  Created by yuxinjin on 12-11-3.
//  Copyright (c) 2012年 yuxinjin. All rights reserved.
//

#import "CIPColorPickController.h"

@interface CIPColorPickController ()

@property (weak, nonatomic) IBOutlet UIView *selColorView;

@property (nonatomic, retain) UIControl *hueSatSelector;
@property (nonatomic, retain) UISlider *valueSlider;
@property (nonatomic, retain) UISlider *alphaSlider;

@property (nonatomic) CGFloat hue;
@property (nonatomic) CGFloat saturation;
@property (nonatomic) CGFloat value;
@property (nonatomic) CGFloat alpha;

@property (weak, nonatomic) IBOutlet UIView *colorHistoryView;
@end

@implementation CIPColorPickController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	[self initParams];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [self setSelColorView:nil];
    [self setColorHistoryView:nil];
    [super viewDidUnload];
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (void) initParams {
    [CIPCustomViewUtils makeMainBackgroundForView:self.view];
    [self initColorViews];
    [self initColorHistory];
}

- (void) initColorViews {
    [self hsvFromColor:self.color];
    
    self.selColorView.layer.cornerRadius = 15;
    self.selColorView.layer.borderColor = [CIPPalette borderColor].CGColor;
    self.selColorView.layer.borderWidth = 2;
    self.selColorView.clipsToBounds = YES;
    
    CGFloat offsetx = 20;
    CGFloat centery = 166;
    self.hueSatSelector = [CIPCustomViewUtils createHueSaturationRect:CGRectMake(offsetx, 66, 200, 200)];
    self.hueSatSelector.clipsToBounds = YES;
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(changeHueSat:)];
    [self.hueSatSelector addGestureRecognizer:tapRecognizer];
    UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(changeHueSat:)];
    [self.hueSatSelector addGestureRecognizer:panRecognizer];
    [self.view addSubview:self.hueSatSelector];
    
    offsetx += 216;
    
    self.valueSlider = [CIPCustomViewUtils createValueSliderWithFrame:CGRectMake(0, 0, 200, 26) withHue:self.hue withSaturation:self.saturation];
    self.valueSlider.transform = CGAffineTransformMakeRotation(M_PI*3/2);
    self.valueSlider.center = CGPointMake(offsetx+13, centery);
    self.valueSlider.value = self.value;
    [self.valueSlider addTarget:self action:@selector(changeValue:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:self.valueSlider];
    
    offsetx += 42;
    
    self.alphaSlider = [CIPCustomViewUtils createAlphaSliderWithFrame:CGRectMake(0, 0, 200, 26)];
    self.alphaSlider.transform = CGAffineTransformMakeRotation(M_PI*3/2);
    self.alphaSlider.center = CGPointMake(offsetx+13, centery);
    self.alphaSlider.value = self.alpha;
    [self.alphaSlider addTarget:self action:@selector(changeAlpha:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:self.alphaSlider];
    
    offsetx += 26;
    [self focusHueSat];
    [self updateColor];
}

- (void) initColorHistory {
    CGFloat margin = 10;
    CGSize size = {36, 36};
    int x, y, idx;
    idx = 0;
    for (UIColor *color in self.colorHistory) {
        x = idx%5;
        y = idx/5;
        CGRect frame = CGRectMake(x*(size.width+margin), y*(size.height+margin), size.width, size.height);
        UIButton *colorBtn = [[UIButton alloc] initWithFrame:frame];
        colorBtn.layer.borderColor = [CIPPalette borderColor].CGColor;
        colorBtn.layer.borderWidth = 2;
        colorBtn.layer.cornerRadius = 10;
        colorBtn.layer.backgroundColor = color.CGColor;
        [colorBtn addTarget:self action:@selector(clickHistoryColor:) forControlEvents:UIControlEventTouchDown];
        [self.colorHistoryView addSubview:colorBtn];
        idx++;
    }
}

#pragma mark -
#pragma mark Control Action Function

- (IBAction)backToCanvas:(UIButton*) sender{
    [self.delegate cipColorPick:self.color];
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (IBAction)changeHueSat:(UITapGestureRecognizer*)recognizer {
    CGPoint p = [recognizer locationInView:self.hueSatSelector];
    self.hue = MAX(0.0, MIN(1.0, (p.x-2)/196));
    self.saturation = MAX(0.0, MIN(1.0, (p.y-2)/196));
    [CIPCustomViewUtils makeValueSliderWith:self.valueSlider withHue:self.hue withSaturation:self.saturation];
    [self focusHueSat];
    [self updateColor];
}

- (IBAction)changeValue:(UISlider*)sender {
    self.value = sender.value;
    [self updateColor];
}

- (IBAction)changeAlpha:(UISlider*)sender {
    self.alpha = sender.value;
    [self updateColor];
}

- (IBAction)clickHistoryColor:(UIButton*)sender {
    UIColor *color = [UIColor colorWithCGColor:sender.layer.backgroundColor];
    [self hsvFromColor:color];
    [self focusHueSat];
    [self updateColor];
    [CIPCustomViewUtils makeValueSliderWith:self.valueSlider withHue:self.hue withSaturation:self.saturation];
    self.alphaSlider.value = self.alpha;
}

#pragma mark -
#pragma mark Color Pick Function
- (void)hsvFromColor:(UIColor *)color {
    self.color = color;
    const CGFloat *rgba = CGColorGetComponents(color.CGColor);
    CGFloat hsv[3];
    CGFloat rgb[3] = {rgba[0], rgba[1], rgba[2]};
    [CIPImageProcess convertRGB:rgb toHSV:hsv];
    self.hue = hsv[0];
    self.saturation = hsv[1];
    self.value = hsv[2];
    self.alpha = rgba[3];
}

- (void) focusHueSat {
    CGFloat x = self.hue*196+2;
    CGFloat y = self.saturation*196+2;
    UIView *focusView = [self.hueSatSelector viewWithTag:TagColorHSFocus];
    if (!focusView) {
        focusView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
        focusView.layer.cornerRadius = 5;
        focusView.layer.borderWidth = 2;
        focusView.layer.borderColor = [UIColor blackColor].CGColor;
        focusView.tag = TagColorHSFocus;
        [self.hueSatSelector addSubview:focusView];
    }
    focusView.center = CGPointMake(x, y);
}

- (void) updateColor {
    CGFloat hsv[3] = {self.hue, self.saturation, self.value};
    CGFloat rgb[3];
    [CIPImageProcess convertHSV:hsv toRGB:rgb];
    self.color = [UIColor colorWithRed:rgb[0] green:rgb[1] blue:rgb[2] alpha:self.alpha];
    self.selColorView.backgroundColor = self.color;
}

@end
