//
//  CIPTextControl.m
//  ImagePainter
//
//  Created by yuxinjin on 12-10-4.
//  Copyright (c) 2012年 yuxinjin. All rights reserved.
//

#import "CIPTextControl.h"


@interface CIPTextControl()

@property (nonatomic, retain) UITextView *textView;
@property (nonatomic, retain) UIScrollView *familyScroll;
@property (nonatomic, retain) UIButton *doneButton;
@property (nonatomic, retain) UISlider *sizeSlider;
@property (nonatomic, retain) UIButton *colorButton;
@property (nonatomic, retain) UIImage *familyScrollImage;
@property (nonatomic, retain) UIView *familyView;

@property (nonatomic, retain) NSString *orgText;
@property (nonatomic, retain) UIFont *orgFont;
@property (nonatomic, retain) UIColor *orgColor;
@property (nonatomic) TextControlStatus orgStatus;


- (IBAction)typeDone:(UIButton *)sender;


@end


@implementation CIPTextControl


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initParams];
    }
    return self;
}

- (void) initParams {
    self.orgStatus = TextControlNone;
    self.orgFont = nil;
    self.orgColor = nil;
    self.orgText = nil;
    
    CGFloat w = self.frame.size.width;
    CGFloat textw = (w-15)*0.55;
    CGFloat texth = 130;
    CGFloat scrollw = (w-15)*0.45;
    CGFloat scrollh = 100;
    CGFloat sliderh = 25;
    
    CGFloat btnw = 40;
    
    self.backgroundColor = [UIColor colorWithRed:0.76 green:0.83 blue:0.84 alpha:1.0];
    
    UIColor *backColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.5];
    self.textView = [[UITextView alloc] initWithFrame:CGRectMake(5, 5, textw, texth)];
    self.textView.tag = TagTextView;
    [self.textView setBackgroundColor:backColor];
    [self.textView.layer setBorderColor:[CIPPalette borderColor].CGColor];
    [self.textView.layer setBorderWidth:2.0];
    [self.textView.layer setCornerRadius:8.0];
    [self addSubview:self.textView];
    self.palette = [[CIPPalette alloc] init];

    self.sizeSlider = [CIPCustomViewUtils createSizeSliderWithFrame:CGRectMake(textw+10, scrollh+10, scrollw, sliderh)];
    [self.sizeSlider addTarget:self action:@selector(changeSize:) forControlEvents:UIControlEventValueChanged];
    [self addSubview:self.sizeSlider];
    
    self.familyScroll = [[UIScrollView alloc] initWithFrame:CGRectMake(textw+10,5, scrollw, scrollh)];
    [self addSubview:self.familyScroll];
    [self initFamilyScroll];
    
    self.colorButton = [CIPCustomViewUtils createColorButton:CGRectMake(w-20-btnw*2, texth+10, btnw, btnw) withColor:[UIColor whiteColor]];
    [self.colorButton addTarget:self action:@selector(callColorPic:) forControlEvents:UIControlEventTouchDown];
    [self addSubview:self.colorButton];

    self.doneButton = [[UIButton alloc] initWithFrame:CGRectMake(w-8-btnw, texth+12, btnw+4, btnw+4)];
    [self.doneButton setBackgroundImage:[UIImage imageNamed:@"textDoneBtn.png"] forState:UIControlStateNormal];
    [self.doneButton addTarget:self action:@selector(typeDone:) forControlEvents:UIControlEventTouchDown];
    [self addSubview:self.doneButton];
    
    NSArray *systemColors = [CIPPalette systemColors];
    CGFloat x = 5;
    for (int i=1; i<6; i++) {
        UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(x, texth+14, btnw-4, btnw-4)];
        btn.layer.borderColor = [CIPPalette borderColor].CGColor;
        btn.layer.borderWidth = 2;
        btn.layer.cornerRadius = 10;
        btn.layer.backgroundColor = [(UIColor*)systemColors[i] CGColor];
        [btn addTarget:self action:@selector(selectSystemColor:) forControlEvents:UIControlEventTouchDown];
        [self addSubview:btn];
        x += btnw+2;
    }
}

- (void) initFamilyScroll {
    CGFloat screenScale = [[UIScreen mainScreen] scale];
    
    NSArray *families = [CIPUtilities getFontFamilies];
    CGFloat lineh = 25;
    CGFloat w = self.familyScroll.bounds.size.width;
    CGFloat h = lineh*families.count+6;
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 3, w, lineh)];
    label.backgroundColor = [UIColor colorWithRed:0.5 green:1.0 blue:0.5 alpha:0.6];
    [self.familyScroll addSubview:label];
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(w, h), 0.0, screenScale);
    CGFloat offy = 3;
    for (NSString *family in families) {
        [family drawInRect:CGRectMake(0, offy+lineh/2.0f-9, w, 25) withFont:[UIFont fontWithName:family size:12] lineBreakMode:NSLineBreakByClipping alignment:NSTextAlignmentCenter];
        offy += lineh;
    }
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    self.familyView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, w, h)];
    self.familyView .layer.contents = (id)image.CGImage;
    
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(changeFamily:)];
    [self.familyView  addGestureRecognizer:tapRecognizer];
    
    [self.familyScroll addSubview:self.familyView ];
    
    self.familyScroll.contentSize = CGSizeMake(w, h);
    [self.familyScroll.layer setBorderWidth:2];
    [self.familyScroll.layer setBorderColor:[CIPPalette borderColor].CGColor];
    [self.familyScroll.layer setCornerRadius:5];
}

