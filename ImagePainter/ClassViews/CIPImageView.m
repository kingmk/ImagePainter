//
//  UIImageProcView.m
//  ImagePainter
//
//  Created by yuxinjin on 12-9-22.
//  Copyright (c) 2012年 yuxinjin. All rights reserved.
//



extern NSString *const LAYER_CONTENT_IMAGE;
extern NSString *const LAYER_CONTENT_PALETTE;
extern NSString *const LAYER_CONTENT_TEXT;

extern CGFloat zoomRadius;
#import "CIPImageView.h"


@interface CIPImageView()
@property (nonatomic) BOOL drawing;
@property (nonatomic) CGPoint lastTranslate;
@property (nonatomic) CGFloat lastScale;
@property (nonatomic) CGFloat lastRotate;
@property (nonatomic) CGPoint lastPoint;

@property (nonatomic) NSInteger virtualLayerIdx;
@property (nonatomic, retain) id layerDelegate;

@property (nonatomic, retain) UIView *testView;

@property (nonatomic) BOOL touchMoved;

- (void) clearLayers;

@end

@implementation CIPImageView

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initParams];
    }
    return self;
}

- (id) init {
    self = [super init];
    if (self) {
        [self initParams];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initParams];
    }
    return self;
}

- (void)initParams {
    self.touchMoved = NO;
    self.changed = NO;
    self.fullScreen = NO;
    self.virtualLayerIdx = -1;
    self.procState = ProcNoImg;
    self.drawing = NO;
    self.palette = [[CIPFileUtilities defaultFileUtils] loadPalette];
    self.historyManager = [[CIPHistoryManager alloc] init];
    CIPPaintLayer *initLayer = [[CIPPaintLayer alloc] init];
    [self.layer addSublayer:initLayer];
    self.curLayerIdx = 0;
    [self initRecognizer];
}

- (void)initRecognizer {
    UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanFrom:)];
    panRecognizer.delegate = self;
    [self addGestureRecognizer:panRecognizer];
    UIPinchGestureRecognizer *pinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinchFrom:)];
    pinchRecognizer.delegate = self;
    [self addGestureRecognizer:pinchRecognizer];
    UIRotationGestureRecognizer *rotateRecognizer = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(handleRotateFrom:)];
    rotateRecognizer.delegate = self;
    [self addGestureRecognizer:rotateRecognizer];
    
//    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapFrom:)];
//    tapRecognizer.numberOfTapsRequired = 2;
//    [self addGestureRecognizer:tapRecognizer];
}

- (void) showBackgroundGrid {
    //self.layer.contents = (id)[UIImage imageNamed:@"canvas.png"].CGImage;
    self.layer.backgroundColor = [UIColor whiteColor].CGColor;
}

- (void) setPalette:(CIPPalette *)palette {
    _palette = palette;
    [[CIPFileUtilities defaultFileUtils] savePalette:self.palette];
}

- (void) setCurLayerIdx:(NSInteger)curLayerIdx {
    _curLayerIdx = curLayerIdx;
}

#pragma mark -
#pragma mark Image Layer Manage Function

- (CIPPaintLayer*) currentLayer {
    return [self.layer.sublayers objectAtIndex:self.curLayerIdx];
}

- (CIPVirtualLayer*) virtualLayer {
    if (self.virtualLayerIdx<0 && self.virtualLayerIdx>=self.layer.sublayers.count) {
        return nil;
    }
    return [self.layer.sublayers objectAtIndex:self.virtualLayerIdx];
}

- (UIImage*) currentLayerThumbnailIn:(CGSize)targetSize {
    CALayer *curlayer = [self currentLayer];
    if (true) {
        return [(CIPPaintLayer*)curlayer getThumbnailWithinSize:targetSize];
    } else {
        return Nil;
    }
}

- (void) clearLayers {
    NSArray *sublayers = self.layer.sublayers;
    int count = sublayers.count;
    for (int i=0; i<count; i++) {
        CALayer *sublayer = [sublayers lastObject];
        [sublayer removeFromSuperlayer];
    }
    [self.historyManager clearHistories];
}

- (BOOL) addPhotoLayer:(UIImage*)image {
    NSInteger addIdx = self.curLayerIdx;
    [self addLayerAt:addIdx layerType:PhotoLayer inFrame:self.frame withContent:[NSDictionary dictionaryWithObjectsAndKeys:image, LAYER_CONTENT_IMAGE, nil]];
    
    // the bound of viewImage should be adjust to coordinate with image size
    CIPPhotoLayer *layer = (CIPPhotoLayer*)[self currentLayer];
    layer.position = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds)-20);
    self.changed = YES;
    [self.delegate cipImageView:self addLayerAt:addIdx+1 with:layer];
    return YES;
}

- (BOOL) reloadLayers:(NSArray*)layers {
    [self clearLayers];
    for (CIPPaintLayer *layer in layers) {
        [self.layer addSublayer:layer];
    }
    self.curLayerIdx = 0;
    self.changed = NO;
    return YES;
}

