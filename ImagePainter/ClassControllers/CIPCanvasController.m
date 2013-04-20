//
//  ViewController.m
//  ImagePainter
//
//  Created by yuxinjin on 12-9-20.
//  Copyright (c) 2012年 yuxinjin. All rights reserved.
//

extern NSString *const LAYER_CONTENT_IMAGE;

CGFloat zoomRadius = 66;

#import "CIPCanvasController.h"

static const CGSize imageInnerBounds = {640, 640};

@interface CIPCanvasController ()
{
    int testcount;
}
@property (nonatomic, retain) UIStoryboard *storyBoard;

@property (weak, nonatomic) IBOutlet CIPImageView *imageView;

@property (nonatomic) CGPoint imageCenter;
@property (nonatomic) CGPoint lastTranslate;
@property (nonatomic) CGAffineTransform affineTrans;

@property (nonatomic) ProcSubType shapeType;


@property (weak, nonatomic) IBOutlet UIButton *undoBtn;
@property (weak, nonatomic) IBOutlet UIButton *redoBtn;
@property (weak, nonatomic) IBOutlet UIView *navMenu;

@property (nonatomic, retain) CIPDrawMenu *drawMenu;
@property (nonatomic, retain) CIPDrawSimple *drawSimple;
@property (nonatomic, retain) CIPPalettePanel *palettePanel;
@property (nonatomic, retain) CIPLayerBar *layerBar;
@property (nonatomic, retain) UIButton *colorBtn;
@property (nonatomic, retain) UIButton *zoomBtn;
@property (nonatomic, retain) UIButton *fullBtn;
@property (nonatomic, retain) CIPTextControl *textControl;

@property (nonatomic, retain) CIPZoomView *zoomView;

@property (nonatomic, retain) UIView *screenMask;
@property (nonatomic, copy) void(^screenMaskCancel)(void);

//@property (nonatomic, retain) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, retain) CIPAppPreference *appPref;

@property (nonatomic, retain) NSString *canvasName;

@property (nonatomic) BOOL imageFullScreen;
@property (nonatomic) BOOL filterAfterAddPhoto;
@property (nonatomic) BOOL cropAfterAddPhoto;


- (IBAction)test:(id)sender;

@end

@implementation CIPCanvasController
@synthesize imageView;

