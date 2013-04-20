//
//  CIPColorPickerController.h
//  ImagePainter
//
//  Created by yuxinjin on 12-11-3.
//  Copyright (c) 2012年 yuxinjin. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol CIPColorPickControllerDelegate;

@interface CIPColorPickController : UIViewController

@property (nonatomic, retain) NSArray *colorHistory;
@property (nonatomic, retain) UIColor *color;
@property (nonatomic, assign) id<CIPColorPickControllerDelegate> delegate;

@end

@protocol CIPColorPickControllerDelegate <NSObject>

@optional
-(void) cipColorPick:(UIColor*)color;

@end