- (BOOL) resetImageForCurrentLayer:(UIImage*)image{
    CIPPaintLayer *layer = [self currentLayer];
    [self.historyManager recordBeforeUpdate:layer at:self.curLayerIdx];
    [layer resetBackImage:image];
    [self.historyManager recordAfterUpdate:layer];
    self.changed = YES;
    return YES;
}

#pragma mark -
#pragma mark Layer Operation Function


- (void) selectLayerAt:(NSInteger)layerIdx {
    self.curLayerIdx = MAX(0, MIN(layerIdx, self.layer.sublayers.count-1));
}

- (void) addLayerAt:(NSUInteger)addIndex layerType:(LayerType)type inFrame:(CGRect)frame withContent:(NSDictionary*)content{
    CIPPaintLayer *layer = [CIPPaintLayer createLayerWithFrame:frame type:type withContent:content];
    if (type == TextLayer) {
        [(CIPTextLayer*)layer setPalette:[self.palette copy]];
    }
    if (layer) {
        [self.layer insertSublayer:layer atIndex:addIndex+1];
        if (self.virtualLayerIdx != -1) {
            self.virtualLayerIdx++;
        }
        [self.historyManager recordCreate:layer at:addIndex+1 from: self.curLayerIdx];
        self.curLayerIdx = addIndex+1;
        self.changed = YES;
    }
}

- (void) moveLayerAt:(NSInteger)moveIndex toIndex:(NSInteger)toIndex {
    if (moveIndex == toIndex) {
        return;
    }
    BOOL moveDownward = moveIndex<toIndex;
    
    CIPPaintLayer *layer = (CIPPaintLayer*)[self.layer.sublayers objectAtIndex:moveIndex];
    [self.layer insertSublayer:layer atIndex:moveDownward?toIndex+1:toIndex];
    self.curLayerIdx = toIndex;
    self.changed = YES;
    [self.historyManager recordMoveFrom:moveIndex to:toIndex];
}

- (void) deleteLayerAt:(NSInteger)delIndex toSelect:(NSInteger)newIndex {
    if (delIndex < 0 || delIndex >= self.layer.sublayers.count) {
        return;
    }
    CIPPaintLayer *layer = (CIPPaintLayer*)[self.layer.sublayers objectAtIndex:delIndex];
    [self.historyManager recordDelete:layer at:delIndex];
    [layer removeFromSuperlayer];
    self.curLayerIdx = newIndex;
    self.changed = YES;
}

- (ResultCode) mergeLayerFrom:(NSInteger)foreIndex toIndex:(NSInteger)backIndex {
    CIPPaintLayer *backLayer = (CIPPaintLayer*)[self.layer.sublayers objectAtIndex:backIndex];
    CIPPaintLayer *foreLayer = (CIPPaintLayer*)[self.layer.sublayers objectAtIndex:foreIndex];
    if ([backLayer getLayerType] == PhotoLayer || [foreLayer getLayerType] == PhotoLayer) {
        // not allowed to merge anything on to the photoLayer or merge the photoLayer to another layer
        return ErrorMergeBack;
    }
    [self.historyManager recordBeforeMergeFrom:foreLayer at:foreIndex to:backLayer at:backIndex];
    
    CIPPaintLayer *newLayer = [[CIPPaintLayer alloc] initWithFrame:backLayer.frame];
    newLayer.backImage = backLayer.backImage;
    [newLayer paintImage:foreLayer.backImage fromRect:foreLayer.frame scale:foreLayer.scale];
    
    [self.layer replaceSublayer:backLayer with:newLayer];
    [foreLayer removeFromSuperlayer];
    
    if (foreIndex < backIndex) {
        self.curLayerIdx = backIndex-1;
    } else {
        self.curLayerIdx = backIndex;
    }
    [self.historyManager recordAfterMerge:newLayer at:self.curLayerIdx];
    
    [self.delegate cipImageView:self didFinishedDrawing:newLayer atIndex:self.curLayerIdx];
    self.changed = YES;
    return SUCCESS;
}

- (void) clearLastLayer {
    [self.historyManager recordBeforeUpdate:[self currentLayer] at:0];
    CIPPaintLayer *initLayer = [[CIPPaintLayer alloc] initWithFrame:CGRectZero];
    [self.layer replaceSublayer:[self currentLayer] with:initLayer];
    [self.historyManager recordAfterUpdate:initLayer];
}

