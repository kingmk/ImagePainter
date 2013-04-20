//
//  CIPSettingTabController.h
//  ImagePainter
//
//  Created by yuxinjin on 12-9-28.
//  Copyright (c) 2012年 yuxinjin. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CIPSettingTabController : UITabBarController
@property (nonatomic) CIPPalette *palette;
@property (nonatomic) NSMutableDictionary *stateMap;

- (ImageProcState) getSelectedState;
- (ProcSubType) getMappedSubTypeFor:(ImageProcState)state;
- (void) setMapKey:(ImageProcState)state withValue:(ProcSubType)subType;
@end