//
//  CIPGalleryController.m
//  ImagePainter
//
//  Created by yuxinjin on 12-11-3.
//  Copyright (c) 2012年 yuxinjin. All rights reserved.
//

#import "CIPGalleryController.h"

extern NSString *const CIPFileAttributeName;

NSString *const CIPFileSelectStatus = @"SelectStatus";

@interface CIPGalleryController ()
@property (nonatomic) CGSize canvasSize;
@property (nonatomic) CGSize thumbSize;
@property (nonatomic) CGFloat margin;
@property (nonatomic) BOOL isDelete;

@property (nonatomic, retain) NSArray *delIndexes;
@property (nonatomic, retain) NSMutableArray *canvasDataList;
@property (weak, nonatomic) IBOutlet UIButton *addBtn;
@property (weak, nonatomic) IBOutlet UIButton *delBtn;
@property (weak, nonatomic) IBOutlet UIButton *delSelBtn;
@property (nonatomic, retain) UIScrollView *canvasScroll;

@property (nonatomic, retain) UIActivityIndicatorView *activityIndicator;
@end

@implementation CIPGalleryController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
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
}

- (void)viewDidUnload {
    [self setDelSelBtn:nil];
    [self setAddBtn:nil];
    [self setDelBtn:nil];
    [self setCanvasScroll:nil];
    [self setDelIndexes:nil];
    [self.canvasDataList removeAllObjects];
    [super viewDidUnload];
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (void) initParams {
    self.isDelete = NO;
    [CIPCustomViewUtils makeMainBackgroundForView:self.view];
    [self initCanvas];
}

- (void) initCanvas {
    CGSize size = self.view.frame.size;
	self.canvasDataList = [NSMutableArray arrayWithArray:[[CIPFileUtilities defaultFileUtils] getLayerDataList]];
    self.canvasSize = CGSizeMake(90, 150);
    self.thumbSize = CGSizeMake(90, 120);
    self.margin = (size.width-270)/4;
    self.canvasScroll = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 46, size.width, size.height-46)];
    self.canvasScroll.contentSize = CGSizeMake(size.width, MAX(((self.canvasDataList.count-1)/3+1)*self.canvasSize.height+self.margin*2, self.canvasScroll.frame.size.height));
    
    [self.view addSubview:self.canvasScroll];
    [self.canvasDataList enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [self insertCanvas:obj at:idx];
    }];
}

- (void) insertCanvas:(NSDictionary *) canvasData at:(NSUInteger)index {
    NSUInteger x = index%3;
    NSUInteger y = index/3;
    
    CGPoint origin = CGPointMake(x*(self.canvasSize.width+self.margin)+self.margin, self.margin+y*self.canvasSize.height);
    CGRect canvasFrame = {origin, self.canvasSize};
    UIControl *canvasCell = [[UIControl alloc] initWithFrame:canvasFrame];
    
    UIImageView *thumbView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.thumbSize.width, self.thumbSize.height)];
    thumbView.tag = TagGalleryThumb;
    UIImage *thumbBack = [UIImage imageNamed:@"gallery_thumb.png"];
    NSString *fileName = [canvasData valueForKey:CIPFileAttributeName];
    UIImage *thumb = [[CIPFileUtilities defaultFileUtils] loadThumbFrom:fileName];
    thumb = [CIPImageProcess fitImage:thumb into:CGSizeMake(thumbBack.size.width-10, thumbBack.size.height-10)];
    CGRect rect = CGRectMake((thumbBack.size.width-thumb.size.width)/2, (thumbBack.size.height-thumb.size.height)/2, thumb.size.width, thumb.size.height);
    thumb = [CIPImageProcess drawImage:thumb onto:thumbBack inRect:rect];
    thumbView.image = thumb;
    [canvasCell addSubview:thumbView];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, self.thumbSize.height, self.canvasSize.width, self.canvasSize.height-self.thumbSize.height)];
    label.tag = TagGalleryDateLabel;
    NSDate *modTime = [canvasData valueForKey:NSFileModificationDate];
    [label setTextAlignment:NSTextAlignmentCenter];
    [label setFont:[CIPPalette appFontWithSize:10]];
    [label setTextColor:[CIPPalette fontDarkColor]];
    [label setBackgroundColor:[UIColor clearColor]];
    label.text = [CIPUtilities displayDate:modTime];
    [canvasCell addSubview:label];

    UILabel *idxLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    idxLabel.tag = TagGalleryCanvasIdx;
    idxLabel.text = [NSString stringWithFormat:@"%d", index];
    [canvasCell addSubview:idxLabel];
    
    [canvasCell addTarget:self action:@selector(clickCanvas:) forControlEvents:UIControlEventTouchDown];
    [self.canvasScroll addSubview:canvasCell];
}

