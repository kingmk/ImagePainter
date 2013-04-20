//
//  CIPDrawViewEx.m
//  ImagePainter
//
//  Created by yuxinjin on 12-9-28.
//  Copyright (c) 2012年 yuxinjin. All rights reserved.
//

#import "CIPDrawView.h"

@interface CIPDrawView()
@property (nonatomic) CGPoint point;
@property (nonatomic) const CGPoint *linePoints;
@property (nonatomic) NSInteger lineCount;
@property (nonatomic) CGRect rect;
@property (nonatomic) CGFloat radius;
@property (nonatomic) NSString *text;

@end

@implementation CIPDrawView

- (id) initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    [self initOutlay];
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.palette = [[CIPPalette alloc] init];
    }
    return self;
}

- (void) initOutlay {
    self.layer.backgroundColor = [UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:0.5].CGColor;
    self.layer.cornerRadius = 5;
    self.clicked = NO;
}

- (void) setClicked:(BOOL)clicked {
    _clicked = clicked;
    if (clicked) {
        self.layer.borderWidth = 3;
        self.layer.borderColor = [UIColor orangeColor].CGColor;
    } else {
        self.layer.borderWidth = 1;
        self.layer.borderColor = [UIColor grayColor].CGColor;
    }
}


- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    switch (self.type) {
        case ProcSubPaintPencil:
            [self drawPencilIn:context];
            break;
        case ProcSubPaintBrush:
            [self drawBrushInContext:context];
            break;
        case ProcSubPaintRubber:
            [self drawRubberInContext:context];
            break;
        case ProcSubShapeLine:
            [self drawLineInContext:context];
            break;
        case ProcSubShapeRect:
            [self drawRectInContext:context];
            break;
        case ProcSubShapeCircle:
            [self drawCircleInContext:context];
            break;
        case ProcSubShapeEclipse:
            [self drawEclipseInContext:context];
            break;
        case ProcSubTextTyping:
            [self drawTextInContext:context];
            break;
        default:
            break;
    }
    CGContextRestoreGState(context);
}

#pragma mark -
#pragma mark Core Drawing Functions
- (void) drawPencilIn:(CGContextRef) context {
    CGContextSetFillColorWithColor(context, [CIPPalette replaceColor:self.palette.strokeColor component:3 withValue:1.0].CGColor);
    CGContextAddArc(context, self.point.x, self.point.y, self.palette.strokeWidth/2, 0, M_PI*2, 0);
    CGContextFillPath(context);
}

- (void) drawBrushInContext:(CGContextRef) context {
    NSUInteger brushType = self.palette.brushType;
    NSInteger width = self.palette.strokeWidth;
    const CGFloat *components = CGColorGetComponents(self.palette.strokeColor.CGColor);
    CGFloat colors[4];
    memcpy(colors, components, sizeof(colors));
    CGImageRef brushImg = [CIPBrushUtilities getBrushForType:brushType withColor:colors];
    [CIPBrushUtilities drawBrushImage:brushImg inSize:CGSizeMake(width, width) atPoint:self.point on:context];
    CGImageRelease(brushImg);
}

- (void) drawRubberInContext:(CGContextRef) context{
    CGContextSetFillColorWithColor(context, [UIColor blackColor].CGColor);
    CGContextFillRect(context, self.bounds);
    CGContextSetBlendMode(context, kCGBlendModeClear);
    //CGContextSetFillColorWithColor(context, [UIColor clearColor].CGColor);
    CGContextAddArc(context, self.point.x, self.point.y, self.palette.strokeWidth/2, 0, M_PI*2, 0);
    CGContextFillPath(context);}

- (void) drawLineInContext:(CGContextRef) context {
    [self setLineStyle:context];
    CGContextAddLines(context, self.linePoints, self.lineCount);
    CGContextStrokePath(context);
}

