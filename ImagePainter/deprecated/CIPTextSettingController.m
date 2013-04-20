//
//  CIPTextSettingController.m
//  ImagePainter
//
//  Created by yuxinjin on 12-9-29.
//  Copyright (c) 2012年 yuxinjin. All rights reserved.
//

#import "CIPTextSettingController.h"

@interface CIPTextSettingController ()
@property (nonatomic) NSArray *fontFamilies;

@property (weak, nonatomic) IBOutlet CIPDrawView *previewFill;
@property (weak, nonatomic) IBOutlet CIPDrawView *previewStroke;
@property (weak, nonatomic) IBOutlet CIPDrawView *previewSF;

@property (weak, nonatomic) IBOutlet UIScrollView *familyScroll;

@property (weak, nonatomic) IBOutlet UILabel *sizeLabel;
@property (weak, nonatomic) IBOutlet UILabel *borderWLabel;

@property (weak, nonatomic) IBOutlet UISlider *sizeSlide;
@property (weak, nonatomic) IBOutlet UISlider *borderWSlide;

@property (weak, nonatomic) IBOutlet CIPColorSlider *fontColorView;
@property (weak, nonatomic) IBOutlet CIPColorSlider *fontBorderColorView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *alignSeg;

- (IBAction)slideSize:(UISlider *)sender;
- (IBAction)slideBorderW:(UISlider *)sender;
- (IBAction)selectAlign:(UISegmentedControl *)sender;

- (IBAction)clickPreview:(CIPDrawView *)sender;

- (IBAction)test:(UIButton *)sender;

@end

@implementation CIPTextSettingController

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
    // to set the color picker control's position and event handler
    
    CGRect frame = self.fontColorView.frame;
    [self.fontColorView setFrame:CGRectMake(20, 10, frame.size.width, frame.size.height)];
    frame = self.fontBorderColorView.frame;
    [self.fontBorderColorView setFrame:CGRectMake(20, 10, frame.size.width, frame.size.height)];
    
    frame = self.alignSeg.frame;
    int outerh = self.alignSeg.superview.frame.size.height;
    int h = 30;
    [self.alignSeg setFrame:CGRectMake(frame.origin.x, (outerh-h)/2, frame.size.width, h)];
	
    [self initFamilyScroll];
    
    [self updateViewWithPalette:self.palette withSubType:self.subType];
}

- (void)viewDidUnload {
    [self setFontColorView:nil];
    [self setFontBorderColorView:nil];
    [self setPreviewFill:nil];
    [self setPreviewStroke:nil];
    [self setPreviewSF:nil];
    [self setBorderWSlide:nil];
    [self setBorderWLabel:nil];
    [self setSizeSlide:nil];
    [self setSizeLabel:nil];
    [self setAlignSeg:nil];
    [self setFamilyScroll:nil];
    [super viewDidUnload];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) initFamilyScroll {
    NSArray *families = [CIPUtilities getFontFamilies];
    CGFloat h = 25;
    CGFloat w = self.familyScroll.bounds.size.width;
    CGFloat offy = 0;
    for (NSString *family in families) {
        UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0, offy, w, h)];
        [button setTitle:family forState:UIControlStateNormal];
        [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [button setTitleColor:[UIColor redColor] forState:UIControlStateHighlighted];
        [button setTitleColor:[UIColor redColor] forState:UIControlStateSelected];
        [button.titleLabel setFont:[UIFont fontWithName:family size:12]];
        [button addTarget:self action:@selector(selectFamily:) forControlEvents:UIControlEventTouchDown];
        [self.familyScroll addSubview:button];
        offy += h;
    }
    self.familyScroll.contentSize = CGSizeMake(w, offy);
    [self.familyScroll.layer setBorderWidth:1];
    [self.familyScroll.layer setBorderColor:[UIColor grayColor].CGColor];
    [self.familyScroll.layer setCornerRadius:5];
}

- (void) updateViewWithPalette:(CIPPalette *)palette withSubType:(ProcSubType)subType{
    [super updateViewWithPalette:palette withSubType:subType];
    if (palette) {
        [self.fontColorView setColor:palette.fontColor];
        [self.fontBorderColorView setColor:palette.fontBorderColor];
        
        self.sizeLabel.text = [NSString stringWithFormat:@"%.0f",palette.font.pointSize];
        self.sizeSlide.value = palette.font.pointSize;
        
        self.borderWLabel.text = [NSString stringWithFormat:@"%.0f",palette.fontBorderWidth];
        self.borderWSlide.value = palette.fontBorderWidth;
        
        switch (palette.textAlignment) {
            case NSTextAlignmentLeft:
                [self.alignSeg setSelectedSegmentIndex:0];
                break;
            case NSTextAlignmentCenter:
                [self.alignSeg setSelectedSegmentIndex:1];
                break;
            case NSTextAlignmentRight:
                [self.alignSeg setSelectedSegmentIndex:2];
                break;
            default:
                break;
        }
        
        [self setFamilySelected:YES withName:palette.font.familyName scrollTo:YES];
        
        self.previewFill.type = kCGTextFill;
        self.previewStroke.type = kCGTextStroke;
        self.previewSF.type = kCGTextFillClip;
        switch (palette.textMode) {
            case kCGTextFill:
                self.previewFill.clicked = YES;
                break;
            case kCGTextStroke:
                self.previewStroke.clicked = YES;
                break;
            case kCGTextFillStroke:
                self.previewSF.clicked = YES;
            default:
                break;
        }
        
        [self showPreview];
    }
}

