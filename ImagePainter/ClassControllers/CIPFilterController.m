//
//  CIPFilterController.m
//  ImagePainter
//
//  Created by yuxinjin on 12-9-30.
//  Copyright (c) 2012年 yuxinjin. All rights reserved.
//

#import "CIPFilterController.h"

@interface CIPFilterController ()
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIScrollView *filterScroll;
@property (weak, nonatomic) IBOutlet UIButton *displayBtn;
@property (nonatomic, retain) UIImageView *focusView;

@property (nonatomic, retain) NSMutableDictionary *filteredImages;

@property (nonatomic) BOOL scrollShow;
@property (nonatomic) CGFloat screenScale;
@property (nonatomic, retain) UIActivityIndicatorView *activityIndicator;


- (IBAction)test:(UIBarButtonItem *)sender;

@end

@implementation CIPFilterController

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
    [CIPCustomViewUtils makeMainBackgroundForView:self.view];
    
    //self.filterScroll.contentSize = CGSizeMake(700, self.filterScroll.frame.size.height);
    self.scrollShow = YES;
    self.screenScale = [[UIScreen mainScreen] scale];
    [self initDisplayBtn];
    [self initFilterScroll];
    [self initImageShow];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [self setImageView:nil];
    [self setFilterScroll:nil];
    [self setDisplayBtn:nil];
    [self setActivityIndicator:nil];
    [self.filteredImages removeAllObjects];
    [super viewDidUnload];
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (void) initDisplayBtn {
    CGSize size = self.displayBtn.frame.size;
    UIView *tmpView = [[UIView alloc] initWithFrame:CGRectMake(5, 5, 20, 20)];
    tmpView.layer.contents = (id)[UIImage imageNamed:@"filter_hide.png"].CGImage;
    tmpView.tag = TagFilterDisplayIcon;
    [self.displayBtn addSubview:tmpView];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(30, 5, size.width-30, 20)];
    label.backgroundColor = [UIColor clearColor];
    label.text = @"Original";
    label.font = [CIPPalette appFontWithSize:14];
    label.tag = TagFilterDisplayLabel;
    label.textColor = [CIPPalette fontDarkColor];
    
    [self.displayBtn addSubview:label];
    [self.displayBtn addTarget:self action:@selector(showScroll:) forControlEvents:UIControlEventTouchDown];
    
    CGSize screenSize = [[UIScreen mainScreen] applicationFrame].size;
    CGRect frame = self.displayBtn.frame;
    self.displayBtn.frame = CGRectMake(frame.origin.x, screenSize.height-self.filterScroll.frame.size.height-frame.size.height, frame.size.width, frame.size.height);
}

- (void) initFilterScroll {
    self.filterScroll.layer.contents = (id)[UIImage imageNamed:@"bar_filter.png"].CGImage;
    
    CGFloat margin = 10;
    CGFloat x = margin;
    CGFloat y = 7;
    CGFloat w = 54;
    
    int filterCount = 11;
    self.filteredImages = [NSMutableDictionary dictionaryWithCapacity:filterCount];
    self.focusView = [[UIImageView alloc] initWithFrame:CGRectMake(x-2, y-2, w+4, w+4)];
    self.focusView.image = [UIImage imageNamed:@"filter_selected.png"];
    
    TagInView tags[] = {TagFilterOriginal, TagFilterInstant, TagFilterExpose, TagFilterVibrance, TagFilterComic, TagFilterOcean, TagFilterLake, TagFilterEmboss, TagFilterOilPaint, TagFilterOldFilm, TagFilterGrayish};
    NSArray *imageNames = [NSArray arrayWithObjects:@"sample_original.png", @"sample_instant.png", @"sample_expose.png", @"sample_vibrance.png", @"sample_comic.png", @"sample_ocean.png", @"sample_lake.png", @"sample_emboss.png", @"sample_oilpaint", @"sample_oldfilm.png", @"sample_grayish.png", nil];
    NSArray *filterNames = [NSArray arrayWithObjects:@"Original", @"Instant", @"Exposual", @"Vibrance", @"Comic", @"Ocean", @"Lake", @"Emboss", @"OilPaint", @"OldFilm", @"Grayish", nil];
    
    for (int i=0; i<filterCount; i++) {
        CGRect frame = CGRectMake(x, y, w, w);
        UIButton *btn = [CIPCustomViewUtils createFilterButton:frame withImage:[UIImage imageNamed:imageNames[i]]];
        btn.tag = tags[i];
        [btn addTarget:self action:@selector(clickFilter:) forControlEvents:UIControlEventTouchDown];
        [self.filterScroll addSubview:btn];
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(x, y+w, w, 18)];
        label.backgroundColor = [UIColor clearColor];
        label.font = [CIPPalette appFontWithSize:10];
        label.text = filterNames[i];
        label.textAlignment = NSTextAlignmentCenter;
        label.textColor = [CIPPalette fontDarkColor];
        [self.filterScroll addSubview:label];
        
        x += w+margin;
    }
    [self.filterScroll addSubview:self.focusView];
    
    if (x > self.filterScroll.frame.size.width) {
        self.filterScroll.contentSize = CGSizeMake(x, self.filterScroll.frame.size.height);
    }
    CGSize screenSize = [[UIScreen mainScreen] applicationFrame].size;
    CGRect frame = self.filterScroll.frame;
    self.filterScroll.frame = CGRectMake(frame.origin.x, screenSize.height-self.filterScroll.frame.size.height, frame.size.width, frame.size.height);
}

