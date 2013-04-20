//
//  CIPHistoryManager.m
//  ImagePainter
//
//  Created by yuxinjin on 12-10-19.
//  Copyright (c) 2012年 yuxinjin. All rights reserved.
//

#import "CIPHistoryManager.h"
NSUInteger const HISTORY_MAX_CAPACITY = 30;

NSString *const HISTORY_KEY_HTYPE = @"historyType";
NSString *const HISTORY_KEY_TYPE = @"layerType";
NSString *const HISTORY_KEY_INDEX = @"layerIndex";
NSString *const HISTORY_KEY_INDEX2 = @"layerIndex2";
NSString *const HISTORY_KEY_CENTER = @"layerCenter";
NSString *const HISTORY_KEY_IMAGE = @"layerImage";
NSString *const HISTORY_KEY_SCALE = @"layerScale";
NSString *const HISTORY_KEY_ANGLE = @"layerAngle";
NSString *const HISTORY_KEY_TEXT = @"layerText";
NSString *const HISTORY_KEY_TEXTRECT = @"layerTextRect";
NSString *const HISTORY_KEY_PALETTE = @"layerPalette";
NSString *const HISTORY_KEY_BEFORE = @"recordBefore";
NSString *const HISTORY_KEY_AFTER = @"recordAfter";
NSString *const HISTORY_KEY_ARRAY = @"layerArray";

@interface CIPHistoryManager()
@property (nonatomic, retain) NSMutableArray *histories;
@property (nonatomic) NSInteger current;

@end

@implementation CIPHistoryManager

- (id) init {
    self = [super init];
    self.histories = [NSMutableArray arrayWithCapacity:HISTORY_MAX_CAPACITY];
    self.current = -1;
    return self;
}

- (void) clearHistories {
    [self.histories removeAllObjects];
    self.current = -1;
}

- (void) removeCurrentHistory {
    if (self.current >= 0) {
        [self.histories removeObjectAtIndex:self.current];
        self.current--;
        [self.delegate historyDidChange:self];
    }
}

- (BOOL) canUndo {
    return self.current>=0;
}

- (BOOL) canRedo {
    return self.current<(NSInteger)self.histories.count-1;
}

- (HistoryType) currentHistoryType {
    if ([self canUndo]) {
        return [(NSNumber*)[self getLastHistoryDataForKey:HISTORY_KEY_HTYPE] integerValue];
    } else {
        return HistoryLayerError;
    }
}

- (HistoryType) nextHistoryType {
    if ([self canRedo]) {
        return [(NSNumber*)[self getNextHistoryDataForKey:HISTORY_KEY_HTYPE] integerValue];
    } else {
        return HistoryLayerError;
    }
}

- (NSUInteger) currentHistoryLayerIndex {
    if ([self canUndo]) {
        return [(NSNumber*)[self getLastHistoryDataForKey:HISTORY_KEY_INDEX] unsignedIntegerValue];
    } else {
        return HistoryLayerError;
    }
}

- (NSUInteger) nextHistoryLayerIndex {
    if ([self canRedo]) {
        return [(NSNumber*)[self getNextHistoryDataForKey:HISTORY_KEY_INDEX] unsignedIntegerValue];
    } else {
        return HistoryLayerError;
    }
}

- (NSDictionary*) nextHistory {
    NSDictionary *history;
    if ([self canRedo]) {
        history = self.histories[++self.current];
//        NSLog(@"========================");
//        NSLog(@"next history:%@", history);
//        NSLog(@"--current:%d--", self.current);
//        NSLog(@"all history after next:%@", [self.histories subarrayWithRange:NSMakeRange(0, self.current+1)]);
//        NSLog(@"========================");
        [self.delegate historyDidChange:self];
    }
    return history;
}

- (NSDictionary*) popHistory {
    NSDictionary *history;
    if ([self canUndo]) {
        history = self.histories[self.current--];
//        NSLog(@"========================");
//        NSLog(@"pop history:%@", history);
//        NSLog(@"--current:%d--", self.current);
//        NSLog(@"all history after pop:%@", [self.histories subarrayWithRange:NSMakeRange(0, self.current+1)]);
//        NSLog(@"========================");
        [self.delegate historyDidChange:self];
    }
    return history;
}

