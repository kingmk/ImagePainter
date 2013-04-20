//
//  CIPLayerBar.m
//  ImagePainter
//
//  Created by yuxinjin on 12-10-27.
//  Copyright (c) 2012年 yuxinjin. All rights reserved.
//

#import "CIPLayerBar.h"
@interface CIPLayerBar()
@property (nonatomic, retain) UIScrollView *scroll;

@property (nonatomic) CGFloat opersW;
@property (nonatomic) CGFloat opersH;
@property (nonatomic) CGFloat scrollW;
@property (nonatomic) CGFloat scrollH;

@property (nonatomic) CGFloat vspace;
@property (nonatomic) CGFloat hspace;
@property (nonatomic) CGSize thumbSize;
@property (nonatomic) CGFloat offsetx;

@property (nonatomic) NSInteger thumbCount;
//@property (nonatomic) NSInteger pressThumbIdx;

@property (nonatomic) BOOL pressMove;
@property (nonatomic, retain) UIView *movePosView;
@property (nonatomic, retain) UIView *moveView;

@end

@implementation CIPLayerBar

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initParams];
    }
    return self;
}

- (void) initParams {
    CGSize frameSize = self.frame.size;
    self.opersH = 34;
    self.opersW = 70;
    self.scrollW = frameSize.width - self.opersW - 14 - frameSize.height;
    self.scrollH = frameSize.height;
    
    self.layer.contents = (id)[UIImage imageNamed:@"bar_layer.png"].CGImage;
    //[self initBackground];
    
    self.curThumbIdx = -1;
    self.thumbCount = 0;
    CGFloat thumbH = self.frame.size.height*10/12;
    self.thumbSize = CGSizeMake(thumbH, thumbH);
    self.vspace = (self.frame.size.height-thumbH)/2;
    self.hspace = self.vspace;
    self.offsetx = 0;
    
    [self initOperSegment];
    [self initLayerScroll];
}

// initialize the add and delete button
- (void) initOperSegment {
    UIControl *control = [[UIControl alloc] initWithFrame:CGRectMake(self.bounds.size.width-self.opersW-7-self.bounds.size.height, 7, self.opersW, self.opersH)];
    control.layer.contents = (id) [UIImage imageNamed:@"back_adddelete.png"].CGImage;
    
    UIButton *addBtn = [[UIButton alloc] initWithFrame:CGRectMake(4, 0, 30, 30)];
    [addBtn setImage:[UIImage imageNamed:@"icon_add.png"] forState:UIControlStateNormal];
    [addBtn addTarget:self action:@selector(operateLayer:) forControlEvents:UIControlEventTouchDown];
    addBtn.tag = TagThumbAdd;
    
    UIButton *delBtn = [[UIButton alloc] initWithFrame:CGRectMake(self.opersW/2+1, 0, 30, 30)];
    [delBtn setImage:[UIImage imageNamed:@"icon_delete.png"] forState:UIControlStateNormal];
    [delBtn addTarget:self action:@selector(operateLayer:) forControlEvents:UIControlEventTouchDown];
    delBtn.tag = TagThumbDel;
    
    [control addSubview:addBtn];
    [control addSubview:delBtn];
    [self addSubview:control];
}

- (void) initLayerScroll {
    self.scroll = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, self.scrollW, self.scrollH)];
    
    UILongPressGestureRecognizer *pressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPressFrom:)];
    [pressRecognizer setMinimumPressDuration:0.3];
    [self.scroll addGestureRecognizer:pressRecognizer];
    
    [self addSubview:self.scroll];
    [self addThumbAt:-1 withImage:nil type:PaintLayer];
}

- (CGSize) getRealThumbSize {
    return CGSizeMake(self.thumbSize.width-2, self.thumbSize.height-2);
}

- (void) clearThumbs {
    self.curThumbIdx = -1;
    self.thumbCount = 0;
    NSArray *thumbs = self.scroll.subviews;
    for (int i=thumbs.count-1; i>=0; i--) {
        [(UIView*)thumbs[i] removeFromSuperview];
    }
    self.offsetx = 0;
}

