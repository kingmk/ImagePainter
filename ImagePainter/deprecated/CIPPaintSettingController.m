//
//  UIColorSettingController.m
//  ImagePainter
//
//  Created by yuxinjin on 12-9-27.
//  Copyright (c) 2012年 yuxinjin. All rights reserved.
//

#import "CIPPaintSettingController.h"

@interface CIPPaintSettingController ()

@property (weak, nonatomic) IBOutlet CIPDrawView *previewPencil;
@property (weak, nonatomic) IBOutlet CIPDrawView *previewBrush;
@property (weak, nonatomic) IBOutlet CIPDrawView *previewRubber;


@property (weak, nonatomic) IBOutlet CIPColorSlider *colorView;

@property (weak, nonatomic) IBOutlet UILabel *diameterLabel;
@property (weak, nonatomic) IBOutlet UILabel *brushtypeLabel;

@property (weak, nonatomic) IBOutlet UISlider *diameterSlide;
@property (weak, nonatomic) IBOutlet UISlider *brushtypeSlide;

- (IBAction)slideDiameter:(UISlider *)sender;
- (IBAction)slideHardness:(UISlider *)sender;

@end

@implementation CIPPaintSettingController
@synthesize previewPencil;
@synthesize previewBrush;

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
    // setup the color picker
    CGRect frame = self.colorView.frame;
    [self.colorView setFrame:CGRectMake(20, 10, frame.size.width, frame.size.height)];
    [self.colorView addTarget:self action:@selector(colorChange:) forControlEvents:UIControlEventValueChanged];
    
    // setup the preview items
    self.previewPencil.type = ProcSubPaintPencil;
    [self.previewPencil addTarget:self action:@selector(clickPreview:) forControlEvents:UIControlEventTouchDown];
    self.previewBrush.type = ProcSubPaintBrush;
    [self.previewBrush addTarget:self action:@selector(clickPreview:) forControlEvents:UIControlEventTouchDown];
    self.previewRubber.type = ProcSubPaintRubber;
    [self.previewRubber addTarget:self action:@selector(clickPreview:) forControlEvents:UIControlEventTouchDown];
    [self updateViewWithPalette:self.palette withSubType:self.subType];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)goBack:(UIBarButtonItem *)sender {
    [self dismissModalViewControllerAnimated:YES];
}

- (void)viewDidUnload {
    [self setColorView:nil];
    [self setPreviewPencil:nil];
    [self setPreviewBrush:nil];
    [self setDiameterLabel:nil];
    [self setBrushtypeLabel:nil];
    [self setPalette:nil];
    [self setDiameterSlide:nil];
    [self setBrushtypeSlide:nil];
    [self setPreviewRubber:nil];
    [super viewDidUnload];
}

- (void) updateViewWithPalette:(CIPPalette *)palette withSubType:(ProcSubType) subType {
    [super updateViewWithPalette:palette withSubType:subType];
    if (self.palette) {
        [self.colorView setColor:self.palette.strokeColor];
        [self.diameterSlide setValue:self.palette.strokeWidth];
        [self.diameterLabel setText:[NSString stringWithFormat:@"%.0f", self.palette.strokeWidth]];
        [self.brushtypeSlide setValue:self.palette.brushType];
        [self.brushtypeLabel setText:[NSString stringWithFormat:@"%d", self.palette.brushType]];
        [self.previewPencil drawPaintAt:CGPointMake(20, 20) withPalette:self.palette subtype:ProcSubPaintPencil];
        [self.previewBrush drawPaintAt:CGPointMake(20, 20) withPalette:self.palette subtype:ProcSubPaintBrush];
        [self.previewRubber drawPaintAt:CGPointMake(20, 20) withPalette:self.palette subtype:ProcSubPaintRubber];
    }
    [self setSubType:subType];
}

- (void) setSubType:(ProcSubType)subType {
    switch (super.subType) {
        case ProcSubPaintPencil:
            self.previewPencil.clicked = NO;
            break;
        case ProcSubPaintBrush:
            self.previewBrush.clicked = NO;
            break;
        case ProcSubPaintRubber:
            self.previewRubber.clicked = NO;
            break;
        default:
            break;
    }
    [super setSubType:subType];
    switch (self.subType) {
        case ProcSubPaintPencil:
            self.previewPencil.clicked = YES;
            break;
        case ProcSubPaintBrush:
            self.previewBrush.clicked = YES;
            break;
        case ProcSubPaintRubber:
            self.previewRubber.clicked = YES;
            break;
        default:
            break;
    }
}

- (void) showPreview {
    CGPoint center = CGPointMake(CGRectGetMidX(self.previewPencil.bounds), CGRectGetMidY(self.previewPencil.bounds));
    [self.previewPencil drawPaintAt:center withPalette:self.palette subtype:ProcSubPaintPencil];
    [self.previewBrush drawPaintAt:center withPalette:self.palette subtype:ProcSubPaintBrush];
    [self.previewRubber drawPaintAt:center withPalette:self.palette subtype:ProcSubPaintRubber];
}

- (IBAction)colorChange:(CIPColorSlider *)sender {
    self.palette.strokeColor = sender.color;
    [self showPreview];
}

- (IBAction)slideDiameter:(UISlider *)sender {
    self.palette.strokeWidth = sender.value;
    self.diameterLabel.text = [NSString stringWithFormat:@"%.0f", self.palette.strokeWidth];
    [self showPreview];
}

- (IBAction)slideHardness:(UISlider *)sender {
    self.palette.brushType = sender.value;
    self.brushtypeLabel.text = [NSString stringWithFormat:@"%d", self.palette.brushType];
    [self showPreview];
}
@end