- (void) drawRectInContext:(CGContextRef) context {
    [self setLineStyle:context];
    CGContextAddRect(context, self.rect);
    CGContextStrokePath(context);
    CGContextSetFillColorWithColor(context, self.palette.fillColor.CGColor);
    CGContextFillRect(context, self.rect);
}

- (void) drawCircleInContext:(CGContextRef) context {
    [self setLineStyle:context];
    CGContextAddArc(context, self.point.x, self.point.y, self.radius, 0, M_PI*2, 0);
    CGContextStrokePath(context);
    CGContextAddArc(context, self.point.x, self.point.y, self.radius, 0, M_PI*2, 0);
    CGContextSetFillColorWithColor(context, self.palette.fillColor.CGColor);
    CGContextFillPath(context);
}

- (void) drawEclipseInContext:(CGContextRef) context {
    [self setLineStyle:context];
    CGContextStrokeEllipseInRect(context, self.rect);
    CGContextSetFillColorWithColor(context, self.palette.fillColor.CGColor);
    CGContextFillEllipseInRect(context, self.rect);
}

- (void) drawTextInContext:(CGContextRef) context {
    [self setLineStyle:context];
    CGContextSetTextDrawingMode(context, kCGTextFillStroke);
    CGContextSetStrokeColorWithColor(context, self.palette.fontBorderColor.CGColor);
    CGContextSetLineWidth(context, self.palette.fontBorderWidth);
    CGContextSetTextDrawingMode(context, self.palette.textMode);
    CGContextSetFillColorWithColor(context, self.palette.fontColor.CGColor);
    //CGContextSetCharacterSpacing(context, 30);
    [self.text drawInRect:self.rect withFont:self.palette.font lineBreakMode:NSLineBreakByCharWrapping alignment:self.palette.textAlignment];
}

- (void)setLineStyle:(CGContextRef)context {
    CGContextSetStrokeColorWithColor(context, self.palette.strokeColor.CGColor);
    CGContextSetLineWidth(context, self.palette.strokeWidth);
    CGContextSetLineJoin(context, self.palette.lineJoin);
    CGContextSetLineCap(context, self.palette.lineCap);
}

#pragma mark -
#pragma mark Interface Implementations
- (void) drawPaintAt:(CGPoint)point withPalette:(CIPPalette *)palette subtype:(ProcSubType)subtype {
    if (palette != Nil) {
        self.palette = palette;
    }
    self.point = point;
    self.type = subtype;
    [self setNeedsDisplay];
}

- (void) drawLines:(const CGPoint*) points pointCount:(NSInteger)count withPalette:(CIPPalette*)palette {
    if (palette != Nil) {
        self.palette = palette;
    }
    self.linePoints = points;
    self.lineCount = count;
    self.type = ProcSubShapeLine;
    [self setNeedsDisplay];
}

- (void) drawRectIn:(CGRect)rect withPalette:(CIPPalette *)palette {
    if (palette != Nil) {
        self.palette = palette;
    }
    self.rect = rect;
    self.type = ProcSubShapeRect;
    [self setNeedsDisplay];
}

- (void) drawCircleAt:(CGPoint)point radius:(CGFloat)radius withPalette:(CIPPalette *)palette {
    if (palette != Nil) {
        self.palette = palette;
    }
    self.point = point;
    self.radius = radius;
    self.type= ProcSubShapeCircle;
    [self setNeedsDisplay];
}

- (void) drawEclipseIn:(CGRect) rect withPalette:(CIPPalette*)palette {
    if (palette != Nil) {
        self.palette = palette;
    }
    self.rect = rect;
    self.type = ProcSubShapeEclipse;
    [self setNeedsDisplay];
}

- (void) drawText:(NSString *)text inRect:(CGRect)rect withPalette:(CIPPalette *)palette {
    if (palette != Nil) {
        self.palette = palette;
    }
    self.rect = rect;
    self.text = text;
    self.type = ProcSubTextTyping;
    [self setNeedsDisplay];
}
@end
