//
//  CIPShapeSettingController.m
//  ImagePainter
//
//  Created by yuxinjin on 12-9-29.
//  Copyright (c) 2012年 yuxinjin. All rights reserved.
//

#import "CIPShapeSettingController.h"

@interface CIPShapeSettingController ()
@property (weak, nonatomic) IBOutlet CIPDrawView *previewLine;
@property (weak, nonatomic) IBOutlet CIPDrawView *previewRect;
@property (weak, nonatomic) IBOutlet CIPDrawView *previewCircle;
@property (weak, nonatomic) IBOutlet CIPDrawView *previewEclipse;


@property (weak, nonatomic) IBOutlet UISlider *widthSlide;
@property (weak, nonatomic) IBOutlet UILabel *widthLabel;


@property (weak, nonatomic) IBOutlet CIPColorSlider *strokeColorView;
@property (weak, nonatomic) IBOutlet CIPColorSlider *fillColorView;


@property (weak, nonatomic) IBOutlet UISegmentedControl *joinStyleSeg;
@property (weak, nonatomic) IBOutlet UISegmentedControl *capStyleSeg;

- (IBAction)slideWidth:(UISlider *)sender;


- (IBAction)selectJoinStyle:(UISegmentedControl *)sender;
- (IBAction)selectCapStyle:(UISegmentedControl *)sender;

@end

@implementation CIPShapeSettingController

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
    // to setup the preview item
    self.previewLine.type = ProcSubShapeLine;
    [self.previewLine addTarget:self action:@selector(clickPreview:) forControlEvents:UIControlEventTouchDown];
    self.previewRect.type = ProcSubShapeRect;
    [self.previewRect addTarget:self action:@selector(clickPreview:) forControlEvents:UIControlEventTouchDown];
    self.previewCircle.type = ProcSubShapeCircle;
    [self.previewCircle addTarget:self action:@selector(clickPreview:) forControlEvents:UIControlEventTouchDown];
    self.previewEclipse.type = ProcSubShapeEclipse;
    [self.previewEclipse addTarget:self action:@selector(clickPreview:) forControlEvents:UIControlEventTouchDown];
    
    // to set the color picker control's position and event handler
    CGRect frame = self.strokeColorView.frame;
    [self.strokeColorView setFrame:CGRectMake(20, 10, frame.size.width, frame.size.height)];
    frame = self.fillColorView.frame;
    [self.fillColorView setFrame:CGRectMake(20, 10, frame.size.width, frame.size.height)];
    
    [self.strokeColorView addTarget:self action:@selector(strokeColorChange:) forControlEvents:UIControlEventValueChanged];
    [self.fillColorView addTarget:self action:@selector(fillColorChange:) forControlEvents:UIControlEventValueChanged];
    
    // to setup the join/cap style segments
    frame = self.joinStyleSeg.frame;
    int outerh = self.joinStyleSeg.superview.frame.size.height;
    int h = 30;
    [self.joinStyleSeg setFrame:CGRectMake(frame.origin.x, (outerh-h)/2, frame.size.width, h)];
    frame = self.capStyleSeg.frame;
    outerh = self.capStyleSeg.superview.frame.size.height;
    h = 30;
    [self.capStyleSeg setFrame:CGRectMake(frame.origin.x, (outerh-h)/2, frame.size.width, h)];
    [self.view setNeedsLayout];
    //[self initPreviewFrame];
    [self updateViewWithPalette:self.palette withSubType:self.subType];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [self setPreviewLine:nil];
    [self setPreviewRect:nil];
    [self setPreviewCircle:nil];
    [self setPreviewEclipse:nil];
    [self setStrokeColorView:nil];
    [self setFillColorView:nil];
    [self setWidthSlide:nil];
    [self setWidthLabel:nil];
    [self setJoinStyleSeg:nil];
    [self setCapStyleSeg:nil];
    [super viewDidUnload];
}

