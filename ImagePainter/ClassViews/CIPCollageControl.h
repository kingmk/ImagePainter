//
//  CIPCollageScroll.h
//  ImagePainter
//
//  Created by yuxinjin on 12-11-6.
//  Copyright (c) 2012年 yuxinjin. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CIPCollageControl : UIControl

@property (nonatomic) UIImage *selectedImage;

- (void) updateColor:(UIColor*)color;

@end
