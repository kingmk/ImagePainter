//
//  CIPPalettePanel.h
//  ImagePainter
//
//  Created by yuxinjin on 12-10-25.
//  Copyright (c) 2012年 yuxinjin. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CIPPalettePanel : UIControl

@property (nonatomic) CIPPalette *palette;
@property (nonatomic) ImageProcState procState;

- (void) updateSubviewsLayout:(ImageProcState)procState withPalette:(CIPPalette*)palette;
- (void) fullScreenMode:(BOOL)isFull;
- (void) beforeFullScreenMode:(BOOL)isFull;

@end
