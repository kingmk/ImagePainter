//
//  CIPLayerOper.m
//  ImagePainter
//
//  Created by yuxinjin on 12-10-4.
//  Copyright (c) 2012年 yuxinjin. All rights reserved.
//

#import "CIPLayerOper.h"

@implementation CIPLayerOper

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.itemHeight = 30;
        //self.backgroundColor = [UIColor grayColor];
        [self.layer setBorderWidth:1];
        [self.layer setBorderColor:[CIPPalette borderColor].CGColor];
        [self.layer setCornerRadius:3];
        [CIPCustomViewUtils makeMainBackgroundForView:self];
    }
    return self;
}

- (BOOL) addOperatorItem:(NSString *)title withTag:(NSUInteger)tag {
    if ([self viewWithTag:tag]) {
        return NO;
    }
    int offy = self.subviews.count*self.itemHeight;
    UIButton *operButton = [[UIButton alloc] initWithFrame:CGRectMake(0, offy, self.frame.size.width, self.itemHeight)];
    operButton.tag = tag;
    [operButton setTitle:title forState:UIControlStateNormal];
    [operButton setTitleColor:[CIPPalette fontDarkColor] forState:UIControlStateNormal];
    [operButton.titleLabel setFont:[CIPPalette appFontWithSize:12]];
    [operButton addTarget:self action:@selector(pressOper:) forControlEvents:UIControlEventTouchDown];
    
    if (offy+self.itemHeight>self.frame.size.height) {
        self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, offy+self.itemHeight);
    }
    [self addSubview:operButton];
    return YES;
}

- (IBAction)pressOper:(UIButton*)sender {
    self.operTag = sender.tag;
    [self sendActionsForControlEvents:UIControlEventTouchDown];
}

@end
