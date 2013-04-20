//
//  CAVirtualLayer.h
//  ImagePainter
//
//  Created by yuxinjin on 12-9-23.
//  Copyright (c) 2012年 yuxinjin. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

@interface CIPVirtualLayer : CAEAGLLayer
@property (nonatomic) ImageProcState procState;
@property(nonatomic) CGRect contentRect;
@property(nonatomic) CGRect selectRect;
@property(nonatomic) CGFloat screenScale;

- (id) initWithFrame:(CGRect) frame;

- (void) setVirtualLayer:(ImageProcState)procState  at:(CGPoint)start;

- (CGPoint) getTranslate;

- (CGRect) calculateContentRect;
- (UIImage*) getFitBackImage;

- (void) drawPaint:(CGPoint) curPoint withPalette:(CIPPalette*) palette;
- (UIImage*) copyImageIn:(CGRect)selRect;
@end