#pragma mark-
#pragma mark Move on Long Press Functions

- (void) showMovePosViewForIndex:(CGFloat)indexf {
    NSInteger index = (int) indexf;
    CGFloat relativeIndex = indexf-index;
    CGRect frame;
    if (relativeIndex < 0) {
        frame = CGRectMake(-10, 0, 20+self.hspace, self.frame.size.height);
    } else if (relativeIndex < 0.6 && relativeIndex > 0.4) {
        frame = CGRectMake(self.hspace+self.thumbSize.width-10, 0, 20+self.hspace, self.frame.size.height);
    } else {
        frame = CGRectMake(self.vspace, 0, self.thumbSize.width, self.frame.size.height);
    }
    frame = CGRectMake(index*(self.hspace+self.thumbSize.width)+frame.origin.x, frame.origin.y, frame.size.width, frame.size.height);
    self.movePosView.frame = frame;
}

- (CGFloat) getMoveIndexFor:(CGFloat) posx {
    CGFloat posIdx = posx/(self.hspace+self.thumbSize.width);
    NSInteger index = MAX(0, MIN((int)posIdx, self.thumbCount-1));
    CGFloat relativePos = posx - index*(self.hspace+self.thumbSize.width);
    if (relativePos < self.hspace+10) {
        posIdx = index - 0.5;
    } else if (relativePos > self.hspace+self.thumbSize.width-10) {
        posIdx = index + 0.5;
    } else {
        posIdx = index;
    }
    return posIdx;
}

- (UIView*) createMoveViewFrom:(NSInteger)thumbIndex {
    CIPThumbView *thumbView = (CIPThumbView*)[self.scroll.subviews objectAtIndex:thumbIndex];
    CGRect scrollFrame = self.scroll.frame;
    UIView *moveView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, scrollFrame.size.height, scrollFrame.size.height)];
    CALayer *layer = [[CALayer alloc] init];
    layer.frame = CGRectMake((scrollFrame.size.height-30)/2, (scrollFrame.size.height-30)/2, 30, 30);
    layer.borderColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.5].CGColor;
    layer.borderWidth = 1;
    layer.contents = [(CALayer*)[thumbView.layer.sublayers objectAtIndex:0] contents];
    [moveView.layer addSublayer:layer];
    return moveView;
}

#pragma mark-
#pragma mark Control Action Function
- (IBAction)operateLayer:(UIButton*)sender {
    switch (sender.tag) {
        case TagThumbAdd:
            if ([self curThumb].layerType == TextLayer ) {
                [self.delegate cipLayerCallTextControl];
            } else if ([self addThumbAt:-1 withImage:Nil type:-1]) {
                [self.delegate cipLayerAddedAt:self.curThumbIdx-1 layerType:[[self curThumb] layerType]];
            }
            break;
        case TagThumbDel: {
            NSInteger delIdx = self.curThumbIdx;
            if (self.thumbCount == 1) {
                [self clearLastThumb];
                [self.delegate cipLayerClearLast];
            } else if ([self deleteThumbAt:self.curThumbIdx]) {
                [self.delegate cipLayerDeletedAt:delIdx toSelect:self.curThumbIdx];
            }
            break;
        }
        default:
            break;
    }
}

- (IBAction)clickThumb:(CIPThumbView*)thumb {
    NSArray *thumbs = self.scroll.subviews;
    NSInteger selectIdx = [thumbs indexOfObject:thumb];
    if (self.curThumbIdx >= 0) {
        CIPThumbView *curThumbView = self.scroll.subviews[self.curThumbIdx];
        [curThumbView setFocusOfView:NO];
    }
    [thumb setFocusOfView:YES];
    self.curThumbIdx = selectIdx;
    [self scrollToCurrentThumb];
    [self.delegate cipLayerSelectedAt:self.curThumbIdx];
}

