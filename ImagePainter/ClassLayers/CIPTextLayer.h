//
//  CIPTextLayer.h
//  ImagePainter
//
//  Created by yuxinjin on 12-10-2.
//  Copyright (c) 2012年 yuxinjin. All rights reserved.
//

#import "CIPPaintLayer.h"

@interface CIPTextLayer : CIPPaintLayer
@property (nonatomic) CIPPalette *palette;
@property (nonatomic) NSString *text;
@property (nonatomic) CGRect textRect;

- (void) setupTextRect:(CGRect)rect withBackColor:(UIColor*)backColor withPalette:(CIPPalette*)palette;
- (void) paintText:(NSString*) text withPalette:(CIPPalette*) palette showBorder:(BOOL) showBorder;
- (void) paintTextWithBorder:(BOOL) showBorder;

- (void) enlarge:(CGFloat)scale component:(NSUInteger)xy delta:(CGFloat)dx;
@end