#pragma mark-
#pragma mark Navigator Function

- (IBAction)backToCanvas:(UIButton*)sender {
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (IBAction)addCanvas:(UIButton*)sender {
    [self createCanvas];
}

- (IBAction)changeToDelete:(UIButton*)sender {
    
    [UIView animateWithDuration:0.3 animations:^{
        [self switchDeleteStatus:YES];
    } completion:^(BOOL finished) {
    }];
}

- (IBAction)deleteSelection:(id)sender {
    self.delIndexes = [self getIndexesToDelete];
    if (self.delIndexes.count > 0) {
        NSString *msg = [NSString stringWithFormat:@"Do you want to remove the selected %d drawings from gallery?", self.delIndexes.count];
        
        UIActionSheet *deleteAlert = [[UIActionSheet alloc] initWithTitle:msg delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:Nil otherButtonTitles:@"Remove", @"Deselect", nil];
        [deleteAlert showInView:self.view];
    } else {
        [UIView animateWithDuration:0.3 animations:^{
            [self switchDeleteStatus:NO];
        } completion:^(BOOL finished) {
        }];
    }
}

- (IBAction)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch (buttonIndex) {
        case 0:
            [self deleteCanvas:self.delIndexes];
        case 1: {
            self.delIndexes = nil;
            [UIView animateWithDuration:0.3 animations:^{
                [self switchDeleteStatus:NO];
            } completion:^(BOOL finished) {
            }];
            break;
        }
        default: {
            break;
        }
    }
}

- (IBAction)clickCanvas:(UIControl*)selCanvas {
    NSString *idxText = [(UILabel*)[selCanvas viewWithTag:TagGalleryCanvasIdx] text];
    NSInteger idx = [idxText integerValue];
    NSDictionary *canvasData = self.canvasDataList[idx];
    if (self.isDelete) {
        BOOL isSelect = YES;
        NSNumber *number = [canvasData valueForKey:CIPFileSelectStatus];
        if (number) {
            isSelect = ![number boolValue];
        }
        [canvasData setValue:[NSNumber numberWithBool:isSelect] forKey:CIPFileSelectStatus];
        [self deleteMarkFor:selCanvas select:isSelect];
    } else {
        NSString *canvasName = [canvasData valueForKey:CIPFileAttributeName];
        
        self.activityIndicator = [CIPUtilities initActivityIndicator:self.view];
        [self.activityIndicator startAnimating];
        NSThread *t = [[NSThread alloc] initWithTarget:self selector:@selector(loadCanvas:) object:canvasName];
        [t start];
    }
}


#pragma mark-
#pragma mark Canvas Operation Function

- (void) createCanvas {
    CIPPaintLayer *layer = [[CIPPaintLayer alloc] initWithFrame:CGRectZero];
    NSArray *layers = [NSArray arrayWithObjects:layer, nil];
    [self.delegate cipGallery:self didLoad:layers withName:nil];
}

- (void) loadCanvas:(NSString*)loadName {
    NSArray *layers = [[CIPFileUtilities defaultFileUtils] loadLayersFrom:loadName];
    [self.delegate cipGallery:self didLoad:layers withName:[loadName substringToIndex:loadName.length-[@".layers" length]]];
    [self.activityIndicator stopAnimating];
    [self.activityIndicator removeFromSuperview];
}

