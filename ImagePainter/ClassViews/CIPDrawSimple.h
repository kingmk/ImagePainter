//
//  CIPDrawSimple.h
//  ImagePainter
//
//  Created by yuxinjin on 12-11-2.
//  Copyright (c) 2012年 yuxinjin. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CIPDrawSimpleDelegate <NSObject>

@optional
- (void) cipDrawSimpleCallFullScreen:(BOOL)needFull;

@end

@interface CIPDrawSimple : CIPDrawMenu<CIPDrawSimpleDelegate>
@property (nonatomic) ImageProcState selectedState;
@property (nonatomic, assign) id<CIPDrawSimpleDelegate> delegate;

- (void) selectState:(ImageProcState)state;
@end