- (void) pushHistory:(NSDictionary*)history {
    int count = self.histories.count-1;
    if (self.current < count) {
        [self.histories removeObjectsInRange:NSMakeRange(self.current+1, self.histories.count-self.current-1)];
    }
    if (self.current == HISTORY_MAX_CAPACITY) {
        [self.histories removeObjectAtIndex:0];
        self.current--;
    }
    [self.histories addObject:history];
    self.current++;
//    NSLog(@"========================");
//    NSLog(@"push history:%@", history);
//    NSLog(@"--current:%d--", self.current);
//    NSLog(@"all history after push:%@", [self.histories subarrayWithRange:NSMakeRange(0, self.current+1)]);
//    NSLog(@"========================");
    [self.delegate historyDidChange:self];
}

- (id) getLastHistoryDataForKey:(NSString*)key {
    NSMutableDictionary *attrs = self.histories[self.current];
    return [attrs valueForKey:key];
}

- (void) setLastHistoryData:(id)data forKey:(NSString*)key {
    NSMutableDictionary *attrs = self.histories[self.current];
    [attrs setValue:data forKey:key];
}

- (id) getNextHistoryDataForKey:(NSString*)key {
    NSMutableDictionary *attrs = self.histories[self.current+1];
    return [attrs valueForKey:key];
}

- (void) recordCreate:(CIPPaintLayer*)layer at:(NSUInteger)index from:(NSUInteger)index2{
    NSDictionary *layerContents = [layer getUpdateHistory];
    NSMutableDictionary *attrs = [NSMutableDictionary dictionaryWithCapacity:4];
    [attrs setValue:[NSNumber numberWithInteger:HistoryLayerCreate] forKey:HISTORY_KEY_HTYPE];
    [attrs setValue:[NSNumber numberWithUnsignedInteger:index] forKey:HISTORY_KEY_INDEX];
    [attrs setValue:[NSNumber numberWithUnsignedInteger:index2] forKey:HISTORY_KEY_INDEX2];
    [attrs setValue:layerContents forKey:HISTORY_KEY_AFTER];
    [self pushHistory:attrs];
}

- (void) recordBeforeUpdate:(CIPPaintLayer*)layer at:(NSUInteger)index {
    NSDictionary *layerContents = [layer getUpdateHistory];
    NSMutableDictionary *attrs = [NSMutableDictionary dictionaryWithCapacity:4];
    [attrs setValue:[NSNumber numberWithInteger:HistoryLayerUpdate] forKey:HISTORY_KEY_HTYPE];
    [attrs setValue:[NSNumber numberWithUnsignedInteger:index] forKey:HISTORY_KEY_INDEX];
    [attrs setValue:layerContents forKey:HISTORY_KEY_BEFORE];
    [self pushHistory:attrs];
}

- (void) recordAfterUpdate:(CIPPaintLayer *)layer {
    NSDictionary *layerContents = [layer getUpdateHistory];
    [self setLastHistoryData:layerContents forKey:HISTORY_KEY_AFTER];
}

- (void) recordBeforeTransform:(CIPPaintLayer*)layer at:(NSUInteger)index {
    NSDictionary *layerTrans = [layer getTransformHistory];
    NSMutableDictionary *attrs = [NSMutableDictionary dictionaryWithCapacity:4];
    [attrs setValue:[NSNumber numberWithInteger:HistoryLayerTransform] forKey:HISTORY_KEY_HTYPE];
    [attrs setValue:[NSNumber numberWithUnsignedInteger:index] forKey:HISTORY_KEY_INDEX];
    [attrs setValue:layerTrans forKey:HISTORY_KEY_BEFORE];
    [self pushHistory:attrs];
}

- (void) recordAfterTransform:(CIPPaintLayer *)layer {
    NSDictionary *layerTrans = [layer getTransformHistory];
    [self setLastHistoryData:layerTrans forKey:HISTORY_KEY_AFTER];
}

- (void) recordDelete:(CIPPaintLayer*)layer at:(NSUInteger) index {
    NSDictionary *layerContents = [layer getUpdateHistory];
    NSMutableDictionary *attrs = [NSMutableDictionary dictionaryWithCapacity:3];
    [attrs setValue:[NSNumber numberWithInteger:HistoryLayerDelete] forKey:HISTORY_KEY_HTYPE];
    [attrs setValue:[NSNumber numberWithUnsignedInteger:index] forKey:HISTORY_KEY_INDEX];
    [attrs setValue:layerContents forKey:HISTORY_KEY_BEFORE];
    [self pushHistory:attrs];
}