- (IBAction)handleLongPressFrom:(UILongPressGestureRecognizer*)recognizer {
    CGPoint curpoint = [recognizer locationInView:self.scroll];
    
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        NSInteger pressThumbIdx = [self getThumbIndexContain:curpoint];
        if (pressThumbIdx>=0) {
            self.pressMove = YES;
            [[self curThumb] setMoveStatus:YES];
            self.movePosView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
            self.movePosView.layer.backgroundColor = [UIColor colorWithRed:1.0 green:0.5 blue:0.0 alpha:0.6].CGColor;
            [self.scroll addSubview:self.movePosView];
        }
    }
    
    if (!self.pressMove) {
        return;
    }
    
    if (recognizer.state == UIGestureRecognizerStateChanged) {
        [self.moveView removeFromSuperview];
        self.moveView = [self createMoveViewFrom:self.curThumbIdx];
        [self.scroll addSubview:self.moveView];
        self.moveView.center = CGPointMake(curpoint.x, self.vspace+self.thumbSize.height/2);
        CGFloat indexf = [self getMoveIndexFor:curpoint.x];
        [self showMovePosViewForIndex:indexf];
    } else if(recognizer.state == UIGestureRecognizerStateEnded) {
        [[self curThumb] setMoveStatus:NO];
        [self.moveView removeFromSuperview];
        [self.movePosView removeFromSuperview];
        [self actionOnMoveThumbIndex:self.curThumbIdx withPosition:curpoint.x];
    } else if(recognizer.state == UIGestureRecognizerStateCancelled) {
        [[self curThumb] setMoveStatus:NO];
        [self.moveView removeFromSuperview];
        [self.movePosView removeFromSuperview];
    }
}

- (void) actionOnMoveThumbIndex:(NSInteger)moveIndex withPosition:(CGFloat)posx {
    CGFloat indexf = [self getMoveIndexFor:posx];
    NSInteger index = (int)indexf;
    CGFloat mod = indexf-index;
    if (mod<0) {
        index = -1;
    }
    if (mod<0.1 && mod>-0.1) {
        CIPThumbView *thumbFore = self.scroll.subviews[moveIndex];
        CIPThumbView *thumbBack = self.scroll.subviews[index];
        if (thumbFore.layerType == PhotoLayer || thumbBack.layerType == PhotoLayer) {
            UIAlertView *alert =[[UIAlertView alloc] initWithTitle:@"Merge Fail" message:@"The background image layer cannot be merged onto another layer. You can merge other kinds of layers." delegate:Nil cancelButtonTitle:@"OK, I know" otherButtonTitles:nil];
            [alert show];
            return;
        } else {
            NSLog(@"to Merge from:%d to %d", moveIndex, index);
            if ([self mergeThumbFrom:moveIndex onto:index]) {
                [self.delegate cipLayerMergedFrom:moveIndex to:index];
            }
            return;
        }
    } else {
        if ([self moveThumbFrom:moveIndex to:(int)(indexf+0.6)]) {
            [self.delegate cipLayerMovedFrom:moveIndex to:self.curThumbIdx];
        }
    }
}

#pragma mark-
#pragma mark Thumb Operation Function

- (CIPThumbView*) curThumb {
    if (self.curThumbIdx < 0) {
        return nil;
    }
    return self.scroll.subviews[self.curThumbIdx];
}

- (CGFloat) getThumbIndexContain:(CGPoint) point{
    NSArray *thumbViews = self.scroll.subviews;
    CGFloat idx=0;
    for (UIView* thumbView in thumbViews) {
        if (CGRectContainsPoint(thumbView.frame, point)) {
            return idx;
        }
        idx++;
    }
    return -1;
}

- (void) changeThumbsPositionsFrom:(NSInteger)start to:(NSInteger)end withDeltaX:(CGFloat) deltaX {
    NSArray *thumbs = [self.scroll.subviews subarrayWithRange:NSMakeRange(start, end-start+1)];
    [UIView animateWithDuration:0.5
                          delay:0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         for (UIView *thumb in thumbs) {
                             CGPoint center = thumb.center;
                             thumb.center = CGPointMake(center.x+deltaX, center.y);
                         }
                     } completion:Nil
     ];
}

