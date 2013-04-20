//
//  UILayerThumb.h
//  ImagePainter
//
//  Created by yuxinjin on 12-9-24.
//  Copyright (c) 2012年 yuxinjin. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CIPThumbView : UIControl

@property (nonatomic) BOOL root;
@property (nonatomic) LayerType layerType;

- (void) setThumbLayerWith:(UIImage*) thumbImage;
- (void) setFocusOfView:(BOOL)focus;
- (void) setMoveStatus:(BOOL)move;

@end