- (void) recordMoveFrom:(NSUInteger)index1 to:(NSUInteger)index2 {
    NSMutableDictionary *attrs = [NSMutableDictionary dictionaryWithCapacity:3];
    [attrs setValue:[NSNumber numberWithInteger:HistoryLayerMove] forKey:HISTORY_KEY_HTYPE];
    [attrs setValue:[NSNumber numberWithUnsignedInteger:index1] forKey:HISTORY_KEY_INDEX];
    [attrs setValue:[NSNumber numberWithUnsignedInteger:index2] forKey:HISTORY_KEY_INDEX2];
    [self pushHistory:attrs];
}

- (void) recordBeforeMergeFrom:(CIPPaintLayer*)layer1 at:(NSUInteger)index1 to:(CIPPaintLayer*)layer2 at:(NSUInteger)index2 {
    NSMutableDictionary *attrs = [NSMutableDictionary dictionaryWithCapacity:2];
    [attrs setValue:[NSNumber numberWithInteger:HistoryLayerMerge] forKey:HISTORY_KEY_HTYPE];

    NSMutableArray *array = [NSMutableArray arrayWithObjects:[layer1 getUpdateHistory], [layer2 getUpdateHistory], nil];
    
    
    NSMutableDictionary *beforeAttrs = [NSMutableDictionary dictionaryWithCapacity:3];
    [beforeAttrs setValue:[NSNumber numberWithUnsignedInteger:index1] forKey:HISTORY_KEY_INDEX];
    [beforeAttrs setValue:[NSNumber numberWithUnsignedInteger:index2] forKey:HISTORY_KEY_INDEX2];
    [beforeAttrs setValue:array forKey:HISTORY_KEY_ARRAY];
    
    [attrs setValue:beforeAttrs forKey:HISTORY_KEY_BEFORE];
    [self pushHistory:attrs];
}

- (void) recordAfterMerge:(CIPPaintLayer *)layerResult at:(NSUInteger)index {
    NSDictionary *layerContents = [layerResult getUpdateHistory];
    NSMutableDictionary *afterAttrs = [NSMutableDictionary dictionaryWithDictionary:layerContents];
    [afterAttrs setValue:[NSNumber numberWithUnsignedInteger:index] forKey:HISTORY_KEY_INDEX];
    
    [self setLastHistoryData:afterAttrs forKey:HISTORY_KEY_AFTER];
}

- (void) recordBeforeCutFrom:(CIPPaintLayer *)layer1 at:(NSUInteger)index1 pasteTo:(NSUInteger)index2 {
    NSMutableDictionary *attrs = [NSMutableDictionary dictionaryWithCapacity:4];
    [attrs setValue:[NSNumber numberWithInteger:HistoryLayerCutPaste] forKey:HISTORY_KEY_HTYPE];
    [attrs setValue:[NSNumber numberWithUnsignedInteger:index1] forKey:HISTORY_KEY_INDEX];
    [attrs setValue:[NSNumber numberWithUnsignedInteger:index2] forKey:HISTORY_KEY_INDEX2];
    [attrs setValue:[layer1 getUpdateHistory] forKey:HISTORY_KEY_BEFORE];
    [self pushHistory:attrs];
}

- (void) recordAfterCutFrom:(CIPPaintLayer *)layer1 pasteTo:(CIPPaintLayer *)layer2 {
    NSMutableArray *array = [NSMutableArray arrayWithObjects:[layer1 getUpdateHistory], [layer2 getUpdateHistory], nil];
    NSMutableDictionary *afterAttrs = [NSMutableDictionary dictionaryWithObject:array forKey:HISTORY_KEY_ARRAY];
    [self setLastHistoryData:afterAttrs forKey:HISTORY_KEY_AFTER];
}

- (BOOL) undoCreate:(NSUInteger *)index from:(NSUInteger *)index2{
    if ([self currentHistoryType] == HistoryLayerCreate) {
        NSDictionary *history = [self popHistory];
        *index = [(NSNumber*)[history valueForKey:HISTORY_KEY_INDEX] unsignedIntegerValue];
        *index2 = [(NSNumber*)[history valueForKey:HISTORY_KEY_INDEX2] unsignedIntegerValue];
        return YES;
    } else {
        return NO;
    }
}