- (UIImage*) mergeAllLayers2Image {
    NSArray *layers = self.layer.sublayers;
    if (layers.count == 0) {
        return Nil;
    }
    CIPPaintLayer *mergeLayer = [[CIPPaintLayer alloc] initWithFrame:[(CIPPaintLayer*)layers[0] frame]];
    for (int i=0; i<layers.count; i++) {
        CIPPaintLayer *layer = layers[i];
        [mergeLayer paintImage:[layer getImageForPaint] fromRect:layer.frame scale:layer.scale];
    }
    self.changed = YES;
    UIImage *mergeImage = [mergeLayer getImageForPaint];
    UIGraphicsBeginImageContextWithOptions(mergeImage.size, NO, mergeImage.scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
    CGRect rect = CGRectMake(0, 0, mergeImage.size.width, mergeImage.size.height);
    CGContextFillRect(context, rect);
    [mergeImage drawInRect:rect];
    UIImage *rltImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return rltImage;
}

#pragma mark -
#pragma mark History Undo/Redo Function

- (void) historyCreate:(BOOL)undo {
    NSUInteger index;
    if (undo) {
        NSUInteger index2;
        if ([self.historyManager undoCreate:&index from:&index2]) {
            [self.layer.sublayers[index] removeFromSuperlayer];
            self.curLayerIdx = MIN(index2, self.layer.sublayers.count-1-(self.virtualLayerIdx==-1?0:1));
            [self.delegate cipImageView:self deleteLayerAt:index toSelect:self.curLayerIdx];
        }
    } else {
        CIPPaintLayer *layer;
        if ([self.historyManager redoCreate:&layer at:&index]) {
            [self.layer insertSublayer:layer atIndex:index];
            self.curLayerIdx = MIN(index, self.layer.sublayers.count-1-(self.virtualLayerIdx==-1?0:1));
            [self.delegate cipImageView:self addLayerAt:self.curLayerIdx with:layer];
        }
    }
}

- (void) historyUpdate:(BOOL)undo {
    CIPPaintLayer *layer;
    NSUInteger index;
    if (undo) {
        if ([self.historyManager undoUpdate:&layer at:&index]) {
            [self.layer replaceSublayer:self.layer.sublayers[index] with:layer];
            self.curLayerIdx = index;
            [self.delegate cipImageView:self didFinishedDrawing:layer atIndex:index];
        }
    } else {
        if ([self.historyManager redoUpdate:&layer at:&index]) {
            [self.layer replaceSublayer:self.layer.sublayers[index] with:layer];
            self.curLayerIdx = index;
            [self.delegate cipImageView:self didFinishedDrawing:layer atIndex:index];
        }    }
}

- (void) historyTransform:(BOOL)undo {
    NSUInteger index;
    CIPPaintLayer *layer;
    if (undo) {
        index = [self.historyManager currentHistoryLayerIndex];
        layer = self.layer.sublayers[index];
        if ([self.historyManager undoTransform:layer]) {
            [self.delegate cipImageView:self selectLayerAt:index];
        }
    } else {
        index = [self.historyManager nextHistoryLayerIndex];
        layer = self.layer.sublayers[index];
        if ([self.historyManager redoTransform:layer]) {
            [self.delegate cipImageView:self selectLayerAt:index];
        }
    }
}

- (void) historyDelete:(BOOL)undo {
    NSUInteger index;
    if (undo) {
        CIPPaintLayer *layer;
        if ([self.historyManager undoDelete:&layer at:&index]) {
            [self.layer insertSublayer:layer atIndex:index];
            [self.delegate cipImageView:self addLayerAt:index with:layer];
        }
    } else {
        if ([self.historyManager redoDelete:&index]) {
            [self.layer.sublayers[index] removeFromSuperlayer];
            self.curLayerIdx = MIN(index, self.layer.sublayers.count-1-(self.virtualLayerIdx==-1?0:1));
            [self.delegate cipImageView:self deleteLayerAt:index toSelect:self.curLayerIdx];
        }
    }
}

- (void) historyMove:(BOOL)undo {
    NSUInteger index1;
    NSUInteger index2;
    if (undo) {
        if ([self.historyManager undoMoveFrom:&index1 to:&index2]) {
            NSInteger toIndex = (index2<index1)?index1+1:index1;
            [self.layer insertSublayer:self.layer.sublayers[index2] atIndex:toIndex];
            self.curLayerIdx = index1;
            [self.delegate cipImageView:self moveLayerAt:index2 toIndex:toIndex];
        }
    } else {
        if ([self.historyManager redoMoveFrom:&index1 to:&index2]) {
            NSInteger toIndex = (index1<index2)?index2+1:index2;
            [self.layer insertSublayer:self.layer.sublayers[index1] atIndex:toIndex];
            self.curLayerIdx = index2;
            [self.delegate cipImageView:self moveLayerAt:index1 toIndex:toIndex];
        }
    }
}

- (void) historyMerge:(BOOL)undo {
    NSUInteger foreIndex, backIndex, mergeIndex;
    CIPPaintLayer *foreLayer, *backLayer;
    if (undo) {
        if ([self.historyManager undoMergeFrom:&foreLayer at:&foreIndex to:&backLayer at:&backIndex resultAt:&mergeIndex]) {
            [self.layer replaceSublayer:self.layer.sublayers[mergeIndex] with:backLayer];
            [self.layer insertSublayer:foreLayer atIndex:foreIndex];
            self.curLayerIdx = foreIndex;
            [self.delegate cipImageView:self didFinishedDrawing:backLayer atIndex:mergeIndex];
            [self.delegate cipImageView:self addLayerAt:foreIndex with:foreLayer];
        }
    } else {
        CIPPaintLayer *mergeLayer;
        if ([self.historyManager redoMergeFrom:&foreIndex to:&backIndex result:&mergeLayer at:&mergeIndex]) {
            foreLayer = self.layer.sublayers[foreIndex];
            [self.layer replaceSublayer:self.layer.sublayers[backIndex] with:mergeLayer];
            [foreLayer removeFromSuperlayer];
            self.curLayerIdx = mergeIndex;
            [self.delegate cipImageView:self deleteLayerAt:foreIndex toSelect:mergeIndex];
            [self.delegate cipImageView:self didFinishedDrawing:mergeLayer atIndex:mergeIndex];
        }
    }
}

- (void) historyCutPaste:(BOOL)undo {
    CIPPaintLayer *cutLayer;
    NSUInteger cutIndex, pasteIndex;
    if (undo) {
        if ([self.historyManager undoCutFrom:&cutLayer at:&cutIndex to:&pasteIndex]) {
            [self.layer replaceSublayer:self.layer.sublayers[cutIndex] with:cutLayer];
            [self.layer.sublayers[pasteIndex] removeFromSuperlayer];
            self.curLayerIdx = cutIndex;
            [self.delegate cipImageView:self didFinishedDrawing:cutLayer atIndex:cutIndex];
            [self.delegate cipImageView:self deleteLayerAt:pasteIndex toSelect:cutIndex];
        }
    } else {
        CIPPaintLayer *pasteLayer;
        if ([self.historyManager redoCutFrom:&cutLayer at:&cutIndex to:&pasteLayer at:&pasteIndex]) {
            [self.layer replaceSublayer:self.layer.sublayers[cutIndex] with:cutLayer];
            [self.layer insertSublayer:pasteLayer atIndex:pasteIndex];
            self.curLayerIdx = pasteIndex;
            [self.delegate cipImageView:self didFinishedDrawing:cutLayer atIndex:cutIndex];
            [self.delegate cipImageView:self addLayerAt:pasteIndex with:pasteLayer];
        }
    }
}

- (void) historyOperate:(BOOL)undo{
    if ((undo && ![self.historyManager canUndo]) || (!undo && ![self.historyManager canRedo])) {
        return;
    }
    HistoryType type;
    if (undo) {
        type = [self.historyManager currentHistoryType];
    } else {
        type = [self.historyManager nextHistoryType];
    }
    switch (type) {
        case HistoryLayerCreate:
            [self historyCreate:undo];
            break;
        case HistoryLayerUpdate:
            [self historyUpdate:undo];
            break;
        case HistoryLayerTransform:
            [self historyTransform:undo];
            break;
        case HistoryLayerDelete:
            [self historyDelete:undo];
            break;
        case HistoryLayerMove:
            [self historyMove:undo];
            break;
        case HistoryLayerMerge:
            [self historyMerge:undo];
            break;
        case HistoryLayerCutPaste:
            [self historyCutPaste:undo];
            break;
        default:
            break;
    }
}

#pragma mark -
#pragma mark Virtual Layer Function

- (void) initVirtualLayer:(ImageProcState)procState withStart:(CGPoint)start{
    if (self.virtualLayerIdx != -1) {
        return;
    }
    CIPVirtualLayer *layer = [[CIPVirtualLayer alloc] initWithFrame:self.bounds];
    [layer setVirtualLayer:procState at:start];
    [self.layer addSublayer:layer];
    self.virtualLayerIdx = [self.layer.sublayers count]-1;
}

- (void) removeVirtualLayer {
    if (self.virtualLayerIdx == -1) {
        return;
    }
    CIPVirtualLayer *layer = [self.layer.sublayers objectAtIndex:self.virtualLayerIdx];
    [layer removeFromSuperlayer];
    self.virtualLayerIdx = -1;
}

- (BOOL) displayVirtualLayer:(CGPoint) curPoint {
    if (self.virtualLayerIdx < 0) {
        return NO;
    }
    CIPVirtualLayer *layer = [self.layer.sublayers objectAtIndex:self.virtualLayerIdx];
    if (layer == Nil) {
        return NO;
    }
    [layer drawPaint:curPoint withPalette:self.palette];

    return YES;
}

- (BOOL) drawVirtualLayerToImageLayer {
    CIPVirtualLayer *virtualLayer = [self.layer.sublayers objectAtIndex:self.virtualLayerIdx];
    if (virtualLayer == Nil) {
        return NO;
    }
    
    CIPPaintLayer* imagelayer = [self currentLayer];
    UIImage *image = [virtualLayer getFitBackImage];
    CGRect rect = virtualLayer.contentRect;
    BOOL newLayer = ([self needNewLayer]!=-1);
    if (newLayer) {
        [self addLayerAt:self.curLayerIdx layerType:PaintLayer inFrame:rect withContent:[NSDictionary dictionaryWithObjectsAndKeys:image, LAYER_CONTENT_IMAGE, nil]];
        [self.delegate cipImageView:self addLayerAt:self.curLayerIdx with:[self currentLayer]];
    } else {
        [self.historyManager recordBeforeUpdate:imagelayer at:self.curLayerIdx];
        [imagelayer paintImage:image fromRect:rect scale:1.0];
        [self.historyManager recordAfterUpdate:imagelayer];
        [self.delegate cipImageView:self didFinishedDrawing:(CIPPaintLayer*)[self currentLayer] atIndex:self.curLayerIdx];
    }

    self.changed = YES;
    return YES;
}

#pragma mark -
#pragma mark Image Drawing Function
- (LayerType) needNewLayer {
    CIPPaintLayer *layer = [self currentLayer];
    // if the current layer is for paint and shape, no new layer needs in the Paint and Shape state
    // if the current layer is for text, no new layer needs in the Text state
    BOOL newLayer = (self.procState == ProcPaint && [layer getLayerType] != PaintLayer) || (self.procState == ProcText && [layer getLayerType] != TextLayer);
    return newLayer?[layer getLayerType]:-1;
}

- (void) initLayerWithImage:(UIImage*)image withFrame:(CGRect)frame atIndex:(NSUInteger)addIndex {
    CIPPaintLayer *layer = [[CIPPaintLayer alloc] initWithFrame:frame];
    layer.backImage = image;
    layer.contents = (id)image.CGImage;
    [self.layer insertSublayer:layer atIndex:addIndex+1];
    self.changed = YES;
}

- (BOOL) drawTest {

    return YES;
}

#pragma mark -
#pragma mark Text Function

- (void) setTextLayer:(CGRect) rect {
    UIColor *backColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.2];
    if ([[self currentLayer] getLayerType] != TextLayer) {
        [self addLayerAt:self.curLayerIdx layerType:TextLayer inFrame:rect withContent:[NSDictionary dictionaryWithObjectsAndKeys:self.palette, LAYER_CONTENT_PALETTE, @"", LAYER_CONTENT_TEXT, nil]];
        [self.delegate cipImageView:self addLayerAt:self.curLayerIdx with:[self currentLayer]];
    } 
    CIPTextLayer *layer = (CIPTextLayer*)[self currentLayer];
    [layer setupTextRect:rect withBackColor:backColor withPalette:self.palette];
    self.changed = YES;
}