- (void)viewDidLoad
{
    [super viewDidLoad];
    testcount = 0;
    self.appPref = [[CIPFileUtilities defaultFileUtils] loadAppPref];
    self.imageFullScreen = NO;
    self.filterAfterAddPhoto = NO;
    
    CGRect appframe = [[UIScreen mainScreen] applicationFrame];

    self.storyBoard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:Nil];
    self.imageView.delegate = self;
    self.imageView.historyManager.delegate = self;
    self.imageView.procState = ProcPaint;
    self.imageView.frame = CGRectMake(0, 0, appframe.size.width, appframe.size.height);
    [self.imageView showBackgroundGrid];

    self.imagePickerController = [[UIImagePickerController alloc] init];
    self.imagePickerController.delegate = self;
    CGFloat width = appframe.size.width;
    CGFloat height = appframe.size.height;
    CGFloat navH = 46;
    CGFloat drawW = 50;
    CGFloat layerH = 45;
    CGFloat paletteH = 40;

    self.drawMenu = [[CIPDrawMenu alloc] initWithFrame:CGRectMake(0, navH, drawW, height-navH-layerH)];
    [self.drawMenu addTarget:self action:@selector(changeProcState:) forControlEvents:UIControlEventValueChanged];
    [self.drawMenu selectState:ProcPaint];
    [self.view addSubview:self.drawMenu];
    
    self.drawSimple = [[CIPDrawSimple alloc] initWithFrame:CGRectMake(0, navH, 20, height-navH-layerH)];
    self.drawSimple.alpha = 0.0;
    self.drawSimple.delegate = self;
    [self.drawSimple addTarget:self action:@selector(changeProcState:) forControlEvents:UIControlEventValueChanged];
    [self.drawSimple selectState:ProcPaint];
    [self.view addSubview:self.drawSimple];

    self.palettePanel = [[CIPPalettePanel alloc] initWithFrame:CGRectMake(drawW, height-layerH-paletteH, width-drawW, paletteH)];
    [self.palettePanel updateSubviewsLayout:ProcPaint withPalette:self.imageView.palette];
    self.palettePanel.alpha = 1.0;
    [self.view addSubview:self.palettePanel];

    self.layerBar = [[CIPLayerBar alloc] initWithFrame:CGRectMake(0, height-layerH, width, layerH)];
    self.layerBar.delegate = self;
    [self.view addSubview:self.layerBar];

    self.colorBtn = [CIPCustomViewUtils createColorButton:CGRectMake(width-layerH+1, height-layerH+1, 40, 40) withColor:self.imageView.palette.strokeColor];
    [self.colorBtn addTarget:self action:@selector(openColorPick:) forControlEvents:UIControlEventTouchDown];
    [self.view addSubview:self.colorBtn];
    
    self.zoomBtn = [[UIButton alloc] initWithFrame:CGRectMake(width-layerH*2+1, height-layerH+1, 40, 40)];
    [self.zoomBtn addTarget:self action:@selector(switchZoom:) forControlEvents:UIControlEventTouchDown];
    if (self.appPref.zoomSwitch) {
        [self.zoomBtn setImage:[UIImage imageNamed:@"zoom_on.png"] forState:UIControlStateNormal];
        self.imageView.zoomSwitch = YES;
    } else {
        [self.zoomBtn setImage:[UIImage imageNamed:@"zoom_off.png"] forState:UIControlStateNormal];
        self.imageView.zoomSwitch = NO;
    }
    self.zoomBtn.alpha = 0.0;
    [self.view addSubview:self.zoomBtn];
    
    self.fullBtn = [[UIButton alloc] initWithFrame:CGRectMake(-35, -35, 80, 80)];
    self.fullBtn.alpha = 0.0;
    [self.fullBtn setImage:[UIImage imageNamed:@"btn_full.png"] forState:UIControlStateNormal];
    [self.fullBtn addTarget:self action:@selector(hideFullScreen:) forControlEvents:UIControlEventTouchDown];
    [self.view insertSubview:self.fullBtn belowSubview:self.navMenu];

    self.screenMask = [[UIView alloc] initWithFrame:self.view.frame];
    self.screenMask.layer.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.3].CGColor;
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(closeScreenMask:)];
    [self.screenMask addGestureRecognizer:tapRecognizer];
    self.screenMaskCancel = Nil;

    self.textControl = [[CIPTextControl alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 400)];
    self.textControl.delegate = self;
    
    self.zoomView = [[CIPZoomView alloc] initWithFrame:CGRectMake(0, height-zoomRadius*2, zoomRadius*2, zoomRadius*2)];
    self.zoomView.alpha = 0.0;
    [self.view addSubview:self.zoomView];
}

- (void)viewDidUnload
{
    [self setImageView:nil];
    [self setUndoBtn:nil];
    [self setRedoBtn:nil];
    [self setNavMenu:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}



#pragma mark -
#pragma mark History Function
- (IBAction)undo:(UIButton *)sender {
    [self.imageView historyOperate:YES];
    [self.undoBtn setEnabled:[self.imageView.historyManager canUndo]];
    [self.redoBtn setEnabled:[self.imageView.historyManager canRedo]];
}

- (IBAction)redo:(UIButton *)sender {
    [self.imageView historyOperate:NO];
    [self.undoBtn setEnabled:[self.imageView.historyManager canUndo]];
    [self.redoBtn setEnabled:[self.imageView.historyManager canRedo]];
}

- (IBAction)openGallery:(UIButton *)sender {
    if (self.imageView.changed) {
        UIActionSheet *galleryAlert = [[UIActionSheet alloc] initWithTitle:@"" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:Nil otherButtonTitles:@"Save", @"Don't save", nil];
        galleryAlert.tag = TagGalleryAction;
        [galleryAlert showInView:self.view];
    } else {
        [self callGallery];
    }
}

- (IBAction)openPhoto:(UIButton *)sender {
    UIActionSheet *photoAlert;
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        photoAlert = [[UIActionSheet alloc] initWithTitle:@"" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:Nil otherButtonTitles:@"Add from Album", @"Take from Camera", @"Save to Album", nil];
    } else {
        photoAlert = [[UIActionSheet alloc] initWithTitle:@"" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:Nil otherButtonTitles:@"Add from Album", @"Save to Album", nil];
    }
    photoAlert.tag = TagPhotoAction;
    [photoAlert showInView:self.view];
}

