//
//  CIPCropView.h
//  ImagePainter
//
//  Created by yuxinjin on 13-2-28.
//  Copyright (c) 2013年 yuxinjin. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol CIPCropControlDelegate;

@interface CIPCropControl : UIView
@property (nonatomic, assign) id<CIPCropControlDelegate> delegate;

- (void) showWithImageRect:(CGRect)rect;

@end



@protocol CIPCropControlDelegate<NSObject>
@optional

- (void) cipCropControlCancel:(CIPCropControl*) cropCtrl;
- (void) cipCropControl:(CIPCropControl*)cropCtrl cropRect:(CGRect)cropRect;
@end