- (void) addText:(NSString*)text withPalette:(CIPPalette *)palette {
    [self.palette copyFontFrom:palette];
    // create a text layer
    [self addLayerAt:self.curLayerIdx layerType:TextLayer inFrame:CGRectMake(50, 60, 220, 100) withContent:[NSDictionary dictionaryWithObjectsAndKeys:self.palette, LAYER_CONTENT_PALETTE, text, LAYER_CONTENT_TEXT, nil]];
    [self.delegate cipImageView:self addLayerAt:self.curLayerIdx with:[self currentLayer]];
}

- (void) updateText:(NSString *)text withPalette:(CIPPalette *)palette {
    CIPPaintLayer *layer = [self currentLayer];
    if ([layer getLayerType] != TextLayer) {
        // create a text layer
        [self addText:text withPalette:palette];
    } else {
        [self.palette copyFontFrom:palette];
        [self.historyManager recordBeforeUpdate:layer at:self.curLayerIdx];
        [(CIPTextLayer*)layer paintText:text withPalette:palette showBorder:NO];
        [self.historyManager recordAfterUpdate:layer];
        [self.delegate cipImageView:self didFinishedDrawing:layer atIndex:self.curLayerIdx];
    }
    [[CIPFileUtilities defaultFileUtils] savePalette:self.palette];
    self.changed = YES;
}


