//
//  CIPGalleryController.h
//  ImagePainter
//
//  Created by yuxinjin on 12-11-3.
//  Copyright (c) 2012年 yuxinjin. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol CIPGalleryControllerDelegate;

@interface CIPGalleryController : UIViewController<UIAlertViewDelegate, UIActionSheetDelegate>

@property (nonatomic, assign) id<CIPGalleryControllerDelegate> delegate;
@end


@protocol CIPGalleryControllerDelegate <NSObject>
@optional
- (void) cipGallery:(CIPGalleryController*)galleryController didLoad:(NSArray*)layers withName:(NSString*)name;

@end