- (void) updateWithText:(NSString*)text palette:(CIPPalette*)palette status:(TextControlStatus)status{
    text = [text stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
    self.orgStatus = status;
    self.orgText = [text copy];
    self.orgFont = [CIPUtilities copyFont:palette.font];
    self.orgColor = [CIPUtilities copyColor:palette.fontColor];
    
    self.text = text;
    [self.palette copyFontFrom:palette];
    [self.textView setText:text];
    [self.textView setTextColor:palette.fontColor];
    [self.textView setFont:palette.font];
    self.sizeSlider.value = palette.font.pointSize;
    [(CALayer*)self.colorButton.layer.sublayers[0] setBackgroundColor:palette.fontColor.CGColor];
    [self selectFamily:YES withName:self.palette.font.familyName scrollTo:YES];
}

- (void) updateColor:(UIColor*)color {
    self.palette.fontColor = color;
    [(CALayer*)self.colorButton.layer.sublayers[0] setBackgroundColor:color.CGColor];
    self.textView.textColor = color;
}

- (void) setFocus {
    [self.textView becomeFirstResponder];
    [self.textView setSelectedRange:NSMakeRange(self.text.length, 0)];
}

- (IBAction)typeDone:(UIButton *)sender {
    self.text = self.textView.text;
    self.text = [self.text stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
    
    [self.textView resignFirstResponder];
    TextControlStatus status = self.orgStatus;
    bool fontChanged = ![self.palette.font isEqual:self.orgFont];
    bool colorChanged = ![self.palette.fontColor isEqual:self.orgColor];
    if (self.orgStatus == TextControlAdded && [self.text length] == 0) {
        status = TextControlNoAdded;
    } else if (self.orgStatus != TextControlAdded) {
        if ([self.text length] == 0) {
            status = TextControlRemoved;
        } else if ([self.text isEqual:self.orgText] && !fontChanged && !colorChanged) {
            status = TextControlUnchanged;
        } else {
            status = TextControlChanged;
        }
    }
    
    self.orgStatus = TextControlNone;
    self.orgFont = nil;
    self.orgColor = nil;
    self.orgText = nil;
    [self.delegate cipTextControlDidEditing:self withStatus:status];
}

- (IBAction)changeSize:(UISlider*)sender {
    self.palette.font = [self.palette.font fontWithSize:[(UISlider*)sender value]];
    [self.textView setFont:self.palette.font];
}

- (IBAction)selectSystemColor:(UIButton*)sender {
    CGColorRef colorRef = sender.layer.backgroundColor;
    [(CALayer*)self.colorButton.layer.sublayers[0] setBackgroundColor:colorRef];
    self.palette.fontColor = [UIColor colorWithCGColor:colorRef];
    [self.textView setTextColor:self.palette.fontColor];
}

- (IBAction)callColorPic:(UIButton*)sender {
    [self.delegate cipTextControl:self callColorPick:self.palette.fontColor];
}

- (IBAction)changeFamily:(UITapGestureRecognizer*)sender {
    CGPoint point = [sender locationOfTouch:0 inView:self.familyView];
    CGFloat lineh = 25;
    CGFloat w = self.familyScroll.bounds.size.width;
    NSInteger familyIdx = (point.y-3)/lineh;
    
    NSArray *families = [CIPUtilities getFontFamilies];
    familyIdx = MIN(familyIdx, families.count-1);
    NSString *family = families[familyIdx];
    
    UILabel *label = [[self.familyScroll subviews] objectAtIndex:0];
    label.frame = CGRectMake(0, 3+lineh*familyIdx, w, lineh);
    
    self.palette.font = [UIFont fontWithName:family size:self.palette.font.pointSize];
    [self.textView setFont:self.palette.font];
}

- (void) selectFamily:(BOOL)selected withName:(NSString*)familyName scrollTo:(BOOL)scroll {
    NSArray *families = [CIPUtilities getFontFamilies];
    NSInteger familyIdx = [families indexOfObject:familyName];
    if (familyIdx == NSNotFound) {
        return;
    }
    CGFloat lineh=25;
    CGFloat w = self.familyScroll.frame.size.width;
    UILabel *label = [[self.familyScroll subviews] objectAtIndex:0];
    label.frame = CGRectMake(0, 3+lineh*familyIdx, w, lineh);
    if (scroll) {
        int pos = MAX(label.frame.origin.y-label.frame.size.height*1.5, 0);
        [self.familyScroll setContentOffset:CGPointMake(0, pos)];
    }
}
@end