#pragma mark -
#pragma mark Crop Function

- (void) selectCropInRect:(CGRect)cropRect {
    CIPPaintLayer *curlayer = [self currentLayer];
    [self.historyManager recordBeforeUpdate:curlayer at:self.curLayerIdx];
    [curlayer cropImageIn:cropRect];
    [self.historyManager recordAfterUpdate:curlayer];
    [self.delegate cipImageView:self didFinishedDrawing:[self currentLayer] atIndex:self.curLayerIdx];
}

// deprecated method
- (IBAction)selectOper:(CIPLayerOper*)sender {
    CIPVirtualLayer *vlayer = [self.layer.sublayers objectAtIndex:self.virtualLayerIdx];
    CIPPaintLayer *curlayer = [self currentLayer];
    CGRect rect = vlayer.selectRect;
    [self removeVirtualLayer];

    switch (sender.operTag) {
        case TagSelectCrop:
            [self.historyManager recordBeforeUpdate:curlayer at:self.curLayerIdx];
            [curlayer cropImageIn:rect];
            [self.historyManager recordAfterUpdate:curlayer];
            break;
        case TagSelectClear:
            [self.historyManager recordBeforeUpdate:curlayer at:self.curLayerIdx];
            [curlayer clearImageIn:rect];
            [self.historyManager recordAfterUpdate:curlayer];
            break;
        case TagSelectCopy: {
            [self.delegate cipImageView:self addLayerAt:-1 with:nil];
            UIImage *selectImage = [curlayer copyImageIn:rect];
            [self addLayerAt:self.curLayerIdx layerType:PaintLayer inFrame:rect withContent:[NSDictionary dictionaryWithObjectsAndKeys:selectImage, LAYER_CONTENT_IMAGE, nil]];
            break;
        }
        case TagSelectCut:{
            [self.historyManager recordBeforeCutFrom:curlayer at:self.curLayerIdx pasteTo:self.curLayerIdx+1];
            UIImage *selectImage = [curlayer copyImageIn:rect];
            [curlayer clearImageIn:rect];
            [self.delegate cipImageView:self didFinishedDrawing:curlayer atIndex:self.curLayerIdx];
            [self.delegate cipImageView:self addLayerAt:-1 with:nil];
            [self initLayerWithImage:selectImage withFrame:rect atIndex:self.curLayerIdx];
            self.curLayerIdx++;
            [self.historyManager recordAfterCutFrom:curlayer pasteTo:[self currentLayer]];
            break;
        }
        default:
            break;
    }
    self.changed = YES;
    [self.delegate cipImageViewDidSelectOper:self];
    [self.delegate cipImageView:self didFinishedDrawing:[self currentLayer] atIndex:self.curLayerIdx];
}