- (void)deleteMarkFor:(UIControl*)canvas select:(BOOL)isSelected {
    
    UIView *markView = [canvas viewWithTag:TagGalleryDeleteMark];
    if (!markView) {
        markView = [[UIView alloc] initWithFrame:[canvas viewWithTag:TagGalleryThumb].frame];
        markView.layer.cornerRadius = 18;
        markView.tag = TagGalleryDeleteMark;
        [[canvas viewWithTag:TagGalleryThumb] addSubview:markView];
    }
    UILabel *dateLabel = (UILabel*)[canvas viewWithTag:TagGalleryDateLabel];
    if (!isSelected) {
        markView.layer.backgroundColor = [UIColor colorWithRed:0.73 green:0.79 blue:0.8 alpha:0.5].CGColor;
        dateLabel.textColor = [UIColor colorWithRed:0.73 green:0.79 blue:0.8 alpha:0.8];
        [[markView viewWithTag:TagGalleryDeleteSel] removeFromSuperview];
    } else {
        markView.layer.backgroundColor = [UIColor colorWithRed:0.58 green:0.47 blue:0.47 alpha:0.5].CGColor;
        dateLabel.textColor = [UIColor colorWithRed:0.58 green:0.47 blue:0.47 alpha:0.8];
        CGSize size = markView.frame.size;
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake((size.width-36)/2, (size.height-36), 36, 34)];
        imageView.image = [UIImage imageNamed:@"gallery_thumb_selected.png"];
        imageView.tag = TagGalleryDeleteSel;
        [markView addSubview:imageView];
    }
}


- (void) switchDeleteStatus:(BOOL)isDelete {
    self.isDelete = isDelete;
    NSArray *canvasList = self.canvasScroll.subviews;
    if (isDelete) {
        self.delBtn.enabled = NO;
        self.addBtn.enabled = NO;
        self.delBtn.alpha = 0.0;
        self.addBtn.alpha = 0.0;
        self.delSelBtn.enabled = YES;
        self.delSelBtn.alpha = 1.0;
    } else {
        self.delSelBtn.enabled = NO;
        self.delSelBtn.alpha = 0.0;
        self.delBtn.enabled = YES;
        self.addBtn.enabled = YES;
        self.delBtn.alpha = 1.0;
        self.addBtn.alpha = 1.0;
    }
    
    for (UIControl *canvas in canvasList) {
        if (isDelete) {
            [self deleteMarkFor:canvas select:NO];
        } else {
            [[canvas viewWithTag:TagGalleryDeleteMark] removeFromSuperview];
            [(UILabel*)[canvas viewWithTag:TagGalleryDateLabel] setTextColor:[UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1.0]];
        }
    }
}

- (NSArray*) getIndexesToDelete {
    NSMutableArray *delIndexes = [NSMutableArray arrayWithCapacity:self.canvasDataList.count];
    NSInteger idx = 0;
    for (NSDictionary *canvasData in self.canvasDataList) {
        NSNumber *sel = [canvasData valueForKey:CIPFileSelectStatus];
        if (sel && [sel boolValue]) {
            [delIndexes addObject:[NSNumber numberWithInteger:idx]];
        }
        idx++;
    }
    
    return delIndexes;
}

- (void) deleteCanvas:(NSArray*)delIndexes {
    NSMutableArray *indexes = [NSMutableArray arrayWithCapacity:delIndexes.count];
    
    for (NSNumber *number in delIndexes) {
        [indexes insertObject:number atIndex:0];
    }
    
    CIPFileUtilities *fm = [CIPFileUtilities defaultFileUtils];
    for (NSNumber *number in indexes) {
        NSInteger idx = [number integerValue];
        NSDictionary *canvasData = self.canvasDataList[idx];
        NSString *canvasName = [canvasData valueForKey:CIPFileAttributeName];
        [fm removeLayerDataFile:canvasName];
        [self.canvasDataList removeObjectAtIndex:idx];
        [(UIView*)self.canvasScroll.subviews[idx] removeFromSuperview];
    }
    
    [UIView animateWithDuration:0.6 animations:^{
        int index = 0;
        for (UIControl *canvas in self.canvasScroll.subviews) {
            NSUInteger x = index%3;
            NSUInteger y = index/3;
            
            CGPoint origin = CGPointMake(x*(self.canvasSize.width+self.margin)+self.margin, self.margin+y*self.canvasSize.height);
            CGRect canvasFrame = {origin, self.canvasSize};
            canvas.frame = canvasFrame;
            [(UILabel*)[canvas viewWithTag:TagGalleryCanvasIdx] setText:[NSString stringWithFormat:@"%d",index]];
            index++;
        }
        CGSize size = self.view.frame.size;
        self.canvasScroll.contentSize = CGSizeMake(size.width, MAX(((self.canvasDataList.count-1)/3+1)*self.canvasSize.height+self.margin*2, size.height-45));
        
    } completion:^(BOOL finished) {
        
    }];
}

@end
