//
//  CIPSettingController.h
//  ImagePainter
//
//  Created by yuxinjin on 12-9-28.
//  Copyright (c) 2012年 yuxinjin. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CIPSettingController : UITableViewController
@property (nonatomic) CIPPalette *palette;
@property (nonatomic) ProcSubType subType;

- (void) updateViewWithPalette:(CIPPalette *)palette withSubType:(ProcSubType) subType;
@end