#pragma mark -
#pragma mark Gesture Recognizer Function
- (void) beforeGestureRecord:(GestureType)gesType {
    CIPPaintLayer *curLayer = [self currentLayer];
    LayerType layerType = [curLayer getLayerType];
    
    switch (gesType) {
        case GesturePan:
            [self.historyManager recordBeforeTransform:curLayer at:self.curLayerIdx];
            break;
        case GesturePinch:
        case GestureRotate:
        {
            switch (layerType) {
                case PaintLayer:
                    [self.historyManager recordBeforeUpdate:curLayer at:self.curLayerIdx];
                    break;
                case PhotoLayer:
                case TextLayer:
                    [self.historyManager recordBeforeTransform:curLayer at:self.curLayerIdx];
                    break;
            }
            break;
        }
        default:
            break;
    }
}

- (void) afterGestureRecord:(GestureType)gesType {
    CIPPaintLayer *curLayer = [self currentLayer];
    LayerType layerType = [curLayer getLayerType];
    switch (gesType) {
        case GesturePan:
            [self.historyManager recordAfterTransform:curLayer];
            break;
        case GesturePinch:
        case GestureRotate:
        {
            switch (layerType) {
                case PaintLayer:
                    [self.historyManager recordAfterUpdate:curLayer];
                    break;
                case PhotoLayer:
                case TextLayer:
                    [self.historyManager recordAfterTransform:curLayer];
                    break;
            }
            break;
        }
        default:
            break;
    }
}

- (void) cancelGestureRecord {
    [self.historyManager removeCurrentHistory];
}

- (NSInteger) topLayerAt:(CGPoint)point {
    int layercount = self.layer.sublayers.count-(self.virtualLayerIdx==-1?0:1);
    NSArray *layers = self.layer.sublayers;
    int idx;
    for (idx = layercount-1; idx>=0; idx--) {
        CIPPaintLayer *layer = layers[idx];
        if ([layer hasSelectAt:point]) {
            break;
        }
    }
    return idx;
}

- (void) selectLayerByGesture:(UIGestureRecognizer *)recognizer {
    NSInteger touchCount = recognizer.numberOfTouches;

    CIPPaintLayer *curLayer = [self currentLayer];
    BOOL allInOneLayer = YES;
    BOOL allInCurLayer = YES;
    NSInteger lastTop = -1;
    for (int i=0; i<touchCount; i++) {
        CGPoint point = [recognizer locationOfTouch:i inView:self];
        NSInteger index = [self topLayerAt:point];
        allInOneLayer = allInOneLayer & (index!=-1);
        if (allInOneLayer) {
            if (lastTop == -1) {
                lastTop = index;
            } else if (lastTop != index) {
                allInOneLayer = NO;
            }
        }
        BOOL hitCurLayer = [curLayer hasSelectAt:point];
        allInCurLayer = allInCurLayer & hitCurLayer;
    }
    if (((!allInCurLayer && allInOneLayer) || touchCount == 1) && self.curLayerIdx != lastTop && lastTop >=0) {
        self.curLayerIdx = lastTop;
        [self.delegate cipImageView:self selectLayerAt:lastTop];
    }
}

- (BOOL) gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    // Disallow recognition when not in ProcView state.
    if (self.procState != ProcView) {
        return NO;
    }
    return YES;
}

- (IBAction)handlePanFrom:(UIPanGestureRecognizer*)sender {
    CGPoint translate = [sender translationInView:self];
    if (sender.state == UIGestureRecognizerStateBegan) {
        [self removeVirtualLayer];
        self.lastTranslate = CGPointZero;
        [self selectLayerByGesture:sender];
        [self beforeGestureRecord:GesturePan];
        self.fullScreen = YES;
        [self.delegate cipImageViewCallFullScreen:YES];
    }
    CIPPaintLayer* curLayer = [self currentLayer];
    CGPoint deltaTranslate = CGPointMake(translate.x-self.lastTranslate.x, translate.y-self.lastTranslate.y);
    [curLayer translate:deltaTranslate];
    self.lastTranslate = translate;
    self.changed = YES;
    if (sender.state == UIGestureRecognizerStateEnded){
        [self afterGestureRecord:GesturePan];
    }
    
    if (sender.state == UIGestureRecognizerStateCancelled) {
        [curLayer translate:CGPointMake(-translate.x, -translate.y)];
        [self cancelGestureRecord];
    }
}

