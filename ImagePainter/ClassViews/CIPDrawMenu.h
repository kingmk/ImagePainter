//
//  CIPOperMenu.h
//  ImagePainter
//
//  Created by yuxinjin on 12-10-26.
//  Copyright (c) 2012年 yuxinjin. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CIPDrawMenu : UIControl
@property (nonatomic) ImageProcState selectedState;

- (void) selectState:(ImageProcState)state;
@end