- (void) historyDidChange:(CIPHistoryManager *)historyManager {
    [self.undoBtn setEnabled:[historyManager canUndo]];
    [self.redoBtn setEnabled:[historyManager canRedo]];
}

- (void) actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (actionSheet.tag == TagGalleryAction) {
        switch (buttonIndex)
        {
            case 0: {
                [self saveToGallery];
                break;
            }
            case 1:
                [self callGallery];
                break;
        }
    } else if (actionSheet.tag == TagPhotoAction) {
        NSString *title = [actionSheet buttonTitleAtIndex:buttonIndex];
        if ([title isEqualToString:@"Add from Album"]) {
            [self callImagePicker];
        } else if ([title isEqualToString:@"Take from Camera"]) {
            [self callCameraPicker];
        } else if ([title isEqualToString:@"Save to Album"]) {
            [self saveToAlbum];
        }
    }
}

#pragma mark -
#pragma mark Gallery Function

- (void) callGallery {
    CIPGalleryController *galleryController = (CIPGalleryController*)[self.storyBoard instantiateViewControllerWithIdentifier: @"GalleryController"];
    galleryController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    galleryController.delegate = self;
    [self presentViewController:galleryController animated:YES completion:^{
    }];
}

- (void)cipGallery:(CIPGalleryController *)galleryController didLoad:(NSArray *)layers withName:(NSString *)name {
    [galleryController dismissViewControllerAnimated:YES completion:^{
        [self loadFromGallery:name withLayers:layers];
    }];
}

- (void)saveToGallery {
    [CIPUtilities activityIndicatorInView:self.view withTask:^{
        CIPFileUtilities *fu = [CIPFileUtilities defaultFileUtils];
        UIImage *image = [self.imageView mergeAllLayers2Image];
        UIImage *thumb = [CIPImageProcess pasteImage:image intoSize:CGSizeMake(200, 200)];
        if (!self.canvasName) {
            self.canvasName = [NSString stringWithFormat:@"Canvas%05d", self.appPref.canvasAutoId++];
        }
        [fu saveAppPref:self.appPref];
        [fu saveLayers:self.imageView.layer.sublayers nameAs:self.canvasName withThumb:thumb];
        self.imageView.changed = NO;
        [self performSelectorOnMainThread:@selector(callGallery) withObject:nil waitUntilDone:YES];
    }];
}

- (void)loadFromGallery:(NSString *)canvasName withLayers:(NSArray*)layers{
    if ([self.imageView reloadLayers:layers]){
        [self.layerBar clearThumbs];
        self.canvasName = canvasName;
        CGSize thumbSize = [self.layerBar getRealThumbSize];
        for (CIPPaintLayer *layer in layers) {
            [self.layerBar addThumbAt:-1 withImage:[layer getThumbnailWithinSize:thumbSize] type:[layer getLayerType]];
        }
        [self.layerBar selectThumbAt:0];
    }
}

#pragma mark -
#pragma mark Photo Function

- (void)callImagePicker {
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        self.imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        [self presentViewController:self.imagePickerController animated:YES completion:^{
        }];
    }
}

- (void)callCameraPicker {
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        self.imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
        self.imagePickerController.mediaTypes = [NSArray arrayWithObjects:(NSString *)kUTTypeImage, nil];
        self.imagePickerController.allowsEditing = NO;
        [self presentViewController:self.imagePickerController animated:YES completion:^{
        }];
    }
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = [info valueForKey:UIImagePickerControllerOriginalImage];
    [picker dismissViewControllerAnimated:YES completion:^{
        [self addFromAlbum:image];
    }];
}