- (void) updateViewWithPalette:(CIPPalette *)palette withSubType:(ProcSubType)subType{
    [super updateViewWithPalette:palette withSubType:subType];
    if (self.palette) {
        [self.strokeColorView setColor:palette.strokeColor];
        [self.fillColorView setColor:palette.fillColor];
        [self.widthSlide setValue:palette.strokeWidth];
        self.widthLabel.text = [NSString stringWithFormat:@"%.0f", palette.strokeWidth];
        
        switch (palette.lineJoin) {
            case kCGLineJoinMiter:
                [self.joinStyleSeg setSelectedSegmentIndex:0];
                break;
            case kCGLineJoinRound:
                [self.joinStyleSeg setSelectedSegmentIndex:1];
                break;
            case kCGLineJoinBevel:
                [self.joinStyleSeg setSelectedSegmentIndex:2];
                break;
            default:
                break;
        }
        switch (palette.lineCap) {
            case kCGLineCapButt:
                [self.capStyleSeg setSelectedSegmentIndex:0];
                break;
            case kCGLineCapRound:
                [self.capStyleSeg setSelectedSegmentIndex:1];
                break;
            case kCGLineCapSquare:
                [self.capStyleSeg setSelectedSegmentIndex:2];
                break;
            default:
                break;
        }
        [self showPreview];
    }
    [self setSubType:subType];
}

- (void) setSubType:(ProcSubType)subType {
    switch (super.subType) {
        case ProcSubShapeLine:
            self.previewLine.clicked = NO;
            break;
        case ProcSubShapeRect:
            self.previewRect.clicked = NO;
            break;
        case ProcSubShapeCircle:
            self.previewCircle.clicked = NO;
            break;
        case ProcSubShapeEclipse:
            self.previewEclipse.clicked = NO;
            break;
        default:
            break;
    }
    [super setSubType:subType];
    switch (self.subType) {
        case ProcSubShapeLine:
            self.previewLine.clicked = YES;
            break;
        case ProcSubShapeRect:
            self.previewRect.clicked = YES;
            break;
        case ProcSubShapeCircle:
            self.previewCircle.clicked = YES;
            break;
        case ProcSubShapeEclipse:
            self.previewEclipse.clicked = YES;
            break;
        default:
            break;
    }
}

- (void) showPreview {
    const CGPoint points[] = {{8,32}, {20,8}, {20,8}, {32,32}};
    [self.previewLine drawLines:points pointCount:4 withPalette:self.palette];
    [self.previewRect drawRectIn:CGRectMake(8, 8, 24, 24) withPalette:self.palette];
    [self.previewCircle drawCircleAt:CGPointMake(20,20) radius:12 withPalette:self.palette];
    [self.previewEclipse drawEclipseIn:CGRectMake(8, 10, 24, 20) withPalette:self.palette];
}

- (IBAction)strokeColorChange:(CIPColorSlider *)sender {
    self.palette.strokeColor = sender.color;
    [self showPreview];
}

- (IBAction)fillColorChange:(CIPColorSlider *)sender {
    self.palette.fillColor = sender.color;
    [self showPreview];

}

- (IBAction)slideWidth:(UISlider *)sender {
    self.palette.strokeWidth = sender.value;
    self.widthLabel.text = [NSString stringWithFormat:@"%.0f", self.palette.strokeWidth];
    [self showPreview];
}

- (IBAction)selectJoinStyle:(UISegmentedControl *)sender {
    switch (sender.selectedSegmentIndex) {
        case 0:
            self.palette.lineJoin = kCGLineJoinMiter;
            break;
        case 1:
            self.palette.lineJoin = kCGLineJoinRound;
            break;
        case 2:
            self.palette.lineJoin = kCGLineJoinBevel;
            break;
        default:
            break;
    }
    [self showPreview];
}

- (IBAction)selectCapStyle:(UISegmentedControl *)sender {
    switch (sender.selectedSegmentIndex) {
        case 0:
            self.palette.lineCap = kCGLineCapButt;
            break;
        case 1:
            self.palette.lineCap = kCGLineCapRound;
            break;
        case 2:
            self.palette.lineCap = kCGLineCapSquare;
            break;
        default:
            break;
    }
    [self showPreview];
}
@end
