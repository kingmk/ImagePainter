//
//  CIPCropView.m
//  ImagePainter
//
//  Created by yuxinjin on 13-2-28.
//  Copyright (c) 2013年 yuxinjin. All rights reserved.
//

#import "CIPCropControl.h"
@interface CIPCropControl()
@property (nonatomic, retain) UIView *cropView;
@property (nonatomic, retain) UIView *panelView;
@property (nonatomic, retain) UIImage *maskImage;
@property (nonatomic) CGRect imageRect;
@property (nonatomic) CGRect cropRect;
@property (nonatomic) CropMoveType moveType;
@property (nonatomic) CGPoint movePoint;

@end

@implementation CIPCropControl

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.moveType = CropNA;
        [self initSubViews];
    }
    return self;
}

- (void) initSubViews {
    CGRect viewRect = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
    self.cropView = [[UIView alloc] initWithFrame:viewRect];
    [self addSubview:self.cropView];
    self.panelView = [[UIView alloc] initWithFrame:CGRectMake(self.frame.size.width, self.frame.size.height-46, 100, 46)];
    self.panelView.layer.contents = (id)[UIImage imageNamed:@"bar_crop.png"].CGImage;
    
    
    UIButton *cancelBtn = [[UIButton alloc] initWithFrame:CGRectMake(15, 7, 30, 30)];
    [cancelBtn setImage:[UIImage imageNamed:@"icon_delete.png"] forState:UIControlStateNormal];
    [cancelBtn addTarget:self action:@selector(cancel:) forControlEvents:UIControlEventTouchDown];
    
    UIButton *confirmBtn = [[UIButton alloc] initWithFrame:CGRectMake(58, 7, 30, 30)];
    [confirmBtn setImage:[UIImage imageNamed:@"icon_confirm.png"] forState:UIControlStateNormal];
    [confirmBtn addTarget:self action:@selector(confirm:) forControlEvents:UIControlEventTouchDown];
    
    [self.panelView addSubview:cancelBtn];
    [self.panelView addSubview:confirmBtn];
    [self addSubview:self.panelView];
}

- (void) showWithImageRect:(CGRect)rect {
    CGRect viewRect = self.cropView.frame;
    self.imageRect = CGRectIntersection(viewRect, rect);
    
    UIGraphicsBeginImageContextWithOptions(viewRect.size, 0.0, [[UIScreen mainScreen] scale]);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:0.75].CGColor);
    CGContextFillRect(context, viewRect);
    
    CGContextSetFillColorWithColor(context, [UIColor colorWithRed:0.0 green:1.0 blue:1.0 alpha:0.3].CGColor);
    CGContextFillRect(context, self.imageRect);
    
    self.maskImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    [self showCropRect:self.imageRect];
    
    [UIView animateWithDuration:0.4 animations:^{
        self.panelView.frame = CGRectMake(self.frame.size.width-100, self.frame.size.height-46, 100, 46);
    }];
}

- (void) showCropRect:(CGRect)rect {
    UIGraphicsBeginImageContextWithOptions(self.cropView.frame.size, 0.0, [[UIScreen mainScreen] scale]);
    CGContextRef context = UIGraphicsGetCurrentContext();
    [self.maskImage drawInRect:self.cropView.frame];
    
    rect =CGRectIntersection(rect, self.imageRect);
    self.cropRect = rect;
    CGContextClearRect(context, rect);
    
    CGContextSetStrokeColorWithColor(context, [UIColor orangeColor].CGColor);
    CGContextSetLineWidth(context, 2);
    CGContextStrokeRect(context, rect);
    
    CGFloat v;
    CGFloat stepx = rect.size.width/3.0f;
    CGFloat stepy = rect.size.height/3.0f;
    
    CGContextSetStrokeColorWithColor(context, [UIColor colorWithRed:1.0 green:0.5 blue:0.0 alpha:0.8].CGColor);
    CGContextSetLineWidth(context, 1);
    for (int i=1; i<=2; i++) {
        v = stepx*i;
        CGContextMoveToPoint(context, rect.origin.x+v, rect.origin.y);
        CGContextAddLineToPoint(context, rect.origin.x+v, rect.origin.y+rect.size.height);
        CGContextStrokePath(context);
    }
    for (int i=1; i<=2; i++) {
        v = stepy*i;
        CGContextMoveToPoint(context, rect.origin.x, rect.origin.y+v);
        CGContextAddLineToPoint(context, rect.origin.x+rect.size.width, rect.origin.y+v);
        CGContextStrokePath(context);
    }
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    self.cropView.layer.contents = (id)image.CGImage;
}


- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [[touches allObjects] objectAtIndex:0];
    CGPoint point = [touch locationInView:self.cropView];
    if (!CGRectContainsPoint(self.cropView.frame, point)) {
        return;
    }
    CGFloat l = self.cropRect.origin.x;
    CGFloat r = self.cropRect.origin.x + self.cropRect.size.width;
    CGFloat t = self.cropRect.origin.y;
    CGFloat b = self.cropRect.origin.y + self.cropRect.size.height;
    CGFloat xmargin = MIN((self.cropRect.size.width/4.0f), 30);
    CGFloat ymargin = MIN((self.cropRect.size.height/4.0f), 30);
    CGFloat xlimit[4] = {l-30, l+xmargin, r-xmargin, r+30};
    CGFloat ylimit[4] = {t-30, t+ymargin, b-ymargin, b+30};
    int xfield = -1, yfield = -1;
    for (int i=0; i<3; i++) {
        if (point.x >= xlimit[i] && point.x<=xlimit[i+1]) {
            xfield = i;
            break;
        }
    }
    for (int i=0; i<3; i++) {
        if (point.y >= ylimit[i] && point.y<=ylimit[i+1]) {
            yfield = i;
            break;
        }
    }
    
    if (xfield == -1 || yfield == -1) {
        return;
    }
    self.moveType = yfield*3+xfield;
    self.movePoint = point;
}

#pragma mark -
#pragma mark Button Action

- (IBAction)cancel:(UIButton*)sender {
    [UIView animateWithDuration:0.4 animations:^{
        self.panelView.frame = CGRectMake(self.frame.size.width, self.frame.size.height-46, 100, 46);
        self.opaque = 0.0;
        [self.delegate cipCropControlCancel:self];
    }];
}

- (IBAction)confirm:(UIButton*)sender {
    [UIView animateWithDuration:0.4 animations:^{
        self.panelView.frame = CGRectMake(self.frame.size.width, self.frame.size.height-46, 100, 46);
        self.opaque = 0.0;
        [self.delegate cipCropControl:self cropRect:self.cropRect];
    }];
    
}

#pragma mark -
#pragma mark Touch Event Function
- (void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    if (self.moveType == CropNA) {
        return;
    }
    UITouch *touch = [[touches allObjects] objectAtIndex:0];
    CGPoint point = [touch locationInView:self.cropView];
    
    CGFloat imgl = self.imageRect.origin.x;
    CGFloat imgr = self.imageRect.origin.x + self.imageRect.size.width;
    CGFloat imgt = self.imageRect.origin.y;
    CGFloat imgb = self.imageRect.origin.y + self.imageRect.size.height;
    CGFloat cropl = self.cropRect.origin.x;
    CGFloat cropr = self.cropRect.origin.x + self.cropRect.size.width;
    CGFloat cropt = self.cropRect.origin.y;
    CGFloat cropb = self.cropRect.origin.y + self.cropRect.size.height;
    switch (self.moveType) {
        case CropLT: {
            CGFloat orgx = MAX(MIN(point.x, cropr-20), imgl);
            CGFloat orgy = MAX(MIN(point.y, cropb-20), imgt);
            self.cropRect = CGRectMake(orgx, orgy, cropr-orgx, cropb-orgy);
            break;
        }
        case CropCT: {
            CGFloat orgy = MAX(MIN(point.y, cropb-20), imgt);
            self.cropRect = CGRectMake(cropl, orgy, cropr-cropl, cropb-orgy);
            break;
        }
        case CropRT: {
            CGFloat dstx = MIN(MAX(point.x, cropl+20), imgr);
            CGFloat orgy = MAX(MIN(point.y, cropb-20), imgt);
            self.cropRect = CGRectMake(cropl, orgy, dstx-cropl, cropb-orgy);
            break;
        }
        case CropLC: {
            CGFloat orgx = MAX(MIN(point.x, cropr-20), imgl);
            self.cropRect = CGRectMake(orgx, cropt, cropr-orgx, cropb-cropt);
            break;
        }
        case CropCC: {
            CGFloat orgx = cropl+point.x-self.movePoint.x;
            CGFloat orgy = cropt+point.y-self.movePoint.y;
            orgx = MAX(MIN(orgx, imgr-(cropr-cropl)), imgl);
            orgy = MAX(MIN(orgy, imgb-(cropb-cropt)), imgt);
            self.cropRect = CGRectMake(orgx, orgy, cropr-cropl, cropb-cropt);
            break;
        }
        case CropRC: {
            CGFloat dstx = MIN(MAX(point.x, cropl+20), imgr);
            self.cropRect = CGRectMake(cropl, cropt, dstx-cropl, cropb-cropt);
            break;
        }
        case CropLB: {
            CGFloat orgx = MAX(MIN(point.x, cropr-20), imgl);
            CGFloat dsty = MIN(MAX(point.y, cropt+20), imgb);
            self.cropRect = CGRectMake(orgx, cropt, cropr-orgx, dsty-cropt);
            break;
        }
        case CropCB: {
            CGFloat dsty = MIN(MAX(point.y, cropt+20), imgb);
            self.cropRect = CGRectMake(cropl, cropt, cropr-cropl, dsty-cropt);
            break;
        }
        case CropRB: {
            CGFloat dstx = MIN(MAX(point.x, cropl+20), imgr);
            CGFloat dsty = MIN(MAX(point.y, cropt+20), imgb);
            self.cropRect = CGRectMake(cropl, cropt, dstx-cropl, dsty-cropt);
            break;
        }
        default:
            break;
    }
    self.movePoint = point;
    [self showCropRect:self.cropRect];
}

- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    if (self.moveType == CropNA) {
        return;
    }
    
    self.moveType = CropNA;
}

- (void) touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    self.moveType = CropNA;
}

@end