- (IBAction)handlePinchFrom:(UIPinchGestureRecognizer*)sender {
    if (sender.state == UIGestureRecognizerStateBegan) {
        [self removeVirtualLayer];
        self.lastScale = 1.0;
        //[self selectLayerByGesture:sender];
        [self beforeGestureRecord:GesturePinch];
        self.fullScreen = YES;
        [self.delegate cipImageViewCallFullScreen:YES];
    }
    NSUInteger xy = 0;
    CIPPaintLayer* curLayer = [self currentLayer];
    CGFloat dx, dy;
    if ([sender numberOfTouches] >= 2) {
        CGPoint p1 = [sender locationOfTouch:0 inView:self];
        CGPoint p2 = [sender locationOfTouch:1 inView:self];
        dx = ABS(p1.x-p2.x);
        dy = ABS(p1.y-p2.y);
        CGFloat angle = atan2f(dx, dy)/M_PI;
        if (angle>=0 && angle<1.0/8.0) {
            xy = 1;
        } else if (angle>=1.0/8.0 && angle<3.0/8.0) {
            xy = 2;
        } else {
            xy = 0;
        }
    } else {
        xy = 2;
    }
    
    CGFloat scale = [sender scale];
    CGFloat deltaScale = scale/self.lastScale;
    if ([curLayer getLayerType] != TextLayer) {
        [curLayer scaleComponent:deltaScale component:xy];
    } else {
        [(CIPTextLayer*)curLayer enlarge:deltaScale component:xy delta:dx];
    }
    self.lastScale = scale;
    
    if (sender.state == UIGestureRecognizerStateEnded) {
        if ([curLayer getLayerType]==PaintLayer) {
            [curLayer applyScale];
            [self.delegate cipImageView:self didFinishedDrawing:(CIPPaintLayer*)[self currentLayer] atIndex:self.curLayerIdx];
        } else if ([curLayer getLayerType]==TextLayer) {
            [(CIPTextLayer*)curLayer paintTextWithBorder:NO];
        }
        
        [self afterGestureRecord:GesturePinch];
        self.changed = YES;
    }
    
    if (sender.state == UIGestureRecognizerStateCancelled) {
        curLayer.affineTransform = CGAffineTransformMakeScale(curLayer.scale, curLayer.scale);
        [self cancelGestureRecord];
    }
}

- (IBAction)handleRotateFrom:(UIRotationGestureRecognizer*)sender {
    if (sender.state == UIGestureRecognizerStateBegan) {
        [self removeVirtualLayer];
        //[self selectLayerByGesture:sender];
        self.lastRotate = 0;
        [self beforeGestureRecord:GestureRotate];
        self.fullScreen = YES;
        [self.delegate cipImageViewCallFullScreen:YES];
    }
    CIPPaintLayer* curLayer = [self currentLayer];
    CGFloat rotate = [sender rotation];
    CGFloat deltaRotate = rotate-self.lastRotate;
    [curLayer rotate:deltaRotate];
    self.lastRotate = rotate;
    
    if (sender.state == UIGestureRecognizerStateEnded) {
        if ([curLayer getLayerType] == PaintLayer) {
            [(CIPPaintLayer *)[self currentLayer] applyRotate];
            [self.delegate cipImageView:self didFinishedDrawing:(CIPPaintLayer*)[self currentLayer] atIndex:self.curLayerIdx];
        } else if ([curLayer getLayerType] == TextLayer) {
            [(CIPTextLayer*)curLayer paintTextWithBorder:NO];
        }
        [self afterGestureRecord:GestureRotate];
        self.changed = YES;
    }
    
    if (sender.state == UIGestureRecognizerStateCancelled) {
        curLayer.affineTransform = CGAffineTransformMakeScale(curLayer.scale, curLayer.scale);
        if ([curLayer getLayerType] == TextLayer) {
            [(CIPTextLayer*)curLayer paintTextWithBorder:NO];
        }
        [self cancelGestureRecord];
    }
}

#pragma mark -
#pragma mark Touch Event Function

- (NSMutableArray*) getTouchPoints:(NSSet *)touches {
    NSMutableArray *touchPoints = [NSMutableArray arrayWithCapacity:touches.count];
    [touches enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        UITouch *touch = (UITouch*)obj;
        CGPoint p = [touch locationInView:self];
        [touchPoints addObject:[NSValue valueWithCGPoint:p]];
    }];

    return touchPoints;
}

