//
//  CABackLayer.h
//  ImagePainter
//
//  Created by yuxinjin on 12-9-24.
//  Copyright (c) 2012年 yuxinjin. All rights reserved.
//

#import "CIPPaintLayer.h"

@interface CIPPhotoLayer : CIPPaintLayer


- (void) setBackgroundImage:(UIImage*) backImage within:(CGSize) viewSize;
@end