- (void) imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    if (self.filterAfterAddPhoto || self.cropAfterAddPhoto) {
        self.filterAfterAddPhoto = NO;
        self.cropAfterAddPhoto = NO;
        self.imageView.procState = ProcView;
        [self.drawMenu selectState:ProcView];
        [self.drawSimple selectState:ProcView];
    }
    [picker dismissViewControllerAnimated:YES completion:^{
    }];
}

- (void)addFromAlbum:(UIImage*)image {
    image = [CIPImageProcess fitImage:image outof:imageInnerBounds];
    if ([self.imageView addPhotoLayer:image]) {
        if (self.filterAfterAddPhoto) {
            [self callFilter];
            self.filterAfterAddPhoto = NO;
        } else if (self.cropAfterAddPhoto) {
            [self callCrop];
            self.cropAfterAddPhoto = NO;
        } else {
            self.imageView.procState = ProcView;
            [self.drawMenu selectState:ProcView];
            [self.drawSimple selectState:ProcView];
        }
    }
}

- (void) saveToAlbum {
    [CIPUtilities activityIndicatorInView:self.view withTask:^{
        CIPFileUtilities *fu = [CIPFileUtilities defaultFileUtils];
        UIImage *image = [self.imageView mergeAllLayers2Image];
        
        [fu saveImage:image withCompletionBloc:^(NSError *error) {
            if (error != nil) {
                NSLog(@"error occurs when saving image to library:%@", error);
            }
            self.imageView.changed = NO;
        }];
    }];
}

#pragma mark -
#pragma mark Color Picker Function
- (IBAction)openColorPick:(UIButton*)sender {
    CGColorRef colorRef = [(CALayer*)sender.layer.sublayers[0] backgroundColor];
    [self callColorPick:[UIColor colorWithCGColor:colorRef]];
}

- (void)callColorPick:(UIColor*)curColor {
    CIPColorPickController *colorPickContorller = (CIPColorPickController*)[self.storyBoard instantiateViewControllerWithIdentifier: @"ColorPickController"];
    colorPickContorller.color = curColor;
    colorPickContorller.colorHistory = self.imageView.palette.colorHistory;
    colorPickContorller.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    colorPickContorller.delegate = self;
    [self presentViewController:colorPickContorller animated:YES completion:^{
    }];
}

- (void)cipColorPick:(UIColor *)color {
    [self.imageView.palette recordColor:color];
    if (self.imageView.procState == ProcText) {
        [self.textControl updateColor:color];
    } else {
        self.imageView.palette.strokeColor = color;
        [(CALayer*)self.colorBtn.layer.sublayers[0] setBackgroundColor:color.CGColor];
        if (self.imageView.procState == ProcCollage) {
            CIPCollageControl *collageCtrl = (CIPCollageControl*)[self.view viewWithTag:TagCollagePanel];
            if (collageCtrl) {
                [collageCtrl updateColor:[UIColor colorWithCGColor:color.CGColor]];
            }
        }
    }
    [[CIPFileUtilities defaultFileUtils] savePalette:self.imageView.palette];
}

#pragma mark-
#pragma mark Collage Insert Function
- (void) callCollagePanel {
    CGRect frame;
    if (self.imageView.fullScreen) {
        frame = CGRectMake(self.drawSimple.frame.size.width, 0, self.view.frame.size.width-self.drawSimple.frame.size.width, self.view.frame.size.height);
    } else {
        frame = CGRectMake(self.drawMenu.frame.size.width, 46, self.view.frame.size.width-self.drawMenu.frame.size.width, self.view.frame.size.height-self.layerBar.frame.size.height-46);
    }
    
    [CIPUtilities activityIndicatorInView:self.view  withTask:^{
        CIPCollageControl *collageCtrl = (CIPCollageControl*)[self.view viewWithTag:TagCollagePanel];
        if (!collageCtrl) {
            collageCtrl = [[CIPCollageControl alloc] initWithFrame:frame];
            collageCtrl.tag = TagCollagePanel;
        }
        [collageCtrl updateColor:self.imageView.palette.strokeColor];
        [collageCtrl addTarget:self action:@selector(insertCollage:) forControlEvents:UIControlEventValueChanged];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.view insertSubview:collageCtrl belowSubview:self.drawMenu];
        });
    }];
}