// brushType = -1: erasing
- (void) showZoomAtPoint:(CGPoint) point withBrush:(NSInteger)brushType {
    if (!self.zoomSwitch) {
        return;
    }
    CGRect zoomRect = CGRectMake(point.x-zoomRadius/2, point.y-zoomRadius/2, zoomRadius, zoomRadius);
    CGFloat width = self.palette.strokeWidth;
    UIGraphicsBeginImageContextWithOptions(zoomRect.size, NO, [[UIScreen mainScreen] scale]);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    for (CALayer *layer in self.layer.sublayers) {
        UIImage *tmpImage = nil;
        if ([layer isKindOfClass:[CIPPaintLayer class]]) {
            tmpImage = [(CIPPaintLayer*)layer copyImageIn:zoomRect];
        } else if ([layer isKindOfClass:[CIPVirtualLayer class]]) {
            tmpImage = [(CIPVirtualLayer*)layer copyImageIn:zoomRect];
        }
        if (tmpImage) {
            [tmpImage drawInRect:CGRectMake(0, 0, zoomRadius, zoomRadius)];
        }
    }
    if (brushType > 0) {
        CGFloat colors[4] = {0, 0, 0, 1};
        CGImageRef brushImg = [CIPBrushUtilities getBrushForType:brushType withColor:colors];
        CGContextDrawImage(context, CGRectMake((zoomRadius-width)/2, (zoomRadius-width)/2, width, width), brushImg);
        CGImageRelease(brushImg);
    } else {
        CGContextSetStrokeColorWithColor(context, [UIColor blackColor].CGColor);
        CGContextAddArc(context, zoomRadius/2, zoomRadius/2, width/2, 0, M_PI*2, 1);
        CGContextStrokePath(context);
    }
    UIImage *cropImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    //CGFloat d = zoomRadius*2;
    CGFloat w = self.frame.size.width;
    CGFloat h = self.frame.size.height;
    CGFloat x = point.x;
    CGFloat y = point.y;
//    if (point.y < d) {
//        y = zoomRadius;
//        x = point.x-sqrtf(zoomRadius*zoomRadius-(zoomRadius-point.y)*(zoomRadius-point.y));
//        if (x < zoomRadius) {
//            x = zoomRadius;
//        } else if (x > w-zoomRadius) {
//            x = w-zoomRadius;
//        }
//    } else {
//        if (point.x < zoomRadius) {
//            x = zoomRadius;
//        } else if (point.x > w-zoomRadius) {
//            x = w-zoomRadius;
//        }
//    }
    if (y >= h-zoomRadius*2 && x <= 2*zoomRadius) {
        x = w-zoomRadius;
        y = zoomRadius;
    } else {
        x = zoomRadius;
        y = h-zoomRadius;
    }
    CGPoint zoomCenter = CGPointMake(x, y);
    [self.delegate cipImageViewShowZoom:cropImage atCenter:zoomCenter];
}

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    self.touchMoved = NO;
    if (self.procState == ProcNoImg || self.procState == ProcView || self.drawing || self.procState == ProcText || self.procState == ProcCrop) {
        return;
    }
    NSMutableArray *touchPoints = [self getTouchPoints:touches];
    CGPoint point = [(NSNumber*)touchPoints[0] CGPointValue];
    self.drawing = YES;
    if (self.procState == ProcEraser) {
        self.lastPoint = point;
        [self.historyManager recordBeforeUpdate:[self currentLayer] at:self.curLayerIdx];
        [[self currentLayer] erasePoint:point withPalette:self.palette];
        return;
    } else {
        [self initVirtualLayer:self.procState withStart:point];
    }

    if (self.procState == ProcPaint) {
        [self displayVirtualLayer:point];
    }
    [self showZoomAtPoint:point withBrush:(self.procState == ProcEraser?-1:self.palette.brushType)];
}

- (void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    self.touchMoved = YES;
    if (self.procState == ProcNoImg || self.procState == ProcView || !self.drawing || self.procState == ProcText || self.procState == ProcCrop) {
        return;
    }
    if (!self.fullScreen) {
        self.fullScreen = YES;
        [self.delegate cipImageViewCallFullScreen:YES];
    }
    NSMutableArray *touchPoints = [self getTouchPoints:touches];
    CGPoint point = [(NSNumber*)touchPoints[0] CGPointValue];
    
    if (self.procState == ProcEraser) {
        [[self currentLayer] eraseLineFrom:self.lastPoint to:point withPalette:self.palette];
        self.lastPoint = point;
    } else {
        [self displayVirtualLayer:point];
    }
    [self showZoomAtPoint:point withBrush:(self.procState == ProcEraser?-1:self.palette.brushType)];
}

- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    if (!self.touchMoved) {
        [self removeVirtualLayer];
        self.drawing = NO;
        self.fullScreen = !self.fullScreen;
        [self.delegate cipImageViewCallFullScreen:self.fullScreen];
        [self.delegate cipImageViewHideZoomView];
        return;
    }
    
    if (self.procState == ProcNoImg || self.procState == ProcView || !self.drawing || self.procState == ProcText || self.procState == ProcCrop) {
        return;
    }
    NSMutableArray *touchPoints = [self getTouchPoints:touches];
    CGPoint point = [(NSNumber*)touchPoints[0] CGPointValue];
    [self displayVirtualLayer:point];
    if (self.procState == ProcEraser) {
        [[self currentLayer] eraseLineFrom:self.lastPoint to:point withPalette:self.palette];
        [self.historyManager recordAfterUpdate:[self currentLayer]];
        [self.delegate cipImageView:self didFinishedDrawing:[self currentLayer] atIndex:self.curLayerIdx];
    } else if (self.procState == ProcPaint) {
        [self drawVirtualLayerToImageLayer];
    }

    [self removeVirtualLayer];
    self.drawing = NO;
    self.changed = YES;
    [self.delegate cipImageViewHideZoomView];
}

- (void) touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    [self removeVirtualLayer];
    if (!self.drawing || !self.touchMoved) {
        return;
    }
    if (self.procState == ProcEraser) {
        [self.historyManager removeCurrentHistory];
    }
    self.drawing = NO;
    [self.delegate cipImageViewHideZoomView];
}


@end