- (BOOL) redoCreate:(CIPPaintLayer**)layer at:(NSUInteger*)index {
    if ([self nextHistoryType] == HistoryLayerCreate) {
        NSDictionary *history = [self nextHistory];
        NSDictionary *attrs = [history valueForKey:HISTORY_KEY_AFTER];
        *layer = [CIPPaintLayer createFromUpdateHistory:attrs];
        *index = [(NSNumber*)[history valueForKey:HISTORY_KEY_INDEX] unsignedIntegerValue];
        return YES;
    } else {
        return NO;
    }
}

- (BOOL) undoUpdate:(CIPPaintLayer **)layer at:(NSUInteger *)index {
    if ([self currentHistoryType] == HistoryLayerUpdate) {
        NSDictionary *history = [self popHistory];
        NSDictionary *attrs = [history valueForKey:HISTORY_KEY_BEFORE];
        *layer = [CIPPaintLayer createFromUpdateHistory:attrs];
        *index = [(NSNumber*)[history valueForKey:HISTORY_KEY_INDEX] unsignedIntegerValue];
        return YES;
    } else {
        return NO;
    }
}

- (BOOL) redoUpdate:(CIPPaintLayer **)layer at:(NSUInteger *)index {
    if ([self nextHistoryType] == HistoryLayerUpdate) {
        NSDictionary *history = [self nextHistory];
        NSDictionary *attrs = [history valueForKey:HISTORY_KEY_AFTER];
        *layer = [CIPPaintLayer createFromUpdateHistory:attrs];
        *index = [(NSNumber*)[history valueForKey:HISTORY_KEY_INDEX] unsignedIntegerValue];
        return YES;
    } else {
        return NO;
    }
}

- (BOOL) undoTransform:(CIPPaintLayer *)layer {
    if ([self currentHistoryType] == HistoryLayerTransform) {
        NSDictionary *history = [self popHistory];
        NSDictionary *attrs = [history valueForKey:HISTORY_KEY_BEFORE];
        [layer loadTransformHistory:attrs];
        return YES;
    } else {
        return NO;
    }
}

- (BOOL) redoTransform:(CIPPaintLayer *)layer {
    if ([self nextHistoryType] == HistoryLayerTransform) {
        NSDictionary *history = [self nextHistory];
        NSDictionary *attrs = [history valueForKey:HISTORY_KEY_AFTER];
        [layer loadTransformHistory:attrs];
        return YES;
    } else {
        return NO;
    }
}

- (BOOL) undoDelete:(CIPPaintLayer **)layer at:(NSUInteger *)index {
    if ([self currentHistoryType] == HistoryLayerDelete) {
        NSDictionary *history = [self popHistory];
        NSDictionary *attrs = [history valueForKey:HISTORY_KEY_BEFORE];
        *layer = [CIPPaintLayer createFromUpdateHistory:attrs];
        *index = [(NSNumber*)[history valueForKey:HISTORY_KEY_INDEX] unsignedIntegerValue];
        return YES;
    } else {
        return NO;
    }
}

- (BOOL) redoDelete:(NSUInteger*)index {
    if ([self nextHistoryType] == HistoryLayerDelete) {
        NSDictionary *history = [self nextHistory];
        *index = [(NSNumber*)[history valueForKey:HISTORY_KEY_INDEX] unsignedIntegerValue];
        return YES;
    } else {
        return NO;
    }
}

- (BOOL) undoMoveFrom:(NSUInteger *)index1 to:(NSUInteger *)index2 {
    if ([self currentHistoryType] == HistoryLayerMove) {
        NSDictionary *history = [self popHistory];
        *index1 = [(NSNumber*)[history valueForKey:HISTORY_KEY_INDEX] unsignedIntegerValue];
        *index2 = [(NSNumber*)[history valueForKey:HISTORY_KEY_INDEX2] unsignedIntegerValue];
        return YES;
    } else {
        return NO;
    }
}

- (BOOL) redoMoveFrom:(NSUInteger *)index1 to:(NSUInteger *)index2 {
    if ([self nextHistoryType] == HistoryLayerMove) {
        NSDictionary *history = [self nextHistory];
        *index1 = [(NSNumber*)[history valueForKey:HISTORY_KEY_INDEX] unsignedIntegerValue];
        *index2 = [(NSNumber*)[history valueForKey:HISTORY_KEY_INDEX2] unsignedIntegerValue];
        return YES;
    } else {
        return NO;
    }
}