- (void) scrollToCurrentThumb {
    CIPThumbView *curThumbView = [self curThumb];
    if (!curThumbView) {
        return;
    }
    CGFloat curThumbOffx = curThumbView.frame.origin.x-self.scroll.contentOffset.x;

    CGFloat offset = self.scroll.contentOffset.x;
    if (curThumbOffx<self.hspace) {
        offset = curThumbView.frame.origin.x-self.hspace;
    } else if (curThumbOffx>self.scrollW-self.thumbSize.width-self.hspace) {
        offset = curThumbView.frame.origin.x+self.thumbSize.width+self.hspace-self.scrollW;
    } else {
        return;
    }
    offset = MIN(self.offsetx-self.scrollW, MAX(0, offset));
    [self.scroll setContentOffset:CGPointMake(offset, 0) animated:YES];
}

- (BOOL) selectThumbAt:(NSInteger)selThumbIdx {
    if (selThumbIdx<0 || selThumbIdx>=self.thumbCount || self.thumbCount<=0) {
        return NO;
    }
    if (selThumbIdx != self.curThumbIdx) {
        [[self curThumb] setFocusOfView:NO];
        [(CIPThumbView*)self.scroll.subviews[selThumbIdx] setFocusOfView:YES];
        self.curThumbIdx = selThumbIdx;
    }
    return YES;
}

- (BOOL) addThumbAt:(NSInteger)addThumbIdx withImage:(UIImage*)image type:(LayerType) layerType {
    // add a thumb in the view, if addIdx = -1, means add thumb at the position next to the current thumb
    if (addThumbIdx == -1) {
        addThumbIdx = self.curThumbIdx+1;
    }
    CIPThumbView *curThumbView = [self curThumb];
    if (curThumbView) {
        [curThumbView setFocusOfView:NO];
        if (layerType == -1) {
            layerType = curThumbView.layerType;
        }
    }
    if (layerType == -1) {
        layerType = PaintLayer;
    }
    
    CIPThumbView *thumbView = [[CIPThumbView alloc] initWithFrame:CGRectMake((self.hspace+self.thumbSize.width)*addThumbIdx+self.hspace, self.vspace, self.thumbSize.width, self.thumbSize.height)];
    [thumbView setThumbLayerWith:image];
    [thumbView setFocusOfView:YES];
    thumbView.layerType = layerType;
    [thumbView addTarget:self action:@selector(clickThumb:) forControlEvents:UIControlEventTouchDown];
    
    CGFloat movestep = self.hspace+self.thumbSize.width;
    [self changeThumbsPositionsFrom:addThumbIdx to:self.thumbCount-1 withDeltaX:movestep];
    [self.scroll insertSubview:thumbView atIndex:addThumbIdx];
    self.thumbCount++;
    self.curThumbIdx = addThumbIdx;
    self.offsetx += movestep;
    
    self.scroll.contentSize = CGSizeMake(MAX(self.offsetx, self.scrollW), self.scrollH);
    [self scrollToCurrentThumb];
    return YES;
}

- (void) updateThumbAt:(NSInteger)upThumbIdx withImage:(UIImage*)image {
    if (upThumbIdx < 0) {
        return;
    }
    [[self curThumb] setFocusOfView:NO];

    CIPThumbView *thumbView = self.scroll.subviews[upThumbIdx];
    [thumbView setThumbLayerWith:[CIPImageProcess fitImage:image into:[self getRealThumbSize]]];
    [thumbView setFocusOfView:YES];
    
    self.curThumbIdx = upThumbIdx;
}

