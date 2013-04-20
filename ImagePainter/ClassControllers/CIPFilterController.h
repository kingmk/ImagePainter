//
//  CIPFilterController.h
//  ImagePainter
//
//  Created by yuxinjin on 12-9-30.
//  Copyright (c) 2012年 yuxinjin. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol CIPFilterControllerDelegate;

@interface CIPFilterController : UIViewController

@property (nonatomic, retain) UIImage *originalImage;
@property (assign) id<CIPFilterControllerDelegate> delegate;

@end

@protocol CIPFilterControllerDelegate<NSObject>
@optional

- (void) filterDidFinishProcess:(UIImage*)image;
- (void) filterDidCancel;
@end