//
//  CIPLayerBar.h
//  ImagePainter
//
//  Created by yuxinjin on 12-10-27.
//  Copyright (c) 2012年 yuxinjin. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol CIPLayerBarDelegate;

@interface CIPLayerBar : UIControl

@property (nonatomic) NSInteger curThumbIdx;
@property (nonatomic, assign) id<CIPLayerBarDelegate> delegate;

- (CGSize) getRealThumbSize;

- (void) clearThumbs;

- (BOOL) selectThumbAt:(NSInteger)selThumbIdx;
- (BOOL) addThumbAt:(NSInteger)addThumbIdx withImage:(UIImage*)image type:(LayerType) layerType;
- (void) updateThumbAt:(NSInteger)upThumbIdx withImage:(UIImage*)image;
- (BOOL) deleteThumbAt:(NSInteger)delThumbIdx;
- (BOOL) moveThumbFrom:(NSInteger)moveThumbIdx to:(NSInteger)toThumbIdx;
- (BOOL) mergeThumbFrom:(NSInteger)foreThumbIdx onto:(NSInteger)backThumbIdx;
- (BOOL) clearLastThumb;
@end


@protocol CIPLayerBarDelegate <NSObject>

- (void)cipLayerSelectedAt:(NSInteger)selIdx;
- (void)cipLayerCallTextControl;
- (void)cipLayerAddedAt:(NSInteger)addIdx layerType:(LayerType)type;
- (void)cipLayerDeletedAt:(NSInteger)delIdx toSelect:(NSInteger)selIdx;
- (void)cipLayerMovedFrom:(NSInteger)moveIdx to:(NSInteger)toIdx;
- (void)cipLayerMergedFrom:(NSInteger)foreIdx to:(NSInteger)backIdx;
- (void)cipLayerClearLast;

@end
