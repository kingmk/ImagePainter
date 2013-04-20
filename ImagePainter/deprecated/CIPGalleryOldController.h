//
//  CIPFileLoadController.h
//  ImagePainter
//
//  Created by yuxinjin on 12-10-14.
//  Copyright (c) 2012年 yuxinjin. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol CIPGalleryControllerDelegate;

@interface CIPGalleryOldController : UIViewController<UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate>

@property (nonatomic, assign) id<CIPGalleryControllerDelegate> delegate;
@end


@protocol CIPGalleryControllerDelegate <NSObject>
@optional
- (void) cipGallery:(CIPGalleryOldController*)galleryController didLoad:(NSArray*)layers withName:(NSString*)name;

@end