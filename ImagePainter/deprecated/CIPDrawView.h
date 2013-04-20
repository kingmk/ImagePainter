//
//  CIPDrawViewEx.h
//  ImagePainter
//
//  Created by yuxinjin on 12-9-28.
//  Copyright (c) 2012年 yuxinjin. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CIPDrawView : UIControl<UIGestureRecognizerDelegate>
@property (nonatomic) ProcSubType type;
@property (nonatomic) CIPPalette *palette;
@property (nonatomic) BOOL clicked;

- (void) drawPaintAt:(CGPoint) point withPalette:(CIPPalette*) palette subtype:(ProcSubType) subtype;
- (void) drawLines:(const CGPoint*) points pointCount:(NSInteger)count withPalette:(CIPPalette*)palette;
- (void) drawRectIn:(CGRect) rect withPalette:(CIPPalette*)palette;
- (void) drawCircleAt:(CGPoint) point radius:(CGFloat) radius withPalette:(CIPPalette*)palette;
- (void) drawEclipseIn:(CGRect) rect withPalette:(CIPPalette*)palette;
- (void) drawText:(NSString*)text inRect:(CGRect)rect withPalette:(CIPPalette*)palette;
@end