- (void) closeCollagePanel {
    CIPCollageControl *collageCtrl = (CIPCollageControl*)[self.view viewWithTag:TagCollagePanel];
    if (collageCtrl) {
        [collageCtrl removeFromSuperview];
    }
}

- (IBAction)insertCollage:(CIPCollageControl*)sender {
    UIImage *image = [CIPImageProcess generateImageWithColor:self.imageView.palette.strokeColor onMask:sender.selectedImage];
    [sender removeFromSuperview];
    CGSize frameSize = self.imageView.bounds.size;
    [self.imageView addLayerAt:self.imageView.curLayerIdx layerType:PaintLayer inFrame:CGRectMake((frameSize.width-image.size.width)/2, (frameSize.height-image.size.height)/2, image.size.width, image.size.height) withContent:[NSDictionary dictionaryWithObjectsAndKeys:image, LAYER_CONTENT_IMAGE, nil]];
    [self.layerBar addThumbAt:-1 withImage:[[self.imageView currentLayer] getThumbnailWithinSize:[self.layerBar getRealThumbSize]] type:PaintLayer];
    self.imageView.procState = ProcView;
    [self.drawMenu selectState:ProcView];
    [self.drawSimple selectState:ProcView];
}

#pragma mark -
#pragma mark TextControl Function
- (void) callTextControl:(TextControlStatus)status {
    CIPPaintLayer *layer = [self.imageView currentLayer];
    if ([layer getLayerType] == TextLayer && status != TextControlAdded) {
        [self.textControl updateWithText:[(CIPTextLayer*)layer text] palette:((CIPTextLayer*)layer).palette status:status];
    } else {
        [self.textControl updateWithText:@"" palette:self.imageView.palette status:TextControlAdded];
    }
    [self.view addSubview:self.textControl];
    [self.textControl setFocus];
}

- (void) cipTextControlDidEditing:(CIPTextControl *)textControl withStatus:(TextControlStatus)status {
    NSString *text = [textControl text];
    if (status == TextControlAdded) {
        [self.imageView addText:text withPalette:textControl.palette];
    } else if (status == TextControlChanged) {
        [self.imageView updateText:text withPalette:textControl.palette];
    } else if (status == TextControlRemoved) {
        if ([[self.imageView currentLayer] getLayerType] == TextLayer) {
            //remove the text layer
            NSInteger delIndex = [self.layerBar curThumbIdx];
            [self.layerBar deleteThumbAt:delIndex];
            [self.imageView deleteLayerAt:delIndex toSelect:[self.layerBar curThumbIdx]];
        }
    }
    [textControl removeFromSuperview];
    self.imageView.procState = ProcView;
    [self.drawMenu selectState:ProcView];
    [self.drawSimple selectState:ProcView];
}

- (void) cipTextControl:(CIPTextControl *)textControl callColorPick:(UIColor *)color {
    [self callColorPick:color];
}

#pragma mark -
#pragma mark Filter Function

- (void) callFilter {
    UIImage *image = [UIImage imageWithCGImage:(CGImageRef)[self.imageView currentLayer].contents scale:[[UIScreen mainScreen] scale] orientation:UIImageOrientationUp];
    if (!image || image.size.width==0 || image.size.height==0) {
        self.filterAfterAddPhoto = YES;
        [self callImagePicker];
    } else {
        CIPFilterController *filterController = (CIPFilterController*)[self.storyBoard instantiateViewControllerWithIdentifier: @"FilterController"];;
        
        filterController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        filterController.delegate = self;
        filterController.originalImage = image;
        [self presentViewController:filterController animated:YES completion:^{
        }];
    }
}

- (void) filterDidFinishProcess:(UIImage *)image {
    [self.imageView resetImageForCurrentLayer:image];
    [self.layerBar updateThumbAt:[self.imageView curLayerIdx] withImage:[[self.imageView currentLayer] getThumbnailWithinSize:[self.layerBar getRealThumbSize]]];
    self.imageView.procState = ProcView;
    [self.drawMenu selectState:ProcView];
    [self.drawSimple selectState:ProcView];
}