- (void) initImageShow {
    CGSize screenSize = [[UIScreen mainScreen] applicationFrame].size;
    self.imageView.frame = CGRectMake(0, 46, screenSize.width, screenSize.height-80);
    
    CGRect bounds = self.imageView.bounds;
    CGFloat w = bounds.size.width;
    CGFloat h = bounds.size.height;
    CGFloat scale = [CIPImageProcess getScaleFor:self.originalImage toFitInto:bounds.size];
    
    CGFloat pw = self.originalImage.size.width*scale;
    CGFloat ph = self.originalImage.size.height*scale;
    CALayer *layer = [[CALayer alloc] init];
    layer.frame = CGRectMake((w-pw)/2, (h-ph)/2, pw, ph);
    layer.contents = (id)self.originalImage.CGImage;
    [self.imageView.layer addSublayer:layer];
}

- (void) previewImage:(UIImage*)image {
    CALayer *layer = [self.imageView.layer.sublayers objectAtIndex:0];
    layer.contents = (id)image.CGImage;
}

#pragma mark -
#pragma mark Action Funtions

- (IBAction)test:(UIBarButtonItem *)sender {
    
}

- (IBAction)apply:(UIButton *)sender {
    [self.delegate filterDidFinishProcess:[UIImage imageWithCGImage:(CGImageRef)[(CALayer*)self.imageView.layer.sublayers[0] contents]]];
    [self dismissViewControllerAnimated:YES completion:^{
    }];
}

