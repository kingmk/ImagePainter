//
//  CIPHistoryManager.h
//  ImagePainter
//
//  Created by yuxinjin on 12-10-19.
//  Copyright (c) 2012年 yuxinjin. All rights reserved.
//

#import <Foundation/Foundation.h>
typedef enum {
    HistoryLayerCreate = 0,
    HistoryLayerDelete = 1,
    HistoryLayerMove = 2,
    HistoryLayerMerge = 3,
    HistoryLayerUpdate = 4,
    HistoryLayerTransform = 5,
    HistoryLayerCutPaste = 6,
    
    HistoryLayerError = 10
} HistoryType;

@protocol CIPHistoryManagerDelegate;

@interface CIPHistoryManager : NSObject

@property (nonatomic, assign) id<CIPHistoryManagerDelegate> delegate;

- (BOOL) canUndo;
- (BOOL) canRedo;
- (void) clearHistories;
- (void) removeCurrentHistory;
- (HistoryType) currentHistoryType;
- (HistoryType) nextHistoryType;
- (NSUInteger) currentHistoryLayerIndex;
- (NSUInteger) nextHistoryLayerIndex;

- (void) recordCreate:(CIPPaintLayer*)layer at:(NSUInteger)index from:(NSUInteger)index2;
- (void) recordBeforeUpdate:(CIPPaintLayer*)layer at:(NSUInteger)index;
- (void) recordAfterUpdate:(CIPPaintLayer*)layer;
- (void) recordBeforeTransform:(CIPPaintLayer*)layer at:(NSUInteger)index;
- (void) recordAfterTransform:(CIPPaintLayer*)layer;
- (void) recordDelete:(CIPPaintLayer*)layer at:(NSUInteger) index;
- (void) recordMoveFrom:(NSUInteger)index1 to:(NSUInteger)index2;
- (void) recordBeforeMergeFrom:(CIPPaintLayer*)layer1 at:(NSUInteger)index1 to:(CIPPaintLayer*)layer2 at:(NSUInteger)index2;
- (void) recordAfterMerge:(CIPPaintLayer*)layerResult at:(NSUInteger)index;
- (void) recordBeforeCutFrom:(CIPPaintLayer*)layer1 at:(NSUInteger)index1 pasteTo:(NSUInteger)index2;
- (void) recordAfterCutFrom:(CIPPaintLayer*)layer1 pasteTo:(CIPPaintLayer*)layer2;

- (BOOL) undoCreate:(NSUInteger*)index from:(NSUInteger *)index2;
- (BOOL) redoCreate:(CIPPaintLayer**)layer at:(NSUInteger*)index;

- (BOOL) undoUpdate:(CIPPaintLayer**)layer at:(NSUInteger*)index;
- (BOOL) redoUpdate:(CIPPaintLayer**)layer at:(NSUInteger *)index;

- (BOOL) undoTransform:(CIPPaintLayer*)layer;
- (BOOL) redoTransform:(CIPPaintLayer*)layer;

- (BOOL) undoDelete:(CIPPaintLayer**)layer at:(NSUInteger*)index;
- (BOOL) redoDelete:(NSUInteger*)index;

- (BOOL) undoMoveFrom:(NSUInteger*)index1 to:(NSUInteger*)index2;
- (BOOL) redoMoveFrom:(NSUInteger*)index1 to:(NSUInteger*)index2;

- (BOOL) undoMergeFrom:(CIPPaintLayer**)layer1 at:(NSUInteger*)index1 to:(CIPPaintLayer**)layer2 at:(NSUInteger*)index2 resultAt:(NSUInteger*)indexResult;
- (BOOL) redoMergeFrom:(NSUInteger*)index1 to:(NSUInteger*)index2 result:(CIPPaintLayer**)layer at:(NSUInteger*)indexResult;

- (BOOL) undoCutFrom:(CIPPaintLayer**)layer1 at:(NSUInteger*)index1 to:(NSUInteger*)index2;
- (BOOL) redoCutFrom:(CIPPaintLayer**)layer1 at:(NSUInteger*)index1 to:(CIPPaintLayer**)layer2 at:(NSUInteger*)index2;

@end

@protocol CIPHistoryManagerDelegate <NSObject>

@required
- (void) historyDidChange:(CIPHistoryManager*)historyManager;

@end
