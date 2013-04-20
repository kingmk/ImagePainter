//
//  UIImageProcView.h
//  ImagePainter
//
//  Created by yuxinjin on 12-9-22.
//  Copyright (c) 2012年 yuxinjin. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol CIPImageViewDelegate;

@interface CIPImageView : UIView<UIGestureRecognizerDelegate, UIAlertViewDelegate>
@property (nonatomic) BOOL changed;
@property (nonatomic) CIPPalette *palette;
@property (nonatomic) ImageProcState procState;
@property (nonatomic, assign) id<CIPImageViewDelegate> delegate;
@property (nonatomic, retain) CIPHistoryManager *historyManager;

@property (nonatomic) BOOL zoomSwitch;
@property (nonatomic) BOOL fullScreen;
@property (nonatomic) NSInteger curLayerIdx;

- (void) showBackgroundGrid;

- (BOOL) resetImageForCurrentLayer:(UIImage*)image;
- (CIPPaintLayer*) currentLayer;
- (UIImage*) currentLayerThumbnailIn:(CGSize)targetSize;
- (BOOL) addPhotoLayer:(UIImage*)image;
- (BOOL) reloadLayers:(NSArray*)layers;

- (void) setTextLayer:(CGRect) rect;
- (void) addText:(NSString*)text withPalette:(CIPPalette *)palette;
- (void) updateText:(NSString*)text withPalette:(CIPPalette*)palette;

- (void) selectLayerAt:(NSInteger)layerIdx;
- (void) addLayerAt:(NSUInteger)addIndex layerType:(LayerType)type inFrame:(CGRect)frame withContent:(NSDictionary*)content;
- (void) moveLayerAt:(NSInteger)moveIndex toIndex:(NSInteger)toIndex ;
- (void) deleteLayerAt:(NSInteger)delIndex toSelect:(NSInteger)newIndex;
- (ResultCode) mergeLayerFrom:(NSInteger)foreIndex toIndex:(NSInteger)backIndex;
- (void) clearLastLayer;

- (void) selectCropInRect:(CGRect)cropRect;

- (UIImage*) mergeAllLayers2Image;

- (void) historyOperate:(BOOL)undo;

- (BOOL) drawTest;
@end


@protocol CIPImageViewDelegate <NSObject>
@optional
- (void) cipImageView:(CIPImageView *)imageView didScaleChanged:(CGFloat)scale;
- (void) cipImageView:(CIPImageView *)imageView selectLayerAt:(NSInteger)selIndex;
- (void) cipImageView:(CIPImageView *)imageView addLayerAt:(NSInteger)addIndex with:(CIPPaintLayer*) layer;
- (void) cipImageView:(CIPImageView *)imageView deleteLayerAt:(NSInteger)delIndex toSelect:(NSInteger)toIndex;
- (void) cipImageView:(CIPImageView *)imageView moveLayerAt:(NSInteger)moveIndex toIndex:(NSInteger)toIndex;
- (void) cipImageView:(CIPImageView *)imageView mergeLayerFrom:(NSInteger)foreIndex toIndex:(NSInteger)backIndex;

- (void) cipImageView:(CIPImageView*)imageView didFinishedDrawing:(CIPPaintLayer*) curLayer atIndex:(NSInteger)upIndex;

- (void) cipImageView:(CIPImageView *)imageView callSelectOper:(CIPLayerOper*)operView onCancel:(void(^)(void))cancel;

- (void) cipImageViewDidSelectOper:(CIPImageView*)imageView;
- (void) cipImageViewCallFullScreen:(BOOL)needFull;

- (void) cipImageViewShowZoom:(UIImage*)image atCenter:(CGPoint)center;
- (void) cipImageViewHideZoomView;

@end