- (IBAction)backToCanvas:(UIButton *)sender {
    [self.delegate filterDidCancel];
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (IBAction)showScroll:(UIButton *)sender {
    [UIView animateWithDuration:0.5 animations:^{
        UIView *iconView = [sender viewWithTag:TagFilterDisplayIcon];
        CGPoint displayBtnCenter = sender.center;
        CGPoint scrollCenter = self.filterScroll.center;
        CGFloat moveStep = self.scrollShow?self.filterScroll.frame.size.height:-self.filterScroll.frame.size.height;
        if (self.scrollShow) {
            iconView.transform = CGAffineTransformMakeRotation(M_PI);
        } else {
            iconView.transform = CGAffineTransformIdentity;
        }
        self.displayBtn.center = CGPointMake(displayBtnCenter.x, displayBtnCenter.y+moveStep);
        self.filterScroll.center = CGPointMake(scrollCenter.x, scrollCenter.y+moveStep);
    } completion:^(BOOL finished) {
        self.scrollShow = !self.scrollShow;
    }];
}

- (IBAction)clickFilter:(UIButton*)sender {
    TagInView tag = sender.tag;
    
    switch (tag) {
        case TagFilterOriginal: {
            CALayer *layer = [self.imageView.layer.sublayers objectAtIndex:0];
            layer.contents = (id)self.originalImage.CGImage;
            [(UILabel*)[self.view viewWithTag:TagFilterDisplayLabel] setText:@"Original"];
            break;
        }
        default: {
            NSString *name = [self nameForFilterWithTag:tag];
            UIImage *image = [self.filteredImages valueForKey:name];
            if (image) {
                CALayer *layer = [self.imageView.layer.sublayers objectAtIndex:0];
                layer.contents = (id)image.CGImage;
                [(UILabel*)[self.view viewWithTag:TagFilterDisplayLabel] setText:name];
            } else {
                self.activityIndicator = [CIPUtilities initActivityIndicator:self.view];
                [self.activityIndicator startAnimating];
                NSThread *t = [[NSThread alloc] initWithTarget:self selector:@selector(previewFilter:) object:[NSNumber numberWithInteger:tag]];
                [t start];

                //[self previewFilter:[NSNumber numberWithInteger:tag]];
            }
            break;
        }
    }
    
    [UIView animateWithDuration:0.1 animations:^{
        self.focusView.alpha = 0.0;
    } completion:^(BOOL finished) {
        self.focusView.center = sender.center;
        [UIView animateWithDuration:0.1 animations:^{
            self.focusView.alpha = 1.0;
        } completion:^(BOOL finished) {
            
        }];
        
    }];
}


- (NSString*) nameForFilterWithTag:(TagInView)filterTag {
    NSString *filterName;
    switch (filterTag) {
        case TagFilterEnhance:
            filterName = @"Enhance";
            break;
        case TagFilterInstant:
            filterName = @"Instant";
            break;
        case TagFilterExpose:
            filterName = @"Exposual";
            break;
        case TagFilterVibrance:
            filterName = @"Vibrance";
            break;
        case TagFilterComic:
            filterName = @"Comic";
            break;
        case TagFilterOcean:
            filterName = @"Ocean";
            break;
        case TagFilterLake:
            filterName = @"Lake";
            break;
        case TagFilterEmboss:
            filterName = @"Emboss";
            break;
        case TagFilterOilPaint:
            filterName = @"OilPaint";
            break;
        case TagFilterOldFilm:
            filterName = @"OldFilm";
            break;
        case TagFilterGrayish:
            filterName = @"Grayish";
            break;
        default:
            break;
    }
    return filterName;
}

- (void) previewFilter:(NSNumber*)filterTag {
    UIImage *image;
    NSString *filterName;
    switch ([filterTag integerValue]) {
        case TagFilterEnhance:
            filterName = @"Enhance";
            //image = [CIPFilter filterEnhance:self.originalImage];
            
            image = [CIPFilter test:self.originalImage];
            break;
        case TagFilterInstant:
            filterName = @"Instant";
            image =[CIPFilter filterInstant:self.originalImage];
            break;
        case TagFilterExpose:
            filterName = @"Exposual";
            image = [CIPFilter filterExpose:self.originalImage];
            break;
        case TagFilterVibrance:
            filterName = @"Vibrance";
            image = [CIPFilter filterVibrance:self.originalImage];
            break;
        case TagFilterComic:
            filterName = @"Comic";
            image = [CIPFilter filterComic:self.originalImage];
            break;
        case TagFilterOcean:
            filterName = @"Ocean";
            image = [CIPFilter filterOcean:self.originalImage];
            break;
        case TagFilterLake:
            filterName = @"Lake";
            image = [CIPFilter filterLake:self.originalImage];
            break;
        case TagFilterEmboss:
            filterName = @"Emboss";
            image = [CIPFilter filterEmboss:self.originalImage];
            break;
        case TagFilterOilPaint:
            filterName = @"OilPaint";
            image = [CIPFilter filterOilPaint:self.originalImage];
            break;
        case TagFilterOldFilm:
            filterName = @"OldFilm";
            image = [CIPFilter filterOldFilm:self.originalImage];
            break;
        case TagFilterGrayish:
            filterName = @"Grayish";
            image = [CIPFilter filterGrayish:self.originalImage];
            break;
        default:
            break;
    }
    [self.filteredImages setValue:image forKey:filterName];
    [self.activityIndicator stopAnimating];
    [self.activityIndicator removeFromSuperview];
    [self performSelectorOnMainThread:@selector(updatePreview:) withObject:filterName waitUntilDone:YES];

}

- (void) updatePreview:(NSString*)filterName {
    UIImage *image = [self.filteredImages valueForKey:filterName];
    [(UILabel*)[self.view viewWithTag:TagFilterDisplayLabel] setText:filterName];
    [(CALayer*)self.imageView.layer.sublayers[0] setContents:(id)image.CGImage];
}

@end