- (void) filterDidCancel {
    self.imageView.procState = ProcView;
    [self.drawMenu selectState:ProcView];
    [self.drawSimple selectState:ProcView];
}

#pragma mark -
#pragma mark Crop Function

- (void) callCrop {
    UIImage *image = [UIImage imageWithCGImage:(CGImageRef)[self.imageView currentLayer].contents];
    if (!image || image.size.width==0 || image.size.height==0) {
        self.cropAfterAddPhoto = YES;
        [self callImagePicker];
    } else {
        [self fullScreenImageView:YES];
        CIPCropControl *cropControl = [[CIPCropControl alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
        cropControl.delegate = self;
        [self.view addSubview:cropControl];
        
        CIPPaintLayer *layer = [self.imageView currentLayer];
        [cropControl showWithImageRect:layer.frame];
    }
}

- (void) cipCropControlCancel:(CIPCropControl *)cropCtrl {
    [cropCtrl removeFromSuperview];
    self.imageView.procState = ProcView;
    [self.drawMenu selectState:ProcView];
    [self.drawSimple selectState:ProcView];
}

- (void) cipCropControl:(CIPCropControl *)cropCtrl cropRect:(CGRect)cropRect {
    [cropCtrl removeFromSuperview];
    self.imageView.procState = ProcView;
    [self.drawMenu selectState:ProcView];
    [self.drawSimple selectState:ProcView];
    [self.imageView selectCropInRect:cropRect];
}

#pragma mark -
#pragma mark Actions Function

- (IBAction)changeProcState:(CIPDrawMenu*)sender {
    CIPPalette *palette = self.imageView.palette;
    self.imageView.procState = sender.selectedState;
    switch (sender.selectedState) {
        case ProcPaint:
        case ProcEraser:
            [self.palettePanel updateSubviewsLayout:sender.selectedState withPalette:palette];
            [self.palettePanel fullScreenMode:self.imageFullScreen];
            self.palettePanel.alpha = 1.0;
            break;
        case ProcText:
            self.palettePanel.alpha = 0.0;
            [self callTextControl:TextControlNone];
            break;
        case ProcCrop:
            self.palettePanel.alpha = 0.0;
            [self callCrop];
            break;
        case ProcCollage:
            [self callCollagePanel];
            self.palettePanel.alpha = 0.0;
            break;
        case ProcFilter:
            [self callFilter];
            self.palettePanel.alpha = 0.0;
            break;
        default:
            self.palettePanel.alpha = 0.0;
            break;
    }
    if (sender.selectedState != ProcCollage) {
        [self closeCollagePanel];
    }
    if (sender == self.drawMenu) {
        [self.drawSimple selectState:sender.selectedState];
    } else {
        [self.drawMenu selectState:sender.selectedState];
    }
}

- (IBAction) hideFullScreen:(UIButton*)sender {
    [self fullScreenImageView:NO];
}

- (IBAction) switchZoom:(UIButton*)sender {
    if (self.imageView.zoomSwitch) {
        [sender setImage:[UIImage imageNamed:@"zoom_off.png"] forState:UIControlStateNormal];
        self.imageView.zoomSwitch = NO;
        self.appPref.zoomSwitch = NO;
    } else {
        [sender setImage:[UIImage imageNamed:@"zoom_on.png"] forState:UIControlStateNormal];
        self.imageView.zoomSwitch = YES;
        self.appPref.zoomSwitch = YES;
    }
    [[CIPFileUtilities defaultFileUtils] saveAppPref:self.appPref];
}

- (void) fullScreenImageView:(BOOL)full {
    self.imageView.fullScreen = full;
    if (self.imageFullScreen == full) {
        return;
    }
    self.imageFullScreen = full;
    CGRect navMenuFrame = self.navMenu.frame;
    CGRect drawMenuFrame = self.drawMenu.frame;
    CGRect layerBarFrame = self.layerBar.frame;
    CGRect fullBtnFrame = self.fullBtn.frame;
    CGFloat paletteAlpha = (self.imageView.procState == ProcPaint || self.imageView.procState == ProcEraser)?1.0:0.0;
    CGFloat zoomBtnAlpha = self.zoomBtn.alpha;
    CGFloat fullBtnAlpha = self.fullBtn.alpha;
    
    if (!full) {
        navMenuFrame = CGRectMake(0, 0, navMenuFrame.size.width, navMenuFrame.size.height);
        drawMenuFrame = CGRectMake(0, drawMenuFrame.origin.y, drawMenuFrame.size.width, drawMenuFrame.size.height);
        layerBarFrame = CGRectMake(0, self.view.frame.size.height-layerBarFrame.size.height, layerBarFrame.size.width, layerBarFrame.size.height);
        zoomBtnAlpha = 0.0;
        fullBtnAlpha = 0.0;
        fullBtnFrame = CGRectMake(0, 0, 80, 80);
        self.drawSimple.alpha = 0.0;
    } else {
        navMenuFrame = CGRectMake(0, -navMenuFrame.size.height, navMenuFrame.size.width, navMenuFrame.size.height);
        drawMenuFrame = CGRectMake(-drawMenuFrame.size.width, drawMenuFrame.origin.y, drawMenuFrame.size.width, drawMenuFrame.size.height);
        layerBarFrame = CGRectMake(0, self.view.frame.size.height, layerBarFrame.size.width, layerBarFrame.size.height);
        //paletteAlpha = 0.0;
        zoomBtnAlpha = 1.0;
        fullBtnAlpha = 1.0;
        fullBtnFrame = CGRectMake(-35, -35, 80, 80);
    }
    [self.palettePanel beforeFullScreenMode:full];
    [UIView animateWithDuration:0.4 animations:^{
        self.navMenu.frame = navMenuFrame;
        self.drawMenu.frame = drawMenuFrame;
        self.layerBar.frame = layerBarFrame;
        self.palettePanel.alpha = paletteAlpha;
        self.zoomBtn.alpha = zoomBtnAlpha;
        self.fullBtn.alpha = fullBtnAlpha;
        self.fullBtn.frame = fullBtnFrame;
        [self.palettePanel fullScreenMode:full];
    } completion:^(BOOL finished) {
        if (full) {
            self.drawSimple.alpha = 1.0;
        }
    }];
}

- (void) cipDrawSimpleCallFullScreen:(BOOL)needFull {
    [self fullScreenImageView:needFull];
}

- (IBAction)test:(id)sender {
//    UIImage *image = [self.imageView currentLayer].backImage;
//    image = [CIPImageProcess test:image];
//    image = [CIPFilter filterOldFilm:image];
//    [self.imageView addPhotoLayer:image];
}

- (IBAction)testShowMenu:(UIView*)sender {

}


#pragma mark -
#pragma mark Operation On the Transparent Screen Mask

- (void) cipImageView:(CIPImageView *)imageView callSelectOper:(CIPLayerOper *)operView onCancel:(void (^)(void))cancel {
    CGRect frame = self.imageView.frame;
    operView.frame = CGRectMake(frame.origin.x+operView.frame.origin.x, frame.origin.y+operView.frame.origin.y, operView.frame.size.width, operView.frame.size.height);
    operView.alpha = 0;

    self.screenMaskCancel = cancel;
    
    [self.screenMask addSubview:operView];
    [self.view addSubview:self.screenMask];
    [UIView animateWithDuration:0.3 animations:^{
        operView.alpha = 1;
    }];
}

- (void) closeScreenMask {
    
    if (self.screenMaskCancel) {
        [self screenMaskCancel]();
        self.screenMaskCancel = Nil;
    }
    NSArray *subviews = self.screenMask.subviews;
    for (int i=0; i<subviews.count; i++) {
        [subviews[0] removeFromSuperview];
    }
    [self.screenMask removeFromSuperview];
}

- (IBAction)closeScreenMask:(UITapGestureRecognizer*) recognizer {
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        BOOL tapBlank = YES;
        NSArray *subviews = self.screenMask.subviews;
        CGPoint p = [recognizer locationInView:self.screenMask];
        for (UIView *subView in subviews) {
            if (CGRectContainsPoint(subView.frame, p)) {
                tapBlank = NO;
                break;
            }
        }
        if (tapBlank) {
            [self closeScreenMask];
        }
    }
}

#pragma mark -
#pragma mark Layer Bar Delegate

- (void) cipLayerSelectedAt:(NSInteger)selIdx {
    [self.imageView selectLayerAt:selIdx];
}

- (void) cipLayerCallTextControl {
    self.imageView.procState = ProcText;
    self.palettePanel.alpha = 0.0;
    [self callTextControl:TextControlAdded];
}

- (void) cipLayerAddedAt:(NSInteger)addIdx  layerType:(LayerType)type{
    [self.imageView addLayerAt:addIdx layerType:type inFrame:CGRectZero withContent:nil];
}

- (void) cipLayerDeletedAt:(NSInteger)delIdx toSelect:(NSInteger)newIdx {
    [self.imageView deleteLayerAt:delIdx toSelect:newIdx];
}

- (void) cipLayerMovedFrom:(NSInteger)moveIdx to:(NSInteger)toIdx {
    [self.imageView moveLayerAt:moveIdx toIndex:toIdx];
}

- (void) cipLayerMergedFrom:(NSInteger)foreIdx to:(NSInteger)backIdx {
    [self.imageView mergeLayerFrom:foreIdx toIndex:backIdx];
}

- (void) cipLayerClearLast {
    [self.imageView clearLastLayer];
}

#pragma mark -
#pragma mark Image View Delegate

- (void) cipImageView:(CIPImageView *)imageView didScaleChanged :(CGFloat)scale {
    //self.scaleLabel.text = [NSString stringWithFormat:@"%.2f%%",scale*100];
}

- (void) cipImageView:(CIPImageView *)imageView selectLayerAt:(NSInteger)selIndex {
    [self.layerBar selectThumbAt:selIndex];
}

- (void) cipImageView:(CIPImageView *)imageView addLayerAt:(NSInteger)addIndex with:(CIPPaintLayer *)layer {
    UIImage *thumbImage;
    if (layer) {
        thumbImage = [layer getThumbnailWithinSize:[self.layerBar getRealThumbSize]];
    }
    [self.layerBar addThumbAt:addIndex withImage:thumbImage type:[layer getLayerType]];
}

- (void) cipImageView:(CIPImageView *)imageView deleteLayerAt:(NSInteger)delIndex toSelect:(NSInteger)toIndex {
    [self.layerBar deleteThumbAt:delIndex];
    [self.layerBar selectThumbAt:toIndex];
}

- (void) cipImageView:(CIPImageView *)imageView moveLayerAt:(NSInteger)moveIndex toIndex:(NSInteger)toIndex {
    [self.layerBar moveThumbFrom:moveIndex to:toIndex];
}

- (void) cipImageView:(CIPImageView *)imageView didFinishedDrawing:(CIPPaintLayer *)curLayer atIndex:(NSInteger)upIndex {
    [self.layerBar updateThumbAt:upIndex withImage:[curLayer getThumbnailWithinSize:[self.layerBar getRealThumbSize]]];
    [[CIPFileUtilities defaultFileUtils] savePalette:self.imageView.palette];
}

- (void) cipImageViewDidSelectOper:(CIPImageView *)imageView {
    [self closeScreenMask];
}

- (void) cipImageViewCallFullScreen:(BOOL)needFull {
    [self fullScreenImageView:needFull];
}

- (void) cipImageViewShowZoom:(UIImage*)image atCenter:(CGPoint)center {
    if (self.zoomView.alpha == 0.0) {
        self.zoomView.alpha = 1.0;
    }
    CGSize size = self.zoomView.frame.size;
    self.zoomView.frame = CGRectMake(center.x-size.width/2, center.y-size.height/2, size.width, size.height);
    [self.zoomView updateImage:image];
}

- (void) cipImageViewHideZoomView {
    self.zoomView.alpha = 0.0;
}

@end