- (void) setFamilySelected:(BOOL)selected withName:(NSString*)familyName scrollTo:(BOOL)scroll {
    NSArray *families = [CIPUtilities getFontFamilies];
    NSInteger familyIdx = [families indexOfObject:familyName];
    if (familyIdx == NSNotFound) {
        return;
    }
    
    UIButton *button = [self.familyScroll.subviews objectAtIndex:familyIdx];
    button.selected = selected;
    if (selected) {
        button.layer.backgroundColor = [UIColor colorWithRed:0.5 green:1.0 blue:0.5 alpha:0.6].CGColor;
    } else {
        button.layer.backgroundColor = [UIColor clearColor].CGColor;
    }
    if (scroll) {
        int pos = MAX(button.frame.origin.y-button.frame.size.height*1.5, 0);
        [self.familyScroll setContentOffset:CGPointMake(0, pos)];
    }
}

- (void) showPreview {
    CGRect rect = CGRectMake(5, 5, self.previewFill.bounds.size.width-10, self.previewFill.bounds.size.height-10);
    CIPPalette *palette = [self.palette copy];
    [self.previewFill drawText:@"Text" inRect:rect withPalette:palette];

    palette = [self.palette copy];
    palette.textMode = kCGTextStroke;
    [self.previewStroke drawText:@"Text" inRect:rect withPalette:palette];
    
    palette = [self.palette copy];
    palette.textMode = kCGTextFillStroke;
    [self.previewSF drawText:@"Text" inRect:rect withPalette:palette];
}

- (IBAction)selectFamily:(UIButton*)sender {
    NSString *family = sender.titleLabel.text;
    NSString *oldFamily = self.palette.font.familyName;
    
    [self setFamilySelected:NO withName:oldFamily scrollTo:NO];
    
    self.palette.font = [UIFont fontWithName:family size:self.palette.font.pointSize];
    sender.selected = YES;
    sender.layer.backgroundColor = [UIColor colorWithRed:0.5 green:1.0 blue:0.5 alpha:0.6].CGColor;
    [self showPreview];
}

- (IBAction)slideSize:(UISlider *)sender {
    self.palette.font = [self.palette.font fontWithSize:sender.value];
    self.sizeLabel.text = [NSString stringWithFormat:@"%.0f",sender.value];
    [self showPreview];
}

- (IBAction)slideBorderW:(UISlider *)sender {
    self.palette.fontBorderWidth = sender.value;
    self.borderWLabel.text = [NSString stringWithFormat:@"%.0f",sender.value];
    [self showPreview];
}

- (IBAction)selectAlign:(UISegmentedControl *)sender {
    switch (sender.selectedSegmentIndex) {
        case 0:
            self.palette.textAlignment = NSTextAlignmentLeft;
            break;
        case 1:
            self.palette.textAlignment = NSTextAlignmentCenter;
            break;
        case 2:
            self.palette.textAlignment = NSTextAlignmentRight;
            break;
        default:
            break;
    }
    [self showPreview];
}

- (IBAction)clickPreview:(CIPDrawView *)sender {
    self.previewFill.clicked = NO;
    self.previewStroke.clicked = NO;
    self.previewSF.clicked = NO;
    if (sender == self.previewFill) {
        sender.clicked = YES;
        self.palette.textMode = kCGTextFill;
    } else if (sender == self.previewStroke) {
        sender.clicked = YES;
        self.palette.textMode = kCGTextStroke;
    } else if (sender == self.previewSF) {
        sender.clicked = YES;
        self.palette.textMode = kCGTextFillClip;
    }
}

- (IBAction)test:(UIButton *)sender {
    UITextView *textView = (UITextView*)[self.view viewWithTag:100];
    CIPDrawView *previewText = (CIPDrawView*)[self.view viewWithTag:101];
    [previewText drawText:textView.text inRect:CGRectMake(5, 5, previewText.frame.size.width-10, previewText.frame.size.height-10) withPalette:self.palette];
    
}

- (IBAction)fontColorChanged:(CIPColorSlider*)sender {
    self.palette.fontColor = sender.color;
    [self showPreview];
}

- (IBAction)fontBorderColorChanged:(CIPColorSlider*)sender {
    self.palette.fontBorderColor = sender.color;
    [self showPreview];
}

@end