- (BOOL) deleteThumbAt:(NSInteger)delThumbIdx {
    if (delThumbIdx<0 || delThumbIdx>=self.thumbCount) {
        return NO;
    } else if (self.thumbCount == 1) {
        return NO;
    }
    
    if (self.curThumbIdx >=0 && self.curThumbIdx<self.thumbCount) {
        [[self curThumb] setFocusOfView:NO];
    }
    CIPThumbView *delThumb = (CIPThumbView*)[self.scroll.subviews objectAtIndex:delThumbIdx];
    CGFloat moveStep = self.hspace+self.thumbSize.width;
    
    [self changeThumbsPositionsFrom:delThumbIdx+1 to:self.thumbCount-1 withDeltaX:-moveStep];
    [delThumb removeFromSuperview];
    
    self.offsetx -= moveStep;
    self.thumbCount--;
    
    if (self.thumbCount>0) {
        NSInteger newThumbIdx = MIN(delThumbIdx, self.thumbCount-1);
        CIPThumbView *newThumb = (CIPThumbView*)[self.scroll.subviews objectAtIndex:newThumbIdx];
        self.curThumbIdx = newThumbIdx;
        [newThumb setFocusOfView:YES];
    } else {
        self.curThumbIdx = -1;
    }
    
    self.scroll.contentSize = CGSizeMake(MAX(self.offsetx, self.scrollW), self.scrollH);
    if (self.scroll.contentOffset.x+self.scrollW>self.offsetx) {
        [self.scroll setContentOffset:CGPointMake(self.scroll.contentOffset.x+self.scrollW-MAX(self.offsetx,self.scrollW), 0) animated:YES];
    }
    return  YES;
}

- (BOOL) moveThumbFrom:(NSInteger)moveThumbIdx to:(NSInteger)toThumbIdx {
    if (moveThumbIdx == toThumbIdx || moveThumbIdx+1 == toThumbIdx) {
        return NO;
    }
    BOOL moveRight = moveThumbIdx<toThumbIdx;
    if (moveRight) {
        toThumbIdx--;
    }
    toThumbIdx = MAX(0, MIN(self.thumbCount-1, toThumbIdx));
    
    CGFloat moveStep = self.vspace+self.thumbSize.height;
    
    CIPThumbView *toThumb = (CIPThumbView*)[self.scroll.subviews objectAtIndex:toThumbIdx];
    CIPThumbView *moveThumb = (CIPThumbView*)[self.scroll.subviews objectAtIndex:moveThumbIdx];
    CGRect moveFrame = toThumb.frame;
    
    [self changeThumbsPositionsFrom:MIN(moveThumbIdx, toThumbIdx) to:MAX(moveThumbIdx, toThumbIdx) withDeltaX:moveRight?-moveStep:moveStep];
    moveThumb.frame = moveFrame;
    [moveThumb removeFromSuperview];
    [self.scroll insertSubview:moveThumb atIndex:toThumbIdx];
    self.curThumbIdx = toThumbIdx;
    
    return YES;
}

- (BOOL) mergeThumbFrom:(NSInteger)foreThumbIdx onto:(NSInteger)backThumbIdx {
    if (foreThumbIdx == backThumbIdx) {
        return NO;
    }
    CIPThumbView *thumbFore = self.scroll.subviews[foreThumbIdx];
    CIPThumbView *thumbBack = self.scroll.subviews[backThumbIdx];
    if (thumbFore.layerType == PhotoLayer || thumbBack.layerType == PhotoLayer) {
        return NO;
    }
    BOOL mergeRight = (foreThumbIdx<backThumbIdx);
    int startIdx = 0;
    if (mergeRight) {
        startIdx = foreThumbIdx;
        self.curThumbIdx = backThumbIdx-1;
    } else {
        startIdx = foreThumbIdx+1;
        self.curThumbIdx = backThumbIdx;
    }
    [self changeThumbsPositionsFrom:startIdx to:self.thumbCount withDeltaX:-(self.hspace+self.thumbSize.width)];
    [thumbFore removeFromSuperview];
    self.offsetx -= self.hspace+self.thumbSize.width;
    self.thumbCount--;
    
    [[self curThumb] setFocusOfView:YES];
    
    self.scroll.contentSize = CGSizeMake(MAX(self.offsetx, self.scrollW), self.scrollH);
    if (self.scroll.contentOffset.x+self.scrollW>self.offsetx) {
        [self.scroll setContentOffset:CGPointMake(self.scroll.contentOffset.x+self.scrollW-MAX(self.offsetx,self.scrollW), 0) animated:YES];
    }
    return YES;
}

- (BOOL) clearLastThumb {
    if (self.thumbCount>1) {
        return NO;
    } 
    
    CIPThumbView *lastThumb = [self curThumb];
    [lastThumb setThumbLayerWith:nil];
    self.curThumbIdx = 0;
    return  YES;
}

@end