- (BOOL) undoMergeFrom:(CIPPaintLayer **)layer1 at:(NSUInteger *)index1 to:(CIPPaintLayer **)layer2 at:(NSUInteger *)index2 resultAt:(NSUInteger *)indexResult {
    if ([self currentHistoryType] == HistoryLayerMerge) {
        NSDictionary *history = [self popHistory];
        NSDictionary *beforeAttrs = [history valueForKey:HISTORY_KEY_BEFORE];
        *index1 = [(NSNumber*)[beforeAttrs valueForKey:HISTORY_KEY_INDEX] unsignedIntegerValue];
        *index2 = [(NSNumber*)[beforeAttrs valueForKey:HISTORY_KEY_INDEX2] unsignedIntegerValue];
        
        NSArray *layers = [beforeAttrs valueForKey:HISTORY_KEY_ARRAY];
        *layer1 = [CIPPaintLayer createFromUpdateHistory:layers[0]];
        *layer2 = [CIPPaintLayer createFromUpdateHistory:layers[1]];
        
        NSDictionary *afterAttrs = [history valueForKey:HISTORY_KEY_AFTER];
        *indexResult = [(NSNumber*)[afterAttrs valueForKey:HISTORY_KEY_INDEX] unsignedIntegerValue];
        
        return YES;
    } else {
        return NO;
    }
}

- (BOOL) redoMergeFrom:(NSUInteger *)index1 to:(NSUInteger *)index2 result:(CIPPaintLayer **)layer at:(NSUInteger *)indexResult {
    if ([self nextHistoryType] == HistoryLayerMerge) {
        NSDictionary *history = [self nextHistory];
        NSDictionary *beforeAttrs = [history valueForKey:HISTORY_KEY_BEFORE];
        *index1 = [(NSNumber*)[beforeAttrs valueForKey:HISTORY_KEY_INDEX] unsignedIntegerValue];
        *index2 = [(NSNumber*)[beforeAttrs valueForKey:HISTORY_KEY_INDEX2] unsignedIntegerValue];
        
        NSDictionary *afterAttrs = [history valueForKey:HISTORY_KEY_AFTER];
        *indexResult = [(NSNumber*)[afterAttrs valueForKey:HISTORY_KEY_INDEX] unsignedIntegerValue];
        
        *layer = [CIPPaintLayer createFromUpdateHistory:afterAttrs];
        
        return YES;
    } else {
        return NO;
    }
}

- (BOOL) undoCutFrom:(CIPPaintLayer **)layer1 at:(NSUInteger *)index1 to:(NSUInteger *)index2 {
    if ([self currentHistoryType] == HistoryLayerCutPaste) {
        NSDictionary *history = [self popHistory];
        *index1 = [(NSNumber*)[history valueForKey:HISTORY_KEY_INDEX] unsignedIntegerValue];
        *index2 = [(NSNumber*)[history valueForKey:HISTORY_KEY_INDEX2] unsignedIntegerValue];
        *layer1 = [CIPPaintLayer createFromUpdateHistory:[history valueForKey:HISTORY_KEY_BEFORE]];
        return YES;
    } else {
        return NO;
    }
}

- (BOOL) redoCutFrom:(CIPPaintLayer **)layer1 at:(NSUInteger *)index1 to:(CIPPaintLayer **)layer2 at:(NSUInteger*)index2 {
    if ([self nextHistoryType] == HistoryLayerCutPaste) {
        NSDictionary *history = [self nextHistory];
        *index1 = [(NSNumber*)[history valueForKey:HISTORY_KEY_INDEX] unsignedIntegerValue];
        *index2 = [(NSNumber*)[history valueForKey:HISTORY_KEY_INDEX2] unsignedIntegerValue];
        NSDictionary *afterAttrs = [history valueForKey:HISTORY_KEY_AFTER];
        NSArray *layers = [afterAttrs valueForKey:HISTORY_KEY_ARRAY];
        *layer1 = [CIPPaintLayer createFromUpdateHistory:layers[0]];
        *layer2 = [CIPPaintLayer createFromUpdateHistory:layers[1]];
        return YES;
    } else {
        return NO;
    }
}

@end
