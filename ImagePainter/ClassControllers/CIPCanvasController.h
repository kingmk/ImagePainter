//
//  ViewController.h
//  ImagePainter
//
//  Created by yuxinjin on 12-9-20.
//  Copyright (c) 2012年 yuxinjin. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface CIPCanvasController : UIViewController<UINavigationControllerDelegate, UIImagePickerControllerDelegate, UITabBarControllerDelegate, UITextViewDelegate, UIActionSheetDelegate, UIAlertViewDelegate, CIPFilterControllerDelegate, CIPImageViewDelegate, CIPDrawSimpleDelegate, CIPLayerBarDelegate, CIPGalleryControllerDelegate, CIPColorPickControllerDelegate, CIPHistoryManagerDelegate, CIPTextControlDelegate, CIPCropControlDelegate>

@property (nonatomic, retain) UIImagePickerController *imagePickerController;